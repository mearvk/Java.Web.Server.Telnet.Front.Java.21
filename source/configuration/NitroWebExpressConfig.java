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
    private static final String CONFIG_FILE = commons.AppRoot.resolveString("configuration/nwe-config.xml");

    private static NitroWebExpressConfig INSTANCE;

    private final Map<String, Boolean> ENABLED = new HashMap<>();
    private final String ADMIN_USERNAME;
    private final String ADMIN_PASSWORD;
    private final String ANTIVIRUS_SCHEDULE;  // hourly|daily|weekly|monthly|yearly
    private final String ANTIVIRUS_SCAN_PATH;

    // Web-servers configuration (Tomcat & Apache)
    private final String TOMCAT_VERSION;
    private final String TOMCAT_INSTALL_DIR;
    private final String TOMCAT_TECH_ID;
    private final String TOMCAT_SERVICE_NAME;
    private final String APACHE_VERSION;
    private final String APACHE_INSTALL_DIR;
    private final String APACHE_APP_SUBDIR;
    private final String APACHE_TECH_ID;
    private final String APACHE_SERVICE_NAME;

    private NitroWebExpressConfig(final Map<String, Boolean> ENABLED,
                                  final String ADMIN_USERNAME,
                                  final String ADMIN_PASSWORD,
                                  final String ANTIVIRUS_SCHEDULE,
                                  final String ANTIVIRUS_SCAN_PATH,
                                  final String TOMCAT_VERSION,
                                  final String TOMCAT_INSTALL_DIR,
                                  final String TOMCAT_TECH_ID,
                                  final String TOMCAT_SERVICE_NAME,
                                  final String APACHE_VERSION,
                                  final String APACHE_INSTALL_DIR,
                                  final String APACHE_APP_SUBDIR,
                                  final String APACHE_TECH_ID,
                                  final String APACHE_SERVICE_NAME)
    {
        this.ENABLED.putAll(ENABLED);
        this.ADMIN_USERNAME       = ADMIN_USERNAME;
        this.ADMIN_PASSWORD       = ADMIN_PASSWORD;
        this.ANTIVIRUS_SCHEDULE   = ANTIVIRUS_SCHEDULE;
        this.ANTIVIRUS_SCAN_PATH  = ANTIVIRUS_SCAN_PATH;
        this.TOMCAT_VERSION       = TOMCAT_VERSION;
        this.TOMCAT_INSTALL_DIR   = TOMCAT_INSTALL_DIR;
        this.TOMCAT_TECH_ID       = TOMCAT_TECH_ID;
        this.TOMCAT_SERVICE_NAME  = TOMCAT_SERVICE_NAME;
        this.APACHE_VERSION       = APACHE_VERSION;
        this.APACHE_INSTALL_DIR   = APACHE_INSTALL_DIR;
        this.APACHE_APP_SUBDIR    = APACHE_APP_SUBDIR;
        this.APACHE_TECH_ID       = APACHE_TECH_ID;
        this.APACHE_SERVICE_NAME  = APACHE_SERVICE_NAME;
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

    // ── Web-Servers Accessors (from <web-servers> section) ────────────────────

    /** Tomcat version from &lt;web-servers&gt;&lt;tomcat&gt;&lt;version&gt;. Default: "11.0.2". */
    public static String tomcatVersion()       { return get().TOMCAT_VERSION; }

    /** Tomcat install directory from &lt;web-servers&gt;&lt;tomcat&gt;&lt;install-dir&gt;. Default: "/opt/apache-tomcat-11.0.2". */
    public static String tomcatInstallDir()    { return get().TOMCAT_INSTALL_DIR; }

    /** Installer tech ID for Tomcat from &lt;web-servers&gt;&lt;tomcat&gt;&lt;tech-id&gt;. */
    public static String tomcatTechId()        { return get().TOMCAT_TECH_ID; }

    /** Tomcat system service name from &lt;web-servers&gt;&lt;tomcat&gt;&lt;service-name&gt;. Default: "tomcat". */
    public static String tomcatServiceName()   { return get().TOMCAT_SERVICE_NAME; }

    /** Apache version from &lt;web-servers&gt;&lt;apache&gt;&lt;version&gt;. Default: "2.4". */
    public static String apacheVersion()       { return get().APACHE_VERSION; }

    /** Apache document root from &lt;web-servers&gt;&lt;apache&gt;&lt;install-dir&gt;. Default: "/var/www/html". */
    public static String apacheInstallDir()    { return get().APACHE_INSTALL_DIR; }

    /** Apache NWE subdirectory from &lt;web-servers&gt;&lt;apache&gt;&lt;app-subdir&gt;. Default: "nwe". */
    public static String apacheAppSubdir()     { return get().APACHE_APP_SUBDIR; }

    /** Installer tech ID for Apache from &lt;web-servers&gt;&lt;apache&gt;&lt;tech-id&gt;. */
    public static String apacheTechId()        { return get().APACHE_TECH_ID; }

    /** Apache system service name from &lt;web-servers&gt;&lt;apache&gt;&lt;service-name&gt;. Default: "apache2". */
    public static String apacheServiceName()   { return get().APACHE_SERVICE_NAME; }

    /** Returns the full Apache document root path: install-dir + "/" + app-subdir. */
    public static String apacheDocRoot()
    {
        String dir = get().APACHE_INSTALL_DIR;
        String sub = get().APACHE_APP_SUBDIR;
        return (dir.endsWith("/") ? dir : dir + "/") + sub;
    }

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
                    antivirusSchedule(doc), antivirusScanPath(doc),
                    webServerText(doc, "tomcat", "version", "11.0.2"),
                    webServerText(doc, "tomcat", "install-dir", "/opt/apache-tomcat-11.0.2"),
                    webServerText(doc, "tomcat", "tech-id", "MEARVK-LLC-Default"),
                    webServerText(doc, "tomcat", "service-name", "tomcat"),
                    webServerText(doc, "apache", "version", "2.4"),
                    webServerText(doc, "apache", "install-dir", "/var/www/html"),
                    webServerText(doc, "apache", "app-subdir", "nwe"),
                    webServerText(doc, "apache", "tech-id", "MEARVK-LLC-Default"),
                    webServerText(doc, "apache", "service-name", "apache2"));

                CommonRails.printSystemComponent(
                    NitroWebExpressConfig.class, NitroWebExpressConfig.class.hashCode(),
                    ". NWECONFIG loaded — " + enabled.size() + " server entries, admin='" + adminUser + "' .",
                    ColorPalette.COLOR_LIME_GREEN);

                CommonRails.printSystemComponent(
                    NitroWebExpressConfig.class, NitroWebExpressConfig.class.hashCode(),
                    ". WEB-SERVERS — Tomcat " + INSTANCE.TOMCAT_VERSION + " at " + INSTANCE.TOMCAT_INSTALL_DIR
                        + " | Apache " + INSTANCE.APACHE_VERSION + " at " + INSTANCE.APACHE_INSTALL_DIR + "/" + INSTANCE.APACHE_APP_SUBDIR
                        + " | tech-id=" + INSTANCE.TOMCAT_TECH_ID + " .",
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
        return new NitroWebExpressConfig(new HashMap<>(), "mearvk", "n21admin", "daily", ".",
            "11.0.2", "/opt/apache-tomcat-11.0.2", "MEARVK-LLC-Default", "tomcat",
            "2.4", "/var/www/html", "nwe", "MEARVK-LLC-Default", "apache2");
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

    /** Extract a value from &lt;web-servers&gt;&lt;serverType&gt;&lt;tag&gt;...&lt;/tag&gt;&lt;/serverType&gt;&lt;/web-servers&gt;.
     *  @param serverType "tomcat" or "apache"
     *  @param tag        child element name (e.g. "version", "install-dir", "tech-id")
     *  @param def        default value if not found */
    private static String webServerText(final Document DOC, final String serverType, final String tag, final String def)
    {
        try
        {
            NodeList wsList = DOC.getElementsByTagName("web-servers");
            if (wsList.getLength() == 0) return def;
            Element wsEl = (Element) wsList.item(0);
            NodeList typeList = wsEl.getElementsByTagName(serverType);
            if (typeList.getLength() == 0) return def;
            Element typeEl = (Element) typeList.item(0);
            return text(typeEl, tag, def);
        }
        catch (Exception e) { return def; }
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
