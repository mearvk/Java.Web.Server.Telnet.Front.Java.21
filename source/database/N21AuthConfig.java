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
 * ensureMysqlRunning() checks systemctl status, starts if needed, then tests JDBC login.
 */
public class N21AuthConfig
{
    public final String  HOST;

    public final int     PORT;
    public final String  USERNAME;
    public final String  PASSWORD;
    public final boolean USESUDO;

    private static final String AUTH_FILE = "authentication/mysql.auth.xml";

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
                    ". systemctl status mysql — MySQL NOT INSTALLED on this system .",
                    ColorPalette.COLOR_STANDARD_RED);
                haltWithException(new RuntimeException("MySQL not installed — systemctl reports not-found"));
                return;
            }
            else if (running)
            {
                CommonRails.printSystemComponent(this, this.hashCode(),
                    ". SYSTEMCTL status mysql — active (running) .",
                    ColorPalette.COLOR_LIME_GREEN);
            }
            else
            {
                CommonRails.printSystemComponent(this, this.hashCode(),
                    ". SYSTEMCTL status mysql — inactive / stopped .",
                    ColorPalette.COLOR_STANDARD_RED);

                if (USESUDO)
                {
                    new ProcessBuilder("sudo", "systemctl", "start", "mysql").inheritIO().start().waitFor();

                    Process recheck = new ProcessBuilder("systemctl", "is-active", "--quiet", "mysql").start();
                    recheck.waitFor();
                    boolean nowRunning = (recheck.exitValue() == 0);

                    if (nowRunning)
                    {
                        CommonRails.printSystemComponent(this, this.hashCode(),
                            ". SYSTEMCTL start mysql — now running .",
                            ColorPalette.COLOR_LIME_GREEN);
                    }
                    else
                    {
                        CommonRails.printSystemComponent(this, this.hashCode(),
                            ". SYSTEMCTL start mysql — FAILED to start .",
                            ColorPalette.COLOR_STANDARD_RED);
                        haltWithException(new RuntimeException("systemctl start mysql failed — service did not become active"));
                    }
                }
                else
                {
                    haltWithException(new RuntimeException("MySQL inactive/stopped and use-sudo=false — cannot auto-start"));
                }
            }
        }
        catch (Exception e)
        {
            CommonRails.printSystemComponent(this, this.hashCode(),
                ". SYSTEMCTL status mysql — check failed: " + e.getMessage() + " .",
                ColorPalette.COLOR_STANDARD_RED);
            haltWithException(e);
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
