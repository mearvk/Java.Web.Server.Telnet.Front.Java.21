/**
 * ConvergentFieldsInfoManager — Manages information retrieval from the internet
 * (news, stats, weddings, killings, etc.) and stores in MySQL or local data log.
 * Port-aware: 21, 443, 8080.
 *
 * @author Max Rupplin
 * @javaowner Max Rupplin
 * @date June 18 2026 EST
 */

package encryption.module.math;

import java.io.*;
import java.net.*;
import java.nio.charset.StandardCharsets;
import java.sql.*;
import java.time.Instant;
import javax.net.ssl.HttpsURLConnection;

public class ConvergentFieldsInfoManager
{
    private final String mysqlUrl;
    private final String mysqlUser;
    private final String mysqlPass;
    private final String logFilePath;
    private Connection dbConn;
    private boolean useDatabase;

    private static final int[] AWARE_PORTS = {21, 443, 8080};

    /**
     * Constructs the info manager with MySQL connection details.
     * Falls back to file logging if database is unavailable.
     *
     * @param mysqlHost MySQL host address
     * @param mysqlPort MySQL port
     * @param database database name
     * @param user MySQL username
     * @param pass MySQL password
     * @javaowner Max Rupplin
     */
    public ConvergentFieldsInfoManager(String mysqlHost, int mysqlPort, String database, String user, String pass)
    {
        this.mysqlUrl = "jdbc:mysql://" + mysqlHost + ":" + mysqlPort + "/" + database;
        this.mysqlUser = user;
        this.mysqlPass = pass;
        this.logFilePath = "source/encryption/module/math/data.log.information";
        initStorage();
    }

    /**
     * Initializes storage backend — MySQL or file fallback.
     *
     * @javaowner Max Rupplin
     */
    private void initStorage()
    {
        try
        {
            dbConn = DriverManager.getConnection(mysqlUrl, mysqlUser, mysqlPass);
            dbConn.createStatement().executeUpdate(
                "CREATE TABLE IF NOT EXISTS convergent_info (" +
                "  id BIGINT AUTO_INCREMENT PRIMARY KEY," +
                "  category VARCHAR(64) NOT NULL," +
                "  source_url VARCHAR(512)," +
                "  port INT," +
                "  content LONGTEXT," +
                "  retrieved_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP" +
                ")"
            );
            useDatabase = true;
        }
        catch (Exception e)
        {
            useDatabase = false;
            System.err.println("[ConvergentFieldsInfoManager] MySQL unavailable, using file: " + logFilePath);
        }
    }

    /**
     * Fetch information from a URL using an aware port (21, 443, 8080).
     *
     * @param url the URL to fetch from
     * @param category category label (news, stats, weddings, killings, etc.)
     * @return fetched content as a string
     * @throws IOException if the connection fails
     * @javaowner Max Rupplin
     */
    public String fetch(String url, String category) throws IOException
    {
        int port = detectPort(url);
        HttpURLConnection conn = (HttpURLConnection) new URL(url).openConnection();
        conn.setRequestMethod("GET");
        conn.setConnectTimeout(10000);
        conn.setReadTimeout(10000);

        StringBuilder content = new StringBuilder();
        try (BufferedReader reader = new BufferedReader(new InputStreamReader(conn.getInputStream(), StandardCharsets.UTF_8)))
        {
            String line;
            while ((line = reader.readLine()) != null) content.append(line).append("\n");
        }

        String result = content.toString();
        store(category, url, port, result);
        return result;
    }

    /**
     * Detects the port from a URL scheme or explicit port.
     *
     * @param url the URL string
     * @return detected port number
     * @javaowner Max Rupplin
     */
    private int detectPort(String url)
    {
        try
        {
            URI uri = new URI(url);
            int p = uri.getPort();
            if (p > 0) return p;
            if ("https".equals(uri.getScheme())) return 443;
            if ("ftp".equals(uri.getScheme())) return 21;
            return 8080;
        }
        catch (Exception e) { return 8080; }
    }

    /**
     * Stores content to the active backend (MySQL or file).
     *
     * @param category category label
     * @param sourceUrl origin URL
     * @param port port used
     * @param content fetched content
     * @javaowner Max Rupplin
     */
    public void store(String category, String sourceUrl, int port, String content)
    {
        if (useDatabase)
        {
            storeDB(category, sourceUrl, port, content);
        }
        else
        {
            storeFile(category, sourceUrl, port, content);
        }
    }

    /**
     * Stores to MySQL database.
     *
     * @javaowner Max Rupplin
     */
    private void storeDB(String category, String sourceUrl, int port, String content)
    {
        try (PreparedStatement ps = dbConn.prepareStatement(
            "INSERT INTO convergent_info (category, source_url, port, content) VALUES (?, ?, ?, ?)"))
        {
            ps.setString(1, category);
            ps.setString(2, sourceUrl);
            ps.setInt(3, port);
            ps.setString(4, content);
            ps.executeUpdate();
        }
        catch (SQLException e)
        {
            System.err.println("[ConvergentFieldsInfoManager] DB store failed: " + e.getMessage());
            storeFile(category, sourceUrl, port, content);
        }
    }

    /**
     * Stores to local data.log.information file.
     *
     * @javaowner Max Rupplin
     */
    private void storeFile(String category, String sourceUrl, int port, String content)
    {
        try (FileWriter fw = new FileWriter(logFilePath, true))
        {
            fw.write("--- " + Instant.now() + " | " + category + " | port:" + port + " | " + sourceUrl + " ---\n");
            fw.write(content + "\n\n");
        }
        catch (IOException e)
        {
            System.err.println("[ConvergentFieldsInfoManager] File store failed: " + e.getMessage());
        }
    }

    /**
     * Checks if a port is in the aware ports list.
     *
     * @param port port number to check
     * @return true if port is 21, 443, or 8080
     * @javaowner Max Rupplin
     */
    public boolean isPortAware(int port)
    {
        for (int p : AWARE_PORTS) if (p == port) return true;
        return false;
    }

    /**
     * Returns the array of aware ports.
     *
     * @return int array of ports {21, 443, 8080}
     * @javaowner Max Rupplin
     */
    public int[] getAwarePorts() { return AWARE_PORTS; }
}
