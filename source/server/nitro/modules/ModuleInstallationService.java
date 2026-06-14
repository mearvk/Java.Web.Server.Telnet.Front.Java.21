package server.nitro.modules;

import commons.CommonRails;
import database.N21Store;
import exceptions.ExceptionHandler;
import server.nitro.NitroWebExpress;

import java.io.*;
import java.net.*;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.security.MessageDigest;
import java.util.HexFormat;
import java.util.concurrent.ConcurrentHashMap;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;

public class ModuleInstallationService extends Thread
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

            try
            {
                CLIENT.close();
            }
            catch (Exception ignored)
            {
                ignored.printStackTrace(System.err);
            }
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

            NitroWebExpress.Aspect.ModuleRegistry.register(new NitroWebExpress.Aspect.InstalledModule(NAME, dest, loader));

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
        boolean removed = NitroWebExpress.Aspect.ModuleRegistry.unload(NAME);

        String result = removed ? "unloaded" : "not-found";

        database.N21Store.storeModuleAction(SESSION.nationalId, NAME, "unload", SESSION.remoteIp, "", 0, "", SESSION.adminToken, result);

        CommonRails.printSystemComponent(this, this.hashCode(), ". ModuleInstallationService admin unload [" + NAME + "] result=" + result + " .");

        return removed ? "[unload] Module '" + NAME + "' unloaded." : "[unload] Module not found: " + NAME;
    }

    private String listModules()
    {
        ConcurrentHashMap<String, NitroWebExpress.Aspect.InstalledModule> all = NitroWebExpress.Aspect.ModuleRegistry.all();

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

        NitroWebExpress.Aspect.InstalledModule m = NitroWebExpress.Aspect.ModuleRegistry.get(MODULE);

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