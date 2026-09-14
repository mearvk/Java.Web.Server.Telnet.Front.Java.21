package city.analysis;

import java.io.File;
import java.nio.file.*;
import java.sql.*;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;
import javax.xml.parsers.*;
import org.w3c.dom.*;

/**
 * @author Max Rupplin
 *
 * @date June 23 2026
 *
 * Main entry point for the CityAnalysis module.
 * Run from IDE or terminal: java CityAnalysisMain [cityName] [inputFile]
 *
 * Input modes (city-analysis-config.xml):
 *   file  — provide input file directly (default)
 *   crawl — crawl property/deeds sites, store raw, then speculate
 */
public class CityAnalysisMain
{
    protected static final String CONFIG_PATH = "source/city/analysis/configuration/city-analysis-config.xml";

    public static void main(String[] args)
    {
        System.out.println("-- : [CityAnalysisMain] . CityAnalysis™ now starting .");

        // Start the city analysis server
        CityAnalysisServer server = new CityAnalysisServer();

        if (args.length > 0)
        {
            server.selectCity(args[0]);
        }

        System.out.println("-- : [CityAnalysisMain] Active city: " + server.getSelectedCity());

        // Determine input mode from config
        String inputMode = getInputMode();

        if (args.length > 1)
        {
            // Explicit file input
            CitySpeculationEngine engine = new CitySpeculationEngine(args[1]);
            engine.speculateRecursively();
            engine.writeResults();
        }
        else if ("crawl".equals(inputMode))
        {
            // Crawl mode — crawl sites, store raw, speculate on results
            System.out.println("-- : [CityAnalysisMain] Input mode: crawl");
            CityAnalysisCrawler crawler = new CityAnalysisCrawler();
            String[] seeds = new String[3 + server.additionalSources.size()];
            seeds[0] = server.deedsUrl;
            seeds[1] = server.propertyRecordsUrl;
            seeds[2] = server.registerOfDeedsUrl;
            for (int i = 0; i < server.additionalSources.size(); i++)
            {
                seeds[3 + i] = server.additionalSources.get(i);
            }
            List<Path> rawFiles = crawler.crawl(seeds);

            // Speculate on each stored raw file
            for (Path rawFile : rawFiles)
            {
                CitySpeculationEngine engine = new CitySpeculationEngine(rawFile.toString());
                engine.speculateRecursively();
                engine.writeResults();
            }
        }
        else
        {
            // File mode (default) — fetch all sources, run search engine, save, speculate
            System.out.println("-- : [CityAnalysisMain] Input mode: file");

            // Run ROD queries to populate deeds data CSV before speculation
            System.out.println("-- : [CityAnalysisMain] Running ROD query handler for deeds data...");
            RodQueryHandler rodHandler = new RodQueryHandler();
            int rodResults = rodHandler.queryAndAppend(50);
            System.out.println("-- : [CityAnalysisMain] ROD query produced " + rodResults + " results");

            String allContent = server.fetchAllSources();

            // Append ROD query results CSV to content for speculation
            Path rodCsv = Paths.get("source/city/analysis/data/durham.nc.rod.query.results.csv");
            if (Files.exists(rodCsv))
            {
                try
                {
                    String rodData = Files.readString(rodCsv);
                    allContent = (allContent != null ? allContent : "") + "\n=== ROD DEEDS QUERY RESULTS ===\n" + rodData;
                    System.out.println("-- : [CityAnalysisMain] Appended ROD CSV (" + rodData.length() + " chars) to speculation input");
                }
                catch (Exception e) { System.err.println("-- : [CityAnalysisMain] Cannot read ROD CSV: " + e.getMessage()); }
            }

            // Search engine integration — query web for additional real estate/lending data
            CityAnalysisSearchEngine searchEngine = new CityAnalysisSearchEngine();
            if (searchEngine.isEnabled())
            {
                String searchContent = searchEngine.search(server.cityName, server.county, server.state);
                if (searchContent != null && !searchContent.isEmpty())
                {
                    allContent = (allContent != null ? allContent : "") + "\n" + searchContent;

                    // Extract typed input objects (target: 1200 items)
                    List<Map<String, String>> inputObjects = searchEngine.extractInputObjects();
                    System.out.println("-- : [CityAnalysisMain] Search engine produced " + inputObjects.size() + "/" + searchEngine.getTargetInputCount() + " typed input objects");

                    // Write typed objects as supplemental data for CSE
                    StringBuilder objectsData = new StringBuilder();
                    objectsData.append("=== SEARCH ENGINE INPUT OBJECTS (" + inputObjects.size() + " items) ===\n");
                    for (Map<String, String> obj : inputObjects)
                    {
                        objectsData.append("[" + obj.get("type") + "] " + obj.get("value") + "\n");
                    }
                    allContent += "\n" + objectsData.toString();

                    // Add discovered URLs back to sources XML if configured
                    if (searchEngine.getDiscoveredUrls().size() > 0)
                    {
                        updateSourcesXml(server.cityName, searchEngine.getDiscoveredUrls());
                    }
                }
            }

            String dateTime = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd/HH-mm-ss"));
            Path fetchDir = Paths.get("source/city/analysis/speculations/" + dateTime);
            try
            {
                Files.createDirectories(fetchDir);
                Path fetchFile = fetchDir.resolve(server.cityName + ".fetched.data");

                // Strip HTML tags — store extracted text, not raw markup
                if (allContent != null) allContent = stripHtml(allContent);

                if (allContent != null) Files.writeString(fetchFile, allContent);
                System.out.println("-- : [CityAnalysisMain] Fetched data saved to " + fetchFile + " (" + (allContent != null ? allContent.length() : 0) + " chars text)");

                CitySpeculationEngine engine = new CitySpeculationEngine(fetchFile.toString());
                engine.speculateRecursively();
                engine.writeResults();
            }
            catch (Exception e)
            {
                System.err.println("-- : [CityAnalysisMain] Error: " + e.getMessage());
            }
        }

        // Major 5 — store to database
        storeMajor5(server);

        // Connection tracker — persist delistings and print summary
        server.connectionTracker.persistToXml();
        server.connectionTracker.printSummary();

        System.out.println("-- : [CityAnalysisMain] . CityAnalysis™ complete .");
    }

    /**
     * Store Major 5 city record to MySQL database
     */
    protected static void storeMajor5(CityAnalysisServer server)
    {
        try
        {
            Document doc = DocumentBuilderFactory.newInstance().newDocumentBuilder().parse(new java.io.File(CONFIG_PATH));
            NodeList major5Nodes = doc.getElementsByTagName("major-5");
            if (major5Nodes.getLength() == 0) return;

            Element m5 = (Element) major5Nodes.item(0);
            if (!"true".equals(m5.getElementsByTagName("enabled").item(0).getTextContent().trim())) return;

            String database = m5.getElementsByTagName("database").item(0).getTextContent().trim();
            String table = m5.getElementsByTagName("table").item(0).getTextContent().trim();

            // Read credentials from <major-5><mysql>
            String host = "localhost";
            String port = "3306";
            String username = "root";
            String password = "";
            NodeList mysqlNodes = m5.getElementsByTagName("mysql");
            if (mysqlNodes.getLength() > 0)
            {
                Element mysql = (Element) mysqlNodes.item(0);
                host = mysql.getElementsByTagName("host").item(0).getTextContent().trim();
                port = mysql.getElementsByTagName("port").item(0).getTextContent().trim();
                username = mysql.getElementsByTagName("username").item(0).getTextContent().trim();
                password = mysql.getElementsByTagName("password").item(0).getTextContent().trim();
            }

            String jdbcUrl = "jdbc:mysql://" + host + ":" + port + "/" + database + "?useSSL=false&allowPublicKeyRetrieval=true";
            Connection conn = DriverManager.getConnection(jdbcUrl, username, password);

            // Create table if not exists
            String createSql = "CREATE TABLE IF NOT EXISTS " + table + " (" +
                    "id INT AUTO_INCREMENT PRIMARY KEY, " +
                    "city VARCHAR(100), " +
                    "county VARCHAR(100), " +
                    "state VARCHAR(10), " +
                    "deeds_url VARCHAR(500), " +
                    "property_records_url VARCHAR(500), " +
                    "fetched_at DATETIME, " +
                    "data_size_bytes BIGINT, " +
                    "speculation_confidence DOUBLE" +
                    ")";
            conn.createStatement().execute(createSql);

            // Insert current city record
            String insertSql = "INSERT INTO " + table +
                    " (city, county, state, deeds_url, property_records_url, fetched_at, data_size_bytes, speculation_confidence) " +
                    "VALUES (?, ?, ?, ?, ?, NOW(), ?, ?)";
            PreparedStatement ps = conn.prepareStatement(insertSql);
            ps.setString(1, server.cityName);
            ps.setString(2, server.county);
            ps.setString(3, server.state);
            ps.setString(4, server.deedsUrl);
            ps.setString(5, server.propertyRecordsUrl);
            ps.setLong(6, 0);
            ps.setDouble(7, 0.0);
            ps.executeUpdate();

            ps.close();
            conn.close();
            System.out.println("-- : [CityAnalysisMain] Major 5 record stored for " + server.cityName);
        }
        catch (Exception e)
        {
            System.err.println("-- : [CityAnalysisMain] Major 5 DB store failed: " + e.getMessage());
        }
    }

    protected static String getInputMode()
    {
        try
        {
            Document doc = DocumentBuilderFactory.newInstance().newDocumentBuilder().parse(new java.io.File(CONFIG_PATH));
            NodeList nodes = doc.getElementsByTagName("default");
            if (nodes.getLength() > 0) return nodes.item(0).getTextContent().trim();
        }
        catch (Exception e) { /* use default */ }
        return "file";
    }

    /**
     * Update city-analysis-config.xml additional-sources with newly discovered URLs from search engine
     */
    protected static void updateSourcesXml(String cityName, List<String> newUrls)
    {
        try
        {
            File configFile = new File(CONFIG_PATH);
            DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
            DocumentBuilder builder = factory.newDocumentBuilder();
            Document doc = builder.parse(configFile);
            doc.getDocumentElement().normalize();

            NodeList cityNodes = doc.getElementsByTagName("city");
            for (int i = 0; i < cityNodes.getLength(); i++)
            {
                Element cityEl = (Element) cityNodes.item(i);
                if ("true".equals(cityEl.getAttribute("selected")))
                {
                    // Find or create <additional-sources>
                    NodeList asNodes = cityEl.getElementsByTagName("additional-sources");
                    Element additionalSources;
                    if (asNodes.getLength() > 0)
                    {
                        additionalSources = (Element) asNodes.item(0);
                    }
                    else
                    {
                        additionalSources = doc.createElement("additional-sources");
                        cityEl.appendChild(additionalSources);
                    }

                    // Collect existing source URLs to avoid duplicates
                    Set<String> existing = new HashSet<>();
                    NodeList srcNodes = additionalSources.getElementsByTagName("source");
                    for (int j = 0; j < srcNodes.getLength(); j++)
                    {
                        existing.add(srcNodes.item(j).getTextContent().trim());
                    }

                    // Add new search-discovered URLs
                    int added = 0;
                    for (String url : newUrls)
                    {
                        if (!existing.contains(url) && url.startsWith("http"))
                        {
                            Element source = doc.createElement("source");
                            source.setAttribute("type", "search-discovered");
                            source.setTextContent(url);
                            additionalSources.appendChild(source);
                            added++;
                        }
                    }

                    if (added > 0)
                    {
                        // Write updated XML back
                        javax.xml.transform.TransformerFactory tf = javax.xml.transform.TransformerFactory.newInstance();
                        javax.xml.transform.Transformer transformer = tf.newTransformer();
                        transformer.setOutputProperty(javax.xml.transform.OutputKeys.INDENT, "yes");
                        transformer.setOutputProperty("{http://xml.apache.org/xslt}indent-amount", "4");
                        transformer.transform(new javax.xml.transform.dom.DOMSource(doc),
                                new javax.xml.transform.stream.StreamResult(configFile));
                        System.out.println("-- : [CityAnalysisMain] Added " + added + " search-discovered URLs to sources XML for " + cityName);
                    }
                    break;
                }
            }
        }
        catch (Exception e)
        {
            System.err.println("-- : [CityAnalysisMain] Failed to update sources XML: " + e.getMessage());
        }
    }

    /**
     * Strips HTML tags, scripts, styles from content. Collapses whitespace.
     * Preserves text content as paragraph/line summary.
     */
    protected static String stripHtml(String html)
    {
        if (html == null) return null;
        // Remove script and style blocks entirely
        String text = html.replaceAll("(?is)<script[^>]*>.*?</script>", "");
        text = text.replaceAll("(?is)<style[^>]*>.*?</style>", "");
        // Replace <br>, <p>, <div>, <li>, <tr> with newlines
        text = text.replaceAll("(?i)<(br|/p|/div|/li|/tr|/h[1-6])[^>]*>", "\n");
        // Strip remaining tags
        text = text.replaceAll("<[^>]+>", "");
        // Decode common entities
        text = text.replace("&amp;", "&").replace("&lt;", "<").replace("&gt;", ">")
                   .replace("&nbsp;", " ").replace("&quot;", "\"").replace("&#39;", "'");
        // Collapse multiple blank lines
        text = text.replaceAll("\\n\\s*\\n\\s*\\n+", "\n\n");
        // Trim leading/trailing whitespace per line
        text = text.lines().map(String::strip).filter(l -> !l.isEmpty())
                   .reduce("", (a, b) -> a + "\n" + b).strip();
        return text;
    }
}
