package server.hardened.experimental.m;

import commons.CommonRails;
import configuration.NitroWebExpressConfig;
import connections.*;
import exceptions.ExceptionHandler;
import heuristics.college.HeuristicClassifier;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.net.InetAddress;
import java.net.ServerSocket;
import java.net.Socket;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicLong;

/**
 * NationalAwareHardService — hardened server with request-weight balancing.
 *
 * Design philosophy:
 *   Every connection carries a "cost" proportional to the time and bytes it
 *   consumes.  A long-running request that occupies a slot for 10 minutes costs
 *   more than a quick handshake.  The server maintains a running weight budget
 *   and rejects or deprioritises connections whose projected cost exceeds the
 *   remaining capacity — protecting short, lightweight requests from starvation
 *   by heavy consumers.
 *
 * Weight model:
 *   spotValue   = 1.0   (base value of any new connection attempt)
 *   costPerSec  = 0.02  (weight accrued per second the connection is alive)
 *   costPerKB   = 0.05  (weight accrued per KB received from the client)
 *   budgetCap   = MAX_CONNECTIONS * spotValue  (total budget pool)
 *
 *   When a connection's accumulated weight exceeds WEIGHT_EJECT_THRESHOLD it is
 *   forcibly closed to free budget for waiting connections.
 *
 * Hardening (inherited + improved from HardenedBaseServer):
 *   • MAX_CONNECTIONS = 5040
 *   • MAX_PER_IP = 1
 *   • Socket timeout = 58 minutes
 *   • Port whitelist enforced at bind
 *   • Backlog 128, SO_REUSEADDR, TcpNoDelay, KeepAlive
 *   • Accept-loop resilient to individual failures
 *   • Graceful shutdown via volatile flag + socket close
 *   • releaseConnection decrements counters and reclaims weight budget
 *
 * @author Max Rupplin
 * @date June 16 2026 EST
 */
public abstract class NationalAwareHardService extends Thread
{
    // ── Limits ────────────────────────────────────────────────────────────────

    private static final int MAX_CONNECTIONS       = 5040;
    private static final int MAX_PER_IP            = 1;
    private static final int CONNECTION_TIMEOUT_MS = 58 * 60 * 1000;
    private static final int BACKLOG               = 128;

    // ── Weight model ──────────────────────────────────────────────────────────

    /** Base spot-value of any new connection attempt. */
    private static final double SPOT_VALUE              = 1.0;
    /** Weight accrued per second the connection is held open. */
    private static final double COST_PER_SEC            = 0.02;
    /** Weight accrued per KB received from the client. */
    private static final double COST_PER_KB             = 0.05;
    /** Maximum accumulated weight before forced ejection. */
    private static final double WEIGHT_EJECT_THRESHOLD  = 120.0;
    /** Total weight budget pool. */
    private static final double WEIGHT_BUDGET           = MAX_CONNECTIONS * SPOT_VALUE;

    // ── Port whitelist ────────────────────────────────────────────────────────

    private static final Set<Integer> ALLOWED_PORTS = Set.of(
        49152, 5512, 6682, 7743, 7744,
        49111, 49122, 49133, 49144, 49155,
        49166, 49177, 49188, 49199, 49200
    );

    // ── State ─────────────────────────────────────────────────────────────────

    public String HOST = "localhost";
    public InetAddress ADDRESS;
    public Integer PORT;
    public ServerSocket SERVER_SOCKET;
    public volatile boolean RUNNING = true;

    public CurrentConnections CURRENT_CONNECTIONS = new CurrentConnections();
    private final RecordedConnections RECORDED_CONNECTIONS = new RecordedConnections();
    private final InternationalConnections INTERNATIONAL_CONNECTIONS = new InternationalConnections();
    private final HeuristicClassifier HEURISTIC = new HeuristicClassifier();

    private final ConcurrentHashMap<String, AtomicInteger> ipConnectionCount = new ConcurrentHashMap<>();
    private final AtomicInteger activeConnections = new AtomicInteger(0);

    /** Current consumed weight across all live connections. */
    private final AtomicLong consumedWeightMillis = new AtomicLong(0); // stored as weight * 1000

    /** Per-connection weight ledger: connectionHashCode -> WeightEntry */
    private final ConcurrentHashMap<Integer, WeightEntry> weightLedger = new ConcurrentHashMap<>();

    // ── Constructor ───────────────────────────────────────────────────────────

    public NationalAwareHardService(final String HOST, final Integer PORT)
    {
        if (HOST == null || PORT == null)
            throw new commons.security.BodiSecurityException("//bodi/connect", Thread.currentThread().getStackTrace()[1]);
        if (!ALLOWED_PORTS.contains(PORT))
            throw new commons.security.BodiSecurityException("//bodi/port-not-allowed:" + PORT, Thread.currentThread().getStackTrace()[1]);

        this.HOST = HOST;
        this.PORT = PORT;
        this.setName("NationalAwareHard-" + PORT);

        try
        {
            this.ADDRESS = InetAddress.getByName(HOST);
            this.SERVER_SOCKET = new ServerSocket(this.PORT, BACKLOG, this.ADDRESS);
            this.SERVER_SOCKET.setReuseAddress(true);
            this.SERVER_SOCKET.setPerformancePreferences(0, 1, 2);
        }
        catch (Exception e)
        {
            ExceptionHandler.dispatch(e);
            this.RUNNING = false;
            return;
        }

        CommonRails.printSystemComponent(this, this.hashCode(),
            ". NationalAwareHardService bound port=" + PORT
            + " max=" + MAX_CONNECTIONS + " perIP=" + MAX_PER_IP
            + " weightBudget=" + WEIGHT_BUDGET + " .");
    }

    // ── Accept loop ───────────────────────────────────────────────────────────

    @Override
    public void run()
    {
        if (SERVER_SOCKET == null || !RUNNING) return;

        while (RUNNING)
        {
            Socket socket = null;
            try
            {
                socket = SERVER_SOCKET.accept();
                String remoteIp = socket.getInetAddress().getHostAddress();

                // ── 1. Global connection cap ──────────────────────────────────
                if (activeConnections.get() >= MAX_CONNECTIONS)
                {
                    reject(socket, remoteIp, "server at capacity (" + MAX_CONNECTIONS + ")");
                    continue;
                }

                // ── 2. Per-IP limit ───────────────────────────────────────────
                AtomicInteger ipCount = ipConnectionCount.computeIfAbsent(remoteIp, k -> new AtomicInteger(0));
                if (ipCount.get() >= MAX_PER_IP)
                {
                    reject(socket, remoteIp, "per-IP limit (" + MAX_PER_IP + ")");
                    continue;
                }

                // ── 3. Weight budget check ────────────────────────────────────
                double currentWeight = consumedWeightMillis.get() / 1000.0;
                if (currentWeight + SPOT_VALUE > WEIGHT_BUDGET)
                {
                    reject(socket, remoteIp, "weight budget exhausted (consumed=" + String.format("%.1f", currentWeight) + ")");
                    continue;
                }

                // ── 4. Heuristic classification ───────────────────────────────
                if (NitroWebExpressConfig.isEnabled("HEURISTIC_CLASSIFIER"))
                {
                    HeuristicClassifier.ConnectionEvent event =
                        new HeuristicClassifier.ConnectionEvent.Builder()
                            .ip(remoteIp).port(this.PORT).build();
                    HeuristicClassifier.Classification result = HEURISTIC.classify(event);
                    if (result.threat)
                    {
                        reject(socket, remoteIp, "threat: " + result.summary());
                        continue;
                    }
                }

                // ── 5. Socket hardening ───────────────────────────────────────
                socket.setSoTimeout(CONNECTION_TIMEOUT_MS);
                socket.setTcpNoDelay(true);
                socket.setKeepAlive(true);

                // ── 6. Build connection ───────────────────────────────────────
                Connection connection = new Connection(this);
                connection.SOCKET = socket;
                connection.remote_address = socket.getRemoteSocketAddress().toString();
                connection.internet_address = socket.getInetAddress();
                connection.inputstream = socket.getInputStream();
                connection.reader = new BufferedReader(new InputStreamReader(connection.inputstream));
                connection.outputstream = socket.getOutputStream();
                connection.writer = new BufferedWriter(new OutputStreamWriter(connection.outputstream));

                // ── 7. Track ──────────────────────────────────────────────────
                CURRENT_CONNECTIONS.add(connection);
                RECORDED_CONNECTIONS.add(connection);
                INTERNATIONAL_CONNECTIONS.add(connection);
                activeConnections.incrementAndGet();
                ipCount.incrementAndGet();

                // Charge spot value
                long spotMillis = (long)(SPOT_VALUE * 1000);
                consumedWeightMillis.addAndGet(spotMillis);
                weightLedger.put(System.identityHashCode(connection), new WeightEntry(remoteIp, spotMillis, System.currentTimeMillis()));

                database.N21Store.storeConnection(connection, this.PORT);

                CommonRails.printSystemComponent(this, this.hashCode(),
                    ". ACCEPTED " + remoteIp + " port=" + PORT
                    + " active=" + activeConnections.get()
                    + " weight=" + String.format("%.1f", consumedWeightMillis.get() / 1000.0)
                    + "/" + String.format("%.0f", WEIGHT_BUDGET) + " .");
            }
            catch (Exception e)
            {
                if (RUNNING)
                {
                    ExceptionHandler.dispatch(e);
                    try { if (socket != null && !socket.isClosed()) socket.close(); } catch (Exception ignored) {}
                }
            }
        }
    }

    // ── Weight accounting ─────────────────────────────────────────────────────

    /**
     * Call periodically (e.g. from ConnectionPoller) to accrue time-based weight
     * for a live connection. Returns true if the connection should be ejected.
     */
    public boolean accrueWeight(final Connection C, final long bytesReceivedSinceLastCall)
    {
        int key = System.identityHashCode(C);
        WeightEntry entry = weightLedger.get(key);
        if (entry == null) return false;

        long now = System.currentTimeMillis();
        double elapsedSec = (now - entry.lastAccrualMs) / 1000.0;
        double timeCost = elapsedSec * COST_PER_SEC;
        double dataCost = (bytesReceivedSinceLastCall / 1024.0) * COST_PER_KB;
        long deltaMillis = (long)((timeCost + dataCost) * 1000);

        entry.accruedMillis += deltaMillis;
        entry.lastAccrualMs = now;
        consumedWeightMillis.addAndGet(deltaMillis);

        double totalWeight = entry.accruedMillis / 1000.0;
        if (totalWeight >= WEIGHT_EJECT_THRESHOLD)
        {
            CommonRails.printSystemComponent(this, this.hashCode(),
                ". EJECT " + entry.ip + " — weight " + String.format("%.1f", totalWeight)
                + " exceeds threshold " + WEIGHT_EJECT_THRESHOLD + " .");
            return true;
        }
        return false;
    }

    // ── Release ───────────────────────────────────────────────────────────────

    public void releaseConnection(final Connection C)
    {
        activeConnections.decrementAndGet();

        int key = System.identityHashCode(C);
        WeightEntry entry = weightLedger.remove(key);
        if (entry != null)
        {
            consumedWeightMillis.addAndGet(-entry.accruedMillis);
            AtomicInteger ipCount = ipConnectionCount.get(entry.ip);
            if (ipCount != null) ipCount.decrementAndGet();
        }
        else if (C != null && C.internet_address != null)
        {
            String ip = C.internet_address.getHostAddress();
            AtomicInteger count = ipConnectionCount.get(ip);
            if (count != null) count.decrementAndGet();
        }
    }

    // ── Shutdown ──────────────────────────────────────────────────────────────

    public void shutdown()
    {
        RUNNING = false;
        try { if (SERVER_SOCKET != null && !SERVER_SOCKET.isClosed()) SERVER_SOCKET.close(); }
        catch (Exception ignored) {}
        CommonRails.printSystemComponent(this, this.hashCode(),
            ". NationalAwareHardService shutdown port=" + PORT + " .");
    }

    // ── Internals ─────────────────────────────────────────────────────────────

    private void reject(final Socket S, final String IP, final String REASON)
    {
        CommonRails.printSystemComponent(this, this.hashCode(),
            ". REJECTED " + IP + " — " + REASON + " .");
        try { S.close(); } catch (Exception ignored) {}
    }

    /** Per-connection weight tracking record. */
    private static class WeightEntry
    {
        final String ip;
        long accruedMillis;
        long lastAccrualMs;

        WeightEntry(final String IP, final long INITIAL_MILLIS, final long NOW)
        {
            this.ip = IP;
            this.accruedMillis = INITIAL_MILLIS;
            this.lastAccrualMs = NOW;
        }
    }
}
