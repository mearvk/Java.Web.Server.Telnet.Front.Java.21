package db;

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import java.io.File;

/**
 * Loads MySQL credentials and options from authentication/mysql.auth.xml.
 * If use-sudo is true, also attempts to start MySQL via sudo before connection.
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

        try
        {
            File file = new File(AUTH_FILE);

            if (!file.exists())
            {
                System.err.println("[N21AuthConfig] " + AUTH_FILE + " not found — using defaults.");
                return fallback();
            }

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

            System.out.println("[N21AuthConfig] Loaded from " + AUTH_FILE
                + " (host=" + host + ", port=" + port + ", user=" + username + ", sudo=" + useSudo + ")");
        }
        catch (Exception e)
        {
            System.err.println("[N21AuthConfig] Parse error: " + e.getMessage() + " — using defaults.");
            INSTANCE = fallback();
        }

        return INSTANCE;
    }

    /**
     * If use-sudo=true, attempt to start MySQL via sudo systemctl.
     * Non-fatal — if it fails the normal TCP/JDBC checks will catch it.
     */
    public void ensureMysqlRunning()
    {
        if (!useSudo) return;

        try
        {
            Process check = new ProcessBuilder("sudo", "systemctl", "is-active", "--quiet", "mysql")
                .start();
            check.waitFor();

            if (check.exitValue() != 0)
            {
                System.out.println("[N21AuthConfig] MySQL not active — starting with sudo...");
                Process start = new ProcessBuilder("sudo", "systemctl", "start", "mysql")
                    .inheritIO()
                    .start();
                start.waitFor();
            }
        }
        catch (Exception e)
        {
            System.err.println("[N21AuthConfig] sudo start failed: " + e.getMessage());
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
