package video.viewer;

import javax.xml.parsers.DocumentBuilderFactory;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import java.io.File;
import java.lang.ProcessHandle;

public class Launcher
{
    public static void main(String...args) throws Exception
    {
        // Suppress JavaFX unnamed module warning
        java.util.logging.Logger.getLogger("com.sun.javafx.application.PlatformImpl").setLevel(java.util.logging.Level.SEVERE);

        int memory = 768;
        try
        {
            File configFile = new File("video/viewer/config/config.xml");
            if (!configFile.exists()) configFile = new File("source-code/video.viewer/config.xml");
            if (configFile.exists())
            {
                Document doc = DocumentBuilderFactory.newInstance().newDocumentBuilder().parse(configFile);
                Element root = doc.getDocumentElement();
                if (root.hasAttribute("memory")) memory = Integer.parseInt(root.getAttribute("memory"));
            }
        }
        catch (Exception e) { /* use default */ }

        long maxMB = Runtime.getRuntime().maxMemory() / (1024 * 1024);
        if (maxMB < memory - 50)
        {
            // Relaunch with correct heap
            String java = ProcessHandle.current().info().command().orElse("java");
            new ProcessBuilder(java, "-Xmx" + memory + "m", "-cp", System.getProperty("java.class.path"),
                "video.viewer.Launcher").inheritIO().start();
            System.exit(0);
        }

        VideoViewer.main(args);
    }
}
