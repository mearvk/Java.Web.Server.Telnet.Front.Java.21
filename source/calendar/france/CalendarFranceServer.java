/**
 * CalendarFranceServer — France Calendar module.
 * Runs on port 49201. Connects to French servers for information gathering,
 * sources, and signals on the internet. Stores in its own MySQL database
 * (nwe_calendar_france). Uses AES2 module and Calendar convergent fields
 * for sophisticated view and calculus.
 * Port-aware: 21, 22, 80, 443, 8080, 8888 for international connectivity.
 *
 * @author Max Rupplin
 * @javaowner Max Rupplin
 * @date June 19 2026 EST
 */

package calendar.france;

import commons.CommonRails;
import encryption.module.math.ConvergentFields;

import java.io.*;
import java.net.*;
import java.nio.charset.StandardCharsets;
import java.sql.*;
import java.time.LocalDate;
import java.time.temporal.ChronoField;

public class CalendarFranceServer implements Runnable
{
    public static final int PORT = 49201;
    public static final String THREAD_NAME = "CALENDAR_FRANCE_SERVER";
    private static final int[] AWARE_PORTS = {21, 22, 80, 443, 8080, 8888};

    private final String host;
    private Connection dbConn;
    private volatile boolean running = true;

    /**
     * Constructs the France server on the given host.
     *
     * @param host bind address
     * @javaowner Max Rupplin
     */
    public CalendarFranceServer(String host)
    {
        this.host = host;
        initDatabase();
        Thread.ofVirtual().name(THREAD_NAME).start(this);
        CommonRails.printSystemComponent(this, this.hashCode(),
            ". CalendarFrance™ now starting on port " + PORT + " .");
    }

    /**
     * Initialize the dedicated nwe_calendar_france database.
     *
     * @javaowner Max Rupplin
     */
    private void initDatabase()
    {
        try
        {
            dbConn = DriverManager.getConnection("jdbc:mysql://localhost:3306/nwe_calendar_france", "nwe", "nwe_receiver_pass");
            try (Statement stmt = dbConn.createStatement())
            {
                stmt.executeUpdate(
                    "CREATE TABLE IF NOT EXISTS france_entries (" +
                    "  id BIGINT AUTO_INCREMENT PRIMARY KEY," +
                    "  date_ordinal INT NOT NULL," +
                    "  year INT NOT NULL," +
                    "  category VARCHAR(64)," +
                    "  source_url VARCHAR(512)," +
                    "  source_port INT," +
                    "  signal_type VARCHAR(64)," +
                    "  content LONGTEXT," +
                    "  aes2_hash VARCHAR(128)," +
                    "  convergence_score DOUBLE," +
                    "  region VARCHAR(64) DEFAULT 'france'," +
                    "  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP" +
                    ")"
                );
            }
        }
        catch (SQLException e)
        {
            System.err.println("[CalendarFranceServer] Database init failed: " + e.getMessage());
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
            System.err.println("[CalendarFranceServer] Server error: " + e.getMessage());
        }
    }

    /**
     * Handles an incoming client connection.
     *
     * @param client the client socket
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
                String[] parts = request.split("\\|", 4);
                if (parts.length >= 3)
                {
                    String signalType = parts.length == 4 ? parts[3] : "news";
                    String result = fetchAndStore(parts[1], parts[2], signalType);
                    out.write(("OK|" + result.length() + "\n").getBytes(StandardCharsets.UTF_8));
                }
            }
            else if ("STATUS".equals(request.trim()))
            {
                String status = "ALIVE|port=" + PORT + "|region=france|date=" + LocalDate.now();
                out.write((status + "\n").getBytes(StandardCharsets.UTF_8));
            }

            out.flush();
        }
        catch (Exception e)
        {
            System.err.println("[CalendarFranceServer] Client error: " + e.getMessage());
        }
    }

    /**
     * Fetches content from a French source URL, computes convergence
     * with today's calendar, and stores in the database.
     *
     * @param url source URL
     * @param category information category
     * @param signalType type of signal (news, radio, government, academic)
     * @return fetched content
     * @javaowner Max Rupplin
     */
    public String fetchAndStore(String url, String category, String signalType)
    {
        try
        {
            int port = detectPort(url);
            HttpURLConnection conn = (HttpURLConnection) new URL(url).openConnection();
            conn.setRequestMethod("GET");
            conn.setConnectTimeout(10000);
            conn.setReadTimeout(10000);
            conn.setRequestProperty("Accept-Language", "fr-FR,fr;q=0.9,en;q=0.5");

            StringBuilder content = new StringBuilder();
            try (BufferedReader reader = new BufferedReader(new InputStreamReader(conn.getInputStream(), StandardCharsets.UTF_8)))
            {
                String line;
                while ((line = reader.readLine()) != null) content.append(line).append("\n");
            }

            String result = content.toString();
            LocalDate today = LocalDate.now();
            int ordinal = today.get(ChronoField.DAY_OF_YEAR);
            int year = today.getYear();

            int[] calStream = ConvergentFields.fromUSCalendar(today, 1);
            double score = calStream.length > 0 ? (result.hashCode() ^ calStream[0]) / (double) Integer.MAX_VALUE : 0.0;

            storeEntry(ordinal, year, category, url, port, signalType, result, Integer.toHexString(result.hashCode()), Math.abs(score));
            return result;
        }
        catch (Exception e)
        {
            System.err.println("[CalendarFranceServer] Fetch failed: " + e.getMessage());
            return "";
        }
    }

    /**
     * Stores an entry in the france_entries table.
     *
     * @javaowner Max Rupplin
     */
    private void storeEntry(int ordinal, int year, String category, String url, int port, String signalType, String content, String aes2Hash, double convergenceScore)
    {
        if (dbConn == null) return;
        try (PreparedStatement ps = dbConn.prepareStatement(
            "INSERT INTO france_entries (date_ordinal, year, category, source_url, source_port, signal_type, content, aes2_hash, convergence_score) VALUES (?,?,?,?,?,?,?,?,?)"))
        {
            ps.setInt(1, ordinal);
            ps.setInt(2, year);
            ps.setString(3, category);
            ps.setString(4, url);
            ps.setInt(5, port);
            ps.setString(6, signalType);
            ps.setString(7, content);
            ps.setString(8, aes2Hash);
            ps.setDouble(9, convergenceScore);
            ps.executeUpdate();
        }
        catch (SQLException e)
        {
            System.err.println("[CalendarFranceServer] Store failed: " + e.getMessage());
        }
    }

    /**
     * Connects to a French server on an aware port.
     *
     * @param host remote host
     * @param port one of 21, 22, 80, 443, 8080, 8888
     * @return socket connection or null
     * @javaowner Max Rupplin
     */
    public Socket connectFrance(String host, int port) throws IOException
    {
        if (!isPortAware(port))
        {
            throw new IOException("Port " + port + " is not in the aware ports list.");
        }
        if (port == 443)
        {
            return javax.net.ssl.SSLSocketFactory.getDefault().createSocket(host, port);
        }
        return new Socket(host, port);
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
            return switch (uri.getScheme())
            {
                case "https" -> 443;
                case "ftp" -> 21;
                case "ssh" -> 22;
                default -> 80;
            };
        }
        catch (Exception e) { return 80; }
    }

    /** @javaowner Max Rupplin */
    public void stop() { running = false; }
}
