package database;

import connections.Connection;
import exceptions.ExceptionHandler;
import exceptions.ExceptionRecord;

import java.sql.*;

import static java.sql.DriverManager.getConnection;

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
                ps.setString(1, R.EXCEPTION().getClass().getSimpleName());
                ps.setString(2, R.EXCEPTION().getMessage());
                ps.setString(3, R.ORIGIN());
                ps.setString(4, R.STACKTRACE());
                ps.setBoolean(5, ISSECURITYEVENT);
                ps.setTimestamp(6, Timestamp.from(R.TIMESTAMP()));
                ps.executeUpdate(); ps.close();
                return;
            }
            catch (Exception e) { fail("exceptions", e); }
        }
        N21XmlFallback.append("exceptions",
            "exception_type", R.EXCEPTION().getClass().getSimpleName(),
            "message",        R.EXCEPTION().getMessage(),
            "origin",         R.ORIGIN(),
            "stack_trace",    R.STACKTRACE(),
            "security",       String.valueOf(ISSECURITYEVENT),
            "recorded_at",    R.TIMESTAMP().toString());
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
                ps.setString(1, R.EXCEPTION().getClass().getSimpleName());
                ps.setString(2, R.EXCEPTION().getMessage());
                ps.setString(3, R.ORIGIN());
                ps.setString(4, SOURCEIP != null ? SOURCEIP : "");
                ps.setTimestamp(5, Timestamp.from(R.TIMESTAMP()));
                ps.executeUpdate(); ps.close();
                return;
            }
            catch (Exception e) { fail("security_events", e); }
        }
        N21XmlFallback.append("security_events",
            "event_type", R.EXCEPTION().getClass().getSimpleName(),
            "message",    R.EXCEPTION().getMessage(),
            "origin",     R.ORIGIN(),
            "source_ip",  SOURCEIP != null ? SOURCEIP : "",
            "recorded_at", R.TIMESTAMP().toString());
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

    // ── ascii_signatures ──────────────────────────────────────────────────────

    public static void createAsciiSignaturesTable()
    {
        if (!dbOk()) return;
        try
        {
            java.sql.Statement st = N21DataSource.get().createStatement();
            st.executeUpdate(
                "CREATE TABLE IF NOT EXISTS ascii_signatures (" +
                "  id          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY," +
                "  national_id BIGINT UNSIGNED NOT NULL," +
                "  sig_id      INT UNSIGNED    NOT NULL," +
                "  ascii_grid  TEXT            NOT NULL," +
                "  issued_at   DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP," +
                "  expires_at  DATETIME        NOT NULL," +
                "  UNIQUE KEY uq_national (national_id)," +
                "  UNIQUE KEY uq_sig_id   (sig_id)," +
                "  INDEX idx_expires      (expires_at)" +
                ") ENGINE=InnoDB");
            st.close();
        }
        catch (Exception e) { fail("ascii_signatures", e); }
    }

    /** Returns the next available sig_id not yet assigned to any national ID. */
    public static int nextAsciiSigId()
    {
        if (dbOk())
        {
            try
            {
                // Find lowest gap in sig_id 0..2097151 not already taken
                PreparedStatement ps = N21DataSource.get().prepareStatement(
                    "SELECT sig_id FROM ascii_signatures ORDER BY sig_id ASC");
                java.sql.ResultSet rs = ps.executeQuery();
                int expected = 0;
                while (rs.next())
                {
                    int used = rs.getInt(1);
                    if (used != expected) break;
                    expected++;
                }
                rs.close(); ps.close();
                return expected;
            }
            catch (Exception e) { fail("ascii_signatures", e); }
        }
        return (int)(System.nanoTime() & 0x1FFFFFL); // fallback
    }

    public static void storeAsciiSignature(final long NATIONAL_ID, final int SIG_ID, final String ASCII_GRID)
    {
        if (dbOk())
        {
            try
            {
                PreparedStatement ps = N21DataSource.get().prepareStatement(
                    "INSERT INTO ascii_signatures (national_id, sig_id, ascii_grid, expires_at) " +
                    "VALUES (?, ?, ?, DATE_ADD(NOW(), INTERVAL 1000 DAY)) " +
                    "ON DUPLICATE KEY UPDATE sig_id=VALUES(sig_id), ascii_grid=VALUES(ascii_grid), " +
                    "issued_at=NOW(), expires_at=DATE_ADD(NOW(), INTERVAL 1000 DAY)");
                ps.setLong(1, NATIONAL_ID);
                ps.setInt(2, SIG_ID);
                ps.setString(3, ASCII_GRID);
                ps.executeUpdate(); ps.close();
                return;
            }
            catch (Exception e) { fail("ascii_signatures", e); }
        }
        N21XmlFallback.append("ascii_signatures",
            "national_id", String.valueOf(NATIONAL_ID),
            "sig_id",      String.valueOf(SIG_ID),
            "ascii_grid",  ASCII_GRID);
    }

    /** Returns {sig_id, ascii_grid, expires_at} row or null if none / expired. */
    public static java.sql.ResultSet loadAsciiSignature(final long NATIONAL_ID)
    {
        if (dbOk())
        {
            try
            {
                PreparedStatement ps = N21DataSource.get().prepareStatement(
                    "SELECT sig_id, ascii_grid, issued_at, expires_at FROM ascii_signatures " +
                    "WHERE national_id=? AND expires_at > NOW()");
                ps.setLong(1, NATIONAL_ID);
                java.sql.ResultSet rs = ps.executeQuery();
                if (rs.next()) return rs;
                rs.close(); ps.close();
            }
            catch (Exception e) { fail("ascii_signatures", e); }
        }
        return null;
    }

    // ── module_loader ─────────────────────────────────────────────────────────

    /** Ensure the module_loader table exists — called once at startup. */
    public static void createModuleLoaderTable()
    {
        if (!dbOk()) return;
        try
        {
            java.sql.Statement st = N21DataSource.get().createStatement();
            st.executeUpdate(
                "CREATE TABLE IF NOT EXISTS module_loader (" +
                "  id            BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY," +
                "  national_id   BIGINT UNSIGNED NOT NULL," +
                "  module_name   VARCHAR(255)    NOT NULL," +
                "  action        VARCHAR(64)     NOT NULL," +   // install / unload / restart / connect
                "  source_ip     VARCHAR(45)     NOT NULL DEFAULT ''," +
                "  file_type     VARCHAR(16)     NOT NULL DEFAULT ''," +
                "  byte_count    INT UNSIGNED    NOT NULL DEFAULT 0," +
                "  sig_hex       VARCHAR(64)     NOT NULL DEFAULT ''," +
                "  admin_token   VARCHAR(128)    NOT NULL DEFAULT ''," +
                "  result        VARCHAR(255)    NOT NULL DEFAULT ''," +
                "  recorded_at   DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP," +
                "  INDEX idx_ml_national  (national_id)," +
                "  INDEX idx_ml_module    (module_name)," +
                "  INDEX idx_ml_action    (action)," +
                "  INDEX idx_ml_recorded  (recorded_at)" +
                ") ENGINE=InnoDB");
            st.close();
        }
        catch (Exception e) { fail("module_loader", e); }
    }

    public static void storeModuleAction(final long NATIONAL_ID, final String MODULE_NAME,
                                          final String ACTION,      final String SOURCE_IP,
                                          final String FILE_TYPE,   final int BYTE_COUNT,
                                          final String SIG_HEX,     final String ADMIN_TOKEN,
                                          final String RESULT)
    {
        if (dbOk())
        {
            try
            {
                PreparedStatement ps = N21DataSource.get().prepareStatement(
                    "INSERT INTO module_loader " +
                    "(national_id, module_name, action, source_ip, file_type, byte_count, sig_hex, admin_token, result) " +
                    "VALUES (?,?,?,?,?,?,?,?,?)");
                ps.setLong(1,   NATIONAL_ID);
                ps.setString(2, MODULE_NAME  != null ? MODULE_NAME  : "");
                ps.setString(3, ACTION       != null ? ACTION       : "");
                ps.setString(4, SOURCE_IP    != null ? SOURCE_IP    : "");
                ps.setString(5, FILE_TYPE    != null ? FILE_TYPE    : "");
                ps.setInt(6,    BYTE_COUNT);
                ps.setString(7, SIG_HEX      != null ? SIG_HEX      : "");
                ps.setString(8, ADMIN_TOKEN  != null ? ADMIN_TOKEN  : "");
                ps.setString(9, RESULT       != null ? RESULT       : "");
                ps.executeUpdate(); ps.close();
                return;
            }
            catch (Exception e) { fail("module_loader", e); }
        }
        N21XmlFallback.append("module_loader",
            "national_id",  String.valueOf(NATIONAL_ID),
            "module_name",  MODULE_NAME  != null ? MODULE_NAME  : "",
            "action",       ACTION       != null ? ACTION       : "",
            "source_ip",    SOURCE_IP    != null ? SOURCE_IP    : "",
            "file_type",    FILE_TYPE    != null ? FILE_TYPE    : "",
            "byte_count",   String.valueOf(BYTE_COUNT),
            "sig_hex",      SIG_HEX      != null ? SIG_HEX      : "",
            "admin_token",  ADMIN_TOKEN  != null ? ADMIN_TOKEN  : "",
            "result",       RESULT       != null ? RESULT       : "");
    }

    // ── communicator_messages / communicator_scheduled ────────────────────────

    public static void createCommunicatorTables()
    {
        if (!dbOk()) return;
        try
        {
            java.sql.Statement st = N21DataSource.get().createStatement();
            st.executeUpdate(
                "CREATE TABLE IF NOT EXISTS communicator_messages (" +
                "  id               BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY," +
                "  from_national_id BIGINT          NOT NULL," +
                "  to_national_id   BIGINT          NOT NULL," +   // -1 = broadcast
                "  message          TEXT            NOT NULL," +
                "  type             VARCHAR(16)     NOT NULL DEFAULT 'direct'," +
                "  sent_at          DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP," +
                "  INDEX idx_cm_from    (from_national_id)," +
                "  INDEX idx_cm_to      (to_national_id)," +
                "  INDEX idx_cm_sent    (sent_at)" +
                ") ENGINE=InnoDB");
            st.executeUpdate(
                "CREATE TABLE IF NOT EXISTS communicator_scheduled (" +
                "  id               BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY," +
                "  from_national_id BIGINT          NOT NULL," +
                "  to_national_id   BIGINT          NOT NULL," +   // -1 = broadcast
                "  message          TEXT            NOT NULL," +
                "  scheduled_time   VARCHAR(5)      NOT NULL," +   // HH:mm
                "  delivered        TINYINT(1)      NOT NULL DEFAULT 0," +
                "  created_at       DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP," +
                "  delivered_at     DATETIME," +
                "  INDEX idx_cs_pending (delivered, scheduled_time)" +
                ") ENGINE=InnoDB");
            st.close();
        }
        catch (Exception e) { fail("communicator_tables", e); }
    }

    // ---------------------------------------------------------------------
    // TABLE CREATION
    // ---------------------------------------------------------------------

    public static void createWhiteAuditorTables() {
        try (Connection c = getConnection()) {

            ((java.sql.Connection) c).createStatement().execute("""
                CREATE TABLE IF NOT EXISTS wat_tasks (
                    id BIGINT AUTO_INCREMENT PRIMARY KEY,
                    from_national_id BIGINT NOT NULL,
                    to_national_id   BIGINT NOT NULL,
                    type VARCHAR(32) NOT NULL,
                    filename VARCHAR(255),
                    size INT,
                    payload LONGTEXT,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """);

        } catch (Exception e) { ExceptionHandler.dispatch(e); }
    }

    // ---------------------------------------------------------------------
    // STORE FILE
    // ---------------------------------------------------------------------

    public static void storeAssignedFile(long fromId, long toId, String filename, String base64) throws Exception
    {
        try (Connection c = getConnection();
             PreparedStatement ps = ((java.sql.Connection) c).prepareStatement("""
                 INSERT INTO wat_tasks (from_national_id, to_national_id, type, filename, payload)
                 VALUES (?, ?, 'file', ?, ?)
             """)) {

            ps.setLong(1, fromId);
            ps.setLong(2, toId);
            ps.setString(3, filename);
            ps.setString(4, base64);
            ps.executeUpdate();

        } catch (Exception e) { ExceptionHandler.dispatch(e); }
    }

    // ---------------------------------------------------------------------
    // STORE BITS
    // ---------------------------------------------------------------------

    public static void storeAssignedBits(long fromId, long toId, int size, String base64) {
        try (Connection c = getConnection();
             PreparedStatement ps = ((java.sql.Connection) c).prepareStatement(
                     """
                     INSERT INTO wat_tasks (from_national_id, to_national_id, type, size, payload)
                     VALUES (?, ?, 'bits', ?, ?)
                     """
             )) {

            ps.setLong(1, fromId);
            ps.setLong(2, toId);
            ps.setInt(3, size);
            ps.setString(4, base64);
            ps.executeUpdate();
        } catch (SQLException ex)
        {
            throw new RuntimeException(ex);
        } catch (Exception e)
        {
            throw new RuntimeException(e);
        }
    }

    // ---------------------------------------------------------------------
    // STORE SIGNATORY
    // ---------------------------------------------------------------------

    public static void storeAssignedSignatory(long fromId, long toId, String symbol) {
        try (Connection c = getConnection();
             PreparedStatement ps = ((java.sql.Connection) c).prepareStatement("""
                 INSERT INTO wat_tasks (from_national_id, to_national_id, type, payload)
                 VALUES (?, ?, 'signatory', ?)
             """)) {

            ps.setLong(1, fromId);
            ps.setLong(2, toId);
            ps.setString(3, symbol);
            ps.executeUpdate();

        } catch (Exception e) { ExceptionHandler.dispatch(e); }
    }

    // ---------------------------------------------------------------------
    // LIST TASKS FOR USER
    // ---------------------------------------------------------------------

    public static ResultSet loadTasksFor(long toId) {
        try {
            Connection c = getConnection();
            PreparedStatement ps = ((java.sql.Connection) c).prepareStatement("""
                SELECT id, type, from_national_id, created_at
                FROM wat_tasks
                WHERE to_national_id = ?
                ORDER BY created_at DESC
            """);
            ps.setLong(1, toId);
            return ps.executeQuery();

        } catch (Exception e) { ExceptionHandler.dispatch(e); return null; }
    }

    // ---------------------------------------------------------------------
    // GET SINGLE TASK
    // ---------------------------------------------------------------------

    public static ResultSet loadTask(long taskId) {
        try {
            Connection c = getConnection();
            PreparedStatement ps = ((java.sql.Connection) c).prepareStatement("""
                SELECT *
                FROM wat_tasks
                WHERE id = ?
            """);
            ps.setLong(1, taskId);
            return ps.executeQuery();

        } catch (Exception e) { ExceptionHandler.dispatch(e); return null; }
    }

    // ---------------------------------------------------------------------
    // DELETE TASK
    // ---------------------------------------------------------------------

    public static void deleteTask(long taskId) {
        try (Connection c = getConnection();
             PreparedStatement ps = ((java.sql.Connection) c).prepareStatement("""
                 DELETE FROM wat_tasks WHERE id = ?
             """)) {

            ps.setLong(1, taskId);
            ps.executeUpdate();

        } catch (Exception e) { ExceptionHandler.dispatch(e); }
    }


    public static Connection getConnection() throws Exception
    {
        String url  = "jdbc:mysql://localhost:3306/n21db?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC&characterEncoding=UTF-8";
        String user = "root";        // change if needed
        String pass = "password";    // change if needed

        Class.forName("com.mysql.cj.jdbc.Driver");

        return (Connection) DriverManager.getConnection(url, user, pass);
    }

    public static void storeChatMessage(final long FROM, final long TO, final String MESSAGE, final String TYPE)
    {
        if (dbOk())
        {
            try
            {
                PreparedStatement ps = N21DataSource.get().prepareStatement(
                    "INSERT INTO communicator_messages (from_national_id, to_national_id, message, type) VALUES (?,?,?,?)");
                ps.setLong(1, FROM); ps.setLong(2, TO);
                ps.setString(3, MESSAGE != null ? MESSAGE : ""); ps.setString(4, TYPE != null ? TYPE : "direct");
                ps.executeUpdate(); ps.close();
                return;
            }
            catch (Exception e) { fail("communicator_messages", e); }
        }
        N21XmlFallback.append("communicator_messages",
            "from", String.valueOf(FROM), "to", String.valueOf(TO), "message", MESSAGE, "type", TYPE);
    }

    public static void storeScheduledMessage(final long FROM, final long TO,
                                              final String MESSAGE, final String SCHED_TIME)
    {
        if (dbOk())
        {
            try
            {
                PreparedStatement ps = N21DataSource.get().prepareStatement(
                    "INSERT INTO communicator_scheduled (from_national_id, to_national_id, message, scheduled_time) VALUES (?,?,?,?)");
                ps.setLong(1, FROM); ps.setLong(2, TO);
                ps.setString(3, MESSAGE != null ? MESSAGE : ""); ps.setString(4, SCHED_TIME);
                ps.executeUpdate(); ps.close();
                return;
            }
            catch (Exception e) { fail("communicator_scheduled", e); }
        }
        N21XmlFallback.append("communicator_scheduled",
            "from", String.valueOf(FROM), "to", String.valueOf(TO),
            "message", MESSAGE, "scheduled_time", SCHED_TIME);
    }

    /** Returns all undelivered scheduled messages as an open ResultSet (caller must close). */
    public static java.sql.ResultSet loadDueScheduledMessages()
    {
        if (!dbOk()) return null;
        try
        {
            PreparedStatement ps = N21DataSource.get().prepareStatement(
                "SELECT id, from_national_id, to_national_id, message, scheduled_time " +
                "FROM communicator_scheduled WHERE delivered=0 ORDER BY created_at ASC");
            return ps.executeQuery();
        }
        catch (Exception e) { fail("communicator_scheduled", e); return null; }
    }

    /** Returns last N chat messages as an open ResultSet (caller must close). */
    public static java.sql.ResultSet loadRecentChatMessages(final int limit)
    {
        if (!dbOk()) return null;
        try
        {
            PreparedStatement ps = N21DataSource.get().prepareStatement(
                "SELECT from_national_id, to_national_id, message, sent_at " +
                "FROM communicator_messages ORDER BY sent_at DESC LIMIT ?");
            ps.setInt(1, limit);
            return ps.executeQuery();
        }
        catch (Exception e) { fail("communicator_messages", e); return null; }
    }

    public static void markScheduledDelivered(final long ID)
    {
        if (!dbOk()) return;
        try
        {
            PreparedStatement ps = N21DataSource.get().prepareStatement(
                "UPDATE communicator_scheduled SET delivered=1, delivered_at=NOW() WHERE id=?");
            ps.setLong(1, ID); ps.executeUpdate(); ps.close();
        }
        catch (Exception e) { fail("communicator_scheduled", e); }
    }

    // ── bitcoin_trades ────────────────────────────────────────────────────────

    public static void createBitcoinTradesTable()
    {
        if (!dbOk()) return;
        try
        {
            java.sql.Statement st = N21DataSource.get().createStatement();
            st.executeUpdate(
                "CREATE TABLE IF NOT EXISTS bitcoin_trades (" +
                "  id          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY," +
                "  action      VARCHAR(64)  NOT NULL," +
                "  wallet      VARCHAR(255) NOT NULL DEFAULT ''," +
                "  detail      TEXT         NOT NULL," +
                "  result      TEXT         NOT NULL," +
                "  recorded_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP," +
                "  INDEX idx_bt_action   (action)," +
                "  INDEX idx_bt_recorded (recorded_at)" +
                ") ENGINE=InnoDB");
            st.close();
        }
        catch (Exception e) { fail("bitcoin_trades", e); }
    }

    /**
     * Persist a Bitcoin operation record.
     *
     * @param action   e.g. "send", "load_wallet", "start_bitcoind"
     * @param wallet   wallet name involved (empty string if N/A)
     * @param detail   human-readable detail: address, amount, args, etc.
     * @param result   raw output returned by bitcoin-cli or error string
     */
    public static void storeBitcoinTrade(final String action, final String wallet,
                                          final String detail, final String result)
    {
        if (dbOk())
        {
            try
            {
                PreparedStatement ps = N21DataSource.get().prepareStatement(
                    "INSERT INTO bitcoin_trades (action, wallet, detail, result) VALUES (?,?,?,?)");
                ps.setString(1, action  != null ? action  : "");
                ps.setString(2, wallet  != null ? wallet  : "");
                ps.setString(3, detail  != null ? detail  : "");
                ps.setString(4, result  != null ? result  : "");
                ps.executeUpdate(); ps.close();
                return;
            }
            catch (Exception e) { fail("bitcoin_trades", e); }
        }
        N21XmlFallback.append("bitcoin_trades",
            "action",  action  != null ? action  : "",
            "wallet",  wallet  != null ? wallet  : "",
            "detail",  detail  != null ? detail  : "",
            "result",  result  != null ? result  : "");
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
