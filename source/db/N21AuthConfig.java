package db;

import commons.CommonRails;
import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import java.io.BufferedReader;
import java.io.File;
import java.io.InputStreamReader;
import java.sql.Connection;
import java.sql.DriverManager;
import java.util.stream.Collectors;

/**
 * Loads MySQL credentials from authentication/mysql.auth.xml.
 * ensureMysqlRunning() checks systemctl status, starts if needed, then tests JDBC login.
 */
public class N21AuthConfig
{
    public static final String COLOR_LIME_GREEN    = "\u001B[92m";
    public static final String COLOR_YELLOW        = "\u001B[93m";
    public static final String COLOR_STANDARD_RED  = "\u001B[91m";
    public static final String COLOR_RESET         = "\u001B[0m";

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

    /**
     * 1. systemctl status mysql — printed via CommonRails with lime/yellow/red OID color.
     * 2. sudo systemctl start mysql if not running and use-sudo=true.
     * 3. JDBC login test using credentials from mysql.auth.xml.
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

            boolean notInstalled = output.contains("not-found") || output.contains("could not be found");
            boolean running      = !notInstalled && ((exit == 0) || output.contains("active (running)"));

            if (notInstalled)
            {
                CommonRails.printSystemComponent(this, this.hashCode(),
                    COLOR_STANDARD_RED + ". systemctl status mysql — MySQL NOT INSTALLED on this system ." + COLOR_RESET);
                return;
            }
            else if (running)
            {
                CommonRails.printSystemComponent(this, this.hashCode(),
                    COLOR_LIME_GREEN + ". systemctl status mysql — active (running) ." + COLOR_RESET);
            }
            else
            {
                CommonRails.printSystemComponent(this, this.hashCode(),
                    COLOR_YELLOW + ". systemctl status mysql — inactive / stopped ." + COLOR_RESET);

                if (useSudo)
                {
                    new ProcessBuilder("sudo", "systemctl", "start", "mysql").inheritIO().start().waitFor();

                    Process recheck = new ProcessBuilder("systemctl", "is-active", "--quiet", "mysql").start();
                    recheck.waitFor();
                    boolean nowRunning = (recheck.exitValue() == 0);

                    CommonRails.printSystemComponent(this, this.hashCode(),
                        (nowRunning ? COLOR_LIME_GREEN : COLOR_STANDARD_RED)
                        + ". systemctl start mysql — " + (nowRunning ? "now running ." : "FAILED to start .") + COLOR_RESET);
                }
            }
        }
        catch (Exception e)
        {
            CommonRails.printSystemComponent(this, this.hashCode(),
                COLOR_STANDARD_RED + ". systemctl status mysql — check failed: " + e.getMessage() + " ." + COLOR_RESET);
        }

        // ── 2. JDBC login test using credentials from mysql.auth.xml ──────────
        try
        {
            String url = "jdbc:mysql://" + host + ":" + port
                + "/N21?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC&connectTimeout=3000";

            Class.forName("com.mysql.cj.jdbc.Driver");

            try (Connection conn = DriverManager.getConnection(url, username, password))
            {
                CommonRails.printSystemComponent(this, this.hashCode(),
                    COLOR_LIME_GREEN + ". MySQL JDBC login — user '" + username + "' authenticated successfully ." + COLOR_RESET);
            }
        }
        catch (Exception e)
        {
            CommonRails.printSystemComponent(this, this.hashCode(),
                COLOR_STANDARD_RED + ". MySQL JDBC login — user '" + username + "' FAILED: " + e.getMessage() + " ." + COLOR_RESET);
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
