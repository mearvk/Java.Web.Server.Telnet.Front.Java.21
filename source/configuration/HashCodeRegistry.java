package configuration;

import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.NodeList;

import javax.xml.parsers.DocumentBuilderFactory;
import java.io.File;
import java.util.HashMap;
import java.util.Map;

/**
 * HashCodeRegistry — loads admin-defined hashcodes from nwe-config.xml.
 *
 * Config format:
 *   <hashcodes>
 *     <entry class="NitroWebExpress">1234567890</entry>
 *     <entry class="MessageQueueSorter">9876543210</entry>
 *   </hashcodes>
 *
 * Call HashCodeRegistry.resolve(object) instead of object.hashCode()
 * to get the admin-overridden value (or default if not configured).
 */
public final class HashCodeRegistry
{
    private static final String CONFIG_FILE = commons.AppRoot.resolveString("configuration/nwe-config.xml");
    private static Map<String, Integer> OVERRIDES;

    private HashCodeRegistry() {}

    public static int resolve(Object owner)
    {
        if (OVERRIDES == null) load();
        String name = owner.getClass().getSimpleName();
        Integer override = OVERRIDES.get(name);
        return override != null ? override : owner.hashCode();
    }

    private static synchronized void load()
    {
        OVERRIDES = new HashMap<>();
        try
        {
            File file = new File(CONFIG_FILE);
            if (!file.exists()) return;

            Document doc = DocumentBuilderFactory.newInstance()
                .newDocumentBuilder().parse(file);
            doc.getDocumentElement().normalize();

            NodeList hcNodes = doc.getElementsByTagName("hashcodes");
            if (hcNodes.getLength() == 0) return;

            Element hcEl = (Element) hcNodes.item(0);
            NodeList entries = hcEl.getElementsByTagName("entry");
            for (int i = 0; i < entries.getLength(); i++)
            {
                Element entry = (Element) entries.item(i);
                String className = entry.getAttribute("class");
                String value = entry.getTextContent().trim();
                if (!className.isEmpty() && !value.isEmpty())
                {
                    try { OVERRIDES.put(className, Integer.parseUnsignedInt(value)); }
                    catch (NumberFormatException ignored) {}
                }
            }
        }
        catch (Exception ignored) {}
    }

    /** Force reload (e.g. after config change). */
    public static void reload() { OVERRIDES = null; }
}
