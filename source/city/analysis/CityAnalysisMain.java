package city.analysis;

import java.nio.file.*;
import java.sql.*;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
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
    protected static final String CONFIG_PATH = "source/city/analysis/city-analysis-config.xml";

    public static void main(String[] args)
    {
        System.out.println("-- : [CityAnalysisMain] . CityAnalysis™ now starting .");

        // Start the city analysis server
        city_analysis.CityAnalysisServer server = new city_analysis.CityAnalysisServer();

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
            city_analysis.CitySpeculationEngine engine = new city_analysis.CitySpeculationEngine(args[1]);
            engine.speculateRecursively();
            engine.writeResults();
        }
        else if ("crawl".equals(inputMode))
        {
            // Crawl mode — crawl sites, store raw, speculate on results
            System.out.println("-- : [CityAnalysisMain] Input mode: crawl");
            city_analysis.CityAnalysisCrawler crawler = new city_analysis.CityAnalysisCrawler();
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
                city_analysis.CitySpeculationEngine engine = new city_analysis.CitySpeculationEngine(rawFile.toString());
                engine.speculateRecursively();
                engine.writeResults();
            }
        }
        else
        {
            // File mode (default) — fetch all sources, save, speculate
            System.out.println("-- : [CityAnalysisMain] Input mode: file");
            String allContent = server.fetchAllSources();

            String dateTime = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd/HH-mm-ss"));
            Path fetchDir = Paths.get("source/city/analysis/speculations/" + dateTime);
            try
            {
                Files.createDirectories(fetchDir);
                Path fetchFile = fetchDir.resolve(server.cityName + ".fetched.data");
                if (allContent != null) Files.writeString(fetchFile, allContent);
                System.out.println("-- : [CityAnalysisMain] Fetched data saved to " + fetchFile);

                city_analysis.CitySpeculationEngine engine = new city_analysis.CitySpeculationEngine(fetchFile.toString());
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

        System.out.println("-- : [CityAnalysisMain] . CityAnalysis™ complete .");
    }

    /**
     * Store Major 5 city record to MySQL database
     */
    protected static void storeMajor5(city_analysis.CityAnalysisServer server)
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

            // Read credentials from <output><mysql>
            NodeList mysqlNodes = doc.getElementsByTagName("mysql");
            String host = "localhost";
            String port = "3306";
            String username = "root";
            String password = "";
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
}
