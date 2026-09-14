package modules.Defined.source.protocol;

import java.sql.*;

/**
 * MySQLHandler — Protocol handler for MySQL (port 3306).
 * Manages database connections with multiple credential levels.
 * Admin credentials: full access. Capitalist credentials: read-only or reports.
 *
 * @author MEARVK LLC — Max Rupplin
 * @date July 2026
 */
public class MySQLHandler extends ProtocolHandler
{
    private String database = "defined_dark_gray";
    private String host = "localhost";
    private Connection currentConnection;

    public MySQLHandler()
    {
        super(3306, "MySQL", "MySQL — Database Protocol");
    }

    /**
     * Connect to MySQL using a specific credential.
     */
    public Connection connect(Credential cred) throws SQLException
    {
        String url = "jdbc:mysql://" + host + ":" + port + "/" + database +
                     "?useSSL=false&serverTimezone=America/New_York";
        String password = cred.resolvePassword();

        Connection conn = DriverManager.getConnection(url, cred.username, password);
        logConnection("MYSQL-CONNECT: " + cred.username + " (" + cred.role + ") → " + database);
        currentConnection = conn;
        return conn;
    }

    /**
     * Connect with the first admin credential available.
     */
    public Connection connectAsAdmin() throws SQLException
    {
        for (Credential cred : credentials.values())
        {
            if ("admin".equals(cred.role))
            {
                return connect(cred);
            }
        }
        throw new SQLException("No admin credential configured for MySQL");
    }

    /**
     * Connect with the first capitalist (read-only) credential.
     */
    public Connection connectAsCapitalist() throws SQLException
    {
        for (Credential cred : credentials.values())
        {
            if ("capitalist".equals(cred.role))
            {
                return connect(cred);
            }
        }
        throw new SQLException("No capitalist credential configured for MySQL");
    }

    /**
     * Test database connectivity.
     */
    public boolean testDatabaseConnection(Credential cred)
    {
        try (Connection conn = connect(cred))
        {
            boolean valid = conn.isValid(5);
            logConnection("MYSQL-TEST: " + (valid ? "OK" : "FAIL"));
            return valid;
        }
        catch (SQLException e)
        {
            logConnection("MYSQL-TEST-FAIL: " + e.getMessage());
            return false;
        }
    }

    public void setDatabase(String db) { this.database = db; }
    public void setHost(String h) { this.host = h; }
    public String getDatabase() { return database; }

    @Override
    public void start()
    {
        active = true;
        logConnection("MySQL handler started (db=" + database + ")");
    }

    @Override
    public void stop()
    {
        active = false;
        if (currentConnection != null)
        {
            try { currentConnection.close(); } catch (SQLException ignored) {}
        }
        logConnection("MySQL handler stopped");
    }
}
