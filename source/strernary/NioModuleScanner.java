/**
 * NioModuleScanner — Startup module discovery for masquerade-aware integration.
 *
 * Scans nwe-config.xml and masquerade-modules.xml to discover all MEARVK LLC
 * modules, extracts their internal port values (0 to MAX_PORT), and registers
 * them with the NioMasqueradeEngine routing table.
 *
 * Called at startup by StrernaryDirectoryServer after NioMasqueradeEngine init.
 *
 * @author Max Rupplin
 * @javaowner Max Rupplin
 * @date June 23 2026 EST
 */

package strernary;

import commons.CommonRails;
import exceptions.ExceptionHandler;

import org.w3c.dom.*;
import javax.xml.parsers.*;

import java.io.File;
import java.util.*;
import java.util.concurrent.CopyOnWriteArrayList;

public class NioModuleScanner
{
    private static final String NWE_CONFIG_PATH = "configuration/nwe-config.xml";
    private static final String MODULES_CONFIG_PATH = "configuration/masquerade-modules.xml";

    public record DiscoveredModule(String id, String name, int port, boolean masqueradeAware, String className) {}

    private final List<DiscoveredModule> modules = new CopyOnWriteArrayList<>();
    private final NioMasqueradeEngine engine;

    public NioModuleScanner(NioMasqueradeEngine engine)
    {
        this.engine = engine;
        scan();
        registerWithEngine();
        CommonRails.printSystemComponent(this, this.hashCode(),
            ". NioModuleScanner™ discovered " + modules.size() + " modules (0-" + engine.getMaxPort() + ") .");
    }

    private void scan()
    {
        scanNweConfig();
        scanMasqueradeModules();
    }

    private void scanNweConfig()
    {
        try
        {
            File f = new File(NWE_CONFIG_PATH);
            if (!f.exists()) return;
            DocumentBuilder db = DocumentBuilderFactory.newInstance().newDocumentBuilder();
            Document doc = db.parse(f);

            NodeList servers = doc.getElementsByTagName("server");
            for (int i = 0; i < servers.getLength(); i++)
            {
                Element srv = (Element) servers.item(i);
                String id = srv.getAttribute("id");
                if (id == null || id.isEmpty()) continue;

                String enabled = getText(srv, "enabled");
                if (!"true".equalsIgnoreCase(enabled)) continue;

                String name = getText(srv, "name");
                String portStr = getText(srv, "port");
                if (portStr.isEmpty()) continue;

                int port = Integer.parseInt(portStr);
                if (port < 0 || port > engine.getMaxPort()) continue;

                // All nwe-config servers are masquerade-aware by default
                modules.add(new DiscoveredModule(id, name, port, true, ""));
            }
        }
        catch (Exception e) { ExceptionHandler.dispatch(e); }
    }

    private void scanMasqueradeModules()
    {
        try
        {
            File f = new File(MODULES_CONFIG_PATH);
            if (!f.exists()) return;
            DocumentBuilder db = DocumentBuilderFactory.newInstance().newDocumentBuilder();
            Document doc = db.parse(f);

            NodeList mods = doc.getElementsByTagName("module");
            for (int i = 0; i < mods.getLength(); i++)
            {
                Element mod = (Element) mods.item(i);
                String id = mod.getAttribute("id");
                String name = getText(mod, "name");
                String portStr = getText(mod, "port");
                String aware = getText(mod, "masquerade-aware");
                String cls = getText(mod, "class");

                if (portStr.isEmpty()) continue;
                int port = Integer.parseInt(portStr);
                if (port < 0 || port > engine.getMaxPort()) continue;

                boolean masqueradeAware = "true".equalsIgnoreCase(aware);

                // Skip duplicates (already discovered from nwe-config)
                boolean exists = modules.stream().anyMatch(m -> m.id().equals(id));
                if (!exists)
                    modules.add(new DiscoveredModule(id, name, port, masqueradeAware, cls));
            }
        }
        catch (Exception e) { ExceptionHandler.dispatch(e); }
    }

    private void registerWithEngine()
    {
        for (DiscoveredModule mod : modules)
        {
            if (!mod.masqueradeAware()) continue;
            engine.registerModule(mod.id(), mod.port());
        }
    }

    public List<DiscoveredModule> getModules() { return Collections.unmodifiableList(modules); }

    public List<DiscoveredModule> getMasqueradeAwareModules()
    {
        return modules.stream().filter(DiscoveredModule::masqueradeAware).toList();
    }

    private String getText(Element parent, String tag)
    {
        NodeList nl = parent.getElementsByTagName(tag);
        return nl.getLength() > 0 ? nl.item(0).getTextContent().trim() : "";
    }
}
