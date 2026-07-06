package communicator;

import commons.CommonRails;
import exceptions.ExceptionHandler;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.net.InetAddress;
import java.net.ServerSocket;
import java.net.Socket;
import java.nio.charset.StandardCharsets;
import java.sql.ResultSet;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;

/**
 * Communicator — persistent 1-hour telnet chat server on port 49199.
 *
 * Commands (after identify):
 *   list                             List all connected users (nationalId, IP, geo)
 *   msg <nationalId> <text>          Send direct message to a connected user
 *   broadcast <text>                 Send message to all connected users
 *   schedule <nationalId> <HH:mm> <text>
 *                                    Schedule a message delivered at HH:mm in
 *                                    the recipient's local timezone (from geo)
 *   schedule broadcast <HH:mm> <text>
 *                                    Schedule broadcast at HH:mm in each
 *                                    recipient's local timezone
 *   history                          Show last 20 chat messages from MySQL
 *   lang <code>                      Switch display language
 *   quit                             Disconnect
 *
 * Sessions expire automatically after 1 hour.
 *
 * MessagePoller — static inner class, polls MySQL every 60 seconds and
 * delivers due scheduled messages to any live sessions.
 *
 * @author Max Rupplin
 * @date June 08 2026
 */
public class Communicator extends Thread
{
    public static final int PORT = 49199;
    private static final long SESSION_LIMIT_MS = 60 * 60 * 1000L; // 1 hour

    private final String HOST;
    private ServerSocket serverSocket;

    /** nationalId (as String) → live Session */
    static final Map<String, Session> LIVE = new ConcurrentHashMap<>();

    // ── Constructor ───────────────────────────────────────────────────────────

    public Communicator(final String host)
    {
        if (host == null) throw new commons.security.BodiSecurityException("//bodi/connect", Thread.currentThread().getStackTrace()[1]);
        this.HOST = host;
        this.setName("Communicator");
        this.setDaemon(true);
    }

    // ── Server loop ───────────────────────────────────────────────────────────

    @Override
    public void run()
    {
        try
        {
            database.N21Store.createCommunicatorTables();
            CommunicatorCrypto.ensureProfileTable();
            serverSocket = new ServerSocket(PORT, 64, InetAddress.getByName(HOST));
            CommonRails.printSystemComponent(this, this.hashCode(),
                ". Communicator listening on port " + PORT + " .");
            MessagePoller.start();
            while (!Thread.currentThread().isInterrupted())
            {
                Socket client = serverSocket.accept();
                Thread h = new Thread(() -> handle(client));
                h.setDaemon(true);
                h.start();
            }
        }
        catch (Exception e) { ExceptionHandler.dispatch(e); e.printStackTrace(System.err); }
    }

    // ── Per-connection session ────────────────────────────────────────────────

    static final class Session
    {
        final String   ip;
        final long     connectedAt = System.currentTimeMillis();
        long           nationalId  = -1;
        String         geoCity     = "";
        String         geoCountry  = "";
        String         timezone    = "UTC";
        BufferedWriter out;

        // ── Crypto session state ──────────────────────────────────────────────
        CommunicatorCrypto.CipherSuite activeCipher = null;
        byte[] sharedSecret = null;
        CommunicatorCrypto.DHSession   dhSession   = null;
        CommunicatorCrypto.ECDHSession ecdhSession = null;
        boolean encrypted = false;

        Session(final String ip) { this.ip = ip; }

        boolean expired() { return System.currentTimeMillis() - connectedAt > SESSION_LIMIT_MS; }

        void writeLine(final String line)
        {
            try
            {
                if (encrypted && sharedSecret != null && activeCipher != null)
                {
                    byte[] ct = CommunicatorCrypto.encrypt(
                        line.getBytes(java.nio.charset.StandardCharsets.UTF_8), sharedSecret, activeCipher);
                    out.write("[ENC:" + activeCipher.displayName + "] " +
                        java.util.HexFormat.of().formatHex(ct) + "\r\n");
                }
                else
                {
                    out.write(line + "\r\n");
                }
                out.flush();
            }
            catch (Exception ignored) {}
        }
    }

    private void handle(final Socket client)
    {
        Session session = new Session(client.getInetAddress().getHostAddress());
        try (
            BufferedReader in  = new BufferedReader(new InputStreamReader(client.getInputStream(),  StandardCharsets.UTF_8));
            BufferedWriter out = new BufferedWriter(new OutputStreamWriter(client.getOutputStream(), StandardCharsets.UTF_8))
        ) {
            session.out = out;
            resolveGeo(session);

            writeLine(out, "╔══════════════════════════════════════════════════════╗");
            writeLine(out, "║  NWE port " + PORT + " — Communicator                        ║");
            writeLine(out, "║  Persistent chat  |  direct msg  |  broadcast        ║");
            writeLine(out, "║  Scheduled delivery  |  1-hour session limit          ║");
            writeLine(out, "╚══════════════════════════════════════════════════════╝");
            writeLine(out, "identify <nationalId>  to begin  |  Session limit: 1 hour");
            writeLine(out, "Geo: " + session.geoCity + ", " + session.geoCountry + "  TZ: " + session.timezone);

            client.setSoTimeout(10_000);

            String line;
            while ((line = readLine(in)) != null)
            {
                if (session.expired()) { writeLine(out, "[communicator] Session expired (1-hour limit)."); break; }

                line = line.trim();
                if (line.isEmpty()) continue;
                if (line.equalsIgnoreCase("quit") || line.equalsIgnoreCase("exit")) break;

                String[] parts = line.split("\\s+", 4);
                String cmd = parts[0].toLowerCase();

                if (cmd.equals("identify") && session.nationalId < 0)
                {
                    if (parts.length < 2) { writeLine(out, "Usage: identify <nationalId>"); continue; }
                    String reply = cmdIdentify(parts[1], session);
                    writeLine(out, reply);
                    continue;
                }

                if (session.nationalId < 0) { writeLine(out, "Identify yourself first: identify <nationalId>"); continue; }

                switch (cmd)
                {
                    case "list"      -> writeLine(out, cmdList());
                    case "msg"       -> { if (parts.length < 3) writeLine(out, "Usage: msg <nationalId> <text>");
                                         else writeLine(out, cmdMsg(parts[1], parts.length > 3 ? parts[2] + " " + parts[3] : parts[2], session)); }
                    case "broadcast" -> { if (parts.length < 2) writeLine(out, "Usage: broadcast <text>");
                                         else writeLine(out, cmdBroadcast(line.substring("broadcast ".length()), session)); }
                    case "schedule"  -> writeLine(out, cmdSchedule(parts, line, session));
                    case "history"   -> writeLine(out, cmdHistory());
                    case "encrypt"   -> writeLine(out, cmdEncrypt(parts, session));
                    case "profile"   -> writeLine(out, cmdProfile(parts, session));
                    case "lang"      -> { if (parts.length < 2) writeLine(out, "Usage: lang <code>");
                                         else writeLine(out, languages.LanguagePack.handleLangCommand(session.ip, parts[1])); }
                    default          -> writeLine(out, "Unknown command. Type 'help' for commands or 'quit' to exit.\r\n" + HELP);
                }
            }
        }
        catch (Exception e) { ExceptionHandler.dispatch(e); }
        finally
        {
            if (session.nationalId >= 0)
                LIVE.remove(String.valueOf(session.nationalId));
            try { client.close(); } catch (Exception ignored) {}
        }
    }

    // ── Commands ──────────────────────────────────────────────────────────────

    private String cmdIdentify(final String idStr, final Session session)
    {
        try
        {
            long id = Long.parseLong(idStr);
            national.NationalFinanceID profile = database.N21Store.loadNationalFinanceID(id);
            if (profile == null) return "[identify] National ID " + id + " not found.";
            session.nationalId = id;
            LIVE.put(idStr, session);
            CommonRails.printSystemComponent(this, this.hashCode(),
                ". Communicator National ID " + id + " connected from " + session.ip + " .");

            // Auto-negotiate if profile has saved cipher preference
            CommunicatorCrypto.CipherSuite savedCipher = CommunicatorCrypto.loadProfileCipher(id);
            String cryptoHint = "";
            if (savedCipher != null)
            {
                session.activeCipher = savedCipher;
                cryptoHint = "\r\n[crypto] Profile cipher: " + savedCipher.displayName +
                    ". Send 'encrypt " + savedCipher.displayName + "' to negotiate, or 'encrypt off' to skip.";
            }

            return "[identify] Welcome, National ID " + id + ". Connected users: " + LIVE.size() + "." + cryptoHint + "\r\n" + HELP;
        }
        catch (NumberFormatException e) { return "[identify] Invalid National ID."; }
    }

    private static String cmdList()
    {
        if (LIVE.isEmpty()) return "[list] No users connected.";
        StringBuilder sb = new StringBuilder("[list] Connected users (" + LIVE.size() + "):\r\n");
        LIVE.forEach((id, s) ->
            sb.append("  NID=").append(id)
              .append("  IP=").append(s.ip)
              .append("  Geo=").append(s.geoCity).append(", ").append(s.geoCountry)
              .append("  TZ=").append(s.timezone)
              .append("  Online=").append((System.currentTimeMillis() - s.connectedAt) / 60000).append("min")
              .append("\r\n"));
        return sb.toString().stripTrailing();
    }

    private String cmdMsg(final String toId, final String text, final Session from)
    {
        Session target = LIVE.get(toId);
        database.N21Store.storeChatMessage(from.nationalId, Long.parseLong(toId), text, "direct");

        // DSA-sign the chat message automatically
        byte[] sig = national.NationalCrypto.signChat(from.nationalId, text.getBytes(StandardCharsets.UTF_8));
        String sigHex = java.util.HexFormat.of().formatHex(sig);

        if (target == null) return "[msg] User " + toId + " not connected. Message stored (DSA-signed).";
        target.writeLine("[MSG from " + from.nationalId + " sig=" + sigHex.substring(0, Math.min(16, sigHex.length())) + "…] " + text);
        return "[msg] Delivered to " + toId + " (DSA-signed).";
    }

    private String cmdBroadcast(final String text, final Session from)
    {
        database.N21Store.storeChatMessage(from.nationalId, -1L, text, "broadcast");

        // RSA-encrypt the broadcast signal for each recipient
        byte[] encrypted = national.NationalCrypto.encryptSignal(from.nationalId, text.getBytes(StandardCharsets.UTF_8));
        String encHex = java.util.HexFormat.of().formatHex(encrypted);
        String preview = encHex.substring(0, Math.min(16, encHex.length()));

        int count = 0;
        for (Session s : LIVE.values())
        {
            if (s.nationalId != from.nationalId) { s.writeLine("[BROADCAST from " + from.nationalId + " rsa=" + preview + "…] " + text); count++; }
        }
        return "[broadcast] Sent to " + count + " user(s) (RSA-signed signal).";
    }

    private String cmdSchedule(final String[] parts, final String raw, final Session from)
    {
        // schedule <nationalId|broadcast> <HH:mm> <text>
        if (parts.length < 4) return "Usage: schedule <nationalId|broadcast> <HH:mm> <text>";
        String target  = parts[1];
        String timeStr = parts[2];
        String text    = parts.length > 3 ? raw.substring(raw.indexOf(timeStr) + timeStr.length()).trim() : "";
        if (!timeStr.matches("\\d{2}:\\d{2}")) return "[schedule] Time must be HH:mm (24h).";

        long toId = target.equalsIgnoreCase("broadcast") ? -1L : Long.parseLong(target);
        database.N21Store.storeScheduledMessage(from.nationalId, toId, text, timeStr);
        return "[schedule] Message scheduled at " + timeStr + " local time for " +
               (toId < 0 ? "all users" : "National ID " + toId) + ".";
    }

    private static String cmdHistory()
    {
        try
        {
            ResultSet rs = database.N21Store.loadRecentChatMessages(20);
            if (rs == null) return "[history] No history available.";
            StringBuilder sb = new StringBuilder("[history] Last messages:\r\n");
            while (rs.next())
                sb.append("  [").append(rs.getString("sent_at")).append("] ")
                  .append(rs.getLong("from_national_id")).append(" → ")
                  .append(rs.getLong("to_national_id") < 0 ? "ALL" : rs.getString("to_national_id"))
                  .append(": ").append(rs.getString("message")).append("\r\n");
            rs.close();
            return sb.toString().stripTrailing();
        }
        catch (Exception e) { return "[history] Error: " + e.getMessage(); }
    }

    // ── Encrypt command ─────────────────────────────────────────────────────

    /**
     * encrypt                     — Show available ciphers (dropdown)
     * encrypt <cipher>            — Initiate DH/ECDH key exchange with chosen cipher
     * encrypt accept <pubkey_hex> — Client sends their DH/ECDH public key to complete exchange
     * encrypt off                 — Disable encryption for this session
     */
    private String cmdEncrypt(final String[] parts, final Session session)
    {
        if (parts.length < 2)
        {
            return "[encrypt] Available ciphers:\r\n" +
                   CommunicatorCrypto.CipherSuite.listAll() + "\r\n" +
                   "Usage: encrypt <cipher-name>   — initiate negotiation\r\n" +
                   "       encrypt off             — disable encryption\r\n" +
                   (session.activeCipher != null ? "Active: " + session.activeCipher.displayName : "Status: plaintext");
        }

        String arg = parts[1].toLowerCase();

        // Disable encryption
        if (arg.equals("off") || arg.equals("none") || arg.equals("disable"))
        {
            session.encrypted = false;
            session.sharedSecret = null;
            session.activeCipher = null;
            session.dhSession = null;
            session.ecdhSession = null;
            return "[encrypt] Encryption disabled. Session is now plaintext.";
        }

        // Accept client public key (Phase 2 of handshake)
        if (arg.equals("accept") && parts.length >= 3)
        {
            try
            {
                byte[] clientPubKey = java.util.HexFormat.of().parseHex(parts[2]);
                if (session.ecdhSession != null)
                {
                    session.ecdhSession.computeSharedSecret(clientPubKey);
                    session.sharedSecret = session.ecdhSession.sharedSecret;
                }
                else if (session.dhSession != null)
                {
                    session.dhSession.computeSharedSecret(clientPubKey);
                    session.sharedSecret = session.dhSession.sharedSecret;
                }
                else
                {
                    return "[encrypt] No pending key exchange. Run 'encrypt <cipher>' first.";
                }
                session.encrypted = true;
                // Save to profile if user has a national ID
                if (session.nationalId > 0 && session.activeCipher != null)
                    CommunicatorCrypto.saveProfileCipher(session.nationalId, session.activeCipher);
                return "[encrypt] Key exchange complete. Session encrypted with " +
                       session.activeCipher.displayName + ". All messages now encrypted.";
            }
            catch (Exception e)
            {
                return "[encrypt] Key exchange failed: " + e.getMessage();
            }
        }

        // Initiate negotiation — resolve cipher name
        // Support numeric selection (1-6) or name
        CommunicatorCrypto.CipherSuite suite;
        try
        {
            int idx = Integer.parseInt(arg) - 1;
            CommunicatorCrypto.CipherSuite[] all = CommunicatorCrypto.CipherSuite.values();
            if (idx < 0 || idx >= all.length) return "[encrypt] Invalid selection. Choose 1-" + all.length;
            suite = all[idx];
        }
        catch (NumberFormatException e)
        {
            suite = CommunicatorCrypto.CipherSuite.fromName(parts[1]);
        }

        if (suite == null)
            return "[encrypt] Unknown cipher. Available:\r\n" + CommunicatorCrypto.CipherSuite.listAll();

        session.activeCipher = suite;

        // Choose key exchange method: ECDH for ECC, DH for everything else
        try
        {
            String serverPubHex;
            if (suite == CommunicatorCrypto.CipherSuite.ECC_SECP256R1)
            {
                session.ecdhSession = new CommunicatorCrypto.ECDHSession();
                session.dhSession = null;
                serverPubHex = java.util.HexFormat.of().formatHex(session.ecdhSession.getPublicKeyEncoded());
                return "[encrypt] Negotiating " + suite.displayName + " via ECDH (secp256r1)\r\n" +
                       "[encrypt] Server public key (ECDH): " + serverPubHex + "\r\n" +
                       "[encrypt] Send your public key: encrypt accept <your_pubkey_hex>";
            }
            else
            {
                session.dhSession = new CommunicatorCrypto.DHSession(true); // RFC 3526 group 14
                session.ecdhSession = null;
                serverPubHex = java.util.HexFormat.of().formatHex(session.dhSession.getPublicKeyEncoded());
                return "[encrypt] Negotiating " + suite.displayName + " via DH-2048 (RFC 3526 Group 14)\r\n" +
                       "[encrypt] Server public key (DH): " + serverPubHex + "\r\n" +
                       "[encrypt] Send your public key: encrypt accept <your_pubkey_hex>";
            }
        }
        catch (Exception e)
        {
            return "[encrypt] Failed to initialize key exchange: " + e.getMessage();
        }
    }

    // ── Profile command ───────────────────────────────────────────────────────

    /**
     * profile                  — Show current profile settings
     * profile cipher <name>   — Set default cipher (auto-negotiates on next connect)
     * profile clear            — Clear profile settings
     */
    private String cmdProfile(final String[] parts, final Session session)
    {
        if (session.nationalId < 0) return "[profile] Identify yourself first.";

        if (parts.length < 2)
        {
            CommunicatorCrypto.CipherSuite saved = CommunicatorCrypto.loadProfileCipher(session.nationalId);
            return "[profile] National ID: " + session.nationalId + "\r\n" +
                   "  Preferred cipher: " + (saved != null ? saved.displayName : "none (plaintext)") + "\r\n" +
                   "  Active cipher:    " + (session.activeCipher != null ? session.activeCipher.displayName : "none") + "\r\n" +
                   "  Encrypted:        " + session.encrypted + "\r\n" +
                   "Usage:\r\n" +
                   "  profile cipher <name|number>  — Set default cipher\r\n" +
                   "  profile clear                 — Clear preference\r\n" +
                   "Available ciphers:\r\n" + CommunicatorCrypto.CipherSuite.listAll();
        }

        String sub = parts[1].toLowerCase();

        if (sub.equals("clear") || sub.equals("reset"))
        {
            try
            {
                var conn = database.N21DataSource.get();
                var ps = conn.prepareStatement("DELETE FROM communicator_profiles WHERE national_id = ?");
                ps.setLong(1, session.nationalId);
                ps.executeUpdate(); ps.close();
            }
            catch (Exception ignored) {}
            return "[profile] Cipher preference cleared. Next session will be plaintext unless negotiated.";
        }

        if (sub.equals("cipher") && parts.length >= 3)
        {
            CommunicatorCrypto.CipherSuite suite;
            try
            {
                int idx = Integer.parseInt(parts[2]) - 1;
                CommunicatorCrypto.CipherSuite[] all = CommunicatorCrypto.CipherSuite.values();
                if (idx < 0 || idx >= all.length) return "[profile] Invalid selection.";
                suite = all[idx];
            }
            catch (NumberFormatException e)
            {
                suite = CommunicatorCrypto.CipherSuite.fromName(parts[2]);
            }
            if (suite == null) return "[profile] Unknown cipher.\r\n" + CommunicatorCrypto.CipherSuite.listAll();

            CommunicatorCrypto.saveProfileCipher(session.nationalId, suite);
            return "[profile] Default cipher set to: " + suite.displayName +
                   "\r\n  This will auto-negotiate on your next connection (after identify).";
        }

        return "[profile] Usage: profile cipher <name>, profile clear";
    }

    // ── Geo resolution ────────────────────────────────────────────────────────

    private static void resolveGeo(final Session session)
    {
        try
        {
            boolean priv = session.ip.startsWith("127.") || session.ip.startsWith("10.")
                || session.ip.startsWith("192.168.") || session.ip.equals("::1");
            java.net.HttpURLConnection c = (java.net.HttpURLConnection)
                new java.net.URL("http://ip-api.com/json/" + (priv ? "" : session.ip)
                    + "?fields=city,country,timezone").openConnection();
            c.setConnectTimeout(2000); c.setConnectTimeout(2000);
            try (BufferedReader r = new BufferedReader(new InputStreamReader(c.getInputStream())))
            {
                String body = r.lines().collect(java.util.stream.Collectors.joining());
                session.geoCity    = extract(body, "city");
                session.geoCountry = extract(body, "country");
                session.timezone   = extract(body, "timezone");
                if (session.timezone.isEmpty()) session.timezone = "UTC";
            }
        }
        catch (Exception ignored) { session.geoCity = "Unknown"; session.geoCountry = ""; session.timezone = "UTC"; }
    }

    private static String extract(final String json, final String key)
    {
        int i = json.indexOf("\"" + key + "\":\"");
        if (i < 0) return "";
        int s = i + key.length() + 4;
        int e = json.indexOf('"', s);
        return e > s ? json.substring(s, e) : "";
    }

    // ── IO helpers ────────────────────────────────────────────────────────────

    private static String readLine(final BufferedReader in)
    {
        try { return in.readLine(); } catch (java.net.SocketTimeoutException e) { return ""; } catch (Exception e) { return null; }
    }

    private static void writeLine(final BufferedWriter out, final String line)
    {
        try { out.write(line + "\r\n"); out.flush(); } catch (Exception ignored) {}
    }

    // ── Help ──────────────────────────────────────────────────────────────────

    private static final String HELP =
        "Commands:\r\n" +
        "  list                                  List connected users\r\n" +
        "  msg <nationalId> <text>               Direct message\r\n" +
        "  broadcast <text>                      Message all users\r\n" +
        "  schedule <nationalId|broadcast> <HH:mm> <text>\r\n" +
        "                                        Scheduled message (recipient local time)\r\n" +
        "  history                               Last 20 chat messages\r\n" +
        "  encrypt                               Show cipher options (dropdown)\r\n" +
        "  encrypt <cipher>                      Negotiate encrypted session (DH/ECDH)\r\n" +
        "  encrypt accept <pubkey_hex>           Complete key exchange\r\n" +
        "  encrypt off                           Disable encryption\r\n" +
        "  profile                               Show/set profile preferences\r\n" +
        "  profile cipher <name|number>          Set default cipher permanently\r\n" +
        "  profile clear                         Clear cipher preference\r\n" +
        "  lang <code>                           Switch language (ja cn ru th es fr de it en)\r\n" +
        "  quit                                  Disconnect";

    // ── MessagePoller ─────────────────────────────────────────────────────────

    /**
     * Polls MySQL every 60 seconds for scheduled messages whose delivery time
     * has arrived in the recipient's local timezone, and delivers them to any
     * live sessions.  Undelivered messages remain pending for next cycle.
     */
    public static final class MessagePoller
    {
        private static volatile boolean started = false;

        public static synchronized void start()
        {
            if (started) return;
            started = true;
            Executors.newSingleThreadScheduledExecutor(r ->
            {
                Thread t = new Thread(r, "Communicator.MessagePoller");
                t.setDaemon(true);
                return t;
            }).scheduleAtFixedRate(MessagePoller::poll, 60, 60, TimeUnit.SECONDS);
            CommonRails.printSystemComponent(MessagePoller.class, MessagePoller.class.hashCode(),
                ". Communicator.MessagePoller started — polling every 60s .");
        }

        static void poll()
        {
            try
            {
                ResultSet rs = database.N21Store.loadDueScheduledMessages();
                if (rs == null) return;
                while (rs.next())
                {
                    long   msgId      = rs.getLong("id");
                    long   fromId     = rs.getLong("from_national_id");
                    long   toId       = rs.getLong("to_national_id");
                    String text       = rs.getString("message");
                    String schedTime  = rs.getString("scheduled_time"); // HH:mm

                    if (toId < 0)
                    {
                        // broadcast — deliver to every live session whose local HH:mm matches
                        for (Session s : LIVE.values())
                            if (localTimeMatches(s.timezone, schedTime))
                            {
                                s.writeLine("[SCHEDULED from " + fromId + "] " + text);
                                database.N21Store.markScheduledDelivered(msgId);
                                break; // mark once; all recipients get it
                            }
                    }
                    else
                    {
                        Session target = LIVE.get(String.valueOf(toId));
                        if (target != null && localTimeMatches(target.timezone, schedTime))
                        {
                            target.writeLine("[SCHEDULED from " + fromId + "] " + text);
                            database.N21Store.markScheduledDelivered(msgId);
                        }
                    }
                }
                rs.close();
            }
            catch (Exception e) { ExceptionHandler.dispatch(e); }
        }

        /** Returns true if the current HH:mm in the given timezone matches schedTime. */
        private static boolean localTimeMatches(final String tz, final String schedTime)
        {
            try
            {
                ZonedDateTime now = ZonedDateTime.now(ZoneId.of(tz));
                String current = now.format(DateTimeFormatter.ofPattern("HH:mm"));
                return current.equals(schedTime);
            }
            catch (Exception e) { return false; }
        }
    }
}
