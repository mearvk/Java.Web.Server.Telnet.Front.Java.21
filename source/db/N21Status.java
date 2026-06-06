package db;

import java.net.InetAddress;
import java.net.Socket;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.Statement;

/**
 * Determines MySQL reachability and readiness at startup (and on demand).
 * All checks are non-fatal — results are returned as a Status record.
 */
public class N21Status
{
    public static String dbHost() { return N21AuthConfig.get().host; }
    public static int    dbPort() { return N21AuthConfig.get().port; }

    public record Status(
        boolean tcpReachable,   // can we open a TCP socket to host:port?
        boolean pingable,       // InetAddress.isReachable (ICMP/echo)
        boolean jdbcConnected,  // full JDBC connect + simple query succeeded
        boolean n21DbExists,    // N21 schema present
        String  message         // human-readable summary
    ) {}

    /** Run all checks and return a Status. Never throws. */
    public static Status check()
    {
        boolean tcp    = checkTcp();
        boolean ping   = checkPing();
        boolean jdbc   = false;
        boolean n21    = false;

        if (tcp)
        {
            jdbc = checkJdbc();
            if (jdbc) n21 = checkN21Exists();
        }

        String msg = buildMessage(tcp, ping, jdbc, n21);
        return new Status(tcp, ping, jdbc, n21, msg);
    }

    // ── individual checks ─────────────────────────────────────────────────────

    private static boolean checkTcp()
    {
        try (Socket s = new Socket())
        {
            s.connect(new java.net.InetSocketAddress(dbHost(), dbPort()), 2000);
            return true;
        }
        catch (Exception e) { return false; }
    }

    private static boolean checkPing()
    {
        try
        {
            return InetAddress.getByName(dbHost()).isReachable(2000);
        }
        catch (Exception e) { return false; }
    }

    private static boolean checkJdbc()
    {
        try
        {
            Connection c = N21DataSource.get();
            try (Statement st = c.createStatement();
                 ResultSet rs = st.executeQuery("SELECT 1"))
            {
                return rs.next();
            }
        }
        catch (Exception e) { return false; }
    }

    private static boolean checkN21Exists()
    {
        try
        {
            Connection c = N21DataSource.get();
            try (Statement st = c.createStatement();
                 ResultSet rs = st.executeQuery(
                     "SELECT SCHEMA_NAME FROM information_schema.SCHEMATA WHERE SCHEMA_NAME='N21'"))
            {
                return rs.next();
            }
        }
        catch (Exception e) { return false; }
    }

    // ── message builder ───────────────────────────────────────────────────────

    private static String buildMessage(boolean tcp, boolean ping, boolean jdbc, boolean n21)
    {
        if (!tcp && !ping)  return "MySQL unreachable at " + dbHost() + ":" + dbPort() + " — XML fallback active.";
        if (!tcp)           return "MySQL port " + dbPort() + " closed (host pingable) — XML fallback active.";
        if (!jdbc)          return "MySQL TCP open but JDBC auth/connect failed — XML fallback active.";
        if (!n21)           return "MySQL connected but database N21 not found — run N21.table.builder.sh.";
        return               "MySQL connected. Database N21 ready at " + dbHost() + ":" + dbPort() + ".";
    }
}
