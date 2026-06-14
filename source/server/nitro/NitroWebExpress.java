package server.nitro;

import database.N21Store;
import server.nitro.modules.MySQLComponent;
import server.nitro.modules.ConnectionStatusServer;
import bitcoin.module.TraderModule;
import commons.CommonRails;
import commons.EnglishArithemeter;
import commons.color.ColorPalette;
import commons.socket.SocketUtils;
import connections.CurrentConnections;
import exceptions.ExceptionHandler;
import encryption.module.aes.two.EncryptionModule;
import messaging.MessageQueue;
import messaging.MessageQueueSorter;
import national.NationalID;
import server.webexpress.WebExpress;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.DataInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.io.OutputStreamWriter;
import java.net.HttpURLConnection;
import java.net.InetAddress;
import java.net.ServerSocket;
import java.net.Socket;
import java.net.SocketTimeoutException;
import java.net.URL;
import java.net.URLClassLoader;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.security.MessageDigest;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.HexFormat;
import java.util.concurrent.ConcurrentHashMap;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;
import java.util.Random;

public class NitroWebExpress extends WebExpress
{
    public final String[] NOTE = new String[]{"AES 2.0 DSS5.0, AES2.0", "California Governor Gavin Newsom"};

    public final String[] PRIMER = new String[]{"AES 2.0 DSS5.0, AES2.0", "North Carolina Governor Joshua Stein"};

    public static NitroWebExpress SELF;

    public static Integer BASE_PORT = 49152;

    public static final Integer AES_COMPLIANT_PORT = 5512;

    public static final Integer BITCOIN_COMPLIANT_PORT = 6682;

    public static final String AES_COMPLIANT_THREADNAME = "AES 2.0 Masterthread";

    public static final String BITCOIN_COMPLIANT_THREADNAME = "Bitcoin v24.0+ Masterthread";

    public static String WEBEXPRESS_COMPLIANT_THREADNAME = "WebExpress v24.0+ Masterthread";


    public static String WEBEXPRESS_COMPLIANT_HOSTNAME = "localhost";

    public static final String BITCOIN_COMPLIANT_HOSTNAME = "localhost";

    public static final String AES_COMPLIANT_HOSTNAME = "localhost";

    public Aspect BRIDGE = new Aspect(this);

    public NationalID NATIONALID = new NationalID();

    public NitroWebExpress(final Integer PORT, final String HOST, final String THREAD_NAME)
    {
        super(HOST, PORT, THREAD_NAME, Boolean.TRUE);

        CommonRails.printSystemComponent(this, 8, ". National ID initialized: "+this.NATIONALID.EIGHT_DIGITS+" .");

        CommonRails.printSystemComponent(this, this.hashCode(),". Nitro version of WebExpress Starting .");

        NitroWebExpress.BASE_PORT = PORT;

        NitroWebExpress.WEBEXPRESS_COMPLIANT_HOSTNAME = HOST;

        NitroWebExpress.WEBEXPRESS_COMPLIANT_THREADNAME = THREAD_NAME;

        NitroWebExpress.SELF = this;
    }

    public static class Aspect
    {
        protected final Integer RANDOM = 10078;

        protected WebExpress WEBEXPRESS;

        protected EncryptionModule ENCRYPTION_MODULE = new EncryptionModule(new Random(RANDOM),"AES 2.0 DSS5.0","AES2.0 - California Governor Gavin Newsom");

        protected TraderModule TRADER_MODULE = new TraderModule(this, "Bitcoin Remote Module 2.0 ADS5.0");

        public AESCompliant AES_COMPONENT;

        public BitcoinCompliant BITCOIN_COMPONENT;

        public RSACompliant RSA_COMPONENT;

        public DSACompliant DSA_COMPONENT;

        public ConnectionStatusServer CONNECTION_STATUS;

        public MySQLComponent MYSQL_COMPONENT = new MySQLComponent();

        public ModuleInstallationService MODULE_INSTALLER_SERVICE;

        public ASCIICreatorServer ASCII_CREATOR_SERVER;

        public loader.ModuleLoaderDaemon MODULE_LOADER_DAEMON;

        public communicator.Communicator COMMUNICATOR;

        public http.BinaryHttpServer BINARY_HTTP_SERVER;

        public weather.WeatherServer WEATHER_SERVER;

        public whiteauditor.WhiteAuditorTasking WHITE_AUDITOR_TASKING;


        /** Start CONNECTION_STATUS and NitroWebExpress.SELF together. */
        public void start()
        {
            if (RSA_COMPONENT            != null) RSA_COMPONENT.start();
            if (DSA_COMPONENT            != null) DSA_COMPONENT.start();
            if (CONNECTION_STATUS        != null) CONNECTION_STATUS.start();
            if (MODULE_INSTALLER_SERVICE != null) MODULE_INSTALLER_SERVICE.start();
            if (ASCII_CREATOR_SERVER     != null) ASCII_CREATOR_SERVER.start();
            if (MODULE_LOADER_DAEMON     != null) MODULE_LOADER_DAEMON.start();
            if (COMMUNICATOR             != null) COMMUNICATOR.start();
            if (BINARY_HTTP_SERVER       != null) BINARY_HTTP_SERVER.start();
            if (WEATHER_SERVER           != null) WEATHER_SERVER.start();
            if (WHITE_AUDITOR_TASKING    != null) WHITE_AUDITOR_TASKING.start();
            if (NitroWebExpress.SELF     != null) NitroWebExpress.SELF.start();
        }

        public Aspect(final WebExpress WEBEXPRESS)
        {
            if(WEBEXPRESS==null) throw new SecurityException("//bodi/connect");

            this.WEBEXPRESS = WEBEXPRESS;

            this.WHITE_AUDITOR_TASKING = new whiteauditor.WhiteAuditorTasking(NitroWebExpress.WEBEXPRESS_COMPLIANT_HOSTNAME);

        }

        public static class InstalledModule
        {
            public final String       NAME;
            public final Path         SOURCE;
            public final URLClassLoader LOADER;
            public final long         INSTALLED_AT = System.currentTimeMillis();

            public InstalledModule(final String NAME, final Path SOURCE, final URLClassLoader LOADER)
            {
                this.NAME   = NAME;

                this.SOURCE = SOURCE;

                this.LOADER = LOADER;
            }
        }

        public static class ModuleRegistry
        {
            private static final ConcurrentHashMap<String, InstalledModule> MODULES = new ConcurrentHashMap<>();

            public static void register(final InstalledModule M)
            {
                MODULES.put(M.NAME, M);
                CommonRails.printSystemComponent(M, M.hashCode(), ". ModuleRegistry registered module [" + M.NAME + "] .");
            }

            public static boolean unload(final String NAME)
            {
                InstalledModule m = MODULES.remove(NAME);

                if (m == null) return false;

                try
                { m.LOADER.close();
                }
                catch (Exception ignored)
                {
                    ignored.printStackTrace(System.err);
                }

                CommonRails.printSystemComponent(m, m.hashCode(), ". ModuleRegistry unloaded module [" + NAME + "] .");

                return true;
            }

            public static InstalledModule get(final String NAME) { return MODULES.get(NAME); }

            public static ConcurrentHashMap<String, InstalledModule> all() { return MODULES; }
        }

        public static class ModuleInstallationService extends Thread
        {
            public static final int PORT = 49166;

            private static final Path INSTALL_DIR = Paths.get("modules");

            private final String HOST;
            private ServerSocket SERVER_SOCKET;

            public ModuleInstallationService(final String HOST)
            {
                if (HOST == null) throw new SecurityException("//bodi/connect");

                this.HOST = HOST;

                this.setName("ModuleInstallationService");

                this.setDaemon(true);
            }

            @Override
            public void run()
            {
                try
                {
                    Files.createDirectories(INSTALL_DIR);

                    N21Store.createModuleLoaderTable();

                    SERVER_SOCKET = new ServerSocket(PORT, 64, InetAddress.getByName(HOST));
                    CommonRails.printSystemComponent(this, this.hashCode(),
                        ". ModuleInstallationService listening on port " + PORT + " .");
                    while (!Thread.currentThread().isInterrupted())
                    {
                        Socket client = SERVER_SOCKET.accept();

                        Thread h = new Thread(() -> handle(client));

                        h.setDaemon(true);

                        h.start();
                    }
                }
                catch (Exception e)
                {
                    ExceptionHandler.dispatch(e);
                }
            }

            /** Per-connection session state. */
            private static class Session
            {
                long   nationalId  = -1;
                String adminToken  = null;
                String remoteIp    = "";
            }

            private void handle(final Socket CLIENT)
            {
                Session session = new Session();

                session.remoteIp = CLIENT.getInetAddress().getHostAddress();

                try (
                    BufferedReader in  = new BufferedReader(new InputStreamReader(CLIENT.getInputStream()));
                    BufferedWriter out = new BufferedWriter(new OutputStreamWriter(CLIENT.getOutputStream()))
                ) {
                    writeLine(out, "[ NWE port " + PORT + " — Module Installation Service  |  install, unload, and manage NWE modules ]");
                    writeLine(out, "ModuleInstallationService v2.0");
                    writeLine(out, "Type 'identify <nationalId>' first, then 'help' for commands.");

                    database.N21Store.storeModuleAction(0, "", "connect", session.remoteIp,
                        "", 0, "", "", "connected");

                    CommonRails.printSystemComponent(this, this.hashCode(),
                        ". ModuleInstallationService connection from " + session.remoteIp + " .");

                    String line;
                    while ((line = in.readLine()) != null)
                    {
                        line = line.trim();

                        if (line.isEmpty()) continue;

                        if (line.equalsIgnoreCase("quit") || line.equalsIgnoreCase("exit")) break;

                        CommonRails.printSystemComponent(this, this.hashCode(), ". ModuleInstallationService [" + session.remoteIp + "] cmd: " + line + " .");

                        String response = dispatch(line, CLIENT.getInputStream(), out, session);

                        if (response != null) writeLine(out, response);
                    }
                }
                catch (Exception e)
                {
                    ExceptionHandler.dispatch(e);
                }
                finally
                {
                    if (session.adminToken != null) admin.ModuleAdmin.logout(session.adminToken);
                    try { CLIENT.close(); } catch (Exception ignored) {}
                }
            }

            private String dispatch(final String CMD, final InputStream RAW, final BufferedWriter OUT, final Session SESSION)
            {
                String[] parts = CMD.split("\\s+", 4);

                switch (parts[0].toLowerCase())
                {
                    case "identify":
                        if (parts.length < 2) return "Usage: identify <nationalId>";
                        return identify(parts[1], SESSION);
                    case "admin":
                        if (parts.length < 2) return "Usage: admin <password>";
                        return adminLogin(parts[1], SESSION);
                    case "install":
                        // install <name> <sha256hex> <bytecount>
                        if (parts.length < 4) return "Usage: install <name> <sha256hex> <bytecount>";
                        if (SESSION.nationalId < 0) return "[install] Identify yourself first: identify <nationalId>";
                        return installModule(parts[1], parts[2], parts[3], RAW, OUT, SESSION);
                    case "unload":
                        if (parts.length < 2) return "Usage: unload <name>";
                        if (!admin.ModuleAdmin.isAdmin(SESSION.adminToken))
                            return "[unload] Admin authentication required. Use: admin <password>";
                        return unloadModule(parts[1], SESSION);
                    case "list":
                        return listModules();
                    case "restart":
                        if (parts.length < 2) return "Usage: restart <module>";
                        return restartModule(parts[1], SESSION);
                    case "comment":
                        if (parts.length < 3) return "Usage: comment <nationalId> <text>";
                        return addComment(parts[1], parts[2]);
                    case "signatory":
                        if (parts.length < 2) return "Usage: signatory <nationalId>";
                        if (!admin.ModuleAdmin.isAdmin(SESSION.adminToken))
                            return "[signatory] Admin authentication required.";
                        return grantSignatory(parts[1]);
                    case "help":
                        return HELP;
                    case "lang":
                        if (parts.length < 2) return "Usage: lang <code>  (" + languages.LanguagePack.SUPPORTED + ")";
                        return languages.LanguagePack.handleLangCommand(SESSION.remoteIp, parts[1]);
                    default:
                        return "Unknown command: " + parts[0] + ". Type 'help'.";
                }
            }

            private String identify(final String NATIONAL_ID_STR, final Session SESSION)
            {
                try
                {
                    long id = Long.parseLong(NATIONAL_ID_STR);

                    national.NationalFinanceID r = database.N21Store.loadNationalFinanceID(id);

                    if (r == null) return "[identify] National ID " + id + " not found.";

                    SESSION.nationalId = id;

                    database.N21Store.storeModuleAction(id, "", "identify", SESSION.remoteIp, "", 0, "", "", "identified");

                    CommonRails.printSystemComponent(this, this.hashCode(), ". ModuleInstallationService identified National ID " + id + " .");

                    return "[identify] National ID " + id + " recognised. Welcome.";
                }
                catch (NumberFormatException e)
                {
                    return "[identify] Invalid National ID.";
                }
            }

            private String adminLogin(final String PASSWORD, final Session SESSION)
            {
                if (SESSION.nationalId < 0) return "[admin] Identify yourself first.";

                String token = admin.ModuleAdmin.login(PASSWORD, SESSION.nationalId);

                if (token == null)
                {
                    database.N21Store.storeModuleAction(SESSION.nationalId, "", "admin-login-fail", SESSION.remoteIp, "", 0, "", "", "failed");

                    return "[admin] Authentication failed.";
                }

                SESSION.adminToken = token;

                database.N21Store.storeModuleAction(SESSION.nationalId, "", "admin-login", SESSION.remoteIp, "", 0, "", token, "success");

                return "[admin] Authenticated. You may now unload modules and grant signatories.";
            }

            private String installModule(final String NAME, final String SIG_HEX, final String BYTE_COUNT_STR, final InputStream RAW, final BufferedWriter OUT, final Session SESSION)
            {
                try
                {
                    int byteCount = Integer.parseInt(BYTE_COUNT_STR);

                    if (byteCount <= 0 || byteCount > 50 * 1024 * 1024)
                        return "[install] Invalid byte count: " + byteCount;

                    writeLine(OUT, "[install] Ready to receive " + byteCount + " bytes for '" + NAME + "'.");

                    byte[] data = new byte[byteCount];

                    new DataInputStream(RAW).readFully(data);

                    // Security check 1: SHA-256
                    String actualHex = sha256hex(data);

                    if (!actualHex.equalsIgnoreCase(SIG_HEX))
                    {
                        String result = "sig-mismatch expected=" + SIG_HEX + " got=" + actualHex;

                        database.N21Store.storeModuleAction(SESSION.nationalId, NAME, "install-reject", SESSION.remoteIp, "", byteCount, SIG_HEX, "", result);

                        CommonRails.printSystemComponent(this, this.hashCode(), ". ModuleInstallationService SECURITY FAIL sig mismatch [" + NAME + "] .");

                        return "[install] REJECTED — signature mismatch.";
                    }

                    // Security check 2: file type
                    String detectedType = detectType(data);

                    if (detectedType == null)
                    {
                        database.N21Store.storeModuleAction(SESSION.nationalId, NAME, "install-reject", SESSION.remoteIp, "unknown", byteCount, SIG_HEX, "", "bad-type");

                        CommonRails.printSystemComponent(this, this.hashCode(), ". ModuleInstallationService SECURITY FAIL unsupported type [" + NAME + "] .");

                        return "[install] REJECTED — unsupported file type (must be .jar, .zip, or .java).";
                    }

                    CommonRails.printSystemComponent(this, this.hashCode(), ". ModuleInstallationService security passed [" + NAME + "] type=" + detectedType + " .");

                    // Heuristics check — score the module before writing to disk
                    try
                    {
                        Path tmp = Files.createTempFile("nwe-heuristic-", "." + detectedType);

                        Files.write(tmp, data);

                        heuristics.ModuleHeuristics.Result hr = heuristics.ModuleHeuristics.evaluate(tmp);

                        Files.deleteIfExists(tmp);

                        CommonRails.printSystemComponent(this, this.hashCode(), ". ModuleInstallationService heuristics [" + NAME + "] score=" + hr.score + " suitable=" + hr.suitable + " .");

                        writeLine(OUT, "[heuristics] " + hr.summary());

                        if (!hr.suitable)
                        {
                            database.N21Store.storeModuleAction(SESSION.nationalId, NAME, "install-reject", SESSION.remoteIp, detectedType, byteCount, SIG_HEX, "", "heuristics-fail score=" + hr.score);

                            return "[install] REJECTED — heuristics score " + hr.score + "/100 is below threshold (" + heuristics.ModuleHeuristics.PASS_THRESHOLD + "). See findings above.";
                        }
                    }
                    catch (Exception hEx)
                    {
                        // Heuristics failure must not block install — log and continue
                        CommonRails.printSystemComponent(this, this.hashCode(), ". ModuleInstallationService heuristics error [" + NAME + "]: " + hEx.getMessage() + " — proceeding .");
                    }

                    String filename = NAME.replaceAll("[^a-zA-Z0-9._-]", "_") + "." + detectedType;

                    Path dest = INSTALL_DIR.resolve(filename);

                    Files.write(dest, data);

                    URLClassLoader loader = null;

                    if (detectedType.equals("jar"))
                    {
                        loader = new URLClassLoader(new URL[]{ dest.toUri().toURL() }, Thread.currentThread().getContextClassLoader());
                    }
                    else if (detectedType.equals("zip"))
                    {
                        Path unzipDir = INSTALL_DIR.resolve(NAME);

                        Files.createDirectories(unzipDir);

                        unzip(data, unzipDir);

                        loader = new URLClassLoader(new URL[]{ unzipDir.toUri().toURL() }, Thread.currentThread().getContextClassLoader());
                    }
                    else
                    {
                        javax.tools.JavaCompiler compiler = javax.tools.ToolProvider.getSystemJavaCompiler();

                        if (compiler == null) return "[install] No system compiler available (JDK required).";

                        Path srcFile = INSTALL_DIR.resolve(NAME + ".java");

                        Files.write(srcFile, data);

                        if (compiler.run(null, null, null, srcFile.toString()) != 0)
                            return "[install] Compilation failed for " + NAME + ".java";

                        loader = new URLClassLoader(new URL[]{ INSTALL_DIR.toUri().toURL() }, Thread.currentThread().getContextClassLoader());
                    }

                    ModuleRegistry.register(new InstalledModule(NAME, dest, loader));

                    String result = "installed " + detectedType + " " + byteCount + "B";

                    database.N21Store.storeModuleAction(SESSION.nationalId, NAME, "install", SESSION.remoteIp, detectedType, byteCount, SIG_HEX, "", result);

                    CommonRails.printSystemComponent(this, this.hashCode(), ". ModuleInstallationService installed [" + NAME + "] for National ID " + SESSION.nationalId + " .");

                    return "[install] Module '" + NAME + "' installed (" + detectedType + ", " + byteCount + " bytes).";
                }
                catch (NumberFormatException e)
                {
                    return "[install] Invalid byte count.";
                }
                catch (Exception e)
                {
                    ExceptionHandler.dispatch(e); return "[install] Error: " + e.getMessage();
                }
            }

            private String unloadModule(final String NAME, final Session SESSION)
            {
                boolean removed = ModuleRegistry.unload(NAME);

                String result = removed ? "unloaded" : "not-found";

                database.N21Store.storeModuleAction(SESSION.nationalId, NAME, "unload", SESSION.remoteIp, "", 0, "", SESSION.adminToken, result);

                CommonRails.printSystemComponent(this, this.hashCode(), ". ModuleInstallationService admin unload [" + NAME + "] result=" + result + " .");

                return removed ? "[unload] Module '" + NAME + "' unloaded." : "[unload] Module not found: " + NAME;
            }

            private String listModules()
            {
                ConcurrentHashMap<String, InstalledModule> all = ModuleRegistry.all();

                if (all.isEmpty()) return "[list] No modules loaded.";

                StringBuilder sb = new StringBuilder("[list] Loaded modules:\r\n");

                all.forEach((name, m) -> sb.append("  ").append(name).append(" — ").append(m.SOURCE).append("\r\n"));

                return sb.toString().stripTrailing();
            }

            private String restartModule(final String MODULE, final Session SESSION)
            {
                database.N21Store.storeModuleAction(SESSION.nationalId, MODULE, "restart",
                    SESSION.remoteIp, "", 0, "", "", "signal-sent");

                CommonRails.printSystemComponent(this, this.hashCode(),
                    ". ModuleInstallationService restart [" + MODULE + "] .");

                InstalledModule m = ModuleRegistry.get(MODULE);

                if (m != null || MODULE.matches("aes|bitcoin|status|national"))
                    return "[restart] Module '" + MODULE + "' restart signal sent.";

                return "[restart] Unknown module: " + MODULE;
            }

            private String addComment(final String NATIONAL_ID_STR, final String COMMENT)
            {
                try
                {
                    long id = Long.parseLong(NATIONAL_ID_STR);
                    national.NationalFinanceID r = database.N21Store.loadNationalFinanceID(id);
                    if (r == null) return "[comment] National ID " + id + " not found.";
                    r.suspects = (r.suspects != null && !r.suspects.isEmpty())
                        ? r.suspects + "; " + COMMENT : COMMENT;
                    database.N21Store.storeNationalFinanceID(r);
                    CommonRails.printSystemComponent(this, this.hashCode(),
                        ". ModuleInstallationService comment added to National ID " + id + " .");
                    return "[comment] Comment added to National ID " + id + ".";
                }
                catch (NumberFormatException e) { return "[comment] Invalid National ID: " + NATIONAL_ID_STR; }
                catch (Exception e) { ExceptionHandler.dispatch(e); return "[comment] Error: " + e.getMessage(); }
            }

            private String grantSignatory(final String NATIONAL_ID_STR)
            {
                try
                {
                    long id = Long.parseLong(NATIONAL_ID_STR);
                    national.NationalFinanceID r = database.N21Store.loadNationalFinanceID(id);
                    if (r == null) return "[signatory] National ID " + id + " not found.";
                    r.trustLevel = 100;
                    database.N21Store.storeNationalFinanceID(r);
                    CommonRails.printSystemComponent(this, this.hashCode(),
                        ". ModuleInstallationService final signatory granted to National ID " + id + " .");
                    return "[signatory] Final signatory rights granted to National ID " + id + ".";
                }
                catch (NumberFormatException e) { return "[signatory] Invalid National ID: " + NATIONAL_ID_STR; }
                catch (Exception e) { ExceptionHandler.dispatch(e); return "[signatory] Error: " + e.getMessage(); }
            }

            // ── Helpers ───────────────────────────────────────────────────────

            private static String detectType(final byte[] DATA)
            {
                if (DATA.length < 4) return null;
                if (DATA[0] == 0x50 && DATA[1] == 0x4B)
                {
                    String header = new String(DATA, 0, Math.min(DATA.length, 256));
                    return header.contains("META-INF") ? "jar" : "zip";
                }
                if (DATA[0] == (byte)0xCA && DATA[1] == (byte)0xFE
                    && DATA[2] == (byte)0xBA && DATA[3] == (byte)0xBE) return null;
                String text = new String(DATA, 0, Math.min(DATA.length, 512));
                if (text.contains("package ") || text.contains("public class") || text.contains("import "))
                    return "java";
                return null;
            }

            private static String sha256hex(final byte[] DATA) throws Exception
            {
                byte[] digest = MessageDigest.getInstance("SHA-256").digest(DATA);
                return HexFormat.of().formatHex(digest);
            }

            private static void unzip(final byte[] DATA, final Path DEST) throws Exception
            {
                try (ZipInputStream zis = new ZipInputStream(new java.io.ByteArrayInputStream(DATA)))
                {
                    ZipEntry entry;
                    while ((entry = zis.getNextEntry()) != null)
                    {
                        Path target = DEST.resolve(entry.getName()).normalize();
                        if (!target.startsWith(DEST)) continue;
                        if (entry.isDirectory()) { Files.createDirectories(target); }
                        else
                        {
                            Files.createDirectories(target.getParent());
                            try (OutputStream os = new FileOutputStream(target.toFile()))
                            { zis.transferTo(os); }
                        }
                        zis.closeEntry();
                    }
                }
            }

            private static void writeLine(final BufferedWriter OUT, final String LINE)
            {
                try { OUT.write(LINE + "\r\n"); OUT.flush(); } catch (Exception ignored) {}
            }

            private static final String HELP =
                "Commands:\r\n" +
                "  identify <nationalId>                   Identify yourself (required before install)\r\n" +
                "  admin <password>                        Authenticate as administrator\r\n" +
                "  install <name> <sha256hex> <bytecount>  Install a module (.jar/.zip/.java)\r\n" +
                "  unload  <name>                          Unload a module (admin only)\r\n" +
                "  list                                    List loaded modules\r\n" +
                "  restart <module>                        Restart a module\r\n" +
                "  comment <nationalId> <text>             Append a comment to a user account\r\n" +
                "  signatory <nationalId>                  Grant final signatory rights (admin only)\r\n" +
                "  help                                    Show this list\r\n" +
                "  quit                                    Close connection";
        }

        // ── ASCIICreatorServer ────────────────────────────────────────────────

        public static class ASCIICreatorServer extends Thread
        {
            public static final int PORT = 49177;
            private final String HOST;
            private ServerSocket SERVER_SOCKET;

            public ASCIICreatorServer(final String HOST)
            {
                if (HOST == null) throw new SecurityException("//bodi/connect");
                this.HOST = HOST;
                this.setName("ASCIICreatorServer");
                this.setDaemon(true);
            }

            @Override
            public void run()
            {
                try
                {
                    database.N21Store.createAsciiSignaturesTable();
                    SERVER_SOCKET = new ServerSocket(PORT, 64, InetAddress.getByName(HOST));
                    CommonRails.printSystemComponent(this, this.hashCode(),
                        ". ASCIICreatorServer listening on port " + PORT + " .");
                    while (!Thread.currentThread().isInterrupted())
                    {
                        Socket client = SERVER_SOCKET.accept();
                        Thread h = new Thread(() -> handle(client));
                        h.setDaemon(true);
                        h.start();
                    }
                }
                catch (Exception e) { ExceptionHandler.dispatch(e); }
            }

            private void handle(final Socket CLIENT)
            {
                try (
                    BufferedReader in  = new BufferedReader(new InputStreamReader(CLIENT.getInputStream()));
                    BufferedWriter out = new BufferedWriter(new OutputStreamWriter(CLIENT.getOutputStream()))
                ) {
                    writeLine(out, "[ NWE port " + PORT + " — ASCII Signature Service  |  issues unique binary ASCII signatures per National ID ]");
                    writeLine(out, "ASCIICreatorServer — Binary ASCII Signature Service");
                    writeLine(out, "Commands: request <nationalId>  |  view <nationalId>  |  quit");

                    String line;
                    while ((line = in.readLine()) != null)
                    {
                        line = line.trim();
                        if (line.isEmpty()) continue;
                        if (line.equalsIgnoreCase("quit") || line.equalsIgnoreCase("exit")) break;

                        String[] parts = line.split("\\s+", 2);
                        switch (parts[0].toLowerCase())
                        {
                            case "request":
                                if (parts.length < 2) { writeLine(out, "Usage: request <nationalId>"); break; }
                                writeLine(out, handleRequest(parts[1], CLIENT.getInetAddress().getHostAddress()));
                                break;
                            case "view":
                                if (parts.length < 2) { writeLine(out, "Usage: view <nationalId>"); break; }
                                writeLine(out, handleView(parts[1]));
                                break;
                            case "lang":
                                if (parts.length < 2) { writeLine(out, "Usage: lang <code>  (" + languages.LanguagePack.SUPPORTED + ")"); break; }
                                writeLine(out, languages.LanguagePack.handleLangCommand(CLIENT.getInetAddress().getHostAddress(), parts[1]));
                                break;
                            default:
                                writeLine(out, "Unknown command. Use: request <nationalId> | view <nationalId> | lang <code> | quit");
                        }
                    }
                }
                catch (Exception e) { ExceptionHandler.dispatch(e); }
                finally { try { CLIENT.close(); } catch (Exception ignored) {} }
            }

            private String handleRequest(final String NATIONAL_ID_STR, final String SOURCE_IP)
            {
                try
                {
                    long nationalId = Long.parseLong(NATIONAL_ID_STR);

                    // Verify national ID exists
                    national.NationalFinanceID profile = database.N21Store.loadNationalFinanceID(nationalId);
                    if (profile == null) return "[request] National ID " + nationalId + " not found.";

                    // Check for existing valid (non-expired) signature
                    java.sql.ResultSet existing = database.N21Store.loadAsciiSignature(nationalId);
                    if (existing != null)
                    {
                        String grid    = existing.getString("ascii_grid");
                        String expires = existing.getString("expires_at");
                        existing.close();
                        return "[request] You already have a valid signature (expires " + expires + ").\r\n" + grid;
                    }

                    // Assign the next available unique sig_id
                    int sigId = database.N21Store.nextAsciiSigId();
                    if (sigId >= (1 << 21))
                        return "[request] Signature space exhausted — contact administrator.";

                    String grid = ascii.creator.ASCIICreator.generateAsciiCode(sigId);
                    database.N21Store.storeAsciiSignature(nationalId, sigId, grid);

                    CommonRails.printSystemComponent(this, this.hashCode(),
                        ". ASCIICreatorServer issued sig_id=" + sigId
                        + " to National ID " + nationalId + " from " + SOURCE_IP + " .");

                    return "[request] Binary ASCII signature issued (sig_id=" + sigId
                        + ", valid 1000 days).\r\n" + grid;
                }
                catch (NumberFormatException e) { return "[request] Invalid National ID."; }
                catch (Exception e) { ExceptionHandler.dispatch(e); return "[request] Error: " + e.getMessage(); }
            }

            private String handleView(final String NATIONAL_ID_STR)
            {
                try
                {
                    long nationalId = Long.parseLong(NATIONAL_ID_STR);
                    java.sql.ResultSet rs = database.N21Store.loadAsciiSignature(nationalId);
                    if (rs == null) return "[view] No valid signature for National ID " + nationalId
                        + ". Use: request <nationalId>";
                    String grid    = rs.getString("ascii_grid");
                    String issued  = rs.getString("issued_at");
                    String expires = rs.getString("expires_at");
                    rs.close();
                    return "[view] National ID " + nationalId + " | issued=" + issued
                        + " | expires=" + expires + "\r\n" + grid;
                }
                catch (NumberFormatException e) { return "[view] Invalid National ID."; }
                catch (Exception e) { ExceptionHandler.dispatch(e); return "[view] Error: " + e.getMessage(); }
            }

            private static void writeLine(final BufferedWriter OUT, final String LINE)
            {
                try { OUT.write(LINE + "\r\n"); OUT.flush(); } catch (Exception ignored) {}
            }
        }

        public static class AESCompliant extends WebExpress
        {
            protected AESCompliant.MessageOutputHandler AES_MESSAGE_OUTPUT_HANDLER = new AESCompliant.MessageOutputHandler();

            public MessageQueueSorter MESSAGE_QUEUE_SORTER = new MessageQueueSorter(this);

            public MessageQueue MESSAGE_QUEUE = new MessageQueue(this);

            public Socket SOCKET;

            public AESCompliant(final String HOST, final Integer PORT, final String THREAD_NAME, final Boolean TELNET_PROXY_ENABLED)
            {
                if(HOST==null || PORT==null || THREAD_NAME==null || TELNET_PROXY_ENABLED==null) throw new SecurityException("//bodi/connect");

                super(HOST, PORT, THREAD_NAME, TELNET_PROXY_ENABLED);

                this.HOST = HOST;

                this.PORT = PORT;

                this.setName(THREAD_NAME);
            }

            public AESCompliant()
            {

            }

            protected static class MessageOutputRecord
            {
                public MessageOutputRecord()
                {
                    CommonRails.printSystemComponent(this, this.hashCode(), ". AESCompliant MessageOutputRecord loads .");
                }
            }

            protected static class MessageOutputHandler
            {
                public Socket SOCKET;

                public MessageOutputHandler()
                {
                    CommonRails.printSystemComponent(this, this.hashCode(), ". AESCompliant MessageOutputHandler starts .");
                }

                public void send_message(final StringBuffer BUFFER)
                {
                    if(BUFFER==null) throw new SecurityException("//bodi/connect");

                    messaging.MessageOutputHandler message_output_handler = new messaging.MessageOutputHandler(SOCKET, BUFFER);

                    message_output_handler.run();
                }

                public void send_message(final String MESSAGE)
                {
                    messaging.MessageOutputHandler message_output_handler = new messaging.MessageOutputHandler(SOCKET, MESSAGE);

                    message_output_handler.run();
                }
            }
        }

        public static class RSACompliant extends WebExpress
        {
            public static final Integer DEFAULT_PORT   = 7743;
            public static final String  DEFAULT_THREAD = "WEBEXPRESS_RSA_SERVER";

            protected final RSACompliant.MessageOutputHandler RSA_MESSAGE_OUTPUT_HANDLER = new RSACompliant.MessageOutputHandler();

            public messaging.MessageQueueSorter MESSAGE_QUEUE_SORTER;
            public messaging.MessageQueue       MESSAGE_QUEUE;
            public java.net.Socket              SOCKET;

            public final encryption.module.rsa.EncryptionModuleRSA ENCRYPTION_MODULE =
                new encryption.module.rsa.EncryptionModuleRSA();

            public RSACompliant(final String HOST, final Integer PORT, final String THREAD_NAME, final Boolean TELNET_PROXY_ENABLED)
            {
                if (HOST == null || PORT == null || THREAD_NAME == null || TELNET_PROXY_ENABLED == null)
                    throw new SecurityException("//bodi/connect");

                super(HOST, PORT, THREAD_NAME, TELNET_PROXY_ENABLED);

                this.HOST        = HOST;
                this.PORT        = PORT;
                this.MESSAGE_QUEUE        = new messaging.MessageQueue(this);
                this.MESSAGE_QUEUE_SORTER = new messaging.MessageQueueSorter(this);
                this.setName(THREAD_NAME);

                CommonRails.printSystemComponent(this, this.hashCode(),
                    ". RSACompliant starting on " + HOST + ":" + PORT + " .");
            }

            public RSACompliant() {}

            protected static class MessageOutputHandler
            {
                public java.net.Socket SOCKET;

                public MessageOutputHandler()
                {
                    CommonRails.printSystemComponent(this, this.hashCode(), ". RSACompliant MessageOutputHandler starts .");
                }

                public void send_message(final String MESSAGE)
                {
                    if (MESSAGE == null) throw new SecurityException("//bodi/connect");
                    messaging.MessageOutputHandler h = new messaging.MessageOutputHandler(SOCKET, MESSAGE);
                    h.run();
                }

                public void send_message(final StringBuffer BUFFER)
                {
                    if (BUFFER == null) throw new SecurityException("//bodi/connect");
                    messaging.MessageOutputHandler h = new messaging.MessageOutputHandler(SOCKET, BUFFER);
                    h.run();
                }
            }
        }

        public static class DSACompliant extends WebExpress
        {
            public static final Integer DEFAULT_PORT   = 7744;
            public static final String  DEFAULT_THREAD = "WEBEXPRESS_DSA_SERVER";

            protected final DSACompliant.MessageOutputHandler DSA_MESSAGE_OUTPUT_HANDLER = new DSACompliant.MessageOutputHandler();

            public messaging.MessageQueueSorter MESSAGE_QUEUE_SORTER;
            public messaging.MessageQueue       MESSAGE_QUEUE;
            public java.net.Socket              SOCKET;

            public final encryption.module.dsa.EncryptionModuleDSA ENCRYPTION_MODULE =
                new encryption.module.dsa.EncryptionModuleDSA();

            public DSACompliant(final String HOST, final Integer PORT, final String THREAD_NAME, final Boolean TELNET_PROXY_ENABLED)
            {
                if (HOST == null || PORT == null || THREAD_NAME == null || TELNET_PROXY_ENABLED == null)
                    throw new SecurityException("//bodi/connect");

                super(HOST, PORT, THREAD_NAME, TELNET_PROXY_ENABLED);

                this.HOST              = HOST;
                this.PORT              = PORT;
                this.MESSAGE_QUEUE        = new messaging.MessageQueue(this);
                this.MESSAGE_QUEUE_SORTER = new messaging.MessageQueueSorter(this);
                this.setName(THREAD_NAME);

                CommonRails.printSystemComponent(this, this.hashCode(),
                    ". DSACompliant starting on " + HOST + ":" + PORT + " .");
            }

            public DSACompliant() {}

            protected static class MessageOutputHandler
            {
                public java.net.Socket SOCKET;

                public MessageOutputHandler()
                {
                    CommonRails.printSystemComponent(this, this.hashCode(), ". DSACompliant MessageOutputHandler starts .");
                }

                public void send_message(final String MESSAGE)
                {
                    if (MESSAGE == null) throw new SecurityException("//bodi/connect");
                    messaging.MessageOutputHandler h = new messaging.MessageOutputHandler(SOCKET, MESSAGE);
                    h.run();
                }

                public void send_message(final StringBuffer BUFFER)
                {
                    if (BUFFER == null) throw new SecurityException("//bodi/connect");
                    messaging.MessageOutputHandler h = new messaging.MessageOutputHandler(SOCKET, BUFFER);
                    h.run();
                }
            }
        }

        public static class BitcoinCompliant extends WebExpress
        {
            protected BitcoinCompliant.MessageOutputHandler bitcoin_message_output_handler = new BitcoinCompliant.MessageOutputHandler();

            public messaging.MessageQueueSorter message_queue_sorter = new messaging.MessageQueueSorter(this);

            public MessageQueue message_queue = new MessageQueue(this);

            public Socket socket;

            public BitcoinCompliant(final String HOST, final Integer PORT, final String THREAD_NAME, final Boolean TELNET_PROXY_ENABLED)
            {
                if(HOST==null || PORT==null || THREAD_NAME==null || TELNET_PROXY_ENABLED==null) throw new SecurityException("//bodi/connect");

                super(HOST, PORT, THREAD_NAME, TELNET_PROXY_ENABLED);

                this.HOST = HOST;

                this.PORT = PORT;

                this.setName(THREAD_NAME);
            }

            public BitcoinCompliant()
            {
                CommonRails.printSystemComponent(this, this.hashCode(), ". BitcoinCompliant starts .");
            }

            protected static class MessageOutputRecord
            {
                public MessageOutputRecord()
                {
                    CommonRails.printSystemComponent(this, this.hashCode(), ". BitcoinCompliant MessageOutputRecord loads .");
                }
            }

            protected static class MessageOutputHandler
            {
                public Socket SOCKET;

                public MessageOutputHandler()
                {
                    CommonRails.printSystemComponent(this, this.hashCode(), ". BitcoinCompliant MessageOutputHandler starts .");
                }

                public void send_message(final StringBuffer BUFFER)
                {
                    if(BUFFER==null) throw new SecurityException("//bodi/connect");

                    messaging.MessageOutputHandler message_output_handler = new messaging.MessageOutputHandler(SOCKET, BUFFER);

                    message_output_handler.run();
                }

                public void send_message(final String MESSAGE)
                {
                    if(MESSAGE==null) throw new SecurityException("//bodi/connect");

                    messaging.MessageOutputHandler message_output_handler = new messaging.MessageOutputHandler(SOCKET, MESSAGE);

                    message_output_handler.run();
                }
            }

            public static class MessageQueueSorter extends Thread
            {
                protected String HASH = "0xDA717018470E213F";

                protected WebExpress WEB_EXPRESS;

                public MessageQueueSorter(final WebExpress WEB_EXPRESS)
                {
                    if(WEB_EXPRESS==null) throw new SecurityException("//bodi/connect");

                    this.WEB_EXPRESS = WEB_EXPRESS;

                    this.setName("MessageQueueSorter");
                }

                @Override
                public void run()
                {
                    CommonRails.printSystemComponent(this, this.hashCode(), ". WebExpress MessageQueueSorter starts .");

                    while(true)
                    {
                        MessageQueue MESSAGE_QUEUE = this.WEB_EXPRESS.MESSAGE_QUEUE;

                        try
                        {
                            synchronized (MESSAGE_QUEUE)
                            {
                                while (MESSAGE_QUEUE.MESSAGES.size() == 0)
                                {
                                    try { MESSAGE_QUEUE.wait(); } catch (InterruptedException ie) { Thread.currentThread().interrupt(); return; }
                                }

                                while (MESSAGE_QUEUE.MESSAGES.size() > 0)
                                {
                                    MessageQueue.Message message = MESSAGE_QUEUE.MESSAGES.remove(0);

                                    try
                                    {
                                        if(SocketUtils.isConnected(message.SOCKET))
                                        {
                                            BufferedWriter writer = this.WEB_EXPRESS.TELNET_COMMUNICATION_PROXY.writer;

                                            CommonRails.printSystemComponent(this, this.hashCode(), ". WebExpress MessageQueueSorter sending to Telnet message Message: " + message.MESSAGE_BUFFER + " .");

                                            writer.write("Message: "+message.MESSAGE_BUFFER +"\n");

                                            CommonRails.printSystemComponent(this, this.hashCode(),". WebExpress MessageQueueSorter sending to Telnet message Date: " + message.TIME_STAMP + " .");

                                            writer.write("[Date]: " + message.TIME_STAMP +"\n");

                                            CommonRails.printSystemComponent(this, this.hashCode(), ". WebExpress MessageQueueSorter sending to Telnet message IP Address: " + message.INTERNET_ADDRESS + " .");

                                            writer.write("[IP Address]: " + message.INTERNET_ADDRESS +"\n");

                                            CommonRails.printSystemComponent(this, this.hashCode(),". WebExpress MessageQueueSorter >> sending to Telnet message Socket: " + message.SOCKET + " .");

                                            writer.write("[Socket]: " + message.SOCKET.toString()+"\n");

                                            writer.flush();

                                            MESSAGE_QUEUE.remove(message);
                                        }
                                    }
                                    catch (SocketTimeoutException ste)
                                    {
                                        try
                                        {
                                            message.SOCKET.close();
                                        }
                                        catch (Exception e)
                                        {
                                            ExceptionHandler.dispatch(e);
                                            CurrentConnections connections = this.WEB_EXPRESS.CURRENT_CONNECTIONS;

                                            connections.remove(message.CONNECTION);

                                            EnglishArithemeter arithemeter = new EnglishArithemeter(connections.size());

                                            CommonRails.printSystemComponent(this, this.hashCode(), ". WebExpress MessageQueueSorter >> dropped connection "+message.SOCKET +" - new connection count "+arithemeter.result.arithemetic +" : "+arithemeter.result.numeral +" .");
                                        }

                                        this.WEB_EXPRESS.CURRENT_CONNECTIONS.remove(message.SOCKET);

                                        break;
                                    }
                                    catch (IOException e)
                                    {
                                        ExceptionHandler.dispatch(e);
                                        CommonRails.printSystemComponent(this, this.hashCode(),". WebExpress MessageQueueSorter socket connection closed Socket: " + message.INTERNET_ADDRESS + " .");
                                    }

                                    try
                                    {
                                        BufferedReader reader = this.WEB_EXPRESS.TELNET_COMMUNICATION_PROXY.reader;

                                        if(SocketUtils.isConnected(message.SOCKET))
                                        {
                                            BufferedWriter writer = new BufferedWriter(new OutputStreamWriter(message.SOCKET.getOutputStream()));

                                            String line = null;

                                            while((line=reader.readLine())!=null)
                                            {
                                                if(SocketUtils.isConnected(message.SOCKET))
                                                {
                                                    CommonRails.printSystemComponent(this, this.hashCode(),". WebExpress MessageQueueSorter received from active Telnet session "+ WebExpress.REMOTE_SITE+":"+ WebExpress.REMOTE_PORT+" message "+line+" .");

                                                    writer.write(line+"\n");

                                                    writer.flush();
                                                }
                                                else
                                                {
                                                    CurrentConnections connections = this.WEB_EXPRESS.CURRENT_CONNECTIONS;

                                                    connections.remove(message.CONNECTION);

                                                    EnglishArithemeter arithemeter = new EnglishArithemeter(connections.size());

                                                    CommonRails.printSystemComponent(this, this.hashCode(),". WebExpress MessageQueueSorter dropped connection "+message.SOCKET +" - new connection count "+arithemeter.result.arithemetic+" : "+arithemeter.result.numeral+" .");

                                                    break;
                                                }
                                            }
                                        }
                                    }
                                    catch (Exception e)
                                    {
                                        ExceptionHandler.dispatch(e);
                                        CommonRails.printSystemComponent(this, this.hashCode(),". WebExpress MessageQueueSorter >> dropped connection "+message.SOCKET +" .");
                                    }
                                }
                            }
                        }
                        catch (Exception e)
                        {
                            ExceptionHandler.dispatch(e);
                            e.printStackTrace(System.err);
                        }
                    }
                }

                public synchronized void addMessage(final MessageQueue.Message MESSAGE)
                {
                    if(MESSAGE==null) throw new SecurityException("//bodi/connect");

                    CommonRails.printSystemComponent(this, this.hashCode(), ". WebExpress addMessage MESSAGE queue size before "+this.getMessageQueueSize()+" .");

                    this.WEB_EXPRESS.MESSAGE_QUEUE.add(MESSAGE);

                    CommonRails.printSystemComponent(this, this.hashCode(), ". WebExpress addMessage MESSAGE queue size after "+this.getMessageQueueSize()+" .");
                }

                public synchronized MessageQueue getMessageQueue()
                {
                    return this.WEB_EXPRESS.MESSAGE_QUEUE;
                }

                public synchronized Integer getMessageQueueSize()
                {
                    return this.WEB_EXPRESS.MESSAGE_QUEUE.MESSAGES.size();
                }
            }
        }
    }
}
