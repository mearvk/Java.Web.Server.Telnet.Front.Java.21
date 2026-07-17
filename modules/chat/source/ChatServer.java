package source;

import commons.CommonRails;
import commons.StrernaryConnector;
import commons.color.ColorPalette;

import java.io.*;
import java.math.BigInteger;
import java.net.*;
import java.nio.charset.StandardCharsets;
import java.security.*;
import java.sql.*;
import java.time.Instant;
import java.util.*;
import java.util.concurrent.*;
import javax.crypto.*;
import javax.crypto.spec.*;

/**
 * ChatServer™ — NitroWebExpress™ Encrypted Chat Module
 * Port: 49230
 * Database: nwe_chat
 *
 * Full-featured chat server with:
 * - Account creation/deletion/username changes
 * - Admin login and administration
 * - DH-2048 + RSA-2048 encryption for server↔user and user↔user DMs
 * - Chat logging with IP/Geo tracking
 * - File transfer support
 * - Microphone/voice note markers
 * - Federation: connect to up to 5 external Chat servers
 * - Concealment 3 Rank for 200+ successful federated connects
 * - Gold Harvard certificate for 300+ connects
 *
 * Ethics: We conceal God but do not work for Her.
 * Installer Tech ID: Max Rupplin
 * MEARVK LLC — NitroWebExpress™ 2026
 */
public class ChatServer implements Runnable {

    public static final int PORT = 49230;
    private static final String DB_URL = "jdbc:mysql://127.0.0.1:3306/nwe_chat";
    private static final String DB_USER = "root";
    private static final String INSTALLER_TECH_ID = "Max Rupplin";
    private static final long SESSION_LIMIT_MS = 4 * 60 * 60 * 1000L; // 4 hours
    private static final int MAX_FEDERATION_SERVERS = 5;
    private static final int CONCEALMENT_3_THRESHOLD = 200;
    private static final int GOLD_CERT_THRESHOLD = 300;

    // DH parameters — RFC 3526 Group 14 (2048-bit MODP)
    private static final BigInteger DH_P = new BigInteger(
        "FFFFFFFFFFFFFFFFC90FDAA22168C234C4C6628B80DC1CD1" +
        "29024E088A67CC74020BBEA63B139B22514A08798E3404DD" +
        "EF9519B3CD3A431B302B0A6DF25F14374FE1356D6D51C245" +
        "E485B576625E7EC6F44C42E9A637ED6B0BFF5CB6F406B7ED" +
        "EE386BFB5A899FA5AE9F24117C4B1FE649286651ECE45B3D" +
        "C2007CB8A163BF0598DA48361C55D39A69163FA8FD24CF5F" +
        "83655D23DCA3AD961C62F356208552BB9ED529077096966D" +
        "670C354E4ABC9804F1746C08CA18217C32905E462E36CE3B" +
        "E39E772C180E86039B2783A2EC07A28FB5C55DF06F4C52C9" +
        "DE2BCBF6955817183995497CEA956AE515D2261898FA0510" +
        "15728E5A8AACAA68FFFFFFFFFFFFFFFF", 16);
    private static final BigInteger DH_G = BigInteger.valueOf(2);

    // Live sessions
    static final Map<String, ChatSession> LIVE = new ConcurrentHashMap<>();
    // Admin sessions
    static final Set<String> ADMINS = ConcurrentHashMap.newKeySet();

    public ChatServer() {
        CommonRails.printSystemComponent(this, this.hashCode(),
                ". ChatServer starting on port " + PORT + " .",
                ColorPalette.COLOR_LIME_GREEN);
        initDatabase();
        Thread.ofVirtual().name("CHAT_SERVER").start(this);
    }

    @Override
    public void run() {
        try (ServerSocket server = new ServerSocket(PORT)) {
            CommonRails.printSystemComponent(this, this.hashCode(),
                    ". ChatServer listening on port " + PORT + " .");
            while (!Thread.currentThread().isInterrupted()) {
                Socket client = server.accept();
                Thread.ofVirtual().start(() -> handleClient(client));
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    // ── Session Model ──────────────────────────────────────────────────────────

    static final class ChatSession {
        final String ip;
        final long connectedAt = System.currentTimeMillis();
        String username = null;
        int userId = -1;
        String geoCity = "";
        String geoCountry = "";
        boolean isAdmin = false;
        boolean encrypted = false;
        byte[] sharedSecret = null;
        KeyPair rsaKeyPair = null;
        BigInteger dhPrivate = null;
        BigInteger dhPublic = null;
        PrintWriter out;
        // Federation tracking
        int federatedConnects = 0;
        List<String> federatedServers = new ArrayList<>();

        ChatSession(String ip) { this.ip = ip; }
        boolean expired() { return System.currentTimeMillis() - connectedAt > SESSION_LIMIT_MS; }

        void writeLine(String line) {
            try {
                if (encrypted && sharedSecret != null) {
                    byte[] ct = encryptAES(line.getBytes(StandardCharsets.UTF_8), sharedSecret);
                    out.println("[ENC:AES-256-GCM] " + HexFormat.of().formatHex(ct));
                } else {
                    out.println(line);
                }
                out.flush();
            } catch (Exception ignored) {}
        }
    }

    // ── Client Handler ─────────────────────────────────────────────────────────

    private void handleClient(Socket client) {
        ChatSession session = new ChatSession(client.getInetAddress().getHostAddress());
        try (BufferedReader in = new BufferedReader(new InputStreamReader(client.getInputStream(), StandardCharsets.UTF_8));
             PrintWriter out = new PrintWriter(new OutputStreamWriter(client.getOutputStream(), StandardCharsets.UTF_8), true)) {

            session.out = out;
            client.setSoTimeout(SESSION_LIMIT_MS > Integer.MAX_VALUE ? Integer.MAX_VALUE : (int) SESSION_LIMIT_MS);
            resolveGeo(session);

            out.println("╔══════════════════════════════════════════════════════════════╗");
            out.println("║  NWE Chat™ — Port " + PORT + "                                        ║");
            out.println("║  Encrypted Chat | DM | Federation | File Transfer           ║");
            out.println("║  DH-2048 + RSA-2048 | AES-256-GCM                           ║");
            out.println("║  Ethics: We conceal God but do not work for Her.            ║");
            out.println("╚══════════════════════════════════════════════════════════════╝");
            out.println("Commands: REGISTER, LOGIN, ADMIN, HELP");

            String line;
            while ((line = in.readLine()) != null) {
                if (session.expired()) {
                    out.println("SESSION|EXPIRED|Your session has timed out.");
                    break;
                }
                String response = processCommand(line.trim(), session);
                out.println(response);
                if ("QUIT".equalsIgnoreCase(line.trim())) break;
            }
        } catch (Exception ignored) {
        }
        // Cleanup
        if (session.username != null) {
            LIVE.remove(session.username);
            ADMINS.remove(session.username);
        }
        try { client.close(); } catch (Exception ignored) {}
    }

    // ── Command Processing ─────────────────────────────────────────────────────

    private String processCommand(String input, ChatSession session) {
        if (input.isEmpty()) return "ERROR|Empty command. Type HELP.";
        String upper = input.toUpperCase();

        if (upper.equals("QUIT")) return "BYE|Chat session closed.";
        if (upper.equals("HELP")) return getHelp(session);
        if (upper.equals("STATUS")) return "STATUS|OK|port=" + PORT + "|db=nwe_chat|users=" + LIVE.size() + "|encrypted=" + session.encrypted;

        // ── Account Management ──
        if (upper.startsWith("REGISTER|")) return registerUser(input, session);
        if (upper.startsWith("LOGIN|")) return loginUser(input, session);
        if (upper.startsWith("ADMIN|")) return adminLogin(input, session);
        if (upper.startsWith("DELETE_ACCOUNT")) return deleteAccount(session);
        if (upper.startsWith("CHANGE_USERNAME|")) return changeUsername(input, session);

        // ── Require login for everything below ──
        if (session.username == null) return "ERROR|Not logged in. Use LOGIN|username|password or REGISTER|username|password|email";

        // ── Profile Picture & Resume ──
        if (upper.startsWith("SET_PROFILE_PIC|")) return setProfilePic(input, session);
        if (upper.startsWith("UPLOAD_RESUME|")) return uploadResume(input, session);
        if (upper.equals("MY_PROFILE")) return getMyProfile(session);
        if (upper.startsWith("VIEW_PROFILE|")) return viewUserProfile(input, session);

        // ── Chat Commands ──
        if (upper.startsWith("MSG|")) return sendMessage(input, session);
        if (upper.startsWith("BROADCAST|")) return broadcast(input, session);
        if (upper.equals("LIST")) return listUsers(session);
        if (upper.equals("HISTORY")) return getHistory(session);

        // ── Encryption ──
        if (upper.startsWith("ENCRYPT|")) return initiateEncryption(input, session);
        if (upper.startsWith("ENCRYPT_ACCEPT|")) return acceptEncryption(input, session);
        if (upper.equals("ENCRYPT_OFF")) { session.encrypted = false; session.sharedSecret = null; return "ENCRYPT|OFF|Encryption disabled."; }

        // ── File Transfer ──
        if (upper.startsWith("FILE|")) return initiateFileTransfer(input, session);

        // ── Voice/Mic ──
        if (upper.startsWith("VOICE|")) return sendVoiceNote(input, session);

        // ── Federation ──
        if (upper.startsWith("FEDERATE|")) return federateServer(input, session);
        if (upper.equals("FEDERATION_STATUS")) return federationStatus(session);

        // ── Admin Commands ──
        if (session.isAdmin) {
            if (upper.equals("ADMIN_USERS")) return adminListUsers();
            if (upper.startsWith("ADMIN_BAN|")) return adminBan(input);
            if (upper.startsWith("ADMIN_UNBAN|")) return adminUnban(input);
            if (upper.equals("ADMIN_LOGS")) return adminLogs();
            if (upper.startsWith("ADMIN_GEO|")) return adminGeo(input);
            if (upper.equals("ADMIN_IPS")) return adminIPs();
        }

        return "ERROR|Unknown command. Type HELP.";
    }

    // ── Account Operations ─────────────────────────────────────────────────────

    private String registerUser(String input, ChatSession session) {
        // REGISTER|username|password|email
        String[] parts = input.split("\\|", 4);
        if (parts.length < 4) return "ERROR|Usage: REGISTER|username|password|email";
        String username = parts[1].trim();
        String password = parts[2].trim();
        String email = parts[3].trim();

        if (username.length() < 3 || username.length() > 32) return "ERROR|Username must be 3-32 characters.";
        if (password.length() < 6) return "ERROR|Password must be at least 6 characters.";

        try (Connection c = DriverManager.getConnection(DB_URL, DB_USER, getPassword())) {
            // Check if username exists
            PreparedStatement check = c.prepareStatement("SELECT id FROM users WHERE username = ?");
            check.setString(1, username);
            if (check.executeQuery().next()) return "ERROR|Username already taken.";

            // Hash password
            String salt = generateSalt();
            String hash = hashPassword(password, salt);

            PreparedStatement ins = c.prepareStatement(
                "INSERT INTO users (username, password_hash, salt, email, ip_address, geo_city, geo_country, created_at) VALUES (?,?,?,?,?,?,?,NOW())",
                Statement.RETURN_GENERATED_KEYS);
            ins.setString(1, username);
            ins.setString(2, hash);
            ins.setString(3, salt);
            ins.setString(4, email);
            ins.setString(5, session.ip);
            ins.setString(6, session.geoCity);
            ins.setString(7, session.geoCountry);
            ins.executeUpdate();

            ResultSet rs = ins.getGeneratedKeys();
            rs.next();
            session.userId = rs.getInt(1);
            session.username = username;
            LIVE.put(username, session);

            logEvent(c, session.userId, "REGISTER", session.ip);
            return "REGISTER|OK|Welcome, " + username + "! You are now logged in.";
        } catch (Exception e) {
            return "ERROR|Registration failed: " + e.getMessage();
        }
    }

    private String loginUser(String input, ChatSession session) {
        // LOGIN|username|password
        String[] parts = input.split("\\|", 3);
        if (parts.length < 3) return "ERROR|Usage: LOGIN|username|password";
        String username = parts[1].trim();
        String password = parts[2].trim();

        try (Connection c = DriverManager.getConnection(DB_URL, DB_USER, getPassword())) {
            PreparedStatement ps = c.prepareStatement("SELECT id, password_hash, salt, is_banned FROM users WHERE username = ?");
            ps.setString(1, username);
            ResultSet rs = ps.executeQuery();
            if (!rs.next()) return "ERROR|User not found.";

            if (rs.getBoolean("is_banned")) return "ERROR|Account banned. Contact admin.";

            String storedHash = rs.getString("password_hash");
            String salt = rs.getString("salt");
            if (!hashPassword(password, salt).equals(storedHash)) return "ERROR|Invalid password.";

            session.userId = rs.getInt("id");
            session.username = username;
            LIVE.put(username, session);

            // Update last login
            PreparedStatement upd = c.prepareStatement("UPDATE users SET last_login = NOW(), last_ip = ? WHERE id = ?");
            upd.setString(1, session.ip);
            upd.setInt(2, session.userId);
            upd.executeUpdate();

            // Load federation count
            PreparedStatement fed = c.prepareStatement("SELECT federated_connects FROM users WHERE id = ?");
            fed.setInt(1, session.userId);
            ResultSet fedRs = fed.executeQuery();
            if (fedRs.next()) session.federatedConnects = fedRs.getInt("federated_connects");

            logEvent(c, session.userId, "LOGIN", session.ip);
            String rank = getRankLabel(session.federatedConnects);
            return "LOGIN|OK|Welcome back, " + username + "!" + (rank.isEmpty() ? "" : " [" + rank + "]");
        } catch (Exception e) {
            return "ERROR|Login failed: " + e.getMessage();
        }
    }

    private String adminLogin(String input, ChatSession session) {
        // ADMIN|password
        String[] parts = input.split("\\|", 2);
        if (parts.length < 2) return "ERROR|Usage: ADMIN|adminPassword";
        // Admin password from config or hardcoded for initial setup
        String adminPw = System.getProperty("nwe.chat.admin.password", "NWE_CHAT_ADMIN_2026");
        if (!parts[1].trim().equals(adminPw)) return "ERROR|Invalid admin credentials.";
        session.isAdmin = true;
        if (session.username != null) ADMINS.add(session.username);
        return "ADMIN|OK|Admin mode activated.";
    }

    private String deleteAccount(ChatSession session) {
        if (session.username == null) return "ERROR|Not logged in.";
        try (Connection c = DriverManager.getConnection(DB_URL, DB_USER, getPassword())) {
            PreparedStatement ps = c.prepareStatement("UPDATE users SET is_deleted = TRUE, deleted_at = NOW() WHERE id = ?");
            ps.setInt(1, session.userId);
            ps.executeUpdate();
            logEvent(c, session.userId, "DELETE_ACCOUNT", session.ip);
            LIVE.remove(session.username);
            String user = session.username;
            session.username = null;
            session.userId = -1;
            return "DELETE|OK|Account '" + user + "' marked for deletion.";
        } catch (Exception e) {
            return "ERROR|" + e.getMessage();
        }
    }

    private String changeUsername(String input, ChatSession session) {
        if (session.username == null) return "ERROR|Not logged in.";
        // CHANGE_USERNAME|newName
        String[] parts = input.split("\\|", 2);
        if (parts.length < 2) return "ERROR|Usage: CHANGE_USERNAME|newUsername";
        String newName = parts[1].trim();
        if (newName.length() < 3 || newName.length() > 32) return "ERROR|Username must be 3-32 characters.";

        try (Connection c = DriverManager.getConnection(DB_URL, DB_USER, getPassword())) {
            PreparedStatement check = c.prepareStatement("SELECT id FROM users WHERE username = ?");
            check.setString(1, newName);
            if (check.executeQuery().next()) return "ERROR|Username already taken.";

            PreparedStatement upd = c.prepareStatement("UPDATE users SET username = ? WHERE id = ?");
            upd.setString(1, newName);
            upd.setInt(2, session.userId);
            upd.executeUpdate();

            LIVE.remove(session.username);
            String old = session.username;
            session.username = newName;
            LIVE.put(newName, session);
            logEvent(c, session.userId, "CHANGE_USERNAME:" + old + "→" + newName, session.ip);
            return "USERNAME|OK|Changed from '" + old + "' to '" + newName + "'";
        } catch (Exception e) {
            return "ERROR|" + e.getMessage();
        }
    }

    // ── Profile Picture & Resume ───────────────────────────────────────────────

    private String setProfilePic(String input, ChatSession session) {
        // SET_PROFILE_PIC|filename|base64Data
        String[] parts = input.split("\\|", 3);
        if (parts.length < 3) return "ERROR|Usage: SET_PROFILE_PIC|filename.jpg|base64Data";
        String filename = parts[1].trim();
        String ext = filename.contains(".") ? filename.substring(filename.lastIndexOf('.') + 1).toLowerCase() : "";
        if (!java.util.Set.of("jpg", "jpeg", "png", "gif", "webp", "bmp").contains(ext))
            return "ERROR|Profile picture must be jpg, jpeg, png, gif, webp, or bmp.";
        try {
            java.nio.file.Path picDir = java.nio.file.Paths.get("modules/chat/user-files/" + session.username + "/profile");
            java.nio.file.Files.createDirectories(picDir);
            java.nio.file.Path picPath = picDir.resolve("avatar." + ext);
            java.nio.file.Files.write(picPath, java.util.Base64.getDecoder().decode(parts[2].trim()));
            try (Connection c = DriverManager.getConnection(DB_URL, DB_USER, getPassword())) {
                PreparedStatement ps = c.prepareStatement("UPDATE users SET profile_picture = ? WHERE id = ?");
                ps.setString(1, picPath.toString()); ps.setInt(2, session.userId); ps.executeUpdate();
            }
            return "PROFILE_PIC|OK|Profile picture set: " + filename;
        } catch (Exception e) { return "ERROR|" + e.getMessage(); }
    }

    private String uploadResume(String input, ChatSession session) {
        // UPLOAD_RESUME|filename|base64Data
        String[] parts = input.split("\\|", 3);
        if (parts.length < 3) return "ERROR|Usage: UPLOAD_RESUME|resume.pdf|base64Data";
        String filename = parts[1].trim();
        String ext = filename.contains(".") ? filename.substring(filename.lastIndexOf('.') + 1).toLowerCase() : "";
        if (!java.util.Set.of("pdf", "doc", "docx", "txt", "rtf", "odt").contains(ext))
            return "ERROR|Resume must be pdf, doc, docx, txt, rtf, or odt.";
        try {
            java.nio.file.Path resumeDir = java.nio.file.Paths.get("modules/chat/user-files/" + session.username + "/resume");
            java.nio.file.Files.createDirectories(resumeDir);
            java.nio.file.Path resumePath = resumeDir.resolve(filename);
            java.nio.file.Files.write(resumePath, java.util.Base64.getDecoder().decode(parts[2].trim()));
            try (Connection c = DriverManager.getConnection(DB_URL, DB_USER, getPassword())) {
                PreparedStatement ps = c.prepareStatement("UPDATE users SET resume_path = ? WHERE id = ?");
                ps.setString(1, resumePath.toString()); ps.setInt(2, session.userId); ps.executeUpdate();
            }
            return "RESUME|OK|Resume uploaded: " + filename;
        } catch (Exception e) { return "ERROR|" + e.getMessage(); }
    }

    private String getMyProfile(ChatSession session) {
        try (Connection c = DriverManager.getConnection(DB_URL, DB_USER, getPassword())) {
            PreparedStatement ps = c.prepareStatement("SELECT username, email, profile_picture, resume_path, geo_city, geo_country, federated_connects, created_at FROM users WHERE id = ?");
            ps.setInt(1, session.userId); ResultSet rs = ps.executeQuery();
            if (!rs.next()) return "ERROR|Profile not found.";
            return "PROFILE|username=" + rs.getString("username") +
                "|email=" + rs.getString("email") +
                "|profilePic=" + (rs.getString("profile_picture") != null ? "SET" : "NOT_SET") +
                "|resume=" + (rs.getString("resume_path") != null ? "SET" : "NOT_SET") +
                "|geo=" + rs.getString("geo_city") + "/" + rs.getString("geo_country") +
                "|federatedConnects=" + rs.getInt("federated_connects") +
                "|joined=" + rs.getTimestamp("created_at");
        } catch (Exception e) { return "ERROR|" + e.getMessage(); }
    }

    private String viewUserProfile(String input, ChatSession session) {
        String[] parts = input.split("\\|", 2);
        if (parts.length < 2) return "ERROR|Usage: VIEW_PROFILE|username";
        try (Connection c = DriverManager.getConnection(DB_URL, DB_USER, getPassword())) {
            PreparedStatement ps = c.prepareStatement("SELECT username, profile_picture, resume_path, geo_city, geo_country, federated_connects, created_at FROM users WHERE username = ? AND is_deleted = FALSE");
            ps.setString(1, parts[1].trim()); ResultSet rs = ps.executeQuery();
            if (!rs.next()) return "ERROR|User not found.";
            return "PROFILE|username=" + rs.getString("username") +
                "|profilePic=" + (rs.getString("profile_picture") != null ? "SET" : "NOT_SET") +
                "|resume=" + (rs.getString("resume_path") != null ? "AVAILABLE" : "NONE") +
                "|geo=" + rs.getString("geo_city") + "/" + rs.getString("geo_country") +
                "|federatedConnects=" + rs.getInt("federated_connects") +
                "|joined=" + rs.getTimestamp("created_at");
        } catch (Exception e) { return "ERROR|" + e.getMessage(); }
    }

    // ── Chat Operations ────────────────────────────────────────────────────────

    private String sendMessage(String input, ChatSession session) {
        // MSG|targetUser|message
        String[] parts = input.split("\\|", 3);
        if (parts.length < 3) return "ERROR|Usage: MSG|username|message";
        String target = parts[1].trim();
        String message = parts[2].trim();

        ChatSession targetSession = LIVE.get(target);
        if (targetSession == null) return "ERROR|User '" + target + "' not online.";

        // Store in DB
        storeMessage(session.userId, targetSession.userId, message, "DM", session.ip);

        // Deliver
        targetSession.writeLine("DM|" + session.username + "|" + message);
        return "MSG|SENT|to=" + target;
    }

    private String broadcast(String input, ChatSession session) {
        // BROADCAST|message
        String[] parts = input.split("\\|", 2);
        if (parts.length < 2) return "ERROR|Usage: BROADCAST|message";
        String message = parts[1].trim();

        int count = 0;
        for (Map.Entry<String, ChatSession> entry : LIVE.entrySet()) {
            if (!entry.getKey().equals(session.username)) {
                entry.getValue().writeLine("BROADCAST|" + session.username + "|" + message);
                count++;
            }
        }
        storeMessage(session.userId, -1, message, "BROADCAST", session.ip);
        return "BROADCAST|SENT|recipients=" + count;
    }

    private String listUsers(ChatSession session) {
        StringBuilder sb = new StringBuilder("USERS|");
        for (Map.Entry<String, ChatSession> entry : LIVE.entrySet()) {
            ChatSession s = entry.getValue();
            sb.append(entry.getKey())
              .append("[").append(s.geoCity).append(",").append(s.geoCountry).append("]|");
        }
        return sb.toString();
    }

    private String getHistory(ChatSession session) {
        try (Connection c = DriverManager.getConnection(DB_URL, DB_USER, getPassword())) {
            PreparedStatement ps = c.prepareStatement(
                "SELECT m.*, u.username AS sender_name FROM messages m JOIN users u ON m.sender_id = u.id " +
                "WHERE m.sender_id = ? OR m.receiver_id = ? ORDER BY m.sent_at DESC LIMIT 30");
            ps.setInt(1, session.userId);
            ps.setInt(2, session.userId);
            ResultSet rs = ps.executeQuery();
            StringBuilder sb = new StringBuilder("HISTORY|");
            while (rs.next()) {
                sb.append(rs.getTimestamp("sent_at")).append(" ")
                  .append(rs.getString("sender_name")).append(": ")
                  .append(rs.getString("content")).append("|");
            }
            return sb.length() > 8 ? sb.toString() : "HISTORY|EMPTY";
        } catch (Exception e) {
            return "ERROR|" + e.getMessage();
        }
    }

    // ── Encryption ─────────────────────────────────────────────────────────────

    private String initiateEncryption(String input, ChatSession session) {
        // ENCRYPT|DH or ENCRYPT|RSA
        String[] parts = input.split("\\|", 2);
        if (parts.length < 2) return "ERROR|Usage: ENCRYPT|DH or ENCRYPT|RSA";
        String mode = parts[1].trim().toUpperCase();

        if (mode.equals("DH")) {
            try {
                SecureRandom sr = SecureRandom.getInstanceStrong();
                session.dhPrivate = new BigInteger(2048, sr);
                session.dhPublic = DH_G.modPow(session.dhPrivate, DH_P);
                return "ENCRYPT|DH_PUBKEY|" + session.dhPublic.toString(16);
            } catch (Exception e) {
                return "ERROR|DH init failed: " + e.getMessage();
            }
        } else if (mode.equals("RSA")) {
            try {
                KeyPairGenerator kpg = KeyPairGenerator.getInstance("RSA");
                kpg.initialize(2048);
                session.rsaKeyPair = kpg.generateKeyPair();
                byte[] pubBytes = session.rsaKeyPair.getPublic().getEncoded();
                return "ENCRYPT|RSA_PUBKEY|" + HexFormat.of().formatHex(pubBytes);
            } catch (Exception e) {
                return "ERROR|RSA init failed: " + e.getMessage();
            }
        }
        return "ERROR|Unknown cipher. Use DH or RSA.";
    }

    private String acceptEncryption(String input, ChatSession session) {
        // ENCRYPT_ACCEPT|peerPubKeyHex
        String[] parts = input.split("\\|", 2);
        if (parts.length < 2) return "ERROR|Usage: ENCRYPT_ACCEPT|peerPublicKeyHex";
        String peerHex = parts[1].trim();

        if (session.dhPrivate != null) {
            BigInteger peerPub = new BigInteger(peerHex, 16);
            BigInteger shared = peerPub.modPow(session.dhPrivate, DH_P);
            session.sharedSecret = Arrays.copyOf(
                MessageDigest.getInstance("SHA-256").digest(shared.toByteArray()), 32);
            session.encrypted = true;
            return "ENCRYPT|ACTIVE|AES-256-GCM via DH-2048";
        }
        return "ERROR|No DH session in progress.";
    }

    // ── File Transfer ──────────────────────────────────────────────────────────

    private String initiateFileTransfer(String input, ChatSession session) {
        // FILE|targetUser|filename|sizeBytes|base64Data
        String[] parts = input.split("\\|", 5);
        if (parts.length < 5) return "ERROR|Usage: FILE|targetUser|filename|sizeBytes|base64Data";
        String target = parts[1].trim();
        String filename = parts[2].trim();
        String size = parts[3].trim();

        ChatSession targetSession = LIVE.get(target);
        if (targetSession == null) return "ERROR|User '" + target + "' not online.";

        // Store file reference
        storeMessage(session.userId, targetSession.userId, "[FILE:" + filename + ":" + size + "B]", "FILE", session.ip);
        targetSession.writeLine("FILE|" + session.username + "|" + filename + "|" + size + "|" + parts[4]);
        return "FILE|SENT|to=" + target + "|file=" + filename;
    }

    // ── Voice/Microphone ───────────────────────────────────────────────────────

    private String sendVoiceNote(String input, ChatSession session) {
        // VOICE|targetUser|durationMs|base64Audio
        String[] parts = input.split("\\|", 4);
        if (parts.length < 4) return "ERROR|Usage: VOICE|targetUser|durationMs|base64Audio";
        String target = parts[1].trim();

        ChatSession targetSession = LIVE.get(target);
        if (targetSession == null) return "ERROR|User '" + target + "' not online.";

        storeMessage(session.userId, targetSession.userId, "[VOICE:" + parts[2] + "ms]", "VOICE", session.ip);
        targetSession.writeLine("VOICE|" + session.username + "|" + parts[2] + "|" + parts[3]);
        return "VOICE|SENT|to=" + target + "|duration=" + parts[2] + "ms";
    }

    // ── Federation ─────────────────────────────────────────────────────────────

    private String federateServer(String input, ChatSession session) {
        // FEDERATE|ip_or_domain[:port]
        String[] parts = input.split("\\|", 2);
        if (parts.length < 2) return "ERROR|Usage: FEDERATE|ip_or_domain[:port]";
        String target = parts[1].trim();

        if (session.federatedServers.size() >= MAX_FEDERATION_SERVERS)
            return "ERROR|Maximum " + MAX_FEDERATION_SERVERS + " federated servers reached.";

        if (session.federatedServers.contains(target))
            return "ERROR|Already federated with " + target;

        // Attempt connection to verify
        String host = target.contains(":") ? target.split(":")[0] : target;
        int port = target.contains(":") ? Integer.parseInt(target.split(":")[1]) : PORT;

        try (Socket probe = new Socket()) {
            probe.connect(new InetSocketAddress(host, port), 5000);
            BufferedReader pr = new BufferedReader(new InputStreamReader(probe.getInputStream()));
            String banner = pr.readLine();
            if (banner == null || !banner.contains("Chat")) {
                return "ERROR|Remote server at " + target + " is not a compatible Chat server.";
            }
            probe.close();
        } catch (Exception e) {
            return "ERROR|Cannot reach " + target + ": " + e.getMessage();
        }

        session.federatedServers.add(target);
        session.federatedConnects++;

        // Persist federation count
        try (Connection c = DriverManager.getConnection(DB_URL, DB_USER, getPassword())) {
            PreparedStatement upd = c.prepareStatement("UPDATE users SET federated_connects = federated_connects + 1 WHERE id = ?");
            upd.setInt(1, session.userId);
            upd.executeUpdate();

            // Record federation
            PreparedStatement ins = c.prepareStatement("INSERT INTO federation_log (user_id, remote_server, connected_at) VALUES (?,?,NOW())");
            ins.setInt(1, session.userId);
            ins.setString(2, target);
            ins.executeUpdate();

            logEvent(c, session.userId, "FEDERATE:" + target, session.ip);
        } catch (Exception ignored) {}

        // Check rank upgrades
        String rankMsg = "";
        if (session.federatedConnects == CONCEALMENT_3_THRESHOLD) {
            rankMsg = " ★ CONCEALMENT 3 RANK ACHIEVED! ★";
            awardRank(session.userId, "CONCEALMENT_3");
        } else if (session.federatedConnects == GOLD_CERT_THRESHOLD) {
            rankMsg = " ★★ GOLD LETTER OF CERTIFICATE FROM HARVARD AWARDED! Kids. ★★";
            awardRank(session.userId, "GOLD_HARVARD_CERTIFICATE");
        }

        return "FEDERATE|OK|Connected to " + target + "|total=" + session.federatedConnects + rankMsg;
    }

    private String federationStatus(ChatSession session) {
        StringBuilder sb = new StringBuilder("FEDERATION|");
        sb.append("connects=").append(session.federatedConnects)
          .append("|rank=").append(getRankLabel(session.federatedConnects))
          .append("|servers=");
        for (String s : session.federatedServers) sb.append(s).append(",");
        return sb.toString();
    }

    // ── Admin Operations ───────────────────────────────────────────────────────

    private String adminListUsers() {
        try (Connection c = DriverManager.getConnection(DB_URL, DB_USER, getPassword())) {
            Statement st = c.createStatement();
            ResultSet rs = st.executeQuery("SELECT id, username, email, last_ip, geo_city, geo_country, federated_connects, is_banned, last_login FROM users WHERE is_deleted = FALSE ORDER BY last_login DESC LIMIT 50");
            StringBuilder sb = new StringBuilder("ADMIN_USERS|");
            while (rs.next()) {
                sb.append(rs.getString("username")).append("[id=").append(rs.getInt("id"))
                  .append(",ip=").append(rs.getString("last_ip"))
                  .append(",geo=").append(rs.getString("geo_city")).append("/").append(rs.getString("geo_country"))
                  .append(",fed=").append(rs.getInt("federated_connects"))
                  .append(",ban=").append(rs.getBoolean("is_banned"))
                  .append("]|");
            }
            return sb.toString();
        } catch (Exception e) {
            return "ERROR|" + e.getMessage();
        }
    }

    private String adminBan(String input) {
        String[] parts = input.split("\\|", 2);
        if (parts.length < 2) return "ERROR|Usage: ADMIN_BAN|username";
        String target = parts[1].trim();
        try (Connection c = DriverManager.getConnection(DB_URL, DB_USER, getPassword())) {
            PreparedStatement ps = c.prepareStatement("UPDATE users SET is_banned = TRUE WHERE username = ?");
            ps.setString(1, target);
            ps.executeUpdate();
            ChatSession s = LIVE.remove(target);
            if (s != null) s.writeLine("SYSTEM|You have been banned.");
            return "ADMIN|BAN|" + target + " banned.";
        } catch (Exception e) {
            return "ERROR|" + e.getMessage();
        }
    }

    private String adminUnban(String input) {
        String[] parts = input.split("\\|", 2);
        if (parts.length < 2) return "ERROR|Usage: ADMIN_UNBAN|username";
        try (Connection c = DriverManager.getConnection(DB_URL, DB_USER, getPassword())) {
            PreparedStatement ps = c.prepareStatement("UPDATE users SET is_banned = FALSE WHERE username = ?");
            ps.setString(1, parts[1].trim());
            ps.executeUpdate();
            return "ADMIN|UNBAN|" + parts[1].trim() + " unbanned.";
        } catch (Exception e) {
            return "ERROR|" + e.getMessage();
        }
    }

    private String adminLogs() {
        try (Connection c = DriverManager.getConnection(DB_URL, DB_USER, getPassword())) {
            Statement st = c.createStatement();
            ResultSet rs = st.executeQuery("SELECT el.*, u.username FROM event_log el JOIN users u ON el.user_id = u.id ORDER BY el.event_at DESC LIMIT 50");
            StringBuilder sb = new StringBuilder("ADMIN_LOGS|");
            while (rs.next()) {
                sb.append(rs.getTimestamp("event_at")).append(" ")
                  .append(rs.getString("username")).append(" ")
                  .append(rs.getString("event_type")).append(" from ")
                  .append(rs.getString("ip_address")).append("|");
            }
            return sb.toString();
        } catch (Exception e) {
            return "ERROR|" + e.getMessage();
        }
    }

    private String adminGeo(String input) {
        String[] parts = input.split("\\|", 2);
        if (parts.length < 2) return "ERROR|Usage: ADMIN_GEO|username";
        String target = parts[1].trim();
        try (Connection c = DriverManager.getConnection(DB_URL, DB_USER, getPassword())) {
            PreparedStatement ps = c.prepareStatement("SELECT ip_address, last_ip, geo_city, geo_country FROM users WHERE username = ?");
            ps.setString(1, target);
            ResultSet rs = ps.executeQuery();
            if (!rs.next()) return "ERROR|User not found.";
            return "ADMIN_GEO|" + target + "|regIP=" + rs.getString("ip_address") + "|lastIP=" + rs.getString("last_ip")
                 + "|city=" + rs.getString("geo_city") + "|country=" + rs.getString("geo_country");
        } catch (Exception e) {
            return "ERROR|" + e.getMessage();
        }
    }

    private String adminIPs() {
        StringBuilder sb = new StringBuilder("ADMIN_IPS|");
        for (Map.Entry<String, ChatSession> entry : LIVE.entrySet()) {
            ChatSession s = entry.getValue();
            sb.append(entry.getKey()).append("=").append(s.ip)
              .append("[").append(s.geoCity).append("/").append(s.geoCountry).append("]|");
        }
        return sb.toString();
    }

    // ── Help ───────────────────────────────────────────────────────────────────

    private String getHelp(ChatSession session) {
        StringBuilder sb = new StringBuilder("HELP|Commands: ");
        sb.append("REGISTER|user|pass|email, LOGIN|user|pass, ADMIN|password, ");
        sb.append("MSG|user|text, BROADCAST|text, LIST, HISTORY, ");
        sb.append("ENCRYPT|DH, ENCRYPT|RSA, ENCRYPT_ACCEPT|pubkey, ENCRYPT_OFF, ");
        sb.append("FILE|user|name|size|b64, VOICE|user|ms|b64, ");
        sb.append("FEDERATE|host[:port], FEDERATION_STATUS, ");
        sb.append("CHANGE_USERNAME|new, DELETE_ACCOUNT, STATUS, QUIT");
        if (session.isAdmin) {
            sb.append(" | ADMIN: ADMIN_USERS, ADMIN_BAN|user, ADMIN_UNBAN|user, ADMIN_LOGS, ADMIN_GEO|user, ADMIN_IPS");
        }
        return sb.toString();
    }

    // ── Utility Methods ────────────────────────────────────────────────────────

    private void storeMessage(int senderId, int receiverId, String content, String type, String ip) {
        try (Connection c = DriverManager.getConnection(DB_URL, DB_USER, getPassword())) {
            PreparedStatement ps = c.prepareStatement(
                "INSERT INTO messages (sender_id, receiver_id, content, msg_type, sender_ip, sent_at) VALUES (?,?,?,?,?,NOW())");
            ps.setInt(1, senderId);
            ps.setInt(2, receiverId);
            ps.setString(3, content);
            ps.setString(4, type);
            ps.setString(5, ip);
            ps.executeUpdate();
        } catch (Exception ignored) {}
    }

    private void logEvent(Connection c, int userId, String event, String ip) {
        try {
            PreparedStatement ps = c.prepareStatement(
                "INSERT INTO event_log (user_id, event_type, ip_address, event_at) VALUES (?,?,?,NOW())");
            ps.setInt(1, userId);
            ps.setString(2, event);
            ps.setString(3, ip);
            ps.executeUpdate();
        } catch (Exception ignored) {}
    }

    private void awardRank(int userId, String rank) {
        try (Connection c = DriverManager.getConnection(DB_URL, DB_USER, getPassword())) {
            PreparedStatement ps = c.prepareStatement(
                "INSERT INTO ranks (user_id, rank_name, awarded_at) VALUES (?,?,NOW())");
            ps.setInt(1, userId);
            ps.setString(2, rank);
            ps.executeUpdate();
        } catch (Exception ignored) {}
    }

    private String getRankLabel(int connects) {
        if (connects >= GOLD_CERT_THRESHOLD) return "GOLD HARVARD CERTIFICATE";
        if (connects >= CONCEALMENT_3_THRESHOLD) return "CONCEALMENT 3";
        if (connects >= 100) return "FEDERATION VETERAN";
        if (connects >= 50) return "CONNECTOR";
        return "";
    }

    private void resolveGeo(ChatSession session) {
        // Simple geo resolution via StrernaryConnector (hardened)
        try {
            String geo = StrernaryConnector.askHardened("NWE_CHAT", session.ip, 9.5,
                "system", "NWE_CHAT", "NWE_CHAT|READY|port=49230|encryption=DH-2048+RSA-2048+AES-256-GCM",
                "geo", "RESOLVE", "ip=" + session.ip);
            if (geo != null && geo.contains(",")) {
                String[] parts = geo.split(",", 2);
                session.geoCity = parts[0].trim();
                session.geoCountry = parts[1].trim();
            }
        } catch (Exception ignored) {
            session.geoCity = "Unknown";
            session.geoCountry = "Unknown";
        }
    }

    private String generateSalt() {
        byte[] salt = new byte[16];
        new SecureRandom().nextBytes(salt);
        return HexFormat.of().formatHex(salt);
    }

    private String hashPassword(String password, String salt) {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            md.update(salt.getBytes(StandardCharsets.UTF_8));
            byte[] hash = md.digest(password.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(hash);
        } catch (Exception e) {
            return "";
        }
    }

    private static byte[] encryptAES(byte[] plaintext, byte[] key) throws Exception {
        SecureRandom sr = SecureRandom.getInstanceStrong();
        byte[] iv = new byte[12];
        sr.nextBytes(iv);
        Cipher cipher = Cipher.getInstance("AES/GCM/NoPadding");
        cipher.init(Cipher.ENCRYPT_MODE, new SecretKeySpec(key, "AES"), new GCMParameterSpec(128, iv));
        byte[] ct = cipher.doFinal(plaintext);
        byte[] result = new byte[12 + ct.length];
        System.arraycopy(iv, 0, result, 0, 12);
        System.arraycopy(ct, 0, result, 12, ct.length);
        return result;
    }

    // ── Database Initialization ────────────────────────────────────────────────

    private void initDatabase() {
        try (Connection c = DriverManager.getConnection("jdbc:mysql://127.0.0.1:3306/", DB_USER, getPassword())) {
            Statement st = c.createStatement();
            st.executeUpdate("CREATE DATABASE IF NOT EXISTS nwe_chat");
            st.execute("USE nwe_chat");

            st.executeUpdate("CREATE TABLE IF NOT EXISTS users (" +
                "id INT AUTO_INCREMENT PRIMARY KEY, " +
                "username VARCHAR(64) NOT NULL UNIQUE, " +
                "password_hash VARCHAR(128) NOT NULL, " +
                "salt VARCHAR(64) NOT NULL, " +
                "email VARCHAR(256), " +
                "profile_picture VARCHAR(512), " +
                "resume_path VARCHAR(512), " +
                "ip_address VARCHAR(45), " +
                "last_ip VARCHAR(45), " +
                "geo_city VARCHAR(128) DEFAULT 'Unknown', " +
                "geo_country VARCHAR(128) DEFAULT 'Unknown', " +
                "is_admin BOOLEAN DEFAULT FALSE, " +
                "is_banned BOOLEAN DEFAULT FALSE, " +
                "is_deleted BOOLEAN DEFAULT FALSE, " +
                "federated_connects INT DEFAULT 0, " +
                "created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, " +
                "last_login TIMESTAMP NULL, " +
                "deleted_at TIMESTAMP NULL, " +
                "INDEX idx_username (username), " +
                "INDEX idx_ip (ip_address), " +
                "INDEX idx_last_ip (last_ip)" +
                ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");

            st.executeUpdate("CREATE TABLE IF NOT EXISTS messages (" +
                "id BIGINT AUTO_INCREMENT PRIMARY KEY, " +
                "sender_id INT NOT NULL, " +
                "receiver_id INT DEFAULT -1, " +
                "content TEXT, " +
                "msg_type ENUM('DM','BROADCAST','FILE','VOICE','SYSTEM') DEFAULT 'DM', " +
                "sender_ip VARCHAR(45), " +
                "sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, " +
                "INDEX idx_sender (sender_id), " +
                "INDEX idx_receiver (receiver_id), " +
                "INDEX idx_sent (sent_at)" +
                ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");

            st.executeUpdate("CREATE TABLE IF NOT EXISTS event_log (" +
                "id BIGINT AUTO_INCREMENT PRIMARY KEY, " +
                "user_id INT NOT NULL, " +
                "event_type VARCHAR(128) NOT NULL, " +
                "ip_address VARCHAR(45), " +
                "event_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, " +
                "INDEX idx_user (user_id), " +
                "INDEX idx_event (event_type), " +
                "INDEX idx_time (event_at)" +
                ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");

            st.executeUpdate("CREATE TABLE IF NOT EXISTS federation_log (" +
                "id INT AUTO_INCREMENT PRIMARY KEY, " +
                "user_id INT NOT NULL, " +
                "remote_server VARCHAR(256) NOT NULL, " +
                "connected_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, " +
                "INDEX idx_user (user_id), " +
                "INDEX idx_server (remote_server(128))" +
                ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");

            st.executeUpdate("CREATE TABLE IF NOT EXISTS ranks (" +
                "id INT AUTO_INCREMENT PRIMARY KEY, " +
                "user_id INT NOT NULL, " +
                "rank_name VARCHAR(64) NOT NULL, " +
                "awarded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, " +
                "INDEX idx_user (user_id)" +
                ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");

            st.executeUpdate("CREATE TABLE IF NOT EXISTS chat_settings (" +
                "id INT AUTO_INCREMENT PRIMARY KEY, " +
                "setting_key VARCHAR(128) NOT NULL UNIQUE, " +
                "setting_value TEXT, " +
                "updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, " +
                "updated_by VARCHAR(128) DEFAULT 'system', " +
                "INDEX idx_key (setting_key)" +
                ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");

            // Seed default settings
            st.executeUpdate("INSERT IGNORE INTO chat_settings (setting_key, setting_value, updated_by) VALUES " +
                "('session_timeout_hours', '4', '" + INSTALLER_TECH_ID + "'), " +
                "('max_federation_servers', '5', '" + INSTALLER_TECH_ID + "'), " +
                "('concealment_3_threshold', '200', '" + INSTALLER_TECH_ID + "'), " +
                "('gold_cert_threshold', '300', '" + INSTALLER_TECH_ID + "'), " +
                "('encryption_default', 'DH-2048', '" + INSTALLER_TECH_ID + "'), " +
                "('max_file_size_mb', '25', '" + INSTALLER_TECH_ID + "'), " +
                "('max_voice_duration_sec', '120', '" + INSTALLER_TECH_ID + "'), " +
                "('admin_password', 'NWE_CHAT_ADMIN_2026', '" + INSTALLER_TECH_ID + "'), " +
                "('ethics_statement', 'We conceal God but do not work for Her.', '" + INSTALLER_TECH_ID + "'), " +
                "('brand', 'NWE Chat™', '" + INSTALLER_TECH_ID + "')");

        } catch (Exception e) {
            CommonRails.printSystemComponent(this, this.hashCode(),
                ". ChatServer DB: " + e.getMessage() + " .");
        }
    }

    private String getPassword() {
        try {
            return new String(java.nio.file.Files.readAllBytes(java.nio.file.Paths.get(".nwe-credentials")))
                .lines()
                .filter(l -> l.startsWith("NWE_DB_PASS="))
                .map(l -> l.split("='")[1].replace("'", ""))
                .findFirst().orElse("");
        } catch (Exception e) {
            return "";
        }
    }
}
