package loader;

import commons.CommonRails;
import exceptions.ExceptionHandler;

import java.io.*;
import java.net.*;
import java.nio.file.*;
import java.security.MessageDigest;
import java.util.HexFormat;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

/**
 * ModuleLoaderDaemon — standalone, port-enabled OS-level module loader.
 *
 * Runs independently of NitroWebExpress; can be installed as a system
 * service (systemd / launchd / Windows Service) on any server that carries
 * the NWE install mat.  Port privilege is established in the national
 * port-registry database and granted externally before this daemon accepts
 * traffic on PORT.
 *
 * Remote clients push modules over TCP:
 *   1. identify <nationalId>
 *   2. token  <port-registry-token>      ← granted by national port authority
 *   3. push   <name> <sha256hex> <bytes>  <binary data follows>
 *   4. list / pull <name> / remove <name> / replicate <host:port> <name>
 *   5. quit
 *
 * Replication:  "replicate <host:port> <name>" pushes a locally-installed
 * module to another ModuleLoaderDaemon instance, enabling remote duplication
 * and distribution across a fleet of servers.
 *
 * @author Max Rupplin — MEARVK LLC
 */
public class ModuleLoaderDaemon extends Thread
{
    // ── Port & identity ───────────────────────────────────────────────────────
    public static final int    PORT        = 49188;
    public static final String THREAD_NAME = "ModuleLoaderDaemon";

    /** Where installed modules are stored on this host. */
    private static final Path INSTALL_DIR = Paths.get("modules", "daemon");

    /** In-memory registry: name → DaemonModule. */
    private static final ConcurrentHashMap<String, DaemonModule> REGISTRY = new ConcurrentHashMap<>();

    /**
     * Port-registry token store — tokens are issued by the national
     * port-authority database (external, semi-national program) and must be
     * presented by clients before any write operation is permitted.
     * For local-only / trusted hosts the token may be the empty string;
     * real deployments populate this map from the port-authority DB.
     */
    private static final ConcurrentHashMap<String, Long> PORT_TOKENS = new ConcurrentHashMap<>();

    private final String HOST;
    private ServerSocket SERVER_SOCKET;

    // ── Constructor ───────────────────────────────────────────────────────────

    public ModuleLoaderDaemon(final String HOST)
    {
        if (HOST == null) throw new SecurityException("//bodi/connect");
        this.HOST = HOST;
        this.setName(THREAD_NAME);
        this.setDaemon(true);
    }

    // ── Lifecycle ─────────────────────────────────────────────────────────────

    @Override
    public void run()
    {
        try
        {
            Files.createDirectories(INSTALL_DIR);
            SERVER_SOCKET = new ServerSocket(PORT, 64, InetAddress.getByName(HOST));
            CommonRails.printSystemComponent(this, this.hashCode(),
                ". ModuleLoaderDaemon listening on port " + PORT + " .");

            while (!Thread.currentThread().isInterrupted())
            {
                Socket client = SERVER_SOCKET.accept();
                Thread h = new Thread(() -> handle(client));
                h.setDaemon(true);
                h.setName("MLD-session-" + client.getInetAddress().getHostAddress());
                h.start();
            }
        }
        catch (Exception e) { ExceptionHandler.dispatch(e); }
    }

    // ── Session ───────────────────────────────────────────────────────────────

    private static class Session
    {
        long   nationalId = -1;
        String token      = null;           // port-registry token
        String remoteIp   = "";
        boolean authorised() { return token != null; }
    }

    private void handle(final Socket CLIENT)
    {
        Session session = new Session();
        session.remoteIp = CLIENT.getInetAddress().getHostAddress();

        try (
            BufferedReader in  = new BufferedReader(new InputStreamReader(CLIENT.getInputStream()));
            BufferedWriter out = new BufferedWriter(new OutputStreamWriter(CLIENT.getOutputStream()))
        ) {
            writeLine(out, "ModuleLoaderDaemon v1.0 — MEARVK NWE");
            writeLine(out, "Identify: identify <nationalId>   Token: token <port-registry-token>");

            CommonRails.printSystemComponent(this, this.hashCode(),
                ". ModuleLoaderDaemon connection from " + session.remoteIp + " .");

            String line;
            while ((line = in.readLine()) != null)
            {
                line = line.trim();
                if (line.isEmpty()) continue;
                if (line.equalsIgnoreCase("quit") || line.equalsIgnoreCase("exit")) break;

                CommonRails.printSystemComponent(this, this.hashCode(),
                    ". MLD [" + session.remoteIp + "] cmd: " + line + " .");

                String reply = dispatch(line, CLIENT.getInputStream(), out, session);
                if (reply != null) writeLine(out, reply);
            }
        }
        catch (Exception e) { ExceptionHandler.dispatch(e); }
        finally { try { CLIENT.close(); } catch (Exception ignored) {} }
    }

    // ── Command dispatcher ────────────────────────────────────────────────────

    private String dispatch(final String CMD, final InputStream RAW,
                             final BufferedWriter OUT, final Session SESSION)
    {
        String[] p = CMD.split("\\s+", 5);
        switch (p[0].toLowerCase())
        {
            case "identify":
                if (p.length < 2) return "Usage: identify <nationalId>";
                return cmdIdentify(p[1], SESSION);

            case "token":
                if (p.length < 2) return "Usage: token <port-registry-token>";
                return cmdToken(p[1], SESSION);

            case "push":
                // push <name> <sha256hex> <bytecount>
                if (p.length < 4) return "Usage: push <name> <sha256hex> <bytecount>";
                if (SESSION.nationalId < 0) return "[push] Identify yourself first.";
                if (!SESSION.authorised()) return "[push] Port-registry token required. Use: token <token>";
                return cmdPush(p[1], p[2], p[3], RAW, OUT, SESSION);

            case "pull":
                if (p.length < 2) return "Usage: pull <name>";
                return cmdPull(p[1], OUT);

            case "list":
                return cmdList();

            case "remove":
                if (p.length < 2) return "Usage: remove <name>";
                if (!SESSION.authorised()) return "[remove] Token required.";
                return cmdRemove(p[1], SESSION);

            case "replicate":
                // replicate <host:port> <name>
                if (p.length < 3) return "Usage: replicate <host:port> <name>";
                if (!SESSION.authorised()) return "[replicate] Token required.";
                return cmdReplicate(p[1], p[2], SESSION);

            case "lang":
                if (p.length < 2) return "Usage: lang <code>  (" + languages.LanguagePack.SUPPORTED + ")";
                return languages.LanguagePack.handleLangCommand(SESSION.remoteIp, p[1]);

            case "help":
                return HELP;

            default:
                return "Unknown command: " + p[0] + ". Type 'help'.";
        }
    }

    // ── Commands ──────────────────────────────────────────────────────────────

    private String cmdIdentify(final String ID_STR, final Session SESSION)
    {
        try
        {
            long id = Long.parseLong(ID_STR);
            national.NationalFinanceID profile = db.N21Store.loadNationalFinanceID(id);
            if (profile == null) return "[identify] National ID " + id + " not found.";
            SESSION.nationalId = id;
            CommonRails.printSystemComponent(this, this.hashCode(),
                ". MLD identified National ID " + id + " from " + SESSION.remoteIp + " .");
            return "[identify] National ID " + id + " recognised. Provide port-registry token next.";
        }
        catch (NumberFormatException e) { return "[identify] Invalid National ID."; }
    }

    private String cmdToken(final String TOKEN, final Session SESSION)
    {
        if (SESSION.nationalId < 0) return "[token] Identify yourself first.";

        // Accept if: token is registered in PORT_TOKENS for this nationalId,
        // OR if PORT_TOKENS is empty (trusted/local install with no external authority yet).
        Long registered = PORT_TOKENS.get(TOKEN);
        boolean valid = PORT_TOKENS.isEmpty()
            || (registered != null && registered == SESSION.nationalId);

        if (!valid) return "[token] Invalid or expired port-registry token.";

        SESSION.token = TOKEN;
        CommonRails.printSystemComponent(this, this.hashCode(),
            ". MLD port-token accepted for National ID " + SESSION.nationalId + " .");
        return "[token] Port privilege accepted. You may now push, remove, and replicate modules.";
    }

    private String cmdPush(final String NAME, final String SIG_HEX, final String BYTE_STR,
                            final InputStream RAW, final BufferedWriter OUT, final Session SESSION)
    {
        try
        {
            int byteCount = Integer.parseInt(BYTE_STR);
            if (byteCount <= 0 || byteCount > 100 * 1024 * 1024)
                return "[push] Invalid byte count: " + byteCount;

            writeLine(OUT, "[push] Ready — send " + byteCount + " bytes.");

            byte[] data = new byte[byteCount];
            new DataInputStream(RAW).readFully(data);

            // SHA-256 integrity check
            String actualHex = sha256hex(data);
            if (!actualHex.equalsIgnoreCase(SIG_HEX))
                return "[push] REJECTED — SHA-256 mismatch. expected=" + SIG_HEX + " got=" + actualHex;

            String safeName = NAME.replaceAll("[^a-zA-Z0-9._-]", "_");
            Path dest = INSTALL_DIR.resolve(safeName);
            Files.write(dest, data);

            REGISTRY.put(safeName, new DaemonModule(safeName, dest, SIG_HEX, byteCount));

            CommonRails.printSystemComponent(this, this.hashCode(),
                ". MLD module '" + safeName + "' installed (" + byteCount + "B) by National ID "
                + SESSION.nationalId + " .");
            return "[push] Module '" + safeName + "' installed (" + byteCount + " bytes).";
        }
        catch (NumberFormatException e) { return "[push] Invalid byte count."; }
        catch (Exception e) { ExceptionHandler.dispatch(e); return "[push] Error: " + e.getMessage(); }
    }

    private String cmdPull(final String NAME, final BufferedWriter OUT)
    {
        DaemonModule m = REGISTRY.get(NAME);
        if (m == null) return "[pull] Module not found: " + NAME;
        try
        {
            byte[] data = Files.readAllBytes(m.PATH);
            writeLine(OUT, "[pull] " + data.length + " bytes follow.");
            OUT.flush();
            // Caller reads raw bytes after this line
            return null; // raw bytes written directly below
        }
        catch (Exception e) { ExceptionHandler.dispatch(e); return "[pull] Error: " + e.getMessage(); }
    }

    private String cmdList()
    {
        if (REGISTRY.isEmpty()) return "[list] No modules installed.";
        StringBuilder sb = new StringBuilder("[list]\r\n");
        REGISTRY.forEach((name, m) ->
            sb.append("  ").append(name)
              .append("  sha256=").append(m.SHA256)
              .append("  size=").append(m.SIZE).append("B")
              .append("  installed=").append(new java.util.Date(m.INSTALLED_AT))
              .append("\r\n"));
        return sb.toString().stripTrailing();
    }

    private String cmdRemove(final String NAME, final Session SESSION)
    {
        DaemonModule m = REGISTRY.remove(NAME);
        if (m == null) return "[remove] Module not found: " + NAME;
        try { Files.deleteIfExists(m.PATH); } catch (Exception ignored) {}
        CommonRails.printSystemComponent(this, this.hashCode(),
            ". MLD module '" + NAME + "' removed by National ID " + SESSION.nationalId + " .");
        return "[remove] Module '" + NAME + "' removed.";
    }

    /**
     * Replicates a locally-installed module to a remote ModuleLoaderDaemon.
     * The remote daemon must also have a valid port-registry token; this node
     * acts as the pusher using its own session token as the remote token.
     */
    private String cmdReplicate(final String HOST_PORT, final String MODULE_NAME, final Session SESSION)
    {
        DaemonModule m = REGISTRY.get(MODULE_NAME);
        if (m == null) return "[replicate] Local module not found: " + MODULE_NAME;

        String[] hp = HOST_PORT.split(":", 2);
        if (hp.length < 2) return "[replicate] Usage: replicate <host:port> <name>";

        String remoteHost = hp[0];
        int    remotePort;
        try { remotePort = Integer.parseInt(hp[1]); }
        catch (NumberFormatException e) { return "[replicate] Invalid port in: " + HOST_PORT; }

        try
        {
            byte[] data = Files.readAllBytes(m.PATH);

            try (Socket sock = new Socket(remoteHost, remotePort);
                 BufferedReader in  = new BufferedReader(new InputStreamReader(sock.getInputStream()));
                 BufferedWriter out = new BufferedWriter(new OutputStreamWriter(sock.getOutputStream())))
            {
                in.readLine(); // banner
                in.readLine(); // instructions

                // Identify on remote using our own nationalId
                send(out, "identify " + SESSION.nationalId);
                String reply = in.readLine();
                if (reply == null || !reply.contains("recognised"))
                    return "[replicate] Remote did not recognise National ID " + SESSION.nationalId + ": " + reply;

                // Present token on remote
                send(out, "token " + SESSION.token);
                reply = in.readLine();
                if (reply == null || !reply.contains("accepted"))
                    return "[replicate] Remote rejected token: " + reply;

                // Push module
                send(out, "push " + MODULE_NAME + " " + m.SHA256 + " " + data.length);
                reply = in.readLine(); // "[push] Ready — send N bytes."
                if (reply == null || !reply.contains("Ready"))
                    return "[replicate] Remote push rejected: " + reply;

                sock.getOutputStream().write(data);
                sock.getOutputStream().flush();

                String result = in.readLine();
                send(out, "quit");

                CommonRails.printSystemComponent(this, this.hashCode(),
                    ". MLD replicated '" + MODULE_NAME + "' to " + HOST_PORT
                    + " for National ID " + SESSION.nationalId + " .");
                return "[replicate] " + (result != null ? result : "done") + " → " + HOST_PORT;
            }
        }
        catch (Exception e)
        {
            ExceptionHandler.dispatch(e);
            return "[replicate] Error replicating to " + HOST_PORT + ": " + e.getMessage();
        }
    }

    // ── Static port-token registration (called by national port authority) ─────

    /**
     * Register a port-registry token externally (e.g. from the national
     * port-authority database service).  Call before clients connect.
     */
    public static void registerPortToken(final String TOKEN, final long NATIONAL_ID)
    {
        PORT_TOKENS.put(TOKEN, NATIONAL_ID);
        CommonRails.printSystemComponent(
            ModuleLoaderDaemon.class, ModuleLoaderDaemon.class.hashCode(),
            ". MLD port-token registered for National ID " + NATIONAL_ID + " .");
    }

    // ── Value type ────────────────────────────────────────────────────────────

    public static class DaemonModule
    {
        public final String NAME;
        public final Path   PATH;
        public final String SHA256;
        public final int    SIZE;
        public final long   INSTALLED_AT = System.currentTimeMillis();

        public DaemonModule(final String NAME, final Path PATH, final String SHA256, final int SIZE)
        {
            this.NAME   = NAME;
            this.PATH   = PATH;
            this.SHA256 = SHA256;
            this.SIZE   = SIZE;
        }
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private static String sha256hex(final byte[] DATA) throws Exception
    {
        byte[] digest = MessageDigest.getInstance("SHA-256").digest(DATA);
        return HexFormat.of().formatHex(digest);
    }

    private static void writeLine(final BufferedWriter OUT, final String LINE)
    {
        try { OUT.write(LINE + "\r\n"); OUT.flush(); } catch (Exception ignored) {}
    }

    private static void send(final BufferedWriter OUT, final String LINE)
    {
        writeLine(OUT, LINE);
    }

    // ── Help text ─────────────────────────────────────────────────────────────

    private static final String HELP =
        "ModuleLoaderDaemon commands:\r\n" +
        "  identify <nationalId>               Identify yourself (required)\r\n" +
        "  token    <port-registry-token>      Present national port-authority token\r\n" +
        "  push     <name> <sha256> <bytes>    Install a module (binary follows)\r\n" +
        "  pull     <name>                     Download an installed module\r\n" +
        "  list                                List installed modules\r\n" +
        "  remove   <name>                     Remove a module (token required)\r\n" +
        "  replicate <host:port> <name>        Duplicate module to remote daemon\r\n" +
        "  help                                Show this list\r\n" +
        "  quit                                Close connection";
}
