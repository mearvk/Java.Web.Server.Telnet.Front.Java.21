package db;

import java.sql.Connection;
import java.sql.DriverManager;

/**
 * Provides a single shared JDBC connection to the N21 MySQL database.
 * Reconnects automatically if the connection is closed/stale.
 */
public class N21DataSource
{
    private static final String URL  = "jdbc:mysql://localhost:3306/N21?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC";
    private static final String USER = "root";
    private static final String PASS = "";  // set password here or via env N21_DB_PASS

    private static Connection CONNECTION = null;

    public static synchronized Connection get() throws Exception
    {
        String pass = System.getenv("N21_DB_PASS") != null ? System.getenv("N21_DB_PASS") : PASS;

        if (CONNECTION == null || CONNECTION.isClosed())
        {
            Class.forName("com.mysql.cj.jdbc.Driver");
            CONNECTION = DriverManager.getConnection(URL, USER, pass);
            CONNECTION.setAutoCommit(true);
        }

        return CONNECTION;
    }

    public static synchronized void close()
    {
        try { if (CONNECTION != null) CONNECTION.close(); } catch (Exception ignored) {}
        CONNECTION = null;
    }
}
