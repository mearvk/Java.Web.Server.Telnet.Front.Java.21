package database;

import commons.CommonRails;
import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;

import commons.color.ColorPalette;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import java.io.BufferedReader;
import java.io.File;
import java.io.FileWriter;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.DriverManager;
import java.time.LocalDateTime;
import java.util.stream.Collectors;

/**
 * Loads MySQL credentials from authentication/mysql.auth.xml.
 * ensureMysqlRunning() checks Windows service status via sc/net, starts if needed, then tests JDBC login.
 */
public class N21AuthConfig
{
    public final String  HOST;

    public final int     PORT;
    public final String  USERNAME;
    public final String  PASSWORD;
    public final boolean USESUDO;

    private static final String AUTH_FILE = commons.AppRoot.resolveString("authentication/mysql.auth.xml");

    private static N21AuthConfig INSTANCE = null;

    private N21AuthConfig(final String HOST, final int PORT, final String USERNAME, final String PASSWORD, final boolean USESUDO)
    {
        this.HOST     = HOST;
        this.PORT     = PORT;
        this.USERNAME = USERNAME;
        this.PASSWORD = PASSWORD;
        this.USESUDO  = USESUDO;
    }

    public static synchronized N21AuthConfig get()
    {
        if (INSTANCE != null) return INSTANCE;

        File file = new File(AUTH_FILE);

        if (!file.exists())
        {
            INSTANCE = fallback();
            return INSTANCE;
        }

        try
        {
            DocumentBuilder builder = DocumentBuilderFactory.newInstance().newDocumentBuilder();
            Document doc = builder.parse(file);
            doc.getDocumentElement().normalize();
            Element root = doc.getDocumentElement();

            String  host     = text(root, "host",     "localhost");
            int     port     = Integer.parseInt(text(root, "port", "3306"));
            String  username = text(root, "username", "root");
            String  password = text(root, "password", "");
            boolean useSudo  = Boolean.parseBoolean(text(root, "use-sudo", "false"));

            INSTANCE = new N21AuthConfig(host, port, username, password, useSudo);
        }
        catch (Exception e)
        {
            INSTANCE = fallback();
        }

        return INSTANCE;
    }

    private static final boolean IS_WINDOWS = System.getProperty("os.name", "").toLowerCase().startsWith("win");

    /**
     * 1. Checks MySQL service status via sc query (Windows) or systemctl (Linux).
     * 2. Starts MySQL if not running and use-sudo=true.
     * 3. JDBC login test using credentials from mysql.auth.xml.
     */
    public void ensureMysqlRunning()
    {
        // ── 1. Discover MySQL service name and check status ───────────────────
        try
        {
            if (IS_WINDOWS)
                ensureMysqlWindows();
            else
                ensureMysqlLinux();
        }
        catch (Exception e)
        {
            CommonRails.printSystemComponent(this, this.hashCode(),
                ". MySQL service check failed: " + e.getMessage() + " .",
                ColorPalette.COLOR_STANDARD_RED);
            haltWithException(e);
        }

        // ── 1b. Verify mysqld daemon is reachable on port 3306 ─────────────────
        try (java.net.Socket sock = new java.net.Socket())
        {
            sock.connect(new java.net.InetSocketAddress("127.0.0.1", PORT), 3000);
            CommonRails.printSystemComponent(this, this.hashCode(),
                ". MYSQLD — daemon reachable on port " + PORT + " .",
                ColorPalette.COLOR_LIME_GREEN);
        }
        catch (Exception e)
        {
            CommonRails.printSystemComponent(this, this.hashCode(),
                ". MYSQLD — daemon NOT reachable on port " + PORT + ": " + e.getMessage() + " .",
                ColorPalette.COLOR_STANDARD_RED);
            haltWithException(new RuntimeException("mysqld not reachable on port " + PORT));
        }

        // ── 2. JDBC login test using credentials from mysql.auth.xml ──────────
        try
        {
            String url = "jdbc:mysql://" + HOST + ":" + PORT
                + "/N21?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC&connectTimeout=3000";

            Class.forName("com.mysql.cj.jdbc.Driver");

            try (Connection conn = DriverManager.getConnection(url, USERNAME, PASSWORD))
            {
                CommonRails.printSystemComponent(this, this.hashCode(),
                    ". MYSQL JDBC login — user '" + USERNAME + "' authenticated successfully .",
                    ColorPalette.COLOR_LIME_GREEN);
            }
        }
        catch (Exception e)
        {
            CommonRails.printSystemComponent(this, this.hashCode(),
                ". MYSQL JDBC login — user '" + USERNAME + "' FAILED: " + e.getMessage() + " .",
                ColorPalette.COLOR_STANDARD_RED);
            haltWithException(e);
        }
    }

    private void ensureMysqlWindows() throws Exception
    {
        // Find actual service name (MySQL80, MySQL84, etc.) via sc query state= all
        ProcessBuilder findPb = new ProcessBuilder("cmd.exe", "/c", "sc query state= all");
        findPb.redirectErrorStream(true);
        Process findProc = findPb.start();
        String allServices = new BufferedReader(new InputStreamReader(findProc.getInputStream()))
            .lines().collect(Collectors.joining("\n"));
        findProc.waitFor();

        String serviceName = null;
        for (String line : allServices.split("\n"))
        {
            if (line.toUpperCase().contains("SERVICE_NAME") && line.toUpperCase().contains("MYSQL"))
            {
                serviceName = line.split(":")[1].trim();
                break;
            }
        }

        if (serviceName == null)
        {
            CommonRails.printSystemComponent(this, this.hashCode(),
                ". sc query state= all — no MySQL service found on this system .",
                ColorPalette.COLOR_STANDARD_RED);
            haltWithException(new RuntimeException("MySQL not installed — no MySQL service registered"));
            return;
        }

        ProcessBuilder pb = new ProcessBuilder("cmd.exe", "/c", "sc", "query", serviceName);
        pb.redirectErrorStream(true);
        Process proc = pb.start();
        String output = new BufferedReader(new InputStreamReader(proc.getInputStream()))
            .lines().collect(Collectors.joining("\n"));
        proc.waitFor();

        boolean running = output.contains("RUNNING");

        if (running)
        {
            CommonRails.printSystemComponent(this, this.hashCode(),
                ". SC QUERY " + serviceName + " — RUNNING .",
                ColorPalette.COLOR_LIME_GREEN);
        }
        else
        {
            CommonRails.printSystemComponent(this, this.hashCode(),
                ". SC QUERY " + serviceName + " — STOPPED .",
                ColorPalette.COLOR_STANDARD_RED);

            if (USESUDO)
            {
                new ProcessBuilder("cmd.exe", "/c", "net", "start", serviceName).inheritIO().start().waitFor();

                Process recheck = new ProcessBuilder("cmd.exe", "/c", "sc", "query", serviceName).start();
                String recheckOut = new BufferedReader(new InputStreamReader(recheck.getInputStream()))
                    .lines().collect(Collectors.joining("\n"));
                recheck.waitFor();

                if (recheckOut.contains("RUNNING"))
                {
                    CommonRails.printSystemComponent(this, this.hashCode(),
                        ". NET START " + serviceName + " — now running .",
                        ColorPalette.COLOR_LIME_GREEN);
                }
                else
                {
                    CommonRails.printSystemComponent(this, this.hashCode(),
                        ". NET START " + serviceName + " — FAILED to start .",
                        ColorPalette.COLOR_STANDARD_RED);
                    haltWithException(new RuntimeException("net start " + serviceName + " failed — service did not become RUNNING"));
                }
            }
            else
            {
                haltWithException(new RuntimeException(serviceName + " stopped and use-sudo=false — cannot auto-start"));
            }
        }
    }

    private void ensureMysqlLinux() throws Exception
    {
        // Check if mysql/mysqld service is active via systemctl
        ProcessBuilder pb = new ProcessBuilder("bash", "-c", "systemctl is-active mysql || systemctl is-active mysqld");
        pb.redirectErrorStream(true);
        Process proc = pb.start();
        String output = new BufferedReader(new InputStreamReader(proc.getInputStream()))
            .lines().collect(Collectors.joining("\n")).trim();
        proc.waitFor();

        boolean running = "active".equals(output);

        if (running)
        {
            CommonRails.printSystemComponent(this, this.hashCode(),
                ". systemctl is-active mysql — RUNNING .",
                ColorPalette.COLOR_LIME_GREEN);
        }
        else
        {
            CommonRails.printSystemComponent(this, this.hashCode(),
                ". systemctl is-active mysql — STOPPED .",
                ColorPalette.COLOR_STANDARD_RED);

            if (USESUDO)
            {
                new ProcessBuilder("bash", "-c", "sudo systemctl start mysql || sudo systemctl start mysqld")
                    .inheritIO().start().waitFor();

                Process recheck = new ProcessBuilder("bash", "-c", "systemctl is-active mysql || systemctl is-active mysqld").start();
                String recheckOut = new BufferedReader(new InputStreamReader(recheck.getInputStream()))
                    .lines().collect(Collectors.joining("\n")).trim();
                recheck.waitFor();

                if ("active".equals(recheckOut))
                {
                    CommonRails.printSystemComponent(this, this.hashCode(),
                        ". sudo systemctl start mysql — now running .",
                        ColorPalette.COLOR_LIME_GREEN);
                }
                else
                {
                    CommonRails.printSystemComponent(this, this.hashCode(),
                        ". sudo systemctl start mysql — FAILED to start .",
                        ColorPalette.COLOR_STANDARD_RED);
                    haltWithException(new RuntimeException("systemctl start mysql failed — service did not become active"));
                }
            }
            else
            {
                haltWithException(new RuntimeException("mysql stopped and use-sudo=false — cannot auto-start"));
            }
        }
    }

    private void haltWithException(Exception cause)
    {
        try (PrintWriter pw = new PrintWriter(new FileWriter("exception.log", true)))
        {
            pw.println("[" + LocalDateTime.now() + "] FATAL — N21AuthConfig startup failure");
            cause.printStackTrace(pw);
        }
        catch (Exception ignored) {}
        System.exit(1);
    }

    private static String text(final Element ROOT, final String TAG, final String DEF)
    {
        var nodes = ROOT.getElementsByTagName(TAG);
        if (nodes.getLength() == 0) return DEF;
        String val = nodes.item(0).getTextContent().trim();
        return val.isEmpty() ? DEF : val;
    }

    private static N21AuthConfig fallback()
    {
        return new N21AuthConfig("localhost", 3306, "root", "", false);
    }
}
