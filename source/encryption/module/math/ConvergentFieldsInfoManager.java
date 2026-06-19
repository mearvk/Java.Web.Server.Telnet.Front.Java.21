/**
 * ConvergentFieldsInfoManager — Manages information retrieval from the internet
 * (news, stats, weddings, killings, etc.) and stores in MySQL or local data log.
 * Port-aware: 21, 443, 8080.
 *
 * @author Max Rupplin
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

    public ConvergentFieldsInfoManager(String mysqlHost, int mysqlPort, String database, String user, String pass)
    {
        this.mysqlUrl = "jdbc:mysql://" + mysqlHost + ":" + mysqlPort + "/" + database;
        this.mysqlUser = user;
        this.mysqlPass = pass;
        this.logFilePath = "source/encryption/module/math/data.log.information";
        initStorage();
    }

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

    public boolean isPortAware(int port)
    {
        for (int p : AWARE_PORTS) if (p == port) return true;
        return false;
    }

    public int[] getAwarePorts() { return AWARE_PORTS; }
}
