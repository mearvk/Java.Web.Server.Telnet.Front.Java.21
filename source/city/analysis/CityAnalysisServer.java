package city_analysis;

import java.io.*;
import java.net.*;
import java.nio.charset.StandardCharsets;
import java.nio.file.*;
import java.security.*;
import java.util.*;
import javax.net.ssl.*;
import javax.xml.parsers.*;

import city.analysis.ConnectionTracker;
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

    protected static final String CONFIG_PATH = "source/city/analysis/configuration/city-analysis-config.xml";
    protected static final String PRESUMES_PATH = "source/city/analysis/configuration/legalice.presumes.xml";
    protected static final String CERTS_DIR = "source/city/analysis/certs/";

    protected static final int[] SUPPORTED_PORTS = {21, 22, 80, 443, 8080};

    protected List<Map<String, String>> presumptions = new ArrayList<>();

    public String cityName;
    public String county;
    public String state;
    public String deedsUrl;
    public String propertyRecordsUrl;
    public String registerOfDeedsUrl;
    public List<String> additionalSources = new ArrayList<>();
    protected int timeoutMs;
    protected int retryCount;
    protected String userAgent;

    protected List<Map<String, String>> allCities = new ArrayList<>();
    public ConnectionTracker connectionTracker = new ConnectionTracker();

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
                    loadAdditionalSources(cityEl);
                }
            }

            System.out.println("-- : [CityAnalysisServer] Loaded " + allCities.size() + " cities. Selected: " + cityName + ", " + state + " (" + additionalSources.size() + " additional sources)");
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
     * Load additional source URLs from city element (skips delisted)
     */
    protected void loadAdditionalSources(Element cityEl)
    {
        additionalSources.clear();
        NodeList sourceNodes = cityEl.getElementsByTagName("source");
        for (int i = 0; i < sourceNodes.getLength(); i++)
        {
            Element sourceEl = (Element) sourceNodes.item(i);
            if ("delisted".equals(sourceEl.getAttribute("status")))
            {
                System.out.println("-- : [CityAnalysisServer] Skipping delisted source: " + sourceEl.getTextContent().trim());
                continue;
            }
            additionalSources.add(sourceEl.getTextContent().trim());
        }
    }

    /**
     * Fetch all sources (primary + additional) and return combined content
     */
    protected static final String RAW_DIR = "source/city/analysis/raw/";

    public String fetchAllSources()
    {
        StringBuilder all = new StringBuilder();
        String date = java.time.LocalDate.now().format(java.time.format.DateTimeFormatter.ofPattern("yyyy-MM-dd"));
        java.nio.file.Path rawDateDir = java.nio.file.Paths.get(RAW_DIR + date);
        try { java.nio.file.Files.createDirectories(rawDateDir); } catch (Exception e) { /* ignore */ }

        // Determine run number for today (001, 002, etc.)
        int runNum = 1;
        try (java.util.stream.Stream<java.nio.file.Path> dirs = java.nio.file.Files.list(rawDateDir))
        {
            runNum = (int) dirs.filter(java.nio.file.Files::isDirectory).count() + 1;
        }
        catch (Exception e) { /* first run */ }
        String runSuffix = String.format("%03d", runNum);

        java.nio.file.Path rawSessionDir = rawDateDir.resolve(runSuffix);
        try { java.nio.file.Files.createDirectories(rawSessionDir); } catch (Exception e) { /* ignore */ }

        String deeds = fetchDeedsSearch();
        if (deeds != null) { all.append(deeds); saveRaw(rawSessionDir, "deeds", deeds); }

        String property = fetchPropertyRecords();
        if (property != null) { all.append(property); saveRaw(rawSessionDir, "property-records", property); }

        String rod = fetchRegisterOfDeeds();
        if (rod != null) { all.append(rod); saveRaw(rawSessionDir, "register-of-deeds", rod); }

        int i = 0;
        for (String sourceUrl : additionalSources)
        {
            System.out.println("-- : [CityAnalysisServer] Fetching additional source: " + sourceUrl);
            String content;
            if (sourceUrl.startsWith("file://"))
            {
                content = readLocalFile(sourceUrl.substring(7));
            }
            else
            {
                content = httpGet(sourceUrl);
            }
            if (content != null)
            {
                all.append(content);
                saveRaw(rawSessionDir, "source-" + i, content);
            }
            i++;
        }

        System.out.println("-- : [CityAnalysisServer] All sources fetched. Total chars: " + all.length() + " Raw saved to: " + rawSessionDir);
        return all.toString();
    }

    /**
     * Save raw web result to /raw/<datetime>/ directory
     */
    protected void saveRaw(java.nio.file.Path dir, String label, String content)
    {
        try
        {
            java.nio.file.Path file = dir.resolve(cityName + "." + label + ".html");
            java.nio.file.Files.writeString(file, content);
        }
        catch (Exception e)
        {
            System.err.println("-- : [CityAnalysisServer] Raw save error: " + e.getMessage());
        }
    }

    /**
     * Read a local file as a source (for file:// URLs like census data)
     */
    protected String readLocalFile(String path)
    {
        try
        {
            String content = Files.readString(Paths.get(path));
            System.out.println("-- : [CityAnalysisServer] Read local file: " + path + " (" + content.length() + " chars)");
            return content;
        }
        catch (Exception e)
        {
            System.err.println("-- : [CityAnalysisServer] Local file read error: " + path + " — " + e.getMessage());
            return null;
        }
    }

    /**
     * HTTP/HTTPS GET with retry logic and SSL cert storage.
     * Port-aware: supports 21, 22, 80, 443, 8080 outbound.
     */
    protected String httpGet(String urlStr)
    {
        if (connectionTracker.isDelisted(urlStr))
        {
            System.out.println("-- : [CityAnalysisServer] Skipping delisted URL: " + urlStr);
            return null;
        }

        for (int attempt = 1; attempt <= retryCount; attempt++)
        {
            try
            {
                URL url = new URL(urlStr);
                int port = url.getPort() == -1 ? url.getDefaultPort() : url.getPort();

                HttpURLConnection conn;
                if ("https".equalsIgnoreCase(url.getProtocol()))
                {
                    HttpsURLConnection httpsConn = (HttpsURLConnection) url.openConnection();
                    SSLContext sslCtx = getSSLContext();
                    if (sslCtx != null) httpsConn.setSSLSocketFactory(sslCtx.getSocketFactory());
                    httpsConn.setHostnameVerifier((hostname, session) -> true);
                    httpsConn.setRequestMethod("GET");
                    httpsConn.setConnectTimeout(timeoutMs);
                    httpsConn.setReadTimeout(timeoutMs);
                    httpsConn.setRequestProperty("User-Agent", userAgent);
                    conn = httpsConn;

                    int code = conn.getResponseCode();
                    connectionTracker.record(urlStr, code);
                    storeCertificates(url.getHost(), httpsConn.getServerCertificates());

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
                            System.out.println("-- : [CityAnalysisServer] Fetched " + sb.length() + " bytes from " + urlStr + " (port " + port + ")");
                            return sb.toString();
                        }
                    }
                    else
                    {
                        System.err.println("-- : [CityAnalysisServer] HTTP " + code + " from " + urlStr + " (attempt " + attempt + ")");
                        if (connectionTracker.isDelisted(urlStr)) return null;
                    }
                    continue;
                }
                else
                {
                    conn = (HttpURLConnection) url.openConnection();
                }

                conn.setRequestMethod("GET");
                conn.setConnectTimeout(timeoutMs);
                conn.setReadTimeout(timeoutMs);
                conn.setRequestProperty("User-Agent", userAgent);

                int code = conn.getResponseCode();
                connectionTracker.record(urlStr, code);

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
                        System.out.println("-- : [CityAnalysisServer] Fetched " + sb.length() + " bytes from " + urlStr + " (port " + port + ")");
                        return sb.toString();
                    }
                }
                else
                {
                    System.err.println("-- : [CityAnalysisServer] HTTP " + code + " from " + urlStr + " (attempt " + attempt + ")");
                    if (connectionTracker.isDelisted(urlStr)) return null;
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
     * Load SSL context — uses local truststore if available, otherwise trusts all (for cert gathering)
     */
    protected SSLContext getSSLContext()
    {
        try
        {
            Path ksPath = Paths.get(CERTS_DIR, "truststore.jks");
            if (Files.exists(ksPath))
            {
                KeyStore ks = KeyStore.getInstance("JKS");
                try (InputStream is = Files.newInputStream(ksPath))
                {
                    ks.load(is, "changeit".toCharArray());
                }
                TrustManagerFactory tmf = TrustManagerFactory.getInstance(TrustManagerFactory.getDefaultAlgorithm());
                tmf.init(ks);
                SSLContext ctx = SSLContext.getInstance("TLS");
                ctx.init(null, tmf.getTrustManagers(), null);
                return ctx;
            }

            // No local truststore — trust all to allow initial cert capture
            TrustManager[] trustAll = new TrustManager[]{
                new javax.net.ssl.X509TrustManager()
                {
                    public java.security.cert.X509Certificate[] getAcceptedIssuers() { return null; }
                    public void checkClientTrusted(java.security.cert.X509Certificate[] c, String a) {}
                    public void checkServerTrusted(java.security.cert.X509Certificate[] c, String a) {}
                }
            };
            SSLContext ctx = SSLContext.getInstance("TLS");
            ctx.init(null, trustAll, new java.security.SecureRandom());
            return ctx;
        }
        catch (Exception e)
        {
            System.err.println("-- : [CityAnalysisServer] SSL context load warning: " + e.getMessage());
        }
        return null;
    }

    /**
     * Store SSL certificates from peer to certs/ directory
     */
    protected void storeCertificates(String host, java.security.cert.Certificate[] certs)
    {
        if (certs == null) return;
        try
        {
            Files.createDirectories(Paths.get(CERTS_DIR));
            for (int i = 0; i < certs.length; i++)
            {
                String filename = host.replace(".", "_") + "_cert_" + i + ".pem";
                Path certPath = Paths.get(CERTS_DIR, filename);
                if (!Files.exists(certPath))
                {
                    String pem = "-----BEGIN CERTIFICATE-----\n" +
                            Base64.getMimeEncoder(64, "\n".getBytes()).encodeToString(certs[i].getEncoded()) +
                            "\n-----END CERTIFICATE-----\n";
                    Files.writeString(certPath, pem);
                    System.out.println("-- : [CityAnalysisServer] Stored cert: " + filename);
                }
            }
        }
        catch (Exception e)
        {
            System.err.println("-- : [CityAnalysisServer] Cert storage warning: " + e.getMessage());
        }
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
