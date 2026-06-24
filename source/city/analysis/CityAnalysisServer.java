package city_analysis;

import java.io.*;
import java.net.*;
import java.nio.charset.StandardCharsets;
import java.util.*;
import javax.xml.parsers.*;
import org.w3c.dom.*;

/**
 * @author Max Rupplin
 *
 * @date June 23 2026
 *
 * CityAnalysisServer — Gathers property/deed information for a given city
 * by contacting the county Register of Deeds and property records websites.
 * Driven by configuration/city-analysis-config.xml.
 */
public class CityAnalysisServer
{
    protected String hash = "0xCA717018470E913F";

    protected static final String CONFIG_PATH = "source/city/analysis/city-analysis-config.xml";
    protected static final String PRESUMES_PATH = "source/city/analysis/legalice.presumes.xml";

    protected List<Map<String, String>> presumptions = new ArrayList<>();

    protected String cityName;
    protected String county;
    protected String state;
    protected String deedsUrl;
    protected String propertyRecordsUrl;
    protected String registerOfDeedsUrl;
    protected int timeoutMs;
    protected int retryCount;
    protected String userAgent;

    protected List<Map<String, String>> allCities = new ArrayList<>();

    public CityAnalysisServer()
    {
        loadConfig();
        loadPresumptions();
    }

    /**
     * Load city-analysis-config.xml and select the default (selected="true") city
     */
    protected void loadConfig()
    {
        try
        {
            File configFile = new File(CONFIG_PATH);
            DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
            DocumentBuilder builder = factory.newDocumentBuilder();
            Document doc = builder.parse(configFile);
            doc.getDocumentElement().normalize();

            // Connection settings
            NodeList connNodes = doc.getElementsByTagName("connection");
            if (connNodes.getLength() > 0)
            {
                Element conn = (Element) connNodes.item(0);
                this.timeoutMs = Integer.parseInt(getTagValue(conn, "timeout-ms"));
                this.retryCount = Integer.parseInt(getTagValue(conn, "retry-count"));
                this.userAgent = getTagValue(conn, "user-agent");
            }

            // Load all cities, select the default
            NodeList cityNodes = doc.getElementsByTagName("city");
            for (int i = 0; i < cityNodes.getLength(); i++)
            {
                Element cityEl = (Element) cityNodes.item(i);
                Map<String, String> city = new HashMap<>();
                city.put("name", getTagValue(cityEl, "name"));
                city.put("county", getTagValue(cityEl, "county"));
                city.put("state", getTagValue(cityEl, "state"));
                city.put("deeds-url", getTagValue(cityEl, "deeds-url"));
                city.put("property-records-url", getTagValue(cityEl, "property-records-url"));
                city.put("register-of-deeds-url", getTagValue(cityEl, "register-of-deeds-url"));
                city.put("selected", cityEl.getAttribute("selected"));
                allCities.add(city);

                if ("true".equals(cityEl.getAttribute("selected")))
                {
                    this.cityName = city.get("name");
                    this.county = city.get("county");
                    this.state = city.get("state");
                    this.deedsUrl = city.get("deeds-url");
                    this.propertyRecordsUrl = city.get("property-records-url");
                    this.registerOfDeedsUrl = city.get("register-of-deeds-url");
                }
            }

            System.out.println("-- : [CityAnalysisServer] Loaded " + allCities.size() + " cities. Selected: " + cityName + ", " + state);
        }
        catch (Exception e)
        {
            System.err.println("-- : [CityAnalysisServer] Failed to load config: " + e.getMessage());
        }
    }

    /**
     * Load legalice.presumes.xml — presumptions, rules, lessons, proofs
     */
    protected void loadPresumptions()
    {
        try
        {
            File presumesFile = new File(PRESUMES_PATH);
            DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
            DocumentBuilder builder = factory.newDocumentBuilder();
            Document doc = builder.parse(presumesFile);
            doc.getDocumentElement().normalize();

            NodeList classNodes = doc.getElementsByTagName("class");
            for (int i = 0; i < classNodes.getLength(); i++)
            {
                Element el = (Element) classNodes.item(i);
                Map<String, String> entry = new HashMap<>();
                entry.put("id", el.getAttribute("id"));
                entry.put("label", getTagValue(el, "label"));
                entry.put("moral-spectrum", getTagValue(el, "moral-spectrum"));
                entry.put("age-consideration", getTagValue(el, "age-consideration"));
                entry.put("presumption", getTagValue(el, "presumption"));
                entry.put("rule", getTagValue(el, "rule"));
                entry.put("lesson", getTagValue(el, "lesson"));
                entry.put("proof", getTagValue(el, "proof"));
                presumptions.add(entry);
            }

            System.out.println("-- : [CityAnalysisServer] Loaded " + presumptions.size() + " presumption classes from legalice.presumes.xml");
        }
        catch (Exception e)
        {
            System.err.println("-- : [CityAnalysisServer] Failed to load presumptions: " + e.getMessage());
        }
    }

    /**
     * Get presumption entry for a given class id
     */
    public Map<String, String> getPresumption(String classId)
    {
        for (Map<String, String> entry : presumptions)
        {
            if (classId.equals(entry.get("id"))) return entry;
        }
        return null;
    }

    /**
     * Select a different city by name
     */
    public void selectCity(String name)
    {
        for (Map<String, String> city : allCities)
        {
            if (city.get("name").equalsIgnoreCase(name))
            {
                this.cityName = city.get("name");
                this.county = city.get("county");
                this.state = city.get("state");
                this.deedsUrl = city.get("deeds-url");
                this.propertyRecordsUrl = city.get("property-records-url");
                this.registerOfDeedsUrl = city.get("register-of-deeds-url");
                System.out.println("-- : [CityAnalysisServer] Selected city: " + cityName);
                return;
            }
        }
        System.err.println("-- : [CityAnalysisServer] City not found: " + name);
    }

    /**
     * Fetch the property records page for the currently selected city
     */
    public String fetchPropertyRecords()
    {
        System.out.println("-- : [CityAnalysisServer] Fetching property records for " + cityName + " from " + propertyRecordsUrl);
        return httpGet(propertyRecordsUrl);
    }

    /**
     * Fetch the register of deeds page for the currently selected city
     */
    public String fetchRegisterOfDeeds()
    {
        System.out.println("-- : [CityAnalysisServer] Fetching register of deeds for " + cityName + " from " + registerOfDeedsUrl);
        return httpGet(registerOfDeedsUrl);
    }

    /**
     * Fetch the deeds search page for the currently selected city
     */
    public String fetchDeedsSearch()
    {
        System.out.println("-- : [CityAnalysisServer] Fetching deeds search for " + cityName + " from " + deedsUrl);
        return httpGet(deedsUrl);
    }

    /**
     * HTTP GET with retry logic
     */
    protected String httpGet(String urlStr)
    {
        for (int attempt = 1; attempt <= retryCount; attempt++)
        {
            try
            {
                URL url = new URL(urlStr);
                HttpURLConnection conn = (HttpURLConnection) url.openConnection();
                conn.setRequestMethod("GET");
                conn.setConnectTimeout(timeoutMs);
                conn.setReadTimeout(timeoutMs);
                conn.setRequestProperty("User-Agent", userAgent);

                int code = conn.getResponseCode();
                if (code == 200)
                {
                    try (BufferedReader reader = new BufferedReader(new InputStreamReader(conn.getInputStream(), StandardCharsets.UTF_8)))
                    {
                        StringBuilder sb = new StringBuilder();
                        String line;
                        while ((line = reader.readLine()) != null)
                        {
                            sb.append(line).append("\n");
                        }
                        System.out.println("-- : [CityAnalysisServer] Fetched " + sb.length() + " bytes from " + urlStr);
                        return sb.toString();
                    }
                }
                else
                {
                    System.err.println("-- : [CityAnalysisServer] HTTP " + code + " from " + urlStr + " (attempt " + attempt + ")");
                }
            }
            catch (Exception e)
            {
                System.err.println("-- : [CityAnalysisServer] Error fetching " + urlStr + " (attempt " + attempt + "): " + e.getMessage());
            }
        }
        return null;
    }

    /**
     * List all configured cities
     */
    public List<Map<String, String>> listCities()
    {
        return Collections.unmodifiableList(allCities);
    }

    /**
     * Get the currently selected city name
     */
    public String getSelectedCity()
    {
        return cityName + ", " + county + " County, " + state;
    }

    protected String getTagValue(Element parent, String tag)
    {
        NodeList nodes = parent.getElementsByTagName(tag);
        if (nodes.getLength() > 0)
        {
            return nodes.item(0).getTextContent().trim();
        }
        return "";
    }

    public static void main(String[] args)
    {
        CityAnalysisServer server = new CityAnalysisServer();

        // If a city name is passed as argument, select it
        if (args.length > 0)
        {
            server.selectCity(String.join(" ", args));
        }

        System.out.println("-- : [CityAnalysisServer] Active city: " + server.getSelectedCity());
        System.out.println("-- : [CityAnalysisServer] Deeds URL: " + server.deedsUrl);
        System.out.println("-- : [CityAnalysisServer] Property Records URL: " + server.propertyRecordsUrl);

        // Fetch deeds page
        String deedsHtml = server.fetchDeedsSearch();
        if (deedsHtml != null)
        {
            System.out.println("-- : [CityAnalysisServer] Deeds page retrieved (" + deedsHtml.length() + " chars)");
        }

        // Fetch property records page
        String propertyHtml = server.fetchPropertyRecords();
        if (propertyHtml != null)
        {
            System.out.println("-- : [CityAnalysisServer] Property records page retrieved (" + propertyHtml.length() + " chars)");
        }
    }
}
