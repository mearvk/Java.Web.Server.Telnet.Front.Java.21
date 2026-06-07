package configuration;

import commons.CommonRails;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.NodeList;

import javax.xml.parsers.DocumentBuilderFactory;
import java.io.File;
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
public class NweConfig
{
    private static final String CONFIG_FILE = "configuration/nwe-config.xml";

    private static NweConfig INSTANCE;

    private final Map<String, Boolean> ENABLED = new HashMap<>();
    private final String ADMIN_USERNAME;
    private final String ADMIN_PASSWORD;

    private NweConfig(final Map<String, Boolean> ENABLED,
                      final String ADMIN_USERNAME,
                      final String ADMIN_PASSWORD)
    {
        this.ENABLED.putAll(ENABLED);
        this.ADMIN_USERNAME = ADMIN_USERNAME;
        this.ADMIN_PASSWORD = ADMIN_PASSWORD;
    }

    // ── Public API ────────────────────────────────────────────────────────────

    /** Returns true if the &lt;server id="..."&gt; block has &lt;enabled&gt;true&lt;/enabled&gt;.
     *  Defaults to true when the tag is absent (safe default — no service is silently dropped). */
    public static boolean isEnabled(final String SERVER_ID)
    {
        return get().ENABLED.getOrDefault(SERVER_ID, true);
    }

    public static String adminUsername() { return get().ADMIN_USERNAME; }
    public static String adminPassword() { return get().ADMIN_PASSWORD; }

    /** Load (or reload) configuration from disk.  Called once from Main(). */
    public static synchronized NweConfig load()
    {
        File file = new File(CONFIG_FILE);

        if (!file.exists())
        {
            CommonRails.printSystemComponent(
                NweConfig.class, NweConfig.class.hashCode(),
                ". NweConfig — " + CONFIG_FILE + " not found; all servers enabled, default admin .",
                CommonRails.COLOR_YELLOW);
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

                INSTANCE = new NweConfig(enabled, adminUser, adminPass);

                CommonRails.printSystemComponent(
                    NweConfig.class, NweConfig.class.hashCode(),
                    ". NweConfig loaded — " + enabled.size() + " server entries, admin='" + adminUser + "' .",
                    CommonRails.COLOR_LIME_GREEN);
            }
            catch (Exception e)
            {
                CommonRails.printSystemComponent(
                    NweConfig.class, NweConfig.class.hashCode(),
                    ". NweConfig parse error: " + e.getMessage() + " — using defaults .",
                    CommonRails.COLOR_STANDARD_RED);
                INSTANCE = defaults();
            }
        }

        // Propagate admin password into ModuleAdmin so TCP services pick it up
        admin.ModuleAdmin.setPassword(INSTANCE.ADMIN_PASSWORD);

        return INSTANCE;
    }

    // ── Internals ─────────────────────────────────────────────────────────────

    private static NweConfig get()
    {
        if (INSTANCE == null) load();
        return INSTANCE;
    }

    private static NweConfig defaults()
    {
        return new NweConfig(new HashMap<>(), "mearvk", "n21admin");
    }

    private static String text(final Element EL, final String TAG, final String DEF)
    {
        NodeList nl = EL.getElementsByTagName(TAG);
        if (nl.getLength() == 0) return DEF;
        String v = nl.item(0).getTextContent().trim();
        return v.isEmpty() ? DEF : v;
    }
}
