/**
 * UkraineSignalServer — Connects to Ukrainian servers for news, market signals,
 * and internet data. Stores in nwe_ukraine MySQL database.
 * Port-aware: 21, 22, 80, 443, 8080, 8888.
 *
 * @author Max Rupplin
 * @javaowner Max Rupplin
 * @date June 19 2026 EST
 */

package ukraine;

import java.io.*;
import java.net.*;
import java.nio.charset.StandardCharsets;
import java.sql.*;
import java.time.Instant;
import javax.net.ssl.SSLSocketFactory;

public class UkraineSignalServer implements Runnable
{
    public static final int PORT = 49203;
    public static final String THREAD_NAME = "UKRAINE_SIGNAL_SERVER";
    private static final int[] AWARE_PORTS = {21, 22, 80, 443, 8080, 8888};

    private final String host;
    private Connection dbConn;
    private volatile boolean running = true;

    /**
     * Constructs the Ukraine signal server.
     *
     * @param host bind address
     * @javaowner Max Rupplin
     */
    public UkraineSignalServer(String host)
    {
        this.host = host;
        initDatabase();
        Thread.ofVirtual().name(THREAD_NAME).start(this);
    }

    /**
     * Initializes the nwe_ukraine database and tables.
     *
     * @javaowner Max Rupplin
     */
    private void initDatabase()
    {
        try
        {
            dbConn = DriverManager.getConnection("jdbc:mysql://localhost:3306/nwe_ukraine", "nwe", "nwe_ukraine_pass");
            try (Statement stmt = dbConn.createStatement())
            {
                stmt.executeUpdate(
                    "CREATE TABLE IF NOT EXISTS ukraine_signals (" +
                    "  id BIGINT AUTO_INCREMENT PRIMARY KEY," +
                    "  signal_type VARCHAR(32) NOT NULL," +
                    "  source_id VARCHAR(64)," +
                    "  source_url VARCHAR(512)," +
                    "  source_port INT," +
                    "  content LONGTEXT," +
                    "  lang VARCHAR(8) DEFAULT 'uk'," +
                    "  retrieved_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP" +
                    ")"
                );
                stmt.executeUpdate(
                    "CREATE TABLE IF NOT EXISTS ukraine_news (" +
                    "  id BIGINT AUTO_INCREMENT PRIMARY KEY," +
                    "  source_id VARCHAR(64)," +
                    "  category VARCHAR(32)," +
                    "  url VARCHAR(512)," +
                    "  headline VARCHAR(512)," +
                    "  content LONGTEXT," +
                    "  retrieved_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP" +
                    ")"
                );
                stmt.executeUpdate(
                    "CREATE TABLE IF NOT EXISTS ukraine_market_data (" +
                    "  id BIGINT AUTO_INCREMENT PRIMARY KEY," +
                    "  index_name VARCHAR(64) NOT NULL," +
                    "  value_raw TEXT," +
                    "  source_url VARCHAR(512)," +
                    "  retrieved_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP" +
                    ")"
                );
            }
        }
        catch (SQLException e)
        {
            System.err.println("[UkraineSignalServer] Database init failed: " + e.getMessage());
        }
    }

    @Override
    public void run()
    {
        try (ServerSocket ss = new ServerSocket(PORT, 50, InetAddress.getByName(host)))
        {
            while (running)
            {
                Socket client = ss.accept();
                Thread.ofVirtual().start(() -> handleClient(client));
            }
        }
        catch (Exception e)
        {
            System.err.println("[UkraineSignalServer] Server error: " + e.getMessage());
        }
    }

    /**
     * Handles incoming client requests.
     *
     * @javaowner Max Rupplin
     */
    private void handleClient(Socket client)
    {
        try (BufferedReader in = new BufferedReader(new InputStreamReader(client.getInputStream()));
             OutputStream out = client.getOutputStream())
        {
            String request = in.readLine();
            if (request == null) return;

            if (request.startsWith("FETCH|"))
            {
                String[] parts = request.split("\\|", 3);
                if (parts.length == 3)
                {
                    String result = fetchSource(parts[1], parts[2]);
                    out.write(("OK|" + result.length() + "\n").getBytes(StandardCharsets.UTF_8));
                }
            }
            else if (request.startsWith("SIGNAL|"))
            {
                String[] parts = request.split("\\|", 2);
                if (parts.length == 2)
                {
                    String result = fetchSignal(parts[1]);
                    out.write(("OK|" + result.length() + "\n").getBytes(StandardCharsets.UTF_8));
                }
            }
            else if ("STATUS".equals(request.trim()))
            {
                out.write(("ALIVE|ukraine|port=" + PORT + "\n").getBytes(StandardCharsets.UTF_8));
            }

            out.flush();
        }
        catch (Exception e)
        {
            System.err.println("[UkraineSignalServer] Client error: " + e.getMessage());
        }
    }

    /**
     * Fetches content from a Ukrainian news source and stores in ukraine_news.
     *
     * @param sourceId source identifier from ukraine-config.xml
     * @param url URL to fetch
     * @return fetched content
     * @javaowner Max Rupplin
     */
    public String fetchSource(String sourceId, String url)
    {
        try
        {
            String content = httpGet(url);
            if (dbConn != null)
            {
                try (PreparedStatement ps = dbConn.prepareStatement(
                    "INSERT INTO ukraine_news (source_id, category, url, content) VALUES (?, ?, ?, ?)"))
                {
                    ps.setString(1, sourceId);
                    ps.setString(2, "news");
                    ps.setString(3, url);
                    ps.setString(4, content);
                    ps.executeUpdate();
                }
            }
            return content;
        }
        catch (Exception e)
        {
            System.err.println("[UkraineSignalServer] Fetch source failed: " + e.getMessage());
            return "";
        }
    }

    /**
     * Fetches a signal (market, currency, energy) and stores in ukraine_signals.
     *
     * @param signalUrl signal URL
     * @return fetched content
     * @javaowner Max Rupplin
     */
    public String fetchSignal(String signalUrl)
    {
        try
        {
            int port = detectPort(signalUrl);
            String content = httpGet(signalUrl);
            if (dbConn != null)
            {
                try (PreparedStatement ps = dbConn.prepareStatement(
                    "INSERT INTO ukraine_signals (signal_type, source_url, source_port, content) VALUES (?, ?, ?, ?)"))
                {
                    ps.setString(1, "signal");
                    ps.setString(2, signalUrl);
                    ps.setInt(3, port);
                    ps.setString(4, content);
                    ps.executeUpdate();
                }
            }
            return content;
        }
        catch (Exception e)
        {
            System.err.println("[UkraineSignalServer] Fetch signal failed: " + e.getMessage());
            return "";
        }
    }

    /**
     * Connects to a Ukrainian server on an aware port.
     *
     * @param host remote host
     * @param port target port
     * @return socket connection
     * @javaowner Max Rupplin
     */
    public Socket connectUkraine(String host, int port) throws IOException
    {
        if (!isPortAware(port)) throw new IOException("Port " + port + " not in aware list.");
        if (port == 443) return SSLSocketFactory.getDefault().createSocket(host, port);
        return new Socket(host, port);
    }

    /** @javaowner Max Rupplin */
    private String httpGet(String url) throws IOException
    {
        HttpURLConnection conn = (HttpURLConnection) new URL(url).openConnection();
        conn.setRequestMethod("GET");
        conn.setConnectTimeout(10000);
        conn.setReadTimeout(10000);
        conn.setRequestProperty("Accept-Language", "uk,en;q=0.9");

        StringBuilder sb = new StringBuilder();
        try (BufferedReader reader = new BufferedReader(new InputStreamReader(conn.getInputStream(), StandardCharsets.UTF_8)))
        {
            String line;
            while ((line = reader.readLine()) != null) sb.append(line).append("\n");
        }
        return sb.toString();
    }

    /** @javaowner Max Rupplin */
    public boolean isPortAware(int port)
    {
        for (int p : AWARE_PORTS) if (p == port) return true;
        return false;
    }

    /** @javaowner Max Rupplin */
    private int detectPort(String url)
    {
        try
        {
            URI uri = new URI(url);
            int p = uri.getPort();
            if (p > 0) return p;
            return "https".equals(uri.getScheme()) ? 443 : 80;
        }
        catch (Exception e) { return 80; }
    }

    /** @javaowner Max Rupplin */
    public void stop() { running = false; }
}
