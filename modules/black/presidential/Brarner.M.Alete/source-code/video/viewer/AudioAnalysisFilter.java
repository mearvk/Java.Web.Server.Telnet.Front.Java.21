package video.viewer;

import javax.xml.parsers.DocumentBuilderFactory;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.NodeList;
import java.io.File;
import java.util.ArrayList;
import java.util.List;

/**
 * AudioAnalysisFilter — loads analysis modules (e.g. FFT) from
 * audio-analysis-filter.config.xml and exposes them for use by the VideoViewer.
 */
public class AudioAnalysisFilter
{
    private static final String CONFIG_FILE = "source-code/video/viewer/config/audio-analysis-filter.config.xml";

    private final List<Module> modules = new ArrayList<>();

    public static class Module
    {
        public final String name;
        public final boolean enabled;
        public final String className;

        public Module(String name, boolean enabled, String className)
        {
            this.name = name;
            this.enabled = enabled;
            this.className = className;
        }

        @Override
        public String toString() { return name + " (" + className + ") enabled=" + enabled; }
    }

    public AudioAnalysisFilter()
    {
        loadConfig();
    }

    private void loadConfig()
    {
        try
        {
            File file = new File(CONFIG_FILE);
            if (!file.exists()) file = new File("video/viewer/config/audio-analysis-filter.config.xml");
            if (!file.exists()) { System.err.println("AudioAnalysisFilter: config not found"); return; }

            Document doc = DocumentBuilderFactory.newInstance().newDocumentBuilder().parse(file);
            NodeList nodes = doc.getElementsByTagName("module");

            for (int i = 0; i < nodes.getLength(); i++)
            {
                Element el = (Element) nodes.item(i);
                String name = el.getAttribute("name");
                boolean enabled = Boolean.parseBoolean(el.getAttribute("enabled"));
                String className = el.getAttribute("class");
                modules.add(new Module(name, enabled, className));
            }
        }
        catch (Exception e) { e.printStackTrace(); }
    }

    public List<Module> getModules() { return modules; }

    public List<Module> getEnabledModules()
    {
        List<Module> enabled = new ArrayList<>();
        for (Module m : modules) if (m.enabled) enabled.add(m);
        return enabled;
    }
}
