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

public class ConnectionStatusServer extends Thread
{
    public static final int STATUS_PORT = 49155;

    private final CurrentConnections WATCHED;
    private final int WATCHEDPORT;
    private final String HOST;
    private ServerSocket SERVERSOCKET;
    private final long startTime = System.currentTimeMillis();

    public ConnectionStatusServer(final String HOST, final CurrentConnections WATCHED, final int WATCHEDPORT)
    {
        if (HOST == null || WATCHED == null) throw new SecurityException("//bodi/connect");

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
            this.SERVERSOCKET = new ServerSocket(STATUS_PORT, 256, InetAddress.getByName(HOST));

            CommonRails.printSystemComponent(this, this.hashCode(), ". ConnectionStatusServer listening on port " + STATUS_PORT + " .");

            while (!Thread.currentThread().isInterrupted())
            {
                Socket client = SERVERSOCKET.accept();

                client.setSoTimeout(20 * 60 * 1000);

                Thread responder = new Thread(() -> respond(client));

                responder.setDaemon(true);

                responder.start();
            }
        }
        catch (Exception e) { ExceptionHandler.dispatch(e); e.printStackTrace(System.err); }
    }

    private void respond(final Socket CLIENT)
    {
        try
        {
            String remoteIp = CLIENT.getInetAddress().getHostAddress();

            BufferedWriter writer = new BufferedWriter(new OutputStreamWriter(CLIENT.getOutputStream(), java.nio.charset.StandardCharsets.UTF_8));

            BufferedReader reader = new BufferedReader(new java.io.InputStreamReader(CLIENT.getInputStream(), java.nio.charset.StandardCharsets.UTF_8));

            writer.write("[ NWE port " + STATUS_PORT + " — Connection Status & Server Health Report  |  20-minute session ]\n");

            writer.write(languages.LanguagePack.t(remoteIp, "label.lang_menu") + "\n");

            writer.write(languages.LanguagePack.t(remoteIp, "label.lang_prompt") + "\n");

            writer.flush();

            CLIENT.setSoTimeout(20 * 60 * 1000);

            try
            {
                String line = reader.readLine();

                if (line != null)
                {
                    line = line.trim();

                    if (line.toLowerCase().startsWith("lang "))
                    {
                        String reply = languages.LanguagePack.handleLangCommand(remoteIp, line.substring(5).trim());

                        writer.write(reply + "\n");

                        writer.flush();
                    }
                }
            }
            catch (java.net.SocketTimeoutException ignored)
            {

            }

            CLIENT.setSoTimeout(0);

            int count = WATCHED.size();

            String geoLine   = fetchGeo(remoteIp);

            String localTime = LocalTime.now().format(DateTimeFormatter.ofPattern("h:mm a"));

            long uptimeSecs  = (System.currentTimeMillis() - startTime) / 1000;

            String uptime    = (uptimeSecs / 3600) + "hrs " + ((uptimeSecs % 3600) / 60) + "mins " + (uptimeSecs % 60) + "secs";

            Runtime rt       = Runtime.getRuntime();

            long totalMB     = rt.totalMemory() / (1024 * 1024);

            long usedMB      = (rt.totalMemory() - rt.freeMemory()) / (1024 * 1024);

            String[] geoParts = geoLine.split(", ", 2);

            database.N21Store.storeGeo(remoteIp, geoParts.length > 0 ? geoParts[0] : "", geoParts.length > 1 ? geoParts[1] : "");

            database.N21Store.storeStatusSnapshot(count, uptimeSecs, totalMB, usedMB);

            StringBuilder geoList = new StringBuilder();

            for (connections.Connection c : WATCHED.CURRENT_CONNECTION)
            {
                if (c.internet_address != null)
                {
                    String ip = c.internet_address.getHostAddress();

                    geoList.append("    ").append(ip).append("  ").append(fetchGeo(ip)).append("\n");
                }
            }

            StringBuilder threads = new StringBuilder();

            Thread.getAllStackTraces().keySet().stream()
                    .filter(t -> t.getState() == Thread.State.RUNNABLE || t.getState() == Thread.State.TIMED_WAITING)
                    .sorted(java.util.Comparator.comparing(Thread::getName))
                    .forEach(t -> threads.append("    [").append(t.getState()).append("] ")
                            .append(t.getName()).append("\n"));

            java.util.function.Function<String,String> L = k -> languages.LanguagePack.t(remoteIp, k);

            String report =
                    "╔══════════════════════════════════════════════╗\n" +
                            "║  " + L.apply("header") + "                ║\n" +
                            "╚══════════════════════════════════════════════╝\n" +
                            L.apply("label.remote_ip")    + "           " + remoteIp  + "\n" +
                            L.apply("label.geo")          + "        " + geoLine   + "\n" +
                            L.apply("label.time")         + "   " + localTime + "\n" +
                            L.apply("label.uptime")       + "       " + uptime    + "\n" +
                            L.apply("label.memory")       + "        " + totalMB   + "MB (used: " + usedMB + "MB)\n" +
                            L.apply("label.connections")  + " " + count + " current\n" +
                            "\nConnected IPs & Geo:\n" + (geoList.length() > 0 ? geoList : "    (none)\n") +
                            "\nRunning Server Threads:\n" + (threads.length() > 0 ? threads : "    (none)\n") +
                            "\n" + L.apply("label.lang_revert") + "\n";

            CommonRails.printSystemComponent(this, this.hashCode(), ". ConnectionStatusServer >> status query: port=" + WATCHEDPORT + " connections=" + count + " lang=" + languages.LanguagePack.langOf(remoteIp) + " .");

            writer.write(report);
            writer.flush();
        }
        catch (Exception e) { ExceptionHandler.dispatch(e); }
        finally { try { CLIENT.close(); } catch (Exception ignored) {} }
    }

    private String fetchGeo(final String IP)
    {
        try
        {
            boolean isPrivate = IP.startsWith("127.") || IP.startsWith("10.") || IP.startsWith("192.168.") || IP.equals("::1") || IP.equals("0:0:0:0:0:0:0:1");

            HttpURLConnection conn = (HttpURLConnection) new URL("http://IP-api.com/line/" + (isPrivate ? "" : IP) + "?fields=city,country").openConnection();

            conn.setConnectTimeout(2000);

            conn.setReadTimeout(2000);

            try (BufferedReader br = new BufferedReader(new InputStreamReader(conn.getInputStream())))
            {
                String country = br.readLine();

                String city    = br.readLine();

                return (city != null ? city : "?") + ", " + (country != null ? country : "?");
            }
        }
        catch (Exception e)
        {
            return "Unknown";
        }
    }
}