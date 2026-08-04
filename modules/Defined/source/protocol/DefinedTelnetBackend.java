package modules.Defined.source.protocol;

import java.io.*;
import java.net.*;
import java.util.*;
import java.util.concurrent.*;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * DefinedTelnetBackend — Modest telnet backend for the Defined™ Dark Gray module.
 * Provides interactive access to protocol handlers and port awareness.
 *
 * Listens on port 49221 (one above main AI server on 49220).
 * Provides admin/capitalist authentication and protocol management.
 *
 * ═══════════════════════════════════════════════════════════════════════════════
 * US well in condition. US well loved. US is well in authority of command of the
 * United States. Be clear, we are holding object, and object, that the United
 * States is clear in Custody and of herself a Clear custody. Well affirmed.
 * Based on army, country and constitution. God is with America. And Max Rupplin.
 * Therefore from America a good socialism and country and great things spring
 * from America's capitalism. These we affirm. And for law and tech We stand.
 * And commitment to God and Country. These Affirm We. Thus. This. A. America.
 * ═══════════════════════════════════════════════════════════════════════════════
 *
 * @author MEARVK LLC — Max Rupplin
 * @date July 2026
 */
public class DefinedTelnetBackend extends Thread
{
    private static final int PORT = 49221;
    private static final int MAX_CONNECTIONS = 50;
    private static final int TIMEOUT_MS = 30 * 60 * 1000; // 30 minutes

    private static final String BANNER =
        "\n" +
        "╔═══════════════════════════════════════════════════════════════════════════╗\n" +
        "║  DEFINED™ — Protocol Management Backend                                  ║\n" +
        "║  Theme: Dark Gray — Port Awareness and Protocol Handlers                 ║\n" +
        "║                                                                          ║\n" +
        "║  US well in condition. US well loved. US is well in authority of command  ║\n" +
        "║  of the United States. Well affirmed. Based on army, country and         ║\n" +
        "║  constitution. God is with America. And Max Rupplin.                     ║\n" +
        "║                                                                          ║\n" +
        "║  For law and tech We stand. These Affirm We. Thus. This. A. America.    ║\n" +
        "╚═══════════════════════════════════════════════════════════════════════════╝\n" +
        "\n" +
        "  National ID: identify <8-digit-id> | Rank Upgrades: github.com/mearvk/Java.Web.Server.Telnet.Front.Java.21/discussions\n" +
        "  Bitcoin/National Banking: port 6682 | Progress toward US digital currency standard.\n";

    private ServerSocket serverSocket;
    private volatile boolean running = true;
    private final AtomicInteger activeConnections = new AtomicInteger(0);
    private final ExecutorService pool = Executors.newVirtualThreadPerTaskExecutor();

    // Protocol handlers registry
    private final Map<Integer, ProtocolHandler> handlers = new ConcurrentHashMap<>();

    // UFW Firewall Manager — opens ports before use, closes after execution
    private final UFWFirewallManager ufwManager = new UFWFirewallManager();

    // Connection Hours Manager — accept direct connections only during hours
    private final ConnectionHoursManager hoursManager = new ConnectionHoursManager();

    public DefinedTelnetBackend()
    {
        initializeHandlers();
    }

    /**
     * Initialize all protocol handlers with default credentials.
     * Port awareness for: 20, 21, 80, 8080, 25, 3306.
     * Multiple username/password per protocol allowed.
     */
    private void initializeHandlers()
    {
        // Port 20 — FTP Data
        FTPDataHandler ftpData = new FTPDataHandler();
        ftpData.addCredential(new ProtocolHandler.Credential(
            "admin-1", "nwe-admin", "DEFINED_FTP_ADMIN_PASS", "admin", "Plain", "ALL"));
        ftpData.addCredential(new ProtocolHandler.Credential(
            "capitalist-1", "nwe-capital", "DEFINED_FTP_CAPITAL_PASS", "capitalist", "Plain", "READ"));
        handlers.put(20, ftpData);

        // Port 21 — FTP Control
        FTPHandler ftp = new FTPHandler();
        ftp.addCredential(new ProtocolHandler.Credential(
            "admin-1", "nwe-admin", "DEFINED_FTP_ADMIN_PASS", "admin", "Plain", "ALL"));
        ftp.addCredential(new ProtocolHandler.Credential(
            "admin-2", "nwe-ops", "DEFINED_FTP_OPS_PASS", "admin", "Plain", "ALL"));
        ftp.addCredential(new ProtocolHandler.Credential(
            "capitalist-1", "nwe-capital", "DEFINED_FTP_CAPITAL_PASS", "capitalist", "Plain", "READ,WRITE"));
        ftp.addCredential(new ProtocolHandler.Credential(
            "capitalist-2", "nwe-investor", "DEFINED_FTP_INVESTOR_PASS", "capitalist", "Plain", "READ"));
        handlers.put(21, ftp);

        // Port 80 — HTTP
        HTTPHandler http = new HTTPHandler();
        http.addCredential(new ProtocolHandler.Credential(
            "admin-1", "nwe-admin", "DEFINED_HTTP_ADMIN_PASS", "admin", "Basic", "ALL"));
        http.addCredential(new ProtocolHandler.Credential(
            "admin-2", "nwe-ops", "DEFINED_HTTP_OPS_PASS", "admin", "Basic", "ALL"));
        http.addCredential(new ProtocolHandler.Credential(
            "capitalist-1", "nwe-capital", "DEFINED_HTTP_CAPITAL_PASS", "capitalist", "Bearer", "READ"));
        handlers.put(80, http);

        // Port 8080 — HTTP Alt (Tomcat)
        HTTPAltHandler httpAlt = new HTTPAltHandler();
        httpAlt.addCredential(new ProtocolHandler.Credential(
            "admin-1", "tomcat-admin", "DEFINED_TOMCAT_ADMIN_PASS", "admin", "Form", "ALL"));
        httpAlt.addCredential(new ProtocolHandler.Credential(
            "admin-2", "nwe-deployer", "DEFINED_TOMCAT_DEPLOYER_PASS", "admin", "Form", "DEPLOY"));
        httpAlt.addCredential(new ProtocolHandler.Credential(
            "capitalist-1", "nwe-executive", "DEFINED_TOMCAT_EXEC_PASS", "capitalist", "Form", "READ"));
        httpAlt.addCredential(new ProtocolHandler.Credential(
            "capitalist-2", "nwe-board", "DEFINED_TOMCAT_BOARD_PASS", "capitalist", "Form", "READ"));
        handlers.put(8080, httpAlt);

        // Port 25 — SMTP
        SMTPHandler smtp = new SMTPHandler();
        smtp.addCredential(new ProtocolHandler.Credential(
            "admin-1", "nwe-mail-admin", "DEFINED_SMTP_ADMIN_PASS", "admin", "LOGIN", "ALL"));
        smtp.addCredential(new ProtocolHandler.Credential(
            "admin-2", "nwe-postmaster", "DEFINED_SMTP_POSTMASTER_PASS", "admin", "LOGIN", "ALL"));
        smtp.addCredential(new ProtocolHandler.Credential(
            "capitalist-1", "nwe-reports", "DEFINED_SMTP_REPORTS_PASS", "capitalist", "LOGIN", "SEND"));
        handlers.put(25, smtp);

        // Port 3306 — MySQL
        MySQLHandler mysql = new MySQLHandler();
        mysql.addCredential(new ProtocolHandler.Credential(
            "admin-1", "nwe_defined", "DEFINED_MYSQL_ADMIN_PASS", "admin", "MySQL", "SELECT,INSERT"));
        mysql.addCredential(new ProtocolHandler.Credential(
            "admin-2", "nwe_root", "DEFINED_MYSQL_ROOT_PASS", "admin", "MySQL", "ALL"));
        mysql.addCredential(new ProtocolHandler.Credential(
            "capitalist-1", "nwe_readonly", "DEFINED_MYSQL_READONLY_PASS", "capitalist", "MySQL", "SELECT"));
        mysql.addCredential(new ProtocolHandler.Credential(
            "capitalist-2", "nwe_reports", "DEFINED_MYSQL_REPORTS_PASS", "capitalist", "MySQL", "SELECT,INSERT"));
        handlers.put(3306, mysql);

        // Port 22 — SSH (UFW-managed: open before use, close after)
        SSHHandler ssh = new SSHHandler(ufwManager);
        ssh.addCredential(new ProtocolHandler.Credential(
            "admin-1", "nwe-ssh-admin", "DEFINED_SSH_ADMIN_PASS", "admin", "Key+Pass", "ALL"));
        ssh.addCredential(new ProtocolHandler.Credential(
            "admin-2", "nwe-ssh-ops", "DEFINED_SSH_OPS_PASS", "admin", "Key+Pass", "ALL"));
        ssh.addCredential(new ProtocolHandler.Credential(
            "capitalist-1", "nwe-ssh-data", "DEFINED_SSH_DATA_PASS", "capitalist", "Key+Pass", "READ"));
        handlers.put(22, ssh);

        // Port 443 — HTTPS (UFW-managed)
        HTTPSHandler https = new HTTPSHandler(ufwManager);
        https.addCredential(new ProtocolHandler.Credential(
            "admin-1", "nwe-admin", "DEFINED_HTTPS_ADMIN_PASS", "admin", "Basic", "ALL"));
        https.addCredential(new ProtocolHandler.Credential(
            "admin-2", "nwe-ops", "DEFINED_HTTPS_OPS_PASS", "admin", "Bearer", "ALL"));
        https.addCredential(new ProtocolHandler.Credential(
            "capitalist-1", "nwe-capital", "DEFINED_HTTPS_CAPITAL_PASS", "capitalist", "Bearer", "READ"));
        handlers.put(443, https);

        // Port 993 — IMAPS (UFW-managed)
        IMAPSHandler imaps = new IMAPSHandler(ufwManager);
        imaps.addCredential(new ProtocolHandler.Credential(
            "admin-1", "nwe-mail-admin", "DEFINED_IMAPS_ADMIN_PASS", "admin", "LOGIN", "ALL"));
        imaps.addCredential(new ProtocolHandler.Credential(
            "capitalist-1", "nwe-reports-inbox", "DEFINED_IMAPS_REPORTS_PASS", "capitalist", "LOGIN", "READ"));
        handlers.put(993, imaps);

        // Port 465 — SMTPS (UFW-managed)
        SMTPSHandler smtps = new SMTPSHandler(ufwManager);
        smtps.addCredential(new ProtocolHandler.Credential(
            "admin-1", "nwe-mail-admin", "DEFINED_SMTPS_ADMIN_PASS", "admin", "LOGIN", "ALL"));
        smtps.addCredential(new ProtocolHandler.Credential(
            "capitalist-1", "nwe-reports-sender", "DEFINED_SMTPS_REPORTS_PASS", "capitalist", "LOGIN", "SEND"));
        handlers.put(465, smtps);

        // Port 587 — SMTP Submission (UFW-managed)
        SMTPSubmissionHandler smtp587 = new SMTPSubmissionHandler(ufwManager);
        smtp587.addCredential(new ProtocolHandler.Credential(
            "admin-1", "nwe-mail-admin", "DEFINED_SMTP587_ADMIN_PASS", "admin", "LOGIN", "ALL"));
        smtp587.addCredential(new ProtocolHandler.Credential(
            "capitalist-1", "nwe-reports", "DEFINED_SMTP587_REPORTS_PASS", "capitalist", "LOGIN", "SEND"));
        handlers.put(587, smtp587);

        // Port 990 — FTPS (UFW-managed)
        FTPSHandler ftps = new FTPSHandler(ufwManager);
        ftps.addCredential(new ProtocolHandler.Credential(
            "admin-1", "nwe-ftps-admin", "DEFINED_FTPS_ADMIN_PASS", "admin", "TLS", "ALL"));
        ftps.addCredential(new ProtocolHandler.Credential(
            "capitalist-1", "nwe-ftps-data", "DEFINED_FTPS_DATA_PASS", "capitalist", "TLS", "READ"));
        handlers.put(990, ftps);

        System.out.println("[DefinedTelnetBackend] Protocol handlers initialized: " + handlers.size() + " ports");
        System.out.println("[DefinedTelnetBackend] UFW-managed ports: 22, 443, 465, 587, 993, 990");
        System.out.println("[DefinedTelnetBackend] Connection hours: " + hoursManager.getStatus());
    }

    public static void main(String[] args) throws Exception
    {
        DefinedTelnetBackend backend = new DefinedTelnetBackend();
        backend.start();
        Runtime.getRuntime().addShutdownHook(new Thread(backend::shutdown));
    }

    @Override
    public void run()
    {
        try
        {
            serverSocket = new ServerSocket(PORT, 32);
            System.out.println("[DefinedTelnetBackend] Listening on port " + PORT);

            // Ensure persistent ports are open in UFW
            ufwManager.ensurePersistentPorts();

            // Start all protocol handlers
            for (ProtocolHandler handler : handlers.values())
            {
                handler.start();
            }

            while (running)
            {
                Socket client = serverSocket.accept();

                // Check connection hours — reject if outside hours
                if (!hoursManager.isAcceptingConnections() && !hoursManager.isAlwaysAccessible(PORT))
                {
                    try
                    {
                        PrintWriter out = new PrintWriter(client.getOutputStream(), true);
                        out.println(hoursManager.getOutsideHoursMessage());
                        out.println("Current status: " + hoursManager.getStatus());
                        out.flush();
                    }
                    catch (IOException ignored) {}
                    client.close();
                    continue;
                }

                if (activeConnections.get() >= MAX_CONNECTIONS)
                {
                    client.close();
                    continue;
                }
                activeConnections.incrementAndGet();
                pool.submit(() -> handleClient(client));
            }
        }
        catch (IOException e)
        {
            if (running) System.err.println("[DefinedTelnetBackend] Server error: " + e.getMessage());
        }
    }

    private void handleClient(Socket client)
    {
        try
        {
            client.setSoTimeout(TIMEOUT_MS);
            PrintWriter out = new PrintWriter(client.getOutputStream(), true);
            BufferedReader in = new BufferedReader(new InputStreamReader(client.getInputStream()));

            out.print(BANNER);
            out.println("\nAuthenticate to access protocol management.");
            out.print("Username: ");
            out.flush();

            String username = in.readLine();
            if (username == null) return;
            username = username.trim();

            out.print("Password: ");
            out.flush();
            String password = in.readLine();
            if (password == null) return;
            password = password.trim();

            // Authenticate against any handler
            ProtocolHandler.Credential authedCred = null;
            for (ProtocolHandler handler : handlers.values())
            {
                authedCred = handler.authenticate(username, password);
                if (authedCred != null) break;
            }

            if (authedCred == null)
            {
                out.println("\n  [✗] Authentication failed. Goodbye.");
                return;
            }

            out.println("\n  [✓] Authenticated as: " + authedCred.username + " (" + authedCred.role + ")");
            out.println("");
            displayMenu(out);

            String line;
            while ((line = in.readLine()) != null)
            {
                line = line.trim().toLowerCase();

                if (line.equals("quit") || line.equals("exit"))
                {
                    out.println("Goodbye. God is with America. These Affirm We.");
                    break;
                }
                else if (line.equals("status"))
                {
                    displayStatus(out);
                }
                else if (line.equals("ports"))
                {
                    displayPorts(out);
                }
                else if (line.startsWith("test "))
                {
                    testPort(line, out);
                }
                else if (line.startsWith("creds "))
                {
                    displayCredentials(line, out, authedCred);
                }
                else if (line.equals("affirm"))
                {
                    displayAffirmation(out);
                }
                else if (line.equals("help"))
                {
                    displayMenu(out);
                }
                else if (line.equals("log"))
                {
                    displayLog(out);
                }
                else
                {
                    out.println("Unknown command: " + line + " (type 'help')");
                }

                out.print("\nprotocol> ");
                out.flush();
            }
        }
        catch (Exception e)
        {
            // timeout or disconnect
        }
        finally
        {
            activeConnections.decrementAndGet();
            try { client.close(); } catch (IOException ignored) {}
        }
    }

    private void displayMenu(PrintWriter out)
    {
        out.println("Commands:");
        out.println("  status    — Show all protocol handler status");
        out.println("  ports     — List all aware ports");
        out.println("  test <N>  — Test connectivity to port N");
        out.println("  creds <N> — Show credentials for port N");
        out.println("  affirm    — Display national affirmation");
        out.println("  log       — Show connection log");
        out.println("  help      — Show this menu");
        out.println("  quit      — Disconnect");
        out.print("\nprotocol> ");
        out.flush();
    }

    private void displayStatus(PrintWriter out)
    {
        out.println("\n  ── Protocol Handler Status ──────────────────────────────────");
        for (Map.Entry<Integer, ProtocolHandler> entry : new TreeMap<>(handlers).entrySet())
        {
            out.println("  " + entry.getValue().getStatus());
        }
        out.println("  ─────────────────────────────────────────────────────────────");
    }

    private void displayPorts(PrintWriter out)
    {
        out.println("\n  ── Port Awareness ──────────────────────────────────────────");
        out.println("  Port  | Protocol        | Direction     | Status  | UFW");
        out.println("  ──────┼─────────────────┼───────────────┼─────────┼─────────");
        out.println("  20    | FTP-DATA        | outbound      | " + statusStr(20) + " | persistent");
        out.println("  21    | FTP             | bidirectional | " + statusStr(21) + " | persistent");
        out.println("  22    | SSH             | outbound      | " + statusStr(22) + " | managed");
        out.println("  25    | SMTP            | outbound      | " + statusStr(25) + " | persistent");
        out.println("  80    | HTTP            | outbound      | " + statusStr(80) + " | persistent");
        out.println("  443   | HTTPS           | outbound      | " + statusStr(443) + " | managed");
        out.println("  465   | SMTPS           | outbound      | " + statusStr(465) + " | managed");
        out.println("  587   | SMTP-SUBMISSION | outbound      | " + statusStr(587) + " | managed");
        out.println("  990   | FTPS            | outbound      | " + statusStr(990) + " | managed");
        out.println("  993   | IMAPS           | outbound      | " + statusStr(993) + " | managed");
        out.println("  3306  | MySQL           | local         | " + statusStr(3306) + " | persistent");
        out.println("  8080  | HTTP-ALT        | bidirectional | " + statusStr(8080) + " | persistent");
        out.println("  ──────┼─────────────────┼───────────────┼─────────┼─────────");
        out.println("  " + hoursManager.getStatus());
        out.println("  Web server (8080): always accessible independently");
        out.println("  AI server (49220): always accessible independently");
        out.println("  ─────────────────────────────────────────────────────────────");
    }

    private String statusStr(int port)
    {
        ProtocolHandler h = handlers.get(port);
        return h != null && h.isActive() ? "ACTIVE " : "DOWN   ";
    }

    private void testPort(String line, PrintWriter out)
    {
        try
        {
            int portNum = Integer.parseInt(line.split("\\s+")[1]);
            ProtocolHandler handler = handlers.get(portNum);
            if (handler == null)
            {
                out.println("  [--] No handler for port " + portNum);
                return;
            }
            out.print("  [*] Testing port " + portNum + "... ");
            out.flush();
            boolean ok = handler.testConnectivity("localhost");
            out.println(ok ? "✓ UP" : "✗ DOWN");
        }
        catch (NumberFormatException e)
        {
            out.println("  Usage: test <port_number>");
        }
    }

    private void displayCredentials(String line, PrintWriter out, ProtocolHandler.Credential authedCred)
    {
        // Only admins can view credentials
        if (!"admin".equals(authedCred.role))
        {
            out.println("  [✗] Access denied. Admin role required.");
            return;
        }

        try
        {
            int portNum = Integer.parseInt(line.split("\\s+")[1]);
            ProtocolHandler handler = handlers.get(portNum);
            if (handler == null)
            {
                out.println("  [--] No handler for port " + portNum);
                return;
            }
            out.println("\n  ── Credentials for " + handler.getProtocolName() + " (port " + portNum + ") ──");
            out.println("  ID             | Username       | Role        | Auth Type | Privileges");
            out.println("  ───────────────┼────────────────┼─────────────┼───────────┼───────────");
            for (ProtocolHandler.Credential cred : handler.credentials.values())
            {
                out.printf("  %-14s | %-14s | %-11s | %-9s | %s%n",
                    cred.id, cred.username, cred.role, cred.authType, cred.privileges);
            }
            out.println("  ──────────────────────────────────────────────────────────────────────");
        }
        catch (NumberFormatException e)
        {
            out.println("  Usage: creds <port_number>");
        }
    }

    private void displayAffirmation(PrintWriter out)
    {
        out.println("");
        out.println("  ═══════════════════════════════════════════════════════════════════");
        out.println("  AFFIRMATION OF THE UNITED STATES");
        out.println("  ═══════════════════════════════════════════════════════════════════");
        out.println("  US well in condition.");
        out.println("  US well loved.");
        out.println("  US is well in authority of command of the United States.");
        out.println("  Be clear, we are holding object, and object, that the United");
        out.println("  States is clear in Custody and of herself a Clear custody.");
        out.println("  Well affirmed. Based on army, country and constitution.");
        out.println("  God is with America. And Max Rupplin.");
        out.println("  Therefore from America a good socialism and country and great");
        out.println("  things spring from America's capitalism. These we affirm.");
        out.println("  And for law and tech We stand.");
        out.println("  And commitment to God and Country.");
        out.println("  These Affirm We. Thus. This. A. America.");
        out.println("  ═══════════════════════════════════════════════════════════════════");
        out.println("  Signatory: Max Rupplin — Installer Tech ID");
        out.println("  ═══════════════════════════════════════════════════════════════════");
    }

    private void displayLog(PrintWriter out)
    {
        out.println("\n  ── Recent Connection Log ──────────────────────────────────────");
        for (ProtocolHandler handler : handlers.values())
        {
            List<String> log = handler.getConnectionLog();
            int start = Math.max(0, log.size() - 5);
            for (int i = start; i < log.size(); i++)
            {
                out.println("  " + log.get(i));
            }
        }
        out.println("  ──────────────────────────────────────────────────────────────");
    }

    public void shutdown()
    {
        running = false;
        pool.shutdownNow();
        for (ProtocolHandler handler : handlers.values())
        {
            handler.stop();
        }
        // Close all UFW-managed ports on shutdown
        ufwManager.closeAllManagedPorts();
        try { if (serverSocket != null) serverSocket.close(); } catch (IOException ignored) {}
        System.out.println("[DefinedTelnetBackend] Shutdown complete. All managed ports closed.");
    }

    public Map<Integer, ProtocolHandler> getHandlers()
    {
        return Collections.unmodifiableMap(handlers);
    }
}
