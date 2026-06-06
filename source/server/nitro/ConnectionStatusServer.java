package server.nitro;

import commons.CommonRails;
import connections.CurrentConnections;
import exceptions.ExceptionHandler;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.net.HttpURLConnection;
import java.net.InetAddress;
import java.net.ServerSocket;
import java.net.Socket;
import java.net.URL;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.lang.management.ManagementFactory;

/**
 * Binds port 49155 and serves a plain-text status report on demand.
 * Any TCP connection to 49155 receives a snapshot of how many clients
 * are currently connected to the main WebExpress port (49152).
 */
public class ConnectionStatusServer extends Thread
{
    public static final int STATUS_PORT = 49155;

    private final CurrentConnections watched;

    private final int watchedPort;

    private final String host;

    private ServerSocket serverSocket;

    private final long startTime = System.currentTimeMillis();

    public ConnectionStatusServer(String host, CurrentConnections watched, int watchedPort)
    {
        if (host == null || watched == null) throw new SecurityException("//bodi/connect");

        this.host = host;
        this.watched = watched;
        this.watchedPort = watchedPort;

        this.setName("ConnectionStatusServer");
        this.setDaemon(true);
    }

    @Override
    public void run()
    {
        try
        {
            InetAddress addr = InetAddress.getByName(host);

            serverSocket = new ServerSocket(STATUS_PORT, 256, addr);

            CommonRails.printSystemComponent(this, this.hashCode(),
                    ". ConnectionStatusServer listening on port " + STATUS_PORT + " .");

            while (!Thread.currentThread().isInterrupted())
            {
                Socket client = serverSocket.accept();

                // Handle each status request on a short-lived thread
                Thread responder = new Thread(() -> respond(client));
                responder.setDaemon(true);
                responder.start();
            }
        } catch (Exception e)
        {
            ExceptionHandler.dispatch(e);
            e.printStackTrace(System.err);
        }
    }

    private void respond(Socket client)
    {
        try
        {
            int count = watched.size();

            String remoteIp = client.getInetAddress().getHostAddress();
            String geoLine = fetchGeo(remoteIp);
            String localTime = LocalTime.now().format(DateTimeFormatter.ofPattern("h:mm a"));

            long uptimeSecs  = (System.currentTimeMillis() - startTime) / 1000;
            String uptime    = (uptimeSecs / 3600) + "hrs " + ((uptimeSecs % 3600) / 60) + "mins " + (uptimeSecs % 60) + "secs";

            Runtime rt       = Runtime.getRuntime();
            long totalMB     = rt.totalMemory() / (1024 * 1024);
            long usedMB      = (rt.totalMemory() - rt.freeMemory()) / (1024 * 1024);

            // Persist geo + status snapshot to N21
            String[] geoParts = geoLine.split(", ", 2);
            db.N21Store.storeGeo(remoteIp, geoParts.length > 0 ? geoParts[0] : "", geoParts.length > 1 ? geoParts[1] : "");
            db.N21Store.storeStatusSnapshot(count, uptimeSecs, totalMB, usedMB);

            String banner =
                    "╔══════════════════════════════════════════════╗\n" +
                            "║   National JDK Finance Engine  v2811.1 v12.1 ║\n" +
                            "╚══════════════════════════════════════════════╝\n";

            String report = banner +
                    "Remote IP:           " + remoteIp  + "\n" +
                    "Geo Location:        " + geoLine   + "\n" +
                    "Local Server Time:   " + localTime + "\n" +
                    "Server Uptime:       " + uptime    + "\n" +
                    "Total Memory:        " + totalMB   + "MB (used: " + usedMB + "MB)\n" +
                    "Current Connections: " + count     + "\n";

            CommonRails.printSystemComponent(this, this.hashCode(),
                    ". ConnectionStatusServer >> status query: port=" + watchedPort
                            + " connections=" + count + " .");

            BufferedWriter writer = new BufferedWriter(new OutputStreamWriter(client.getOutputStream()));

            writer.write(report);
            writer.flush();
        } catch (Exception e)
        {
            ExceptionHandler.dispatch(e);
        } finally
        {
            try
            {
                client.close();
            } catch (Exception ignored)
            {
            }
        }
    }

    /**
     * Returns "City, Country" for the given IP, or "Unknown" on failure.
     * Private/loopback IPs fall back to the server's own public IP.
     */
    private String fetchGeo(String ip)
    {
        try
        {
            boolean isPrivate = ip.startsWith("127.") || ip.startsWith("10.")
                || ip.startsWith("192.168.") || ip.equals("::1") || ip.equals("0:0:0:0:0:0:0:1");

            String target = isPrivate ? "" : ip;

            HttpURLConnection conn = (HttpURLConnection) new URL("http://ip-api.com/line/" + target + "?fields=city,country").openConnection();
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
