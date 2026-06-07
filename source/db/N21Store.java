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

    public static void storeConnection(final Connection C, final int SERVERPORT)
    {
        String remoteAddr  = C.remote_address != null ? C.remote_address : "";
        String inetAddr    = C.internet_address != null ? C.internet_address.getHostAddress() : "";
        String telnet      = Boolean.TRUE.equals(C.IS_TELNET_EXCELSIOR_CONNECTED) ? "1" : "0";
        String inception   = C.inception_date != null ? C.inception_date.toString() : "";

        if (dbOk())
        {
            try
            {
                PreparedStatement ps = N21DataSource.get().prepareStatement(
                    "INSERT INTO connections (remote_address, internet_address, server_port, is_telnet_excelsior_connected, inception_date) VALUES (?,?,?,?,?)");
                ps.setString(1, remoteAddr);
                ps.setString(2, inetAddr);
                ps.setInt(3, SERVERPORT);
                ps.setBoolean(4, Boolean.TRUE.equals(C.IS_TELNET_EXCELSIOR_CONNECTED));
                ps.setTimestamp(5, C.inception_date != null ? new Timestamp(C.inception_date.getTime()) : new Timestamp(System.currentTimeMillis()));
                ps.executeUpdate(); ps.close();
                return;
            }
            catch (Exception e) { fail("connections", e); }
        }
        N21XmlFallback.append("connections",
            "remote_address", remoteAddr, "internet_address", inetAddr,
            "server_port", String.valueOf(SERVERPORT), "telnet", telnet, "inception_date", inception);
    }

    // ── geo_locations ─────────────────────────────────────────────────────────

    public static void storeGeo(final String IP, final String CITY, final String COUNTRY)
    {
        if (dbOk())
        {
            try
            {
                PreparedStatement ps = N21DataSource.get().prepareStatement(
                    "INSERT INTO geo_locations (ip_address, CITY, COUNTRY) VALUES (?,?,?) " +
                    "ON DUPLICATE KEY UPDATE CITY=VALUES(CITY), COUNTRY=VALUES(COUNTRY), resolved_at=NOW()");
                ps.setString(1, IP); ps.setString(2, CITY != null ? CITY : ""); ps.setString(3, COUNTRY != null ? COUNTRY : "");
                ps.executeUpdate(); ps.close();
                return;
            }
            catch (Exception e) { fail("geo_locations", e); }
        }
        N21XmlFallback.append("geo_locations", "ip_address", IP, "city", CITY, "country", COUNTRY);
    }

    // ── exceptions ────────────────────────────────────────────────────────────

    public static void storeException(final ExceptionRecord R, final boolean ISSECURITYEVENT)
    {
        if (dbOk())
        {
            try
            {
                PreparedStatement ps = N21DataSource.get().prepareStatement(
                    "INSERT INTO exceptions (exception_type, message, origin, stack_trace, is_security_event, recorded_at) VALUES (?,?,?,?,?,?)");
                ps.setString(1, R.exception().getClass().getSimpleName());
                ps.setString(2, R.exception().getMessage());
                ps.setString(3, R.origin());
                ps.setString(4, R.stackTrace());
                ps.setBoolean(5, ISSECURITYEVENT);
                ps.setTimestamp(6, Timestamp.from(R.timestamp()));
                ps.executeUpdate(); ps.close();
                return;
            }
            catch (Exception e) { fail("exceptions", e); }
        }
        N21XmlFallback.append("exceptions",
            "exception_type", R.exception().getClass().getSimpleName(),
            "message",        R.exception().getMessage(),
            "origin",         R.origin(),
            "stack_trace",    R.stackTrace(),
            "security",       String.valueOf(ISSECURITYEVENT),
            "recorded_at",    R.timestamp().toString());
    }

    // ── security_events ───────────────────────────────────────────────────────

    public static void storeSecurityEvent(final ExceptionRecord R, final String SOURCEIP)
    {
        if (dbOk())
        {
            try
            {
                PreparedStatement ps = N21DataSource.get().prepareStatement(
                    "INSERT INTO security_events (event_type, message, origin, source_ip, recorded_at) VALUES (?,?,?,?,?)");
                ps.setString(1, R.exception().getClass().getSimpleName());
                ps.setString(2, R.exception().getMessage());
                ps.setString(3, R.origin());
                ps.setString(4, SOURCEIP != null ? SOURCEIP : "");
                ps.setTimestamp(5, Timestamp.from(R.timestamp()));
                ps.executeUpdate(); ps.close();
                return;
            }
            catch (Exception e) { fail("security_events", e); }
        }
        N21XmlFallback.append("security_events",
            "event_type", R.exception().getClass().getSimpleName(),
            "message",    R.exception().getMessage(),
            "origin",     R.origin(),
            "source_ip",  SOURCEIP != null ? SOURCEIP : "",
            "recorded_at", R.timestamp().toString());
    }

    // ── national_ids ──────────────────────────────────────────────────────────

    public static void storeNationalId(final long EIGHTDIGIT, final long SIXTEENDIGIT)
    {
        if (dbOk())
        {
            try
            {
                PreparedStatement ps = N21DataSource.get().prepareStatement(
                    "INSERT IGNORE INTO national_ids (eight_digit_id, sixteen_digit_key) VALUES (?,?)");
                ps.setLong(1, EIGHTDIGIT); ps.setLong(2, SIXTEENDIGIT);
                ps.executeUpdate(); ps.close();
                return;
            }
            catch (Exception e) { fail("national_ids", e); }
        }
        N21XmlFallback.append("national_ids",
            "eight_digit_id",    String.valueOf(EIGHTDIGIT),
            "sixteen_digit_key", String.valueOf(SIXTEENDIGIT));
    }

    // ── national_finance_ids ──────────────────────────────────────────────────

    public static void storeNationalFinanceID(final national.NationalFinanceID N)
    {
        if (dbOk())
        {
            try
            {
                // Satisfy the FK: ensure the eight_digit_id exists in national_ids first.
                // Uses a placeholder sixteen_digit_key of 0 when none is provided.
                PreparedStatement pi = N21DataSource.get().prepareStatement(
                    "INSERT IGNORE INTO national_ids (eight_digit_id, sixteen_digit_key) VALUES (?,0)");
                pi.setLong(1, N.nationalId);
                pi.executeUpdate(); pi.close();

                PreparedStatement ps = N21DataSource.get().prepareStatement(
                    "INSERT INTO national_finance_ids " +
                    "(national_id, remote_address, iq, education_level, social_skills, equipment, " +
                    " trust_level, parent_one, parent_two, suspects, social_spotting, promissory_note, created_at) " +
                    "VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)");
                ps.setLong(1,   N.nationalId);
                ps.setString(2, N.remoteAddress != null ? N.remoteAddress : "");
                ps.setInt(3,    N.iq);
                ps.setString(4, N.educationLevel != null ? N.educationLevel : "");
                ps.setInt(5,    N.socialSkills);
                ps.setString(6, N.equipment != null ? N.equipment : "");
                ps.setInt(7,    N.trustLevel);
                ps.setString(8, N.parentOne != null ? N.parentOne : "");
                ps.setString(9, N.parentTwo != null ? N.parentTwo : "");
                ps.setString(10, N.suspects != null ? N.suspects : "");
                ps.setString(11, N.socialSpotting != null ? N.socialSpotting : "");
                ps.setDouble(12, N.promissoryNote);
                ps.setTimestamp(13, N.createdAt != null ? new Timestamp(N.createdAt.getTime()) : new Timestamp(System.currentTimeMillis()));
                ps.executeUpdate(); ps.close();
                return;
            }
            catch (Exception e) { fail("national_finance_ids", e); }
        }
        N21XmlFallback.append("national_finance_ids",
            "national_id",     String.valueOf(N.nationalId),
            "remote_address",  N.remoteAddress != null ? N.remoteAddress : "",
            "iq",              String.valueOf(N.iq),
            "education_level", N.educationLevel != null ? N.educationLevel : "",
            "social_skills",   String.valueOf(N.socialSkills),
            "equipment",       N.equipment != null ? N.equipment : "",
            "trust_level",     String.valueOf(N.trustLevel),
            "parent_one",      N.parentOne != null ? N.parentOne : "",
            "parent_two",      N.parentTwo != null ? N.parentTwo : "",
            "suspects",        N.suspects != null ? N.suspects : "",
            "social_spotting", N.socialSpotting != null ? N.socialSpotting : "",
            "promissory_note", String.valueOf(N.promissoryNote),
            "created_at",      N.createdAt != null ? N.createdAt.toString() : "");
    }

    public static national.NationalFinanceID loadNationalFinanceID(final long NATIONALID)
    {
        if (dbOk())
        {
            try
            {
                PreparedStatement ps = N21DataSource.get().prepareStatement(
                    "SELECT * FROM national_finance_ids WHERE national_id=? ORDER BY id DESC LIMIT 1");
                ps.setLong(1, NATIONALID);
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

    public static void storeStatusSnapshot(final int ACTIVECONNECTIONS, final long UPTIMESECS, final long TOTALMB, final long USEDMB)
    {
        if (dbOk())
        {
            try
            {
                PreparedStatement ps = N21DataSource.get().prepareStatement(
                    "INSERT INTO status_snapshots (active_connections, server_uptime_secs, total_memory_mb, used_memory_mb, local_server_time) VALUES (?,?,?,?,NOW())");
                ps.setInt(1, ACTIVECONNECTIONS); ps.setLong(2, UPTIMESECS);
                ps.setLong(3, TOTALMB);          ps.setLong(4, USEDMB);
                ps.executeUpdate(); ps.close();
                return;
            }
            catch (Exception e) { fail("status_snapshots", e); }
        }
        N21XmlFallback.append("status_snapshots",
            "active_connections", String.valueOf(ACTIVECONNECTIONS),
            "uptime_secs",        String.valueOf(UPTIMESECS),
            "total_memory_mb",    String.valueOf(TOTALMB),
            "used_memory_mb",     String.valueOf(USEDMB));
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
    private static void fail(final String TABLE, final Exception E)
    {
        System.err.println("[N21Store] DB unavailable for TABLE '" + TABLE + "': " + E.getMessage() + " — routing to XML fallback.");
        N21DataSource.markFailed();
    }
}
