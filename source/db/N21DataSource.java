package db;

import java.sql.Connection;
import java.sql.DriverManager;

/**
 * Provides a single shared JDBC connection to the N21 MySQL database.
 * Once a connection attempt fails, isAvailable() returns false so callers
 * can route immediately to the XML fallback without retrying on every call.
 * A successful reconnect re-enables DB mode automatically.
 */
public class N21DataSource
{
    private static final String URL  = "jdbc:mysql://localhost:3306/N21?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC&connectTimeout=3000";
    private static final String USER = "root";
    private static final String PASS = "";  // override with env N21_DB_PASS

    private static Connection CONNECTION  = null;
    private static boolean    DB_FAILED   = false;   // latched on first failure, cleared on success

    public static synchronized boolean isAvailable()
    {
        if (DB_FAILED) return false;
        try
        {
            return CONNECTION != null && !CONNECTION.isClosed();
        }
        catch (Exception e) { return false; }
    }

    public static synchronized Connection get() throws Exception
    {
        String pass = System.getenv("N21_DB_PASS") != null ? System.getenv("N21_DB_PASS") : PASS;

        if (CONNECTION == null || CONNECTION.isClosed())
        {
            Class.forName("com.mysql.cj.jdbc.Driver");
            CONNECTION = DriverManager.getConnection(URL, USER, pass);
            CONNECTION.setAutoCommit(true);
            DB_FAILED = false;  // successful connect clears failure latch
        }

        return CONNECTION;
    }

    /** Mark DB as unavailable — called by N21Store on any exception. */
    public static synchronized void markFailed()
    {
        DB_FAILED = true;
        try { if (CONNECTION != null) CONNECTION.close(); } catch (Exception ignored) {}
        CONNECTION = null;
    }

    public static synchronized void close()
    {
        try { if (CONNECTION != null) CONNECTION.close(); } catch (Exception ignored) {}
        CONNECTION = null;
        DB_FAILED  = false;
    }
}
