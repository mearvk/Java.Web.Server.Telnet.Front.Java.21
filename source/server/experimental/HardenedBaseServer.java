package server.experimental;

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

/**
 * HardenedBaseServer — experimental hardened replacement for BaseServer.
 *
 * Improvements over BaseServer:
 *
 *  1. MAX_CONNECTIONS cap — rejects new connections once limit is reached.
 *  2. PER-IP connection limit — prevents a single IP from monopolising slots.
 *  3. PORT whitelist enforcement — refuses to bind on non-approved ports.
 *  4. Reduced SO_TIMEOUT — original 48-hour timeout replaced with 30-minute default.
 *  5. Backlog reduced from 4096 to 128 — limits SYN queue depth against SYN-flood.
 *  6. Accept-loop resilience — individual connection failures no longer kill the loop.
 *  7. ServerSocket hardening — SO_REUSEADDR enabled, performance preferences set.
 *  8. Graceful shutdown — RUNNING is volatile, shutdown() closes socket cleanly.
 *
 * @author Max Rupplin
 * @date June 16 2026 EST
 */
public abstract class HardenedBaseServer extends Thread
{
    // ── Configuration ─────────────────────────────────────────────────────────

    /** Maximum simultaneous connections server-wide. */
    private static final int MAX_CONNECTIONS = 512;

    /** Maximum simultaneous connections from a single IP. */
    private static final int MAX_PER_IP = 10;

    /** Socket timeout: 30 minutes (was 48 hours in BaseServer). */
    private static final int CONNECTION_TIMEOUT_MS = 30 * 60 * 1000;

    /** TCP backlog queue depth (was 4096). */
    private static final int BACKLOG = 128;

    /** Approved ports — connections on other ports are refused at bind time. */
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

    /** Live connection count per remote IP. */
    private final ConcurrentHashMap<String, AtomicInteger> ipConnectionCount = new ConcurrentHashMap<>();

    /** Total active connections. */
    private final AtomicInteger activeConnections = new AtomicInteger(0);

    // ── Constructors ──────────────────────────────────────────────────────────

    public HardenedBaseServer(final String HOST, final Integer PORT)
    {
        if (HOST == null || PORT == null)
            throw new commons.security.BodiSecurityException("//bodi/connect", Thread.currentThread().getStackTrace()[1]);

        if (!ALLOWED_PORTS.contains(PORT))
            throw new commons.security.BodiSecurityException("//bodi/port-not-allowed:" + PORT, Thread.currentThread().getStackTrace()[1]);

        this.HOST = HOST;
        this.PORT = PORT;
        this.setName("HardenedServer-" + PORT);

        try
        {
            this.ADDRESS = InetAddress.getByName(HOST);
            this.SERVER_SOCKET = new ServerSocket(this.PORT, BACKLOG, this.ADDRESS);
            this.SERVER_SOCKET.setReuseAddress(true);
            this.SERVER_SOCKET.setPerformancePreferences(0, 1, 2); // latency > bandwidth
        }
        catch (Exception e)
        {
            ExceptionHandler.dispatch(e);
            this.RUNNING = false;
            return;
        }

        CommonRails.printSystemComponent(this, this.hashCode(),
            ". HardenedBaseServer bound on port " + this.PORT + " (max=" + MAX_CONNECTIONS + ", perIP=" + MAX_PER_IP + ") .");
    }

    // ── Main accept loop ──────────────────────────────────────────────────────

    @Override
    public void run()
    {
        if (this.SERVER_SOCKET == null || !RUNNING) return;

        while (RUNNING)
        {
            Socket socket = null;
            try
            {
                socket = this.SERVER_SOCKET.accept();
                String remoteIp = socket.getInetAddress().getHostAddress();

                // ── 1. Global connection cap ──────────────────────────────────
                if (activeConnections.get() >= MAX_CONNECTIONS)
                {
                    CommonRails.printSystemComponent(this, this.hashCode(),
                        ". REJECTED connection from " + remoteIp + " — server at capacity (" + MAX_CONNECTIONS + ") .");
                    socket.close();
                    continue;
                }

                // ── 2. Per-IP connection limit ────────────────────────────────
                AtomicInteger ipCount = ipConnectionCount.computeIfAbsent(remoteIp, k -> new AtomicInteger(0));
                if (ipCount.get() >= MAX_PER_IP)
                {
                    CommonRails.printSystemComponent(this, this.hashCode(),
                        ". REJECTED connection from " + remoteIp + " — per-IP limit (" + MAX_PER_IP + ") .");
                    socket.close();
                    continue;
                }

                // ── 3. Heuristic classification ───────────────────────────────
                if (NitroWebExpressConfig.isEnabled("HEURISTIC_CLASSIFIER"))
                {
                    HeuristicClassifier.ConnectionEvent event =
                        new HeuristicClassifier.ConnectionEvent.Builder()
                            .ip(remoteIp).port(this.PORT).build();
                    HeuristicClassifier.Classification result = HEURISTIC.classify(event);
                    if (result.threat)
                    {
                        CommonRails.printSystemComponent(this, this.hashCode(),
                            ". REJECTED threat: " + result.summary() + " .");
                        socket.close();
                        continue;
                    }
                }

                // ── 4. Apply hardened socket settings ─────────────────────────
                socket.setSoTimeout(CONNECTION_TIMEOUT_MS);
                socket.setTcpNoDelay(true);
                socket.setKeepAlive(true);

                // ── 5. Build connection object ────────────────────────────────
                Connection connection = new Connection(this);
                connection.SOCKET = socket;
                connection.remote_address = socket.getRemoteSocketAddress().toString();
                connection.internet_address = socket.getInetAddress();
                connection.SERVER = this;
                connection.inputstream = socket.getInputStream();
                connection.reader = new BufferedReader(new InputStreamReader(connection.inputstream));
                connection.outputstream = socket.getOutputStream();
                connection.writer = new BufferedWriter(new OutputStreamWriter(connection.outputstream));

                // ── 6. Start poller, track connection ─────────────────────────
                connection.thread = new ConnectionPoller(this, this.HOST, this.PORT);
                connection.thread.start();

                this.CURRENT_CONNECTIONS.add(connection);
                this.RECORDED_CONNECTIONS.add(connection);
                this.INTERNATIONAL_CONNECTIONS.add(connection);
                activeConnections.incrementAndGet();
                ipCount.incrementAndGet();

                database.N21Store.storeConnection(connection, this.PORT);

                CommonRails.printSystemComponent(this, this.hashCode(),
                    ". ACCEPTED " + remoteIp + " on port " + this.PORT
                    + " (active=" + activeConnections.get() + ", ipSlots=" + ipCount.get() + "/" + MAX_PER_IP + ") .");
            }
            catch (Exception e)
            {
                // Individual connection failure must NOT kill the accept loop
                if (RUNNING)
                {
                    ExceptionHandler.dispatch(e);
                    try { if (socket != null && !socket.isClosed()) socket.close(); } catch (Exception ignored) {}
                }
            }
        }
    }

    // ── Connection release (call when a connection is closed) ─────────────────

    public void releaseConnection(final Connection C)
    {
        activeConnections.decrementAndGet();
        if (C != null && C.internet_address != null)
        {
            String ip = C.internet_address.getHostAddress();
            AtomicInteger count = ipConnectionCount.get(ip);
            if (count != null) count.decrementAndGet();
        }
    }

    // ── Graceful shutdown ─────────────────────────────────────────────────────

    public void shutdown()
    {
        RUNNING = false;
        try { if (SERVER_SOCKET != null && !SERVER_SOCKET.isClosed()) SERVER_SOCKET.close(); }
        catch (Exception ignored) {}
        CommonRails.printSystemComponent(this, this.hashCode(), ". HardenedBaseServer shutdown on port " + PORT + " .");
    }
}
