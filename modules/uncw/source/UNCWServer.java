package source;

import commons.CommonRails;
import commons.StrernaryConnector;
import commons.color.ColorPalette;

import java.io.*;
import java.net.*;
import java.nio.charset.StandardCharsets;
import java.nio.file.*;
import java.security.*;
import java.sql.*;
import java.time.*;
import java.util.*;
import java.util.concurrent.*;

/**
 * UNCWServer™ — UNCW (Wilmington at the Coast of NC) University Module
 * Port: 49231
 * Database: nwe_uncw
 *
 * Computer Science Club & College Community Platform
 * Universal, fun. SeaCoast colors (teal + gold).
 *
 * Features:
 * - User accounts with student IDs, National IDs (confirmed by NWE servers)
 * - Chancellor login (current + past, up to 2000 total)
 * - Messaging (Chancellor unlimited; Users 10 free/month to other users)
 * - File sharing (80MB, stored in DB or user folder by preference)
 * - Audio file awareness and playback support
 * - Chancellor online status indicator (half-teal/gold squares)
 * - User profiles visible to other users
 * - Admin panel
 *
 * Installer Tech ID: Max Rupplin
 * MEARVK LLC — NitroWebExpress™ 2026
 */
public class UNCWServer implements Runnable {

    public static final int PORT = 49231;
    private static final String DB_URL = "jdbc:mysql://127.0.0.1:3306/nwe_uncw";
    private static final String DB_USER = "root";
    private static final String INSTALLER_TECH_ID = "Max Rupplin";
    private static final long SESSION_LIMIT_MS = 8 * 60 * 60 * 1000L; // 8 hours
    private static final int MAX_FILE_SIZE_MB = 80;
    private static final int FREE_MSGS_PER_MONTH = 10;
    private static final int MAX_CHANCELLORS = 2000;

    // Known audio file extensions
    private static final Set<String> AUDIO_TYPES = Set.of(
        "mp3", "wav", "ogg", "flac", "aac", "m4a", "wma", "opus", "aiff", "mid", "midi"
    );

    static final Map<String, UNCWSession> LIVE = new ConcurrentHashMap<>();

    public UNCWServer() {
        CommonRails.printSystemComponent(this, this.hashCode(),
                ". UNCWServer starting on port " + PORT + " .",
                ColorPalette.COLOR_LIME_GREEN);
        initDatabase();
        Thread.ofVirtual().name("UNCW_SERVER").start(this);
    }

    @Override
    public void run() {
        try (ServerSocket server = new ServerSocket(PORT)) {
            CommonRails.printSystemComponent(this, this.hashCode(),
                    ". UNCWServer listening on port " + PORT + " .");
            while (!Thread.currentThread().isInterrupted()) {
                Socket client = server.accept();
                Thread.ofVirtual().start(() -> handleClient(client));
            }
        } catch (Exception e) { e.printStackTrace(); }
    }

    // ── Session ────────────────────────────────────────────────────────────────

    static final class UNCWSession {
        final String ip;
        final long connectedAt = System.currentTimeMillis();
        String username = null;
        int userId = -1;
        boolean isChancellor = false;
        boolean isAdmin = false;
        String studentId = "";
        String nationalId = "";
        boolean nationalIdConfirmed = false;
        String college = "";
        PrintWriter out;

        UNCWSession(String ip) { this.ip = ip; }
        boolean expired() { return System.currentTimeMillis() - connectedAt > SESSION_LIMIT_MS; }

        void writeLine(String line) {
            try { out.println(line); out.flush(); } catch (Exception ignored) {}
        }
    }

    // ── Client Handler ─────────────────────────────────────────────────────────

    private void handleClient(Socket client) {
        UNCWSession session = new UNCWSession(client.getInetAddress().getHostAddress());
        try (BufferedReader in = new BufferedReader(new InputStreamReader(client.getInputStream(), StandardCharsets.UTF_8));
             PrintWriter out = new PrintWriter(new OutputStreamWriter(client.getOutputStream(), StandardCharsets.UTF_8), true)) {

            session.out = out;
            client.setSoTimeout((int) Math.min(SESSION_LIMIT_MS, Integer.MAX_VALUE));

            out.println("╔══════════════════════════════════════════════════════════════╗");
            out.println("║  UNCW™ — Wilmington at the Coast of NC                      ║");
            out.println("║  Computer Science Club & College Community                   ║");
            out.println("║  Port " + PORT + " | SeaCoast | Universal & Fun                      ║");
            out.println("╚══════════════════════════════════════════════════════════════╝");
            out.println("Commands: REGISTER, LOGIN, CHANCELLOR_LOGIN, HELP");

            String line;
            while ((line = in.readLine()) != null) {
                if (session.expired()) { out.println("SESSION|EXPIRED"); break; }
                String response = processCommand(line.trim(), session);
                out.println(response);
                if ("QUIT".equalsIgnoreCase(line.trim())) break;
            }
        } catch (Exception ignored) {}
        if (session.username != null) LIVE.remove(session.username);
        try { client.close(); } catch (Exception ignored) {}
    }

    // ── Command Processing ─────────────────────────────────────────────────────

    private String processCommand(String input, UNCWSession session) {
        if (input.isEmpty()) return "ERROR|Empty command. Type HELP.";
        String upper = input.toUpperCase();

        if (upper.equals("QUIT")) return "BYE|UNCW session closed. Go Seahawks!";
        if (upper.equals("HELP")) return getHelp(session);
        if (upper.equals("STATUS")) return "STATUS|OK|port=" + PORT + "|db=nwe_uncw|users=" + LIVE.size() + "|chancellors_online=" + countChancellorsOnline();

        // Account
        if (upper.startsWith("REGISTER|")) return registerUser(input, session);
        if (upper.startsWith("LOGIN|")) return loginUser(input, session);
        if (upper.startsWith("CHANCELLOR_LOGIN|")) return chancellorLogin(input, session);
        if (upper.startsWith("ADMIN|")) return adminLogin(input, session);

        // Require login
        if (session.username == null) return "ERROR|Not logged in. Use LOGIN|username|password";

        // Profile & Social
        if (upper.equals("PROFILE")) return getOwnProfile(session);
        if (upper.startsWith("VIEW_PROFILE|")) return viewProfile(input, session);
        if (upper.equals("USERS")) return listUsers();
        if (upper.equals("CHANCELLOR_STATUS")) return chancellorStatus();

        // Messaging
        if (upper.startsWith("MSG|")) return sendMessage(input, session);
        if (upper.equals("INBOX")) return getInbox(session);

        // Files
        if (upper.startsWith("UPLOAD|")) return uploadFile(input, session);
        if (upper.startsWith("DOWNLOAD|")) return downloadFile(input, session);
        if (upper.startsWith("SEND_FILE|")) return sendFile(input, session);
        if (upper.equals("MY_FILES")) return listMyFiles(session);
        if (upper.startsWith("FILE_STORAGE|")) return setFileStorage(input, session);

        // National ID
        if (upper.startsWith("SET_NATIONAL_ID|")) return setNationalId(input, session);
        if (upper.equals("CHECK_NATIONAL_ID")) return checkNationalId(session);

        // Profile Picture & Resume
        if (upper.startsWith("SET_PROFILE_PIC|")) return setProfilePic(input, session);
        if (upper.startsWith("UPLOAD_RESUME|")) return uploadResume(input, session);
        if (upper.equals("GET_PROFILE_PIC")) return getProfilePic(session);
        if (upper.equals("GET_RESUME")) return getResume(session);

        // Chancellor Notes (chancellor only)
        if (session.isChancellor && upper.startsWith("CHANCELLOR_NOTE|")) return addChancellorNote(input, session);
        if (upper.equals("CHANCELLOR_NOTES")) return getChancellorNotes();

        // Admin
        if (session.isAdmin) {
            if (upper.equals("ADMIN_USERS")) return adminListUsers();
            if (upper.startsWith("ADMIN_BAN|")) return adminBan(input);
            if (upper.startsWith("ADMIN_SET_CHANCELLOR|")) return adminSetChancellor(input);
            if (upper.startsWith("ADMIN_CONFIRM_NID|")) return adminConfirmNationalId(input);
        }

        return "ERROR|Unknown command. Type HELP.";
    }

    // ── Account Operations ─────────────────────────────────────────────────────

    private String registerUser(String input, UNCWSession session) {
        // REGISTER|username|password|email|studentId|college
        String[] parts = input.split("\\|", 6);
        if (parts.length < 6) return "ERROR|Usage: REGISTER|username|password|email|studentId|college";
        String username = parts[1].trim(), password = parts[2].trim(), email = parts[3].trim();
        String studentId = parts[4].trim(), college = parts[5].trim();

        if (username.length() < 3 || username.length() > 32) return "ERROR|Username must be 3-32 chars.";
        if (password.length() < 6) return "ERROR|Password must be 6+ chars.";

        try (Connection c = DriverManager.getConnection(DB_URL, DB_USER, getPassword())) {
            PreparedStatement check = c.prepareStatement("SELECT id FROM users WHERE username = ?");
            check.setString(1, username);
            if (check.executeQuery().next()) return "ERROR|Username taken.";

            String salt = genSalt(); String hash = hashPw(password, salt);
            PreparedStatement ins = c.prepareStatement(
                "INSERT INTO users (username, password_hash, salt, email, student_id, college, ip_address, created_at) VALUES (?,?,?,?,?,?,?,NOW())",
                Statement.RETURN_GENERATED_KEYS);
            ins.setString(1, username); ins.setString(2, hash); ins.setString(3, salt);
            ins.setString(4, email); ins.setString(5, studentId); ins.setString(6, college);
            ins.setString(7, session.ip); ins.executeUpdate();
            ResultSet rs = ins.getGeneratedKeys(); rs.next();
            session.userId = rs.getInt(1); session.username = username;
            session.studentId = studentId; session.college = college;
            LIVE.put(username, session);

            // Create user file directory
            Path userDir = Paths.get("modules/uncw/user-files/" + username);
            Files.createDirectories(userDir);

            return "REGISTER|OK|Welcome to UNCW, " + username + "! Go Seahawks! 🌊";
        } catch (Exception e) { return "ERROR|" + e.getMessage(); }
    }

    private String loginUser(String input, UNCWSession session) {
        String[] parts = input.split("\\|", 3);
        if (parts.length < 3) return "ERROR|Usage: LOGIN|username|password";
        String username = parts[1].trim(), password = parts[2].trim();

        try (Connection c = DriverManager.getConnection(DB_URL, DB_USER, getPassword())) {
            PreparedStatement ps = c.prepareStatement("SELECT * FROM users WHERE username = ? AND is_banned = FALSE");
            ps.setString(1, username); ResultSet rs = ps.executeQuery();
            if (!rs.next()) return "ERROR|User not found or banned.";
            if (!hashPw(password, rs.getString("salt")).equals(rs.getString("password_hash"))) return "ERROR|Invalid password.";

            session.userId = rs.getInt("id"); session.username = username;
            session.isChancellor = rs.getBoolean("is_chancellor");
            session.isAdmin = rs.getBoolean("is_admin");
            session.studentId = rs.getString("student_id");
            session.nationalId = rs.getString("national_id") != null ? rs.getString("national_id") : "";
            session.nationalIdConfirmed = rs.getBoolean("national_id_confirmed");
            session.college = rs.getString("college");
            LIVE.put(username, session);

            PreparedStatement upd = c.prepareStatement("UPDATE users SET last_login = NOW(), last_ip = ? WHERE id = ?");
            upd.setString(1, session.ip); upd.setInt(2, session.userId); upd.executeUpdate();

            String label = session.isChancellor ? " [Chancellor]" : "";
            String nidWarn = session.nationalIdConfirmed ? "" : " | ⚠ Reminder: Set your National ID (SET_NATIONAL_ID|<id>) and confirm with our server.";
            return "LOGIN|OK|Welcome back, " + username + "!" + label + nidWarn;
        } catch (Exception e) { return "ERROR|" + e.getMessage(); }
    }

    private String chancellorLogin(String input, UNCWSession session) {
        // CHANCELLOR_LOGIN|username|password
        String[] parts = input.split("\\|", 3);
        if (parts.length < 3) return "ERROR|Usage: CHANCELLOR_LOGIN|username|password";

        String result = loginUser("LOGIN|" + parts[1] + "|" + parts[2], session);
        if (result.startsWith("LOGIN|OK") && !session.isChancellor) {
            return "ERROR|This account is not a Chancellor account.";
        }
        if (result.startsWith("LOGIN|OK")) {
            // Update chancellor_last_online
            try (Connection c = DriverManager.getConnection(DB_URL, DB_USER, getPassword())) {
                PreparedStatement ps = c.prepareStatement("UPDATE users SET chancellor_last_online = NOW() WHERE id = ?");
                ps.setInt(1, session.userId); ps.executeUpdate();
            } catch (Exception ignored) {}
        }
        return result;
    }

    private String adminLogin(String input, UNCWSession session) {
        String[] parts = input.split("\\|", 2);
        if (parts.length < 2) return "ERROR|Usage: ADMIN|password";
        if (!parts[1].trim().equals("NWE_UNCW_ADMIN_2026")) return "ERROR|Invalid admin credentials.";
        session.isAdmin = true;
        return "ADMIN|OK|Admin mode activated.";
    }

    // ── Profile & Social ───────────────────────────────────────────────────────

    private String getOwnProfile(UNCWSession session) {
        try (Connection c = DriverManager.getConnection(DB_URL, DB_USER, getPassword())) {
            PreparedStatement ps = c.prepareStatement("SELECT * FROM users WHERE id = ?");
            ps.setInt(1, session.userId); ResultSet rs = ps.executeQuery();
            if (!rs.next()) return "ERROR|Profile not found.";
            return "PROFILE|username=" + rs.getString("username") +
                "|studentId=" + rs.getString("student_id") +
                "|college=" + rs.getString("college") +
                "|email=" + rs.getString("email") +
                "|nationalId=" + (rs.getString("national_id") != null ? rs.getString("national_id") : "NOT_SET") +
                "|nidConfirmed=" + rs.getBoolean("national_id_confirmed") +
                "|chancellor=" + rs.getBoolean("is_chancellor") +
                "|profilePic=" + (rs.getString("profile_picture") != null ? "SET" : "NOT_SET") +
                "|resume=" + (rs.getString("resume_path") != null ? "SET" : "NOT_SET") +
                "|joined=" + rs.getTimestamp("created_at") +
                "|fileStorage=" + rs.getString("file_storage_pref");
        } catch (Exception e) { return "ERROR|" + e.getMessage(); }
    }

    private String viewProfile(String input, UNCWSession session) {
        String[] parts = input.split("\\|", 2);
        if (parts.length < 2) return "ERROR|Usage: VIEW_PROFILE|username";
        try (Connection c = DriverManager.getConnection(DB_URL, DB_USER, getPassword())) {
            PreparedStatement ps = c.prepareStatement("SELECT username, student_id, college, is_chancellor, national_id_confirmed, profile_picture, resume_path, created_at, chancellor_last_online FROM users WHERE username = ? AND is_banned = FALSE");
            ps.setString(1, parts[1].trim()); ResultSet rs = ps.executeQuery();
            if (!rs.next()) return "ERROR|User not found.";
            return "PROFILE|username=" + rs.getString("username") +
                "|studentId=" + rs.getString("student_id") +
                "|college=" + rs.getString("college") +
                "|chancellor=" + rs.getBoolean("is_chancellor") +
                "|nationalIdVerified=" + rs.getBoolean("national_id_confirmed") +
                "|profilePic=" + (rs.getString("profile_picture") != null ? "SET" : "NOT_SET") +
                "|resume=" + (rs.getString("resume_path") != null ? "AVAILABLE" : "NONE") +
                "|joined=" + rs.getTimestamp("created_at") +
                (rs.getBoolean("is_chancellor") ? "|lastOnline=" + rs.getTimestamp("chancellor_last_online") : "");
        } catch (Exception e) { return "ERROR|" + e.getMessage(); }
    }

    private String listUsers() {
        try (Connection c = DriverManager.getConnection(DB_URL, DB_USER, getPassword())) {
            Statement st = c.createStatement();
            ResultSet rs = st.executeQuery("SELECT username, college, is_chancellor FROM users WHERE is_banned = FALSE ORDER BY is_chancellor DESC, username ASC LIMIT 100");
            StringBuilder sb = new StringBuilder("USERS|");
            while (rs.next()) {
                sb.append(rs.getString("username"))
                  .append("[").append(rs.getString("college")).append("]")
                  .append(rs.getBoolean("is_chancellor") ? "★" : "").append("|");
            }
            return sb.toString();
        } catch (Exception e) { return "ERROR|" + e.getMessage(); }
    }

    private String chancellorStatus() {
        try (Connection c = DriverManager.getConnection(DB_URL, DB_USER, getPassword())) {
            // Count chancellors online now
            int online = 0;
            for (UNCWSession s : LIVE.values()) { if (s.isChancellor) online++; }

            // Count chancellors online within a year
            PreparedStatement ps = c.prepareStatement(
                "SELECT COUNT(*) AS cnt FROM users WHERE is_chancellor = TRUE AND chancellor_last_online >= DATE_SUB(NOW(), INTERVAL 1 YEAR)");
            ResultSet rs = ps.executeQuery(); rs.next();
            int withinYear = rs.getInt("cnt");

            // Total chancellors
            PreparedStatement tot = c.prepareStatement("SELECT COUNT(*) AS cnt FROM users WHERE is_chancellor = TRUE");
            ResultSet totRs = tot.executeQuery(); totRs.next();
            int total = totRs.getInt("cnt");

            return "CHANCELLOR_STATUS|online_now=" + online + "|online_within_year=" + withinYear + "|total=" + total + "|max=" + MAX_CHANCELLORS;
        } catch (Exception e) { return "ERROR|" + e.getMessage(); }
    }

    // ── Messaging ──────────────────────────────────────────────────────────────

    private String sendMessage(String input, UNCWSession session) {
        // MSG|targetUser|message
        String[] parts = input.split("\\|", 3);
        if (parts.length < 3) return "ERROR|Usage: MSG|username|message";
        String target = parts[1].trim(), message = parts[2].trim();

        // Check messaging limits (chancellors unlimited, users 10/month)
        if (!session.isChancellor) {
            try (Connection c = DriverManager.getConnection(DB_URL, DB_USER, getPassword())) {
                PreparedStatement ps = c.prepareStatement(
                    "SELECT COUNT(*) AS cnt FROM messages WHERE sender_id = ? AND sent_at >= DATE_SUB(NOW(), INTERVAL 1 MONTH)");
                ps.setInt(1, session.userId); ResultSet rs = ps.executeQuery(); rs.next();
                if (rs.getInt("cnt") >= FREE_MSGS_PER_MONTH) {
                    return "ERROR|Monthly message limit reached (" + FREE_MSGS_PER_MONTH + " messages/month for non-Chancellor users).";
                }
            } catch (Exception ignored) {}
        }

        // Store and deliver
        try (Connection c = DriverManager.getConnection(DB_URL, DB_USER, getPassword())) {
            PreparedStatement getTarget = c.prepareStatement("SELECT id FROM users WHERE username = ?");
            getTarget.setString(1, target); ResultSet rs = getTarget.executeQuery();
            if (!rs.next()) return "ERROR|User '" + target + "' not found.";
            int targetId = rs.getInt("id");

            PreparedStatement ins = c.prepareStatement(
                "INSERT INTO messages (sender_id, receiver_id, content, sent_at) VALUES (?,?,?,NOW())");
            ins.setInt(1, session.userId); ins.setInt(2, targetId); ins.setString(3, message);
            ins.executeUpdate();

            // Deliver if online
            UNCWSession targetSession = LIVE.get(target);
            if (targetSession != null) {
                targetSession.writeLine("MSG|" + session.username + "|" + message);
            }
            return "MSG|SENT|to=" + target;
        } catch (Exception e) { return "ERROR|" + e.getMessage(); }
    }

    private String getInbox(UNCWSession session) {
        try (Connection c = DriverManager.getConnection(DB_URL, DB_USER, getPassword())) {
            PreparedStatement ps = c.prepareStatement(
                "SELECT m.*, u.username AS sender_name FROM messages m JOIN users u ON m.sender_id = u.id " +
                "WHERE m.receiver_id = ? ORDER BY m.sent_at DESC LIMIT 30");
            ps.setInt(1, session.userId); ResultSet rs = ps.executeQuery();
            StringBuilder sb = new StringBuilder("INBOX|");
            while (rs.next()) {
                sb.append(rs.getTimestamp("sent_at")).append(" ").append(rs.getString("sender_name"))
                  .append(": ").append(rs.getString("content")).append("|");
            }
            return sb.length() > 6 ? sb.toString() : "INBOX|EMPTY";
        } catch (Exception e) { return "ERROR|" + e.getMessage(); }
    }

    // ── File Operations ────────────────────────────────────────────────────────

    private String uploadFile(String input, UNCWSession session) {
        // UPLOAD|filename|sizeBytes|base64Data
        String[] parts = input.split("\\|", 4);
        if (parts.length < 4) return "ERROR|Usage: UPLOAD|filename|sizeBytes|base64Data";
        String filename = parts[1].trim();
        long size = Long.parseLong(parts[2].trim());

        if (size > MAX_FILE_SIZE_MB * 1024L * 1024L) return "ERROR|File too large. Max " + MAX_FILE_SIZE_MB + "MB.";

        String ext = filename.contains(".") ? filename.substring(filename.lastIndexOf('.') + 1).toLowerCase() : "";
        boolean isAudio = AUDIO_TYPES.contains(ext);

        try (Connection c = DriverManager.getConnection(DB_URL, DB_USER, getPassword())) {
            // Check user preference for file storage
            PreparedStatement prefPs = c.prepareStatement("SELECT file_storage_pref FROM users WHERE id = ?");
            prefPs.setInt(1, session.userId); ResultSet prefRs = prefPs.executeQuery(); prefRs.next();
            String pref = prefRs.getString("file_storage_pref");

            if ("FOLDER".equals(pref)) {
                // Store in user's folder
                Path userDir = Paths.get("modules/uncw/user-files/" + session.username);
                Files.createDirectories(userDir);
                Files.write(userDir.resolve(filename), Base64.getDecoder().decode(parts[3].trim()));

                // Record in DB without blob
                PreparedStatement ins = c.prepareStatement(
                    "INSERT INTO files (owner_id, filename, file_size, is_audio, storage_type, file_path, uploaded_at) VALUES (?,?,?,?,?,?,NOW())");
                ins.setInt(1, session.userId); ins.setString(2, filename); ins.setLong(3, size);
                ins.setBoolean(4, isAudio); ins.setString(5, "FOLDER");
                ins.setString(6, userDir.resolve(filename).toString()); ins.executeUpdate();
            } else {
                // Store in database (default)
                PreparedStatement ins = c.prepareStatement(
                    "INSERT INTO files (owner_id, filename, file_size, is_audio, storage_type, file_data, uploaded_at) VALUES (?,?,?,?,?,?,NOW())");
                ins.setInt(1, session.userId); ins.setString(2, filename); ins.setLong(3, size);
                ins.setBoolean(4, isAudio); ins.setString(5, "DATABASE");
                ins.setString(6, parts[3].trim()); ins.executeUpdate();
            }

            return "UPLOAD|OK|file=" + filename + "|size=" + size + "|audio=" + isAudio + "|storage=" + pref;
        } catch (Exception e) { return "ERROR|" + e.getMessage(); }
    }

    private String downloadFile(String input, UNCWSession session) {
        // DOWNLOAD|fileId
        String[] parts = input.split("\\|", 2);
        if (parts.length < 2) return "ERROR|Usage: DOWNLOAD|fileId";
        try (Connection c = DriverManager.getConnection(DB_URL, DB_USER, getPassword())) {
            PreparedStatement ps = c.prepareStatement("SELECT * FROM files WHERE id = ?");
            ps.setInt(1, Integer.parseInt(parts[1].trim())); ResultSet rs = ps.executeQuery();
            if (!rs.next()) return "ERROR|File not found.";

            String storage = rs.getString("storage_type");
            if ("FOLDER".equals(storage)) {
                byte[] data = Files.readAllBytes(Paths.get(rs.getString("file_path")));
                return "FILE_DATA|" + rs.getString("filename") + "|" + Base64.getEncoder().encodeToString(data);
            } else {
                return "FILE_DATA|" + rs.getString("filename") + "|" + rs.getString("file_data");
            }
        } catch (Exception e) { return "ERROR|" + e.getMessage(); }
    }

    private String sendFile(String input, UNCWSession session) {
        // SEND_FILE|targetUser|fileId
        String[] parts = input.split("\\|", 3);
        if (parts.length < 3) return "ERROR|Usage: SEND_FILE|username|fileId";
        String target = parts[1].trim();
        int fileId = Integer.parseInt(parts[2].trim());

        try (Connection c = DriverManager.getConnection(DB_URL, DB_USER, getPassword())) {
            // Verify file belongs to sender
            PreparedStatement ps = c.prepareStatement("SELECT filename, file_size FROM files WHERE id = ? AND owner_id = ?");
            ps.setInt(1, fileId); ps.setInt(2, session.userId); ResultSet rs = ps.executeQuery();
            if (!rs.next()) return "ERROR|File not found or not yours.";

            // Share record
            PreparedStatement getTarget = c.prepareStatement("SELECT id FROM users WHERE username = ?");
            getTarget.setString(1, target); ResultSet trs = getTarget.executeQuery();
            if (!trs.next()) return "ERROR|User not found.";

            PreparedStatement ins = c.prepareStatement(
                "INSERT INTO file_shares (file_id, owner_id, shared_with_id, shared_at) VALUES (?,?,?,NOW())");
            ins.setInt(1, fileId); ins.setInt(2, session.userId); ins.setInt(3, trs.getInt("id"));
            ins.executeUpdate();

            UNCWSession targetSession = LIVE.get(target);
            if (targetSession != null) {
                targetSession.writeLine("FILE_SHARED|" + session.username + "|" + rs.getString("filename") + "|fileId=" + fileId);
            }
            return "SEND_FILE|OK|" + rs.getString("filename") + " shared with " + target;
        } catch (Exception e) { return "ERROR|" + e.getMessage(); }
    }

    private String listMyFiles(UNCWSession session) {
        try (Connection c = DriverManager.getConnection(DB_URL, DB_USER, getPassword())) {
            PreparedStatement ps = c.prepareStatement("SELECT id, filename, file_size, is_audio, storage_type, uploaded_at FROM files WHERE owner_id = ? ORDER BY uploaded_at DESC LIMIT 50");
            ps.setInt(1, session.userId); ResultSet rs = ps.executeQuery();
            StringBuilder sb = new StringBuilder("MY_FILES|");
            while (rs.next()) {
                sb.append("id=").append(rs.getInt("id"))
                  .append(",name=").append(rs.getString("filename"))
                  .append(",size=").append(rs.getLong("file_size"))
                  .append(",audio=").append(rs.getBoolean("is_audio"))
                  .append(",storage=").append(rs.getString("storage_type")).append("|");
            }
            return sb.length() > 9 ? sb.toString() : "MY_FILES|EMPTY";
        } catch (Exception e) { return "ERROR|" + e.getMessage(); }
    }

    private String setFileStorage(String input, UNCWSession session) {
        // FILE_STORAGE|DATABASE or FILE_STORAGE|FOLDER
        String[] parts = input.split("\\|", 2);
        if (parts.length < 2) return "ERROR|Usage: FILE_STORAGE|DATABASE or FILE_STORAGE|FOLDER";
        String pref = parts[1].trim().toUpperCase();
        if (!pref.equals("DATABASE") && !pref.equals("FOLDER")) return "ERROR|Must be DATABASE or FOLDER.";

        try (Connection c = DriverManager.getConnection(DB_URL, DB_USER, getPassword())) {
            PreparedStatement ps = c.prepareStatement("UPDATE users SET file_storage_pref = ? WHERE id = ?");
            ps.setString(1, pref); ps.setInt(2, session.userId); ps.executeUpdate();
            return "FILE_STORAGE|OK|Preference set to " + pref;
        } catch (Exception e) { return "ERROR|" + e.getMessage(); }
    }

    // ── Profile Picture & Resume ─────────────────────────────────────────────────

    private String setProfilePic(String input, UNCWSession session) {
        // SET_PROFILE_PIC|filename|base64Data
        String[] parts = input.split("\\|", 3);
        if (parts.length < 3) return "ERROR|Usage: SET_PROFILE_PIC|filename.jpg|base64Data";
        String filename = parts[1].trim();
        String ext = filename.contains(".") ? filename.substring(filename.lastIndexOf('.') + 1).toLowerCase() : "";
        if (!Set.of("jpg", "jpeg", "png", "gif", "webp", "bmp").contains(ext))
            return "ERROR|Profile picture must be jpg, jpeg, png, gif, webp, or bmp.";

        try {
            Path picDir = Paths.get("modules/uncw/user-files/" + session.username + "/profile");
            Files.createDirectories(picDir);
            Path picPath = picDir.resolve("avatar." + ext);
            Files.write(picPath, Base64.getDecoder().decode(parts[2].trim()));

            try (Connection c = DriverManager.getConnection(DB_URL, DB_USER, getPassword())) {
                PreparedStatement ps = c.prepareStatement("UPDATE users SET profile_picture = ? WHERE id = ?");
                ps.setString(1, picPath.toString()); ps.setInt(2, session.userId); ps.executeUpdate();
            }
            return "PROFILE_PIC|OK|Profile picture set: " + filename;
        } catch (Exception e) { return "ERROR|" + e.getMessage(); }
    }

    private String getProfilePic(UNCWSession session) {
        try (Connection c = DriverManager.getConnection(DB_URL, DB_USER, getPassword())) {
            PreparedStatement ps = c.prepareStatement("SELECT profile_picture FROM users WHERE id = ?");
            ps.setInt(1, session.userId); ResultSet rs = ps.executeQuery();
            if (rs.next() && rs.getString("profile_picture") != null) {
                Path picPath = Paths.get(rs.getString("profile_picture"));
                if (Files.exists(picPath)) {
                    byte[] data = Files.readAllBytes(picPath);
                    return "PROFILE_PIC|DATA|" + picPath.getFileName() + "|" + Base64.getEncoder().encodeToString(data);
                }
                return "PROFILE_PIC|NOT_FOUND|File missing on disk.";
            }
            return "PROFILE_PIC|NOT_SET|Use SET_PROFILE_PIC|filename|base64Data to upload.";
        } catch (Exception e) { return "ERROR|" + e.getMessage(); }
    }

    private String uploadResume(String input, UNCWSession session) {
        // UPLOAD_RESUME|filename|base64Data
        String[] parts = input.split("\\|", 3);
        if (parts.length < 3) return "ERROR|Usage: UPLOAD_RESUME|resume.pdf|base64Data";
        String filename = parts[1].trim();
        String ext = filename.contains(".") ? filename.substring(filename.lastIndexOf('.') + 1).toLowerCase() : "";
        if (!Set.of("pdf", "doc", "docx", "txt", "rtf", "odt").contains(ext))
            return "ERROR|Resume must be pdf, doc, docx, txt, rtf, or odt.";

        try {
            Path resumeDir = Paths.get("modules/uncw/user-files/" + session.username + "/resume");
            Files.createDirectories(resumeDir);
            Path resumePath = resumeDir.resolve(filename);
            Files.write(resumePath, Base64.getDecoder().decode(parts[2].trim()));

            try (Connection c = DriverManager.getConnection(DB_URL, DB_USER, getPassword())) {
                PreparedStatement ps = c.prepareStatement("UPDATE users SET resume_path = ? WHERE id = ?");
                ps.setString(1, resumePath.toString()); ps.setInt(2, session.userId); ps.executeUpdate();
            }
            return "RESUME|OK|Resume uploaded: " + filename;
        } catch (Exception e) { return "ERROR|" + e.getMessage(); }
    }

    private String getResume(UNCWSession session) {
        try (Connection c = DriverManager.getConnection(DB_URL, DB_USER, getPassword())) {
            PreparedStatement ps = c.prepareStatement("SELECT resume_path FROM users WHERE id = ?");
            ps.setInt(1, session.userId); ResultSet rs = ps.executeQuery();
            if (rs.next() && rs.getString("resume_path") != null) {
                Path rPath = Paths.get(rs.getString("resume_path"));
                if (Files.exists(rPath)) {
                    byte[] data = Files.readAllBytes(rPath);
                    return "RESUME|DATA|" + rPath.getFileName() + "|" + Base64.getEncoder().encodeToString(data);
                }
                return "RESUME|NOT_FOUND|File missing on disk.";
            }
            return "RESUME|NOT_SET|Use UPLOAD_RESUME|filename|base64Data to upload.";
        } catch (Exception e) { return "ERROR|" + e.getMessage(); }
    }

    // ── National ID ────────────────────────────────────────────────────────────

    private String setNationalId(String input, UNCWSession session) {
        String[] parts = input.split("\\|", 2);
        if (parts.length < 2) return "ERROR|Usage: SET_NATIONAL_ID|yourNationalId";
        String nid = parts[1].trim();
        try (Connection c = DriverManager.getConnection(DB_URL, DB_USER, getPassword())) {
            PreparedStatement ps = c.prepareStatement("UPDATE users SET national_id = ? WHERE id = ?");
            ps.setString(1, nid); ps.setInt(2, session.userId); ps.executeUpdate();
            session.nationalId = nid;
            return "NATIONAL_ID|SET|Please wait for confirmation by one of our servers. Check with CHECK_NATIONAL_ID.";
        } catch (Exception e) { return "ERROR|" + e.getMessage(); }
    }

    private String checkNationalId(UNCWSession session) {
        // Attempt server-side verification via Strernary (hardened)
        if (session.nationalId.isEmpty()) return "NATIONAL_ID|NOT_SET|Use SET_NATIONAL_ID|<id> first.";
        String result = StrernaryConnector.askHardened("UNCW", session.ip, 9.5,
            session.username, "UNCW", "UNCW|READY|port=49231",
            "national-id", "VERIFY", "id=" + session.nationalId + " user=" + session.username);
        if (result != null && result.contains("CONFIRMED")) {
            try (Connection c = DriverManager.getConnection(DB_URL, DB_USER, getPassword())) {
                PreparedStatement ps = c.prepareStatement("UPDATE users SET national_id_confirmed = TRUE WHERE id = ?");
                ps.setInt(1, session.userId); ps.executeUpdate();
                session.nationalIdConfirmed = true;
            } catch (Exception ignored) {}
            return "NATIONAL_ID|CONFIRMED|Your National ID has been verified by our server. ✓";
        }
        return "NATIONAL_ID|PENDING|Verification pending. An administrator or our server will confirm shortly.";
    }

    // ── Chancellor Notes ───────────────────────────────────────────────────────

    private String addChancellorNote(String input, UNCWSession session) {
        // CHANCELLOR_NOTE|content
        String[] parts = input.split("\\|", 2);
        if (parts.length < 2) return "ERROR|Usage: CHANCELLOR_NOTE|your note";
        try (Connection c = DriverManager.getConnection(DB_URL, DB_USER, getPassword())) {
            PreparedStatement ps = c.prepareStatement(
                "INSERT INTO chancellor_notes (chancellor_id, content, created_at) VALUES (?,?,NOW())");
            ps.setInt(1, session.userId); ps.setString(2, parts[1].trim()); ps.executeUpdate();
            return "CHANCELLOR_NOTE|OK|Note saved.";
        } catch (Exception e) { return "ERROR|" + e.getMessage(); }
    }

    private String getChancellorNotes() {
        try (Connection c = DriverManager.getConnection(DB_URL, DB_USER, getPassword())) {
            PreparedStatement ps = c.prepareStatement(
                "SELECT cn.*, u.username FROM chancellor_notes cn JOIN users u ON cn.chancellor_id = u.id ORDER BY cn.created_at DESC LIMIT 20");
            ResultSet rs = ps.executeQuery();
            StringBuilder sb = new StringBuilder("CHANCELLOR_NOTES|");
            while (rs.next()) {
                sb.append(rs.getTimestamp("created_at")).append(" [").append(rs.getString("username")).append("] ")
                  .append(rs.getString("content")).append("|");
            }
            return sb.length() > 18 ? sb.toString() : "CHANCELLOR_NOTES|NONE";
        } catch (Exception e) { return "ERROR|" + e.getMessage(); }
    }

    // ── Admin ──────────────────────────────────────────────────────────────────

    private String adminListUsers() {
        try (Connection c = DriverManager.getConnection(DB_URL, DB_USER, getPassword())) {
            Statement st = c.createStatement();
            ResultSet rs = st.executeQuery("SELECT id, username, student_id, college, is_chancellor, is_banned, national_id_confirmed, last_login FROM users ORDER BY last_login DESC LIMIT 100");
            StringBuilder sb = new StringBuilder("ADMIN_USERS|");
            while (rs.next()) {
                sb.append(rs.getString("username")).append("[sid=").append(rs.getString("student_id"))
                  .append(",college=").append(rs.getString("college"))
                  .append(",chan=").append(rs.getBoolean("is_chancellor"))
                  .append(",nid=").append(rs.getBoolean("national_id_confirmed"))
                  .append(",ban=").append(rs.getBoolean("is_banned")).append("]|");
            }
            return sb.toString();
        } catch (Exception e) { return "ERROR|" + e.getMessage(); }
    }

    private String adminBan(String input) {
        String[] parts = input.split("\\|", 2);
        if (parts.length < 2) return "ERROR|Usage: ADMIN_BAN|username";
        try (Connection c = DriverManager.getConnection(DB_URL, DB_USER, getPassword())) {
            PreparedStatement ps = c.prepareStatement("UPDATE users SET is_banned = TRUE WHERE username = ?");
            ps.setString(1, parts[1].trim()); ps.executeUpdate();
            LIVE.remove(parts[1].trim());
            return "ADMIN|BAN|" + parts[1].trim() + " banned.";
        } catch (Exception e) { return "ERROR|" + e.getMessage(); }
    }

    private String adminSetChancellor(String input) {
        // ADMIN_SET_CHANCELLOR|username|true/false
        String[] parts = input.split("\\|", 3);
        if (parts.length < 3) return "ERROR|Usage: ADMIN_SET_CHANCELLOR|username|true/false";
        try (Connection c = DriverManager.getConnection(DB_URL, DB_USER, getPassword())) {
            PreparedStatement ps = c.prepareStatement("UPDATE users SET is_chancellor = ? WHERE username = ?");
            ps.setBoolean(1, Boolean.parseBoolean(parts[2].trim()));
            ps.setString(2, parts[1].trim()); ps.executeUpdate();
            return "ADMIN|CHANCELLOR|" + parts[1].trim() + " → chancellor=" + parts[2].trim();
        } catch (Exception e) { return "ERROR|" + e.getMessage(); }
    }

    private String adminConfirmNationalId(String input) {
        String[] parts = input.split("\\|", 2);
        if (parts.length < 2) return "ERROR|Usage: ADMIN_CONFIRM_NID|username";
        try (Connection c = DriverManager.getConnection(DB_URL, DB_USER, getPassword())) {
            PreparedStatement ps = c.prepareStatement("UPDATE users SET national_id_confirmed = TRUE WHERE username = ?");
            ps.setString(1, parts[1].trim()); ps.executeUpdate();
            return "ADMIN|NID_CONFIRMED|" + parts[1].trim() + " National ID confirmed.";
        } catch (Exception e) { return "ERROR|" + e.getMessage(); }
    }

    // ── Utilities ──────────────────────────────────────────────────────────────

    private int countChancellorsOnline() {
        int count = 0;
        for (UNCWSession s : LIVE.values()) { if (s.isChancellor) count++; }
        return count;
    }

    private String getHelp(UNCWSession session) {
        return "HELP|REGISTER|user|pass|email|sid|college, LOGIN|user|pass, CHANCELLOR_LOGIN|user|pass, " +
            "PROFILE, VIEW_PROFILE|user, USERS, MSG|user|text, INBOX, " +
            "UPLOAD|filename|size|b64, DOWNLOAD|fileId, SEND_FILE|user|fileId, MY_FILES, FILE_STORAGE|DB/FOLDER, " +
            "SET_NATIONAL_ID|id, CHECK_NATIONAL_ID, CHANCELLOR_STATUS, CHANCELLOR_NOTES, " +
            (session != null && session.isChancellor ? "CHANCELLOR_NOTE|text, " : "") +
            "STATUS, HELP, QUIT";
    }

    private String genSalt() { byte[] s = new byte[16]; new SecureRandom().nextBytes(s); return HexFormat.of().formatHex(s); }
    private String hashPw(String pw, String salt) {
        try { MessageDigest md = MessageDigest.getInstance("SHA-256"); md.update(salt.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(md.digest(pw.getBytes(StandardCharsets.UTF_8))); } catch (Exception e) { return ""; }
    }

    // ── Database Init ──────────────────────────────────────────────────────────

    private void initDatabase() {
        try (Connection c = DriverManager.getConnection("jdbc:mysql://127.0.0.1:3306/", DB_USER, getPassword())) {
            Statement st = c.createStatement();
            st.executeUpdate("CREATE DATABASE IF NOT EXISTS nwe_uncw");
            st.execute("USE nwe_uncw");

            st.executeUpdate("CREATE TABLE IF NOT EXISTS users (" +
                "id INT AUTO_INCREMENT PRIMARY KEY, username VARCHAR(64) NOT NULL UNIQUE, " +
                "password_hash VARCHAR(128) NOT NULL, salt VARCHAR(64) NOT NULL, " +
                "email VARCHAR(256), student_id VARCHAR(32), college VARCHAR(128) DEFAULT 'Computer Science', " +
                "national_id VARCHAR(64), national_id_confirmed BOOLEAN DEFAULT FALSE, " +
                "is_chancellor BOOLEAN DEFAULT FALSE, is_admin BOOLEAN DEFAULT FALSE, is_banned BOOLEAN DEFAULT FALSE, " +
                "file_storage_pref ENUM('DATABASE','FOLDER') DEFAULT 'DATABASE', " +
                "profile_picture VARCHAR(512), resume_path VARCHAR(512), " +
                "ip_address VARCHAR(45), last_ip VARCHAR(45), " +
                "chancellor_last_online TIMESTAMP NULL, " +
                "created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, last_login TIMESTAMP NULL, " +
                "INDEX idx_username (username), INDEX idx_student_id (student_id), INDEX idx_chancellor (is_chancellor)" +
                ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");

            st.executeUpdate("CREATE TABLE IF NOT EXISTS messages (" +
                "id BIGINT AUTO_INCREMENT PRIMARY KEY, sender_id INT NOT NULL, receiver_id INT NOT NULL, " +
                "content TEXT, sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, " +
                "INDEX idx_sender (sender_id), INDEX idx_receiver (receiver_id), INDEX idx_sent (sent_at)" +
                ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");

            st.executeUpdate("CREATE TABLE IF NOT EXISTS files (" +
                "id INT AUTO_INCREMENT PRIMARY KEY, owner_id INT NOT NULL, " +
                "filename VARCHAR(256) NOT NULL, file_size BIGINT DEFAULT 0, " +
                "is_audio BOOLEAN DEFAULT FALSE, storage_type ENUM('DATABASE','FOLDER') DEFAULT 'DATABASE', " +
                "file_data LONGTEXT, file_path VARCHAR(512), " +
                "uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, " +
                "INDEX idx_owner (owner_id), INDEX idx_audio (is_audio)" +
                ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");

            st.executeUpdate("CREATE TABLE IF NOT EXISTS file_shares (" +
                "id INT AUTO_INCREMENT PRIMARY KEY, file_id INT NOT NULL, " +
                "owner_id INT NOT NULL, shared_with_id INT NOT NULL, " +
                "shared_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, " +
                "INDEX idx_file (file_id), INDEX idx_shared_with (shared_with_id)" +
                ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");

            st.executeUpdate("CREATE TABLE IF NOT EXISTS chancellor_notes (" +
                "id INT AUTO_INCREMENT PRIMARY KEY, chancellor_id INT NOT NULL, " +
                "content TEXT NOT NULL, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, " +
                "INDEX idx_chancellor (chancellor_id)" +
                ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");

        } catch (Exception e) {
            CommonRails.printSystemComponent(this, this.hashCode(), ". UNCW DB: " + e.getMessage() + " .");
        }
    }

    private String getPassword() {
        try { return new String(java.nio.file.Files.readAllBytes(java.nio.file.Paths.get(".nwe-credentials")))
            .lines().filter(l -> l.startsWith("NWE_DB_PASS=")).map(l -> l.split("='")[1].replace("'", ""))
            .findFirst().orElse(""); } catch (Exception e) { return ""; }
    }
}
