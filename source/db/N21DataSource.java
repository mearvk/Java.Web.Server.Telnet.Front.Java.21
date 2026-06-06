package db;

import java.sql.Connection;
import java.sql.DriverManager;

/**
 * Provides a single shared JDBC connection to the N21 MySQL database.
 * Credentials and host are loaded from authentication/mysql.auth.xml via N21AuthConfig.
 * Once a connection attempt fails, isAvailable() returns false so callers
 * can route immediately to the XML fallback without retrying on every call.
 */
public class N21DataSource
{
    private static Connection CONNECTION = null;
    private static boolean    DB_FAILED  = false;

    private static String buildUrl()
    {
        N21AuthConfig cfg = N21AuthConfig.get();
        return "jdbc:mysql://" + cfg.host + ":" + cfg.port
            + "/N21?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC&connectTimeout=3000";
    }

    public static synchronized boolean isAvailable()
    {
        if (DB_FAILED) return false;
        try { return CONNECTION != null && !CONNECTION.isClosed(); }
        catch (Exception e) { return false; }
    }

    public static synchronized Connection get() throws Exception
    {
        if (CONNECTION == null || CONNECTION.isClosed())
        {
            N21AuthConfig cfg = N21AuthConfig.get();
            Class.forName("com.mysql.cj.jdbc.Driver");
            CONNECTION = DriverManager.getConnection(buildUrl(), cfg.username, cfg.password);
            CONNECTION.setAutoCommit(true);
            DB_FAILED = false;
        }
        return CONNECTION;
    }

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
