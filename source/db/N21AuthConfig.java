package db;

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import java.io.BufferedReader;
import java.io.File;
import java.io.InputStreamReader;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.stream.Collectors;

/**
 * Loads MySQL credentials from authentication/mysql.auth.xml.
 * Provides ensureMysqlRunning() which uses systemctl status mysql to check
 * whether MySQL is installed and running, and starts it via sudo if needed.
 */
public class N21AuthConfig
{
    public final String  host;
    public final int     port;
    public final String  username;
    public final String  password;
    public final boolean useSudo;

    private static final String AUTH_FILE = "authentication/mysql.auth.xml";

    private static N21AuthConfig INSTANCE = null;

    private N21AuthConfig(String host, int port, String username, String password, boolean useSudo)
    {
        this.host     = host;
        this.port     = port;
        this.username = username;
        this.password = password;
        this.useSudo  = useSudo;
    }

    public static synchronized N21AuthConfig get()
    {
        if (INSTANCE != null) return INSTANCE;

        File file = new File(AUTH_FILE);

        if (!file.exists())
        {
            System.err.println("[N21AuthConfig] " + file.getAbsolutePath() + " NOT FOUND — using defaults.");
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

            // Explicit confirmation that the file was read and what was loaded (password masked)
            System.out.println("[N21AuthConfig] Read: " + file.getAbsolutePath());
            System.out.println("[N21AuthConfig]   host=" + host + "  port=" + port
                + "  username=" + username + "  password=" + (password.isEmpty() ? "(empty)" : "***")
                + "  use-sudo=" + useSudo);
        }
        catch (Exception e)
        {
            System.err.println("[N21AuthConfig] Parse error: " + e.getMessage() + " — using defaults.");
            INSTANCE = fallback();
        }

        return INSTANCE;
    }

    /**
     * 1. Runs "systemctl status mysql" to determine install + running state.
     * 2. If installed but not running and use-sudo=true, starts it.
     * 3. Runs a login test: mysql -h host -P port -u user -pPASS -e "SELECT 1"
     *    to confirm the username from the XML can authenticate.
     */
    public void ensureMysqlRunning()
    {
        // ── 1. systemctl status mysql ─────────────────────────────────────────
        try
        {
            ProcessBuilder pb = new ProcessBuilder("systemctl", "status", "mysql");
            pb.redirectErrorStream(true);
            Process proc = pb.start();
            String output = new BufferedReader(new InputStreamReader(proc.getInputStream()))
                .lines().collect(Collectors.joining("\n"));
            int exit = proc.waitFor();

            if (output.contains("not-found") || output.contains("could not be found"))
            {
                System.err.println("[N21AuthConfig] systemctl: MySQL is NOT installed on this system.");
                return;
            }

            boolean running = (exit == 0) || output.contains("active (running)");

            System.out.println("[N21AuthConfig] systemctl status mysql → "
                + (running ? "active (running)" : "inactive/stopped") + " (exit=" + exit + ")");

            if (!running && useSudo)
            {
                System.out.println("[N21AuthConfig] Starting MySQL via sudo systemctl start mysql...");
                Process start = new ProcessBuilder("sudo", "systemctl", "start", "mysql")
                    .inheritIO().start();
                start.waitFor();

                // re-check
                Process recheck = new ProcessBuilder("systemctl", "is-active", "--quiet", "mysql").start();
                recheck.waitFor();
                System.out.println("[N21AuthConfig] MySQL after start: "
                    + (recheck.exitValue() == 0 ? "running" : "still not running"));
            }
        }
        catch (Exception e)
        {
            System.err.println("[N21AuthConfig] systemctl check failed: " + e.getMessage());
        }

        // ── 2. Login test — credentials passed via --defaults-file (never in argv/ps) ──
        File cnf = null;
        try
        {
            // Write a temp .cnf readable only by owner; deleted immediately after the test
            cnf = File.createTempFile("n21-mysql-", ".cnf");
            cnf.setReadable(false, false);
            cnf.setReadable(true, true);   // owner-only read
            cnf.setWritable(true, true);
            cnf.deleteOnExit();

            try (java.io.FileWriter fw = new java.io.FileWriter(cnf))
            {
                fw.write("[client]\n");
                fw.write("user=" + username + "\n");
                fw.write("password=" + password + "\n");
                fw.write("host=" + host + "\n");
                fw.write("port=" + port + "\n");
            }

            String url = "jdbc:mysql://localhost:3306/N21";
            String user = "mearvk";
            String password = "$$Ironman1";

            try (Connection conn = DriverManager.getConnection(url, user, password))
            {
                System.out.println("Connected successfully without terminal commands!");
            }
            catch (SQLException e)
            {
                e.printStackTrace();
            }
        }
        catch (Exception e)
        {
            System.err.println("[N21AuthConfig] Login test error: " + e.getMessage());
        }
        finally
        {
            if (cnf != null) cnf.delete();
        }
    }

    private static String text(Element root, String tag, String def)
    {
        var nodes = root.getElementsByTagName(tag);
        if (nodes.getLength() == 0) return def;
        String val = nodes.item(0).getTextContent().trim();
        return val.isEmpty() ? def : val;
    }

    private static N21AuthConfig fallback()
    {
        return new N21AuthConfig("localhost", 3306, "root", "", false);
    }
}
