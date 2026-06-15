package server.nitro.modules;

import commons.CommonRails;
import connections.CurrentConnections;
import exceptions.ExceptionHandler;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.net.*;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.concurrent.*;

public class ConnectionStatusServer extends Thread
{
    public static final int STATUS_PORT = 49155;

    private final CurrentConnections WATCHED;
    private final int WATCHEDPORT;
    private final String HOST;

    private volatile ServerSocket serverSocket;
    private final long startTime = System.currentTimeMillis();

    // Bounded responder pool
    private final ExecutorService responderPool =
            new ThreadPoolExecutor(
                    8,                      // core
                    32,                     // max
                    60L, TimeUnit.SECONDS,  // idle timeout
                    new LinkedBlockingQueue<>(256),
                    r -> {
                        Thread t = new Thread(r);
                        t.setDaemon(true);
                        t.setName("ConnectionStatusResponder");
                        return t;
                    },
                    new ThreadPoolExecutor.AbortPolicy()
            );

    // Simple geo cache
    private final ConcurrentMap<String, String> geoCache = new ConcurrentHashMap<>();
    private final ConcurrentMap<String, Long> geoCacheTime = new ConcurrentHashMap<>();
    private static final long GEO_TTL_MS = 10 * 60 * 1000; // 10 minutes

    public ConnectionStatusServer(final String HOST,
                                  final CurrentConnections WATCHED,
                                  final int WATCHEDPORT)
    {
        if (HOST == null || WATCHED == null)
            throw new SecurityException("//bodi/connect");

        if (WATCHEDPORT <= 0 || WATCHEDPORT > 65535)
            throw new IllegalArgumentException("Invalid WATCHEDPORT: " + WATCHEDPORT);

        this.HOST = HOST;
        this.WATCHED = WATCHED;
        this.WATCHEDPORT = WATCHEDPORT;

        this.setName("ConnectionStatusServer");
        this.setDaemon(true);
    }

    @Override
    public void run()
    {
        try
        {
            InetAddress bindAddr = InetAddress.getByName(HOST);
            serverSocket = new ServerSocket(STATUS_PORT, 256, bindAddr);

            CommonRails.printSystemComponent(
                    this, this.hashCode(),
                    ". ConnectionStatusServer listening on port " + STATUS_PORT + " ."
            );

            while (!Thread.currentThread().isInterrupted() && !serverSocket.isClosed())
            {
                try
                {
                    Socket client = serverSocket.accept();
                    client.setSoTimeout(20 * 60 * 1000);

                    // Submit to bounded pool; if saturated, close client quickly
                    try
                    {
                        responderPool.submit(() -> respond(client));
                    }
                    catch (RejectedExecutionException rex)
                    {
                        ExceptionHandler.dispatch(rex);
                        try { client.close(); } catch (Exception ignored) {}
                    }
                }
                catch (SocketException se)
                {
                    // Likely closed during shutdown
                    break;
                }
                catch (Exception e)
                {
                    ExceptionHandler.dispatch(e);
                }
            }
        }
        catch (Exception e)
        {
            ExceptionHandler.dispatch(e);
            e.printStackTrace(System.err);
        }
        finally
        {
            shutdown();
        }
    }

    /**
     * Graceful shutdown of server socket and responder pool.
     */
    public void shutdown()
    {
        try
        {
            if (serverSocket != null && !serverSocket.isClosed())
                serverSocket.close();
        }
        catch (Exception ignored) {}

        responderPool.shutdown();
        try
        {
            if (!responderPool.awaitTermination(10, TimeUnit.SECONDS))
                responderPool.shutdownNow();
        }
        catch (InterruptedException ie)
        {
            responderPool.shutdownNow();
            Thread.currentThread().interrupt();
        }

        CommonRails.printSystemComponent(
                this, this.hashCode(),
                ". ConnectionStatusServer shutdown complete ."
        );
    }

    private void respond(final Socket client)
    {
        String remoteIp = null;

        try
        {
            remoteIp = client.getInetAddress().getHostAddress();

            BufferedWriter writer = new BufferedWriter(
                    new OutputStreamWriter(client.getOutputStream(), java.nio.charset.StandardCharsets.UTF_8)
            );
            BufferedReader reader = new BufferedReader(
                    new InputStreamReader(client.getInputStream(), java.nio.charset.StandardCharsets.UTF_8)
            );

            // Per‑session language context (avoid global IP‑based state)
            String sessionLang = languages.LanguagePack.langOf(remoteIp);

            writer.write("[ NWE port " + STATUS_PORT + " ? Connection Status & Server Health Report  |  20-minute session ]\n");
            writer.write(languages.LanguagePack.t(sessionLang, "label.lang_menu") + "\n");
            writer.write(languages.LanguagePack.t(sessionLang, "label.lang_prompt") + "\n");
            writer.flush();

            client.setSoTimeout(20 * 60 * 1000);

            try
            {
                String line = reader.readLine();
                if (line != null)
                {
                    line = line.trim();
                    if (line.toLowerCase().startsWith("lang "))
                    {
                        String requested = line.substring(5).trim();
                        String reply = languages.LanguagePack.handleLangCommand(remoteIp, requested);
                        // Update session language after command
                        sessionLang = languages.LanguagePack.langOf(remoteIp);

                        writer.write(reply + "\n");
                        writer.flush();
                    }
                }
            }
            catch (SocketTimeoutException ignored)
            {
                // Language selection timed out; continue with default
            }

            client.setSoTimeout(0);

            int count = WATCHED.size();

            String geoLine   = fetchGeo(remoteIp);
            String localTime = LocalTime.now().format(DateTimeFormatter.ofPattern("h:mm a"));

            long uptimeSecs  = (System.currentTimeMillis() - startTime) / 1000;
            String uptime    = (uptimeSecs / 3600) + "hrs " +
                    ((uptimeSecs % 3600) / 60) + "mins " +
                    (uptimeSecs % 60) + "secs";

            Runtime rt       = Runtime.getRuntime();
            long totalMB     = rt.totalMemory() / (1024 * 1024);
            long usedMB      = (rt.totalMemory() - rt.freeMemory()) / (1024 * 1024);

            String[] geoParts = geoLine.split(", ", 2);
            database.N21Store.storeGeo(
                    remoteIp,
                    geoParts.length > 0 ? geoParts[0] : "",
                    geoParts.length > 1 ? geoParts[1] : ""
            );
            database.N21Store.storeStatusSnapshot(count, uptimeSecs, totalMB, usedMB);

            StringBuilder geoList = new StringBuilder();
            for (connections.Connection c : WATCHED.CURRENT_CONNECTION)
            {
                if (c.internet_address != null)
                {
                    String ip = c.internet_address.getHostAddress();
                    geoList.append("    ")
                            .append(ip)
                            .append("  ")
                            .append(fetchGeo(ip))
                            .append("\n");
                }
            }

            // Only expose counts, not internal thread names
            int runnableCount = 0;
            int timedWaitingCount = 0;
            for (Thread t : Thread.getAllStackTraces().keySet())
            {
                Thread.State s = t.getState();
                if (s == Thread.State.RUNNABLE) runnableCount++;
                else if (s == Thread.State.TIMED_WAITING) timedWaitingCount++;
            }

            String finalSessionLang = sessionLang;
            java.util.function.Function<String,String> L =
                    k -> languages.LanguagePack.t(finalSessionLang, k);

            String report =
                    "????????????????????????????????????????????????\n" +
                            "?  " + L.apply("header") + "                ?\n" +
                            "????????????????????????????????????????????????\n" +
                            L.apply("label.remote_ip")   + "           " + remoteIp  + "\n" +
                            L.apply("label.geo")         + "        " + geoLine   + "\n" +
                            L.apply("label.time")        + "   " + localTime + "\n" +
                            L.apply("label.uptime")      + "       " + uptime    + "\n" +
                            L.apply("label.memory")      + "        " + totalMB   + "MB (used: " + usedMB + "MB)\n" +
                            L.apply("label.connections") + " " + count + " current\n" +
                            "Thread summary: RUNNABLE=" + runnableCount +
                            ", TIMED_WAITING=" + timedWaitingCount + "\n" +
                            "\nConnected IPs & Geo:\n" +
                            (geoList.length() > 0 ? geoList.toString() : "    (none)\n") +
                            "\n" + L.apply("label.lang_revert") + "\n";

            CommonRails.printSystemComponent(
                    this, this.hashCode(),
                    ". ConnectionStatusServer >> status query: port=" + WATCHEDPORT +
                            " connections=" + count +
                            " lang=" + sessionLang + " ."
            );

            writer.write(report);
            writer.flush();
        }
        catch (Exception e)
        {
            ExceptionHandler.dispatch(e);
        }
        finally
        {
            try { client.close(); } catch (Exception ignored) {}
        }
    }

    private String fetchGeo(final String ip)
    {
        try
        {
            long now = System.currentTimeMillis();

            // Cache hit with TTL
            String cached = geoCache.get(ip);
            Long ts = geoCacheTime.get(ip);
            if (cached != null && ts != null && (now - ts) < GEO_TTL_MS)
            {
                return cached;
            }

            boolean isPrivate =
                    ip.startsWith("127.") ||
                            ip.startsWith("10.") ||
                            ip.startsWith("192.168.") ||
                            ip.equals("::1") ||
                            ip.equals("0:0:0:0:0:0:0:1");

            String targetIp = isPrivate ? "" : ip;
            String urlStr   = "http://IP-api.com/line/" + targetIp + "?fields=city,country";

            HttpURLConnection conn = (HttpURLConnection) new URL(urlStr).openConnection();
            conn.setConnectTimeout(1000);
            conn.setReadTimeout(1000);

            String result;
            try (BufferedReader br = new BufferedReader(new InputStreamReader(conn.getInputStream())))
            {
                String country = br.readLine();
                String city    = br.readLine();
                result = (city != null ? city : "?") + ", " + (country != null ? country : "?");
            }

            geoCache.put(ip, result);
            geoCacheTime.put(ip, now);

            return result;
        }
        catch (Exception e)
        {
            return "Unknown";
        }
    }
}
