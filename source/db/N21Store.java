package db;

import connections.Connection;
import exceptions.ExceptionRecord;

import java.sql.PreparedStatement;
import java.sql.Timestamp;

/**
 * Static store methods — one per N21 table.
 * Each method attempts MySQL first; on any failure it marks the DB unavailable
 * and seamlessly routes the record to the XML fallback.
 */
public class N21Store
{
    // ── connections ───────────────────────────────────────────────────────────

    public static void storeConnection(Connection c, int serverPort)
    {
        String remoteAddr  = c.remote_address != null ? c.remote_address : "";
        String inetAddr    = c.internet_address != null ? c.internet_address.getHostAddress() : "";
        String telnet      = Boolean.TRUE.equals(c.IS_TELNET_EXCELSIOR_CONNECTED) ? "1" : "0";
        String inception   = c.inception_date != null ? c.inception_date.toString() : "";

        if (dbOk())
        {
            try
            {
                PreparedStatement ps = N21DataSource.get().prepareStatement(
                    "INSERT INTO connections (remote_address, internet_address, server_port, is_telnet_excelsior_connected, inception_date) VALUES (?,?,?,?,?)");
                ps.setString(1, remoteAddr);
                ps.setString(2, inetAddr);
                ps.setInt(3, serverPort);
                ps.setBoolean(4, Boolean.TRUE.equals(c.IS_TELNET_EXCELSIOR_CONNECTED));
                ps.setTimestamp(5, c.inception_date != null ? new Timestamp(c.inception_date.getTime()) : new Timestamp(System.currentTimeMillis()));
                ps.executeUpdate(); ps.close();
                return;
            }
            catch (Exception e) { fail("connections", e); }
        }
        N21XmlFallback.append("connections",
            "remote_address", remoteAddr, "internet_address", inetAddr,
            "server_port", String.valueOf(serverPort), "telnet", telnet, "inception_date", inception);
    }

    // ── geo_locations ─────────────────────────────────────────────────────────

    public static void storeGeo(String ip, String city, String country)
    {
        if (dbOk())
        {
            try
            {
                PreparedStatement ps = N21DataSource.get().prepareStatement(
                    "INSERT INTO geo_locations (ip_address, city, country) VALUES (?,?,?) " +
                    "ON DUPLICATE KEY UPDATE city=VALUES(city), country=VALUES(country), resolved_at=NOW()");
                ps.setString(1, ip); ps.setString(2, city != null ? city : ""); ps.setString(3, country != null ? country : "");
                ps.executeUpdate(); ps.close();
                return;
            }
            catch (Exception e) { fail("geo_locations", e); }
        }
        N21XmlFallback.append("geo_locations", "ip_address", ip, "city", city, "country", country);
    }

    // ── exceptions ────────────────────────────────────────────────────────────

    public static void storeException(ExceptionRecord r, boolean isSecurityEvent)
    {
        if (dbOk())
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
                ps.executeUpdate(); ps.close();
                return;
            }
            catch (Exception e) { fail("exceptions", e); }
        }
        N21XmlFallback.append("exceptions",
            "exception_type", r.exception().getClass().getSimpleName(),
            "message",        r.exception().getMessage(),
            "origin",         r.origin(),
            "stack_trace",    r.stackTrace(),
            "security",       String.valueOf(isSecurityEvent),
            "recorded_at",    r.timestamp().toString());
    }

    // ── security_events ───────────────────────────────────────────────────────

    public static void storeSecurityEvent(ExceptionRecord r, String sourceIp)
    {
        if (dbOk())
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
                ps.executeUpdate(); ps.close();
                return;
            }
            catch (Exception e) { fail("security_events", e); }
        }
        N21XmlFallback.append("security_events",
            "event_type", r.exception().getClass().getSimpleName(),
            "message",    r.exception().getMessage(),
            "origin",     r.origin(),
            "source_ip",  sourceIp != null ? sourceIp : "",
            "recorded_at", r.timestamp().toString());
    }

    // ── national_ids ──────────────────────────────────────────────────────────

    public static void storeNationalId(long eightDigit, long sixteenDigit)
    {
        if (dbOk())
        {
            try
            {
                PreparedStatement ps = N21DataSource.get().prepareStatement(
                    "INSERT IGNORE INTO national_ids (eight_digit_id, sixteen_digit_key) VALUES (?,?)");
                ps.setLong(1, eightDigit); ps.setLong(2, sixteenDigit);
                ps.executeUpdate(); ps.close();
                return;
            }
            catch (Exception e) { fail("national_ids", e); }
        }
        N21XmlFallback.append("national_ids",
            "eight_digit_id",    String.valueOf(eightDigit),
            "sixteen_digit_key", String.valueOf(sixteenDigit));
    }

    // ── national_finance_ids ──────────────────────────────────────────────────

    public static void storeNationalFinanceID(national.NationalFinanceID n)
    {
        if (dbOk())
        {
            try
            {
                // Satisfy the FK: ensure the eight_digit_id exists in national_ids first.
                // Uses a placeholder sixteen_digit_key of 0 when none is provided.
                PreparedStatement pi = N21DataSource.get().prepareStatement(
                    "INSERT IGNORE INTO national_ids (eight_digit_id, sixteen_digit_key) VALUES (?,0)");
                pi.setLong(1, n.nationalId);
                pi.executeUpdate(); pi.close();

                PreparedStatement ps = N21DataSource.get().prepareStatement(
                    "INSERT INTO national_finance_ids " +
                    "(national_id, remote_address, iq, education_level, social_skills, equipment, " +
                    " trust_level, parent_one, parent_two, suspects, social_spotting, promissory_note, created_at) " +
                    "VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)");
                ps.setLong(1,   n.nationalId);
                ps.setString(2, n.remoteAddress != null ? n.remoteAddress : "");
                ps.setInt(3,    n.iq);
                ps.setString(4, n.educationLevel != null ? n.educationLevel : "");
                ps.setInt(5,    n.socialSkills);
                ps.setString(6, n.equipment != null ? n.equipment : "");
                ps.setInt(7,    n.trustLevel);
                ps.setString(8, n.parentOne != null ? n.parentOne : "");
                ps.setString(9, n.parentTwo != null ? n.parentTwo : "");
                ps.setString(10, n.suspects != null ? n.suspects : "");
                ps.setString(11, n.socialSpotting != null ? n.socialSpotting : "");
                ps.setDouble(12, n.promissoryNote);
                ps.setTimestamp(13, n.createdAt != null ? new Timestamp(n.createdAt.getTime()) : new Timestamp(System.currentTimeMillis()));
                ps.executeUpdate(); ps.close();
                return;
            }
            catch (Exception e) { fail("national_finance_ids", e); }
        }
        N21XmlFallback.append("national_finance_ids",
            "national_id",     String.valueOf(n.nationalId),
            "remote_address",  n.remoteAddress != null ? n.remoteAddress : "",
            "iq",              String.valueOf(n.iq),
            "education_level", n.educationLevel != null ? n.educationLevel : "",
            "social_skills",   String.valueOf(n.socialSkills),
            "equipment",       n.equipment != null ? n.equipment : "",
            "trust_level",     String.valueOf(n.trustLevel),
            "parent_one",      n.parentOne != null ? n.parentOne : "",
            "parent_two",      n.parentTwo != null ? n.parentTwo : "",
            "suspects",        n.suspects != null ? n.suspects : "",
            "social_spotting", n.socialSpotting != null ? n.socialSpotting : "",
            "promissory_note", String.valueOf(n.promissoryNote),
            "created_at",      n.createdAt != null ? n.createdAt.toString() : "");
    }

    public static national.NationalFinanceID loadNationalFinanceID(long nationalId)
    {
        if (dbOk())
        {
            try
            {
                PreparedStatement ps = N21DataSource.get().prepareStatement(
                    "SELECT * FROM national_finance_ids WHERE national_id=? ORDER BY id DESC LIMIT 1");
                ps.setLong(1, nationalId);
                java.sql.ResultSet rs = ps.executeQuery();
                if (rs.next())
                {
                    national.NationalFinanceID n = new national.NationalFinanceID();
                    n.nationalId     = rs.getLong("national_id");
                    n.remoteAddress  = rs.getString("remote_address");
                    n.iq             = rs.getInt("iq");
                    n.educationLevel = rs.getString("education_level");
                    n.socialSkills   = rs.getInt("social_skills");
                    n.equipment      = rs.getString("equipment");
                    n.trustLevel     = rs.getInt("trust_level");
                    n.parentOne      = rs.getString("parent_one");
                    n.parentTwo      = rs.getString("parent_two");
                    n.suspects       = rs.getString("suspects");
                    n.socialSpotting = rs.getString("social_spotting");
                    n.promissoryNote = rs.getDouble("promissory_note");
                    n.createdAt      = rs.getTimestamp("created_at");
                    rs.close(); ps.close();
                    return n;
                }
                rs.close(); ps.close();
            }
            catch (Exception e) { fail("national_finance_ids", e); }
        }
        return null;
    }

    // ── status_snapshots ──────────────────────────────────────────────────────

    public static void storeStatusSnapshot(int activeConnections, long uptimeSecs, long totalMb, long usedMb)
    {
        if (dbOk())
        {
            try
            {
                PreparedStatement ps = N21DataSource.get().prepareStatement(
                    "INSERT INTO status_snapshots (active_connections, server_uptime_secs, total_memory_mb, used_memory_mb, local_server_time) VALUES (?,?,?,?,NOW())");
                ps.setInt(1, activeConnections); ps.setLong(2, uptimeSecs);
                ps.setLong(3, totalMb);          ps.setLong(4, usedMb);
                ps.executeUpdate(); ps.close();
                return;
            }
            catch (Exception e) { fail("status_snapshots", e); }
        }
        N21XmlFallback.append("status_snapshots",
            "active_connections", String.valueOf(activeConnections),
            "uptime_secs",        String.valueOf(uptimeSecs),
            "total_memory_mb",    String.valueOf(totalMb),
            "used_memory_mb",     String.valueOf(usedMb));
    }

    // ── helpers ───────────────────────────────────────────────────────────────

    /** Returns true only if a live DB connection can be obtained. */
    private static boolean dbOk()
    {
        if (!N21DataSource.isAvailable())
        {
            // Attempt a reconnect once per call — if it throws, stay in fallback mode
            try { N21DataSource.get(); return true; }
            catch (Exception ignored) { return false; }
        }
        return true;
    }

    /** Log the failure, mark the datasource down, and let the caller fall through to XML. */
    private static void fail(String table, Exception e)
    {
        System.err.println("[N21Store] DB unavailable for table '" + table + "': " + e.getMessage() + " — routing to XML fallback.");
        N21DataSource.markFailed();
    }
}
