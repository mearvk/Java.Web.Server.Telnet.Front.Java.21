package configuration;

import commons.CommonRails;
import commons.color.ColorPalette;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.NodeList;

import javax.xml.parsers.DocumentBuilderFactory;
import java.io.File;
import java.io.FileWriter;
import java.io.PrintWriter;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

/**
 * NweConfig — loads configuration/nwe-config.xml at startup.
 *
 * Provides:
 *   - isEnabled(serverId)   inclusion decision for each &lt;server&gt; block
 *   - adminUsername()       initial administrator username
 *   - adminPassword()       initial administrator password
 *
 * Call NweConfig.load() once at the top of Main() before any service is
 * instantiated.  ModuleAdmin.PASSWORD is updated from the XML value so the
 * admin may log in to any TCP service with the configured credentials.
 */
public class NitroWebExpressConfig
{
    private static final String CONFIG_FILE = "configuration/nwe-config.xml";

    private static NitroWebExpressConfig INSTANCE;

    private final Map<String, Boolean> ENABLED = new HashMap<>();
    private final String ADMIN_USERNAME;
    private final String ADMIN_PASSWORD;
    private final String ANTIVIRUS_SCHEDULE;  // hourly|daily|weekly|monthly|yearly
    private final String ANTIVIRUS_SCAN_PATH;

    private NitroWebExpressConfig(final Map<String, Boolean> ENABLED,
                                  final String ADMIN_USERNAME,
                                  final String ADMIN_PASSWORD,
                                  final String ANTIVIRUS_SCHEDULE,
                                  final String ANTIVIRUS_SCAN_PATH)
    {
        this.ENABLED.putAll(ENABLED);
        this.ADMIN_USERNAME       = ADMIN_USERNAME;
        this.ADMIN_PASSWORD       = ADMIN_PASSWORD;
        this.ANTIVIRUS_SCHEDULE   = ANTIVIRUS_SCHEDULE;
        this.ANTIVIRUS_SCAN_PATH  = ANTIVIRUS_SCAN_PATH;
    }

    // ── Public API ────────────────────────────────────────────────────────────

    /** Returns true if the &lt;server id="..."&gt; block has &lt;enabled&gt;true&lt;/enabled&gt;.
     *  Defaults to true when the tag is absent (safe default — no service is silently dropped). */
    public static boolean isEnabled(final String SERVER_ID)
    {
        return get().ENABLED.getOrDefault(SERVER_ID, true);
    }

    public static String adminUsername()        { return get().ADMIN_USERNAME; }
    public static String adminPassword()        { return get().ADMIN_PASSWORD; }
    public static String antivirusSchedule()    { return get().ANTIVIRUS_SCHEDULE; }
    public static String antivirusScanPath()    { return get().ANTIVIRUS_SCAN_PATH; }

    /** Returns the fully-qualified class name of the selected server-class option.
     *  Defaults to "server.base.BaseServer" if not configured. */
    public static String selectedServerClass()
    {
        if (INSTANCE == null) load();
        try
        {
            Document doc = DocumentBuilderFactory.newInstance()
                .newDocumentBuilder().parse(new File(CONFIG_FILE));
            doc.getDocumentElement().normalize();
            NodeList options = doc.getElementsByTagName("option");
            for (int i = 0; i < options.getLength(); i++)
            {
                Element el = (Element) options.item(i);
                if ("true".equalsIgnoreCase(el.getAttribute("selected")))
                {
                    NodeList cls = el.getElementsByTagName("class");
                    if (cls.getLength() > 0) return cls.item(0).getTextContent().trim();
                }
            }
        }
        catch (Exception ignored) {}
        return "server.base.BaseServer";
    }

    /** Returns true if the selected server-class option is marked premium="true". */
    public static boolean isSelectedServerPremium()
    {
        if (INSTANCE == null) load();
        try
        {
            Document doc = DocumentBuilderFactory.newInstance()
                .newDocumentBuilder().parse(new File(CONFIG_FILE));
            doc.getDocumentElement().normalize();
            NodeList options = doc.getElementsByTagName("option");
            for (int i = 0; i < options.getLength(); i++)
            {
                Element el = (Element) options.item(i);
                if ("true".equalsIgnoreCase(el.getAttribute("selected")))
                    return "true".equalsIgnoreCase(el.getAttribute("premium"));
            }
        }
        catch (Exception ignored) {}
        return false;
    }

    /** Return the text content of the first top-level &lt;key&gt; element, or null. */
    public static String get(final String KEY)
    {
        if (INSTANCE == null) load();
        try
        {
            Document doc = DocumentBuilderFactory.newInstance()
                .newDocumentBuilder().parse(new File(CONFIG_FILE));
            doc.getDocumentElement().normalize();
            NodeList nl = doc.getDocumentElement().getElementsByTagName(KEY);
            if (nl.getLength() == 0) return null;
            String v = nl.item(0).getTextContent().trim();
            return v.isEmpty() ? null : v;
        }
        catch (Exception e) { return null; }
    }

    /** Load (or reload) configuration from disk.  Called once from Main(). */
    public static synchronized NitroWebExpressConfig load()
    {
        File file = new File(CONFIG_FILE);

        if (!file.exists())
        {
            CommonRails.printSystemComponent(
                NitroWebExpressConfig.class, NitroWebExpressConfig.class.hashCode(),
                ". NweConfig — " + CONFIG_FILE + " not found; cannot start .",
                ColorPalette.COLOR_STANDARD_RED);
            haltWithException(new RuntimeException("NweConfig — " + CONFIG_FILE + " not found"));
            INSTANCE = defaults();
        }
        else
        {
            try
            {
                Document doc = DocumentBuilderFactory.newInstance()
                    .newDocumentBuilder().parse(file);
                doc.getDocumentElement().normalize();

                Map<String, Boolean> enabled = new HashMap<>();

                NodeList servers = doc.getElementsByTagName("server");
                for (int i = 0; i < servers.getLength(); i++)
                {
                    Element el  = (Element) servers.item(i);
                    String  id  = el.getAttribute("id");
                    String  val = text(el, "enabled", "true");
                    if (!id.isEmpty()) enabled.put(id, Boolean.parseBoolean(val));
                }

                Element root          = doc.getDocumentElement();
                NodeList adminNodes   = root.getElementsByTagName("admin");
                String adminUser      = "mearvk";
                String adminPass      = "n21admin";
                if (adminNodes.getLength() > 0)
                {
                    Element adminEl = (Element) adminNodes.item(0);
                    adminUser = text(adminEl, "username", adminUser);
                    adminPass = text(adminEl, "password", adminPass);
                }

                INSTANCE = new NitroWebExpressConfig(enabled, adminUser, adminPass,
                    antivirusSchedule(doc), antivirusScanPath(doc));

                CommonRails.printSystemComponent(
                    NitroWebExpressConfig.class, NitroWebExpressConfig.class.hashCode(),
                    ". NWECONFIG loaded — " + enabled.size() + " server entries, admin='" + adminUser + "' .",
                    ColorPalette.COLOR_LIME_GREEN);
            }
            catch (Exception e)
            {
                CommonRails.printSystemComponent(
                    NitroWebExpressConfig.class, NitroWebExpressConfig.class.hashCode(),
                    ". NweConfig parse error: " + e.getMessage() + " — cannot start .",
                    ColorPalette.COLOR_STANDARD_RED);
                haltWithException(e);
                INSTANCE = defaults();
            }
        }

        // Propagate admin password into ModuleAdmin so TCP services pick it up
        admin.ModuleAdmin.setPassword(INSTANCE.ADMIN_PASSWORD);

        return INSTANCE;
    }

    // ── Internals ─────────────────────────────────────────────────────────────

    private static NitroWebExpressConfig get()
    {
        if (INSTANCE == null) load();
        return INSTANCE;
    }

    private static NitroWebExpressConfig defaults()
    {
        return new NitroWebExpressConfig(new HashMap<>(), "mearvk", "n21admin", "daily", ".");
    }

    /** Extract &lt;schedule&gt; from the ANTIVIRUS server block, default "daily". */
    private static String antivirusSchedule(final Document DOC)
    {
        NodeList servers = DOC.getElementsByTagName("server");
        for (int i = 0; i < servers.getLength(); i++)
        {
            Element el = (Element) servers.item(i);
            if ("Antivirus".equals(el.getAttribute("id")))
                return text(el, "schedule", "daily");
        }
        return "daily";
    }

    /** Extract &lt;scan-path&gt; from the ANTIVIRUS server block, default ".". */
    private static String antivirusScanPath(final Document DOC)
    {
        NodeList servers = DOC.getElementsByTagName("server");
        for (int i = 0; i < servers.getLength(); i++)
        {
            Element el = (Element) servers.item(i);
            if ("Antivirus".equals(el.getAttribute("id")))
                return text(el, "scan-path", ".");
        }
        return ".";
    }

    private static String text(final Element EL, final String TAG, final String DEF)
    {
        NodeList nl = EL.getElementsByTagName(TAG);
        if (nl.getLength() == 0) return DEF;
        String v = nl.item(0).getTextContent().trim();
        return v.isEmpty() ? DEF : v;
    }

    private static void haltWithException(Exception cause)
    {
        try (PrintWriter pw = new PrintWriter(new FileWriter("exception.log", true)))
        {
            pw.println("[" + LocalDateTime.now() + "] FATAL — NweConfig startup failure");
            cause.printStackTrace(pw);
        }
        catch (Exception ignored) {}
        System.exit(1);
    }
}
