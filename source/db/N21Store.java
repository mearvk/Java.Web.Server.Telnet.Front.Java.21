package db;

import connections.Connection;
import exceptions.ExceptionRecord;

import java.sql.PreparedStatement;
import java.sql.Timestamp;
import java.time.Instant;
import java.time.LocalTime;

/**
 * Static store methods — one per N21 table.
 * Each method silently swallows failures so the server never crashes on a DB write.
 */
public class N21Store
{
    // ── connections ──────────────────────────────────────────────────────────

    public static void storeConnection(Connection c, int serverPort)
    {
        try
        {
            PreparedStatement ps = N21DataSource.get().prepareStatement(
                "INSERT INTO connections (remote_address, internet_address, server_port, is_telnet_excelsior_connected, inception_date) VALUES (?,?,?,?,?)");
            ps.setString(1, c.remote_address != null ? c.remote_address : "");
            ps.setString(2, c.internet_address != null ? c.internet_address.getHostAddress() : "");
            ps.setInt(3, serverPort);
            ps.setBoolean(4, Boolean.TRUE.equals(c.IS_TELNET_EXCELSIOR_CONNECTED));
            ps.setTimestamp(5, c.inception_date != null ? new Timestamp(c.inception_date.getTime()) : new Timestamp(System.currentTimeMillis()));
            ps.executeUpdate();
            ps.close();
        }
        catch (Exception e) { System.err.println("[N21Store] connections: " + e.getMessage()); }
    }

    // ── geo_locations ─────────────────────────────────────────────────────────

    public static void storeGeo(String ip, String city, String country)
    {
        try
        {
            PreparedStatement ps = N21DataSource.get().prepareStatement(
                "INSERT INTO geo_locations (ip_address, city, country) VALUES (?,?,?) " +
                "ON DUPLICATE KEY UPDATE city=VALUES(city), country=VALUES(country), resolved_at=NOW()");
            ps.setString(1, ip);
            ps.setString(2, city != null ? city : "");
            ps.setString(3, country != null ? country : "");
            ps.executeUpdate();
            ps.close();
        }
        catch (Exception e) { System.err.println("[N21Store] geo_locations: " + e.getMessage()); }
    }

    // ── exceptions ────────────────────────────────────────────────────────────

    public static void storeException(ExceptionRecord r, boolean isSecurityEvent)
    {
        try
        {
            PreparedStatement ps = N21DataSource.get().prepareStatement(
                "INSERT INTO exceptions (exception_type, message, origin, stack_trace, is_security_event, recorded_at) VALUES (?,?,?,?,?,?)");
            ps.setString(1, r.exception().getClass().getSimpleName());
            ps.setString(2, r.exception().getMessage());
            ps.setString(3, r.origin());
            ps.setString(4, r.stackTrace());
            ps.setBoolean(5, isSecurityEvent);
            ps.setTimestamp(6, Timestamp.from(r.timestamp()));
            ps.executeUpdate();
            ps.close();
        }
        catch (Exception e) { System.err.println("[N21Store] exceptions: " + e.getMessage()); }
    }

    // ── security_events ───────────────────────────────────────────────────────

    public static void storeSecurityEvent(ExceptionRecord r, String sourceIp)
    {
        try
        {
            PreparedStatement ps = N21DataSource.get().prepareStatement(
                "INSERT INTO security_events (event_type, message, origin, source_ip, recorded_at) VALUES (?,?,?,?,?)");
            ps.setString(1, r.exception().getClass().getSimpleName());
            ps.setString(2, r.exception().getMessage());
            ps.setString(3, r.origin());
            ps.setString(4, sourceIp != null ? sourceIp : "");
            ps.setTimestamp(5, Timestamp.from(r.timestamp()));
            ps.executeUpdate();
            ps.close();
        }
        catch (Exception e) { System.err.println("[N21Store] security_events: " + e.getMessage()); }
    }

    // ── national_ids ──────────────────────────────────────────────────────────

    public static void storeNationalId(long eightDigit, long sixteenDigit)
    {
        try
        {
            PreparedStatement ps = N21DataSource.get().prepareStatement(
                "INSERT IGNORE INTO national_ids (eight_digit_id, sixteen_digit_key) VALUES (?,?)");
            ps.setLong(1, eightDigit);
            ps.setLong(2, sixteenDigit);
            ps.executeUpdate();
            ps.close();
        }
        catch (Exception e) { System.err.println("[N21Store] national_ids: " + e.getMessage()); }
    }

    // ── status_snapshots ──────────────────────────────────────────────────────

    public static void storeStatusSnapshot(int activeConnections, long uptimeSecs, long totalMb, long usedMb)
    {
        try
        {
            PreparedStatement ps = N21DataSource.get().prepareStatement(
                "INSERT INTO status_snapshots (active_connections, server_uptime_secs, total_memory_mb, used_memory_mb, local_server_time) VALUES (?,?,?,?,NOW())");
            ps.setInt(1, activeConnections);
            ps.setLong(2, uptimeSecs);
            ps.setLong(3, totalMb);
            ps.setLong(4, usedMb);
            ps.executeUpdate();
            ps.close();
        }
        catch (Exception e) { System.err.println("[N21Store] status_snapshots: " + e.getMessage()); }
    }
}
