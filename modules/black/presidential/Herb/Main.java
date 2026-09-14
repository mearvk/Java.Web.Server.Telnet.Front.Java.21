package presidential.Herb;// AFTER: Each transformation is a named step in the pipeline

import javax.xml.parsers.DocumentBuilderFactory;
import org.w3c.dom.*;
import java.io.File;
import java.net.URI;
import java.util.*;

/**
 * Green.Durham.Grass.and.Herb — Main entry point.
 *
 * <p>Appree is a careful and concernful program all the way down to the Mayor
 * of Chapel Hill and her study of students of the County.</p>
 *
 * <p>This is subtly an Appree project riding on NC Labor Laws &amp; Organization.</p>
 */
public class Main {

    private static final String[] CONFIG_PATHS = {
        "configuration/appree-config.xml",
        "configuration/github-polling-config.xml",
        "configuration/ai-interpreter-config.xml",
        "configuration/ethical-db-config.xml",
        "configuration/labor-db-config.xml",
        "configuration/moral-db-config.xml",
        "configuration/mortality-db-config.xml",
        "configuration/known.port.49152.servers.xml",
        "configuration/jwstfj21-integration.xml"
    };

    private static String baseDir = "";

    public static void main(String... args) throws Exception {
        // Accept optional base directory argument, or detect from jar location
        if (args.length > 0) {
            baseDir = args[0].endsWith(File.separator) ? args[0] : args[0] + File.separator;
        } else {
            String jarPath = Main.class.getProtectionDomain().getCodeSource().getLocation().toURI().getPath();
            File jarFile = new File(jarPath);
            File jarDir = jarFile.isDirectory() ? jarFile : jarFile.getParentFile();
            // Walk up to find "configuration" folder
            File dir = jarDir;
            while (dir != null && !new File(dir, "configuration").isDirectory()) dir = dir.getParentFile();
            if (dir != null) baseDir = dir.getPath() + File.separator;
        }

        XmlReader reader = new XmlReader();
        Map<String, Document> configs = reader.loadAll(CONFIG_PATHS);

        // Print version from appree-config.xml
        String version = "unknown";
        Document appreeDoc = configs.get("configuration/appree-config.xml");
        if (appreeDoc != null) {
            NodeList vNodes = appreeDoc.getElementsByTagName("version");
            if (vNodes.getLength() > 0) version = vNodes.item(0).getTextContent();
        }

        System.out.println("=== Green.Durham.Grass.and.Herb . Java Finance and Moral Systems . Version "+version+" . Startup ===");

        System.out.println("\n--- Module Status ---");

        // DB modules
        String[] dbModules = {"ethical", "labor", "moral", "mortality"};
        boolean allDbLoaded = true;
        for (String mod : dbModules) {
            String key = "configuration/" + mod + "-db-config.xml";
            boolean found = configs.containsKey(key);
            System.out.println("[DB] " + mod + ": " + (found ? "LOADED" : "NOT FOUND"));
            if (!found) allDbLoaded = false;
        }

        // AI modules
        boolean aiLoaded = configs.containsKey("configuration/ai-interpreter-config.xml");
        System.out.println("[AI] ai-interpreter: " + (aiLoaded ? "LOADED" : "NOT FOUND"));

        // Check jars directory
        File jarsDir = new File(baseDir + "jars");
        boolean jarsFound = jarsDir.isDirectory() && jarsDir.list().length > 0;
        System.out.println("[AI] PyTorch jars: " + (jarsFound ? "FOUND (" + jarsDir.list().length + " jars)" : "NOT FOUND"));

        // Appree config (starting XML)
        boolean appreeLoaded = configs.containsKey("configuration/appree-config.xml");
        boolean pollingLoaded = configs.containsKey("configuration/github-polling-config.xml");
        System.out.println("[CORE] appree-config: " + (appreeLoaded ? "LOADED" : "NOT FOUND"));
        System.out.println("[CORE] github-polling-config: " + (pollingLoaded ? "LOADED" : "NOT FOUND"));

        // Final verdict
        boolean systemReady = allDbLoaded && aiLoaded && appreeLoaded;
        System.out.println("\n--- Result ---");
        System.out.println("[SYSTEM] All DB modules loaded: " + (allDbLoaded ? "YES" : "NO"));
        System.out.println("[SYSTEM] AI modules loaded: " + (aiLoaded ? "YES" : "NO"));
        System.out.println("[SYSTEM] Started from XML: " + (appreeLoaded ? "YES" : "NO"));
        System.out.println("[SYSTEM] Status: " + (systemReady ? "RUNNING" : "DEGRADED") + "\n");

        // JWSTFJ21 integration — reflective masquerade
        if (configs.containsKey("configuration/jwstfj21-integration.xml")) {
            System.out.println("\n--- JWSTFJ21 Integration ---");
            try {
                Class<?> masqClass = Class.forName("integration.JWSTFJ21Masquerade");
                Object masquerade = masqClass.getDeclaredConstructor().newInstance();
                boolean integrated = (boolean) masqClass.getMethod("register").invoke(masquerade);
                System.out.println("[JWSTFJ21] Status: " + (integrated ? "INTEGRATED" : "STANDALONE"));
            } catch (ClassNotFoundException e) {
                System.out.println("[JWSTFJ21] Masquerade class not compiled — skipping.");
            } catch (Exception e) {
                System.out.println("[JWSTFJ21] Integration deferred: " + e.getMessage());
            }
        }

        DecisionMaker dm = new DecisionMaker(configs);
        dm.evaluate();
    }

    static class XmlReader {
        Map<String, Document> loadAll(String[] paths) {
            Map<String, Document> docs = new LinkedHashMap<>();
            for (String path : paths) {
                try {
                    Document doc = DocumentBuilderFactory.newInstance()
                            .newDocumentBuilder().parse(new File(baseDir + path));
                    doc.getDocumentElement().normalize();
                    docs.put(path, doc);
                    System.out.println("[XML] Loaded: " + path);
                } catch (Exception e) {
                    System.err.println("[XML] Failed: " + path + " - " + e.getMessage());
                }
            }
            return docs;
        }
    }

    static class DecisionMaker {
        private final Map<String, Document> configs;

        DecisionMaker(Map<String, Document> configs) {
            this.configs = configs;
        }

        void evaluate() {
            System.out.println("\n[DECISION] Evaluating " + configs.size() + " config(s)...");

            for (Map.Entry<String, Document> entry : configs.entrySet()) {
                String path = entry.getKey();
                Document doc = entry.getValue();

                if (path.contains("appree") && !path.contains("github")) {
                    evaluateListeners(doc);
                } else if (path.contains("github-polling")) {
                    evaluateGithubPolling(doc);
                } else if (path.contains("ai-interpreter")) {
                    evaluateInterpreters(doc);
                } else if (path.contains("db-config")) {
                    evaluateDbConfig(path, doc);
                }
            }
            int total = 8; // total expected configs (incl. jwstfj21-integration)
            int loaded = configs.size();
            if (loaded == total) {
                System.out.println("\u001B[32m[DECISION] Evaluation complete.\u001B[0m");
            } else if (loaded > 0) {
                System.out.println("\u001B[33m[DECISION] Evaluation complete (" + (total - loaded) + " config(s) missing).\u001B[0m");
            } else {
                System.out.println("\u001B[31m[DECISION] Evaluation failed — program did not load.\u001B[0m");
            }
        }

        private void evaluateListeners(Document doc) {
            NodeList nodes = doc.getElementsByTagName("listener");
            int enabled = 0;
            for (int i = 0; i < nodes.getLength(); i++) {
                if ("true".equals(((Element) nodes.item(i)).getAttribute("enabled"))) enabled++;
            }
            System.out.println("[DECISION] Listeners: " + enabled + "/" + nodes.getLength() + " enabled");
        }

        private void evaluateInterpreters(Document doc) {
            NodeList nodes = doc.getElementsByTagName("interpreter");
            System.out.println("[DECISION] AI Interpreters configured: " + nodes.getLength());
        }

        private void evaluateDbConfig(String path, Document doc) {
            String module = path.replaceAll(".*/", "").replace("-db-config.xml", "");
            NodeList urlNodes = doc.getElementsByTagName("url");
            String url = urlNodes.getLength() > 0 ? urlNodes.item(0).getTextContent() : "unknown";
            System.out.println("[DECISION] DB for " + module + ": " + url);
        }

        private void evaluateGithubPolling(Document doc) {
            NodeList sites = doc.getElementsByTagName("site");
            int enabled = 0;
            for (int i = 0; i < sites.getLength(); i++) {
                if ("true".equals(((Element) sites.item(i)).getAttribute("enabled"))) enabled++;
            }
            System.out.println("[DECISION] GitHub polling: " + enabled + "/" + sites.getLength() + " sites enabled");
        }
    }
}
