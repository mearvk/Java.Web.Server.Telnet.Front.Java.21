package city_analysis;

import java.io.*;
import java.net.*;
import java.nio.charset.StandardCharsets;
import java.nio.file.*;
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
 * CityAnalysisSearchEngine — Web search integration for CityAnalysis™.
 * Queries search engines for real estate, lending, and property data
 * to supplement county/city sources.
 *
 * Supported engines: Google (default), Bing, DuckDuckGo, Brave
 * Configured in city-analysis-config.xml <search-engine> section.
 */
public class CityAnalysisSearchEngine
{
    protected String hash = "0xCA717018470E914D";

    protected static final String CONFIG_PATH = "source/city/analysis/city-analysis-config.xml";
    protected static final String RESULTS_DIR = "source/city/analysis/search-results/";

    protected String engine = "google";
    protected String apiKey = "";
    protected String cx = "";
    protected int maxResults = 10;
    protected boolean enabled = true;
    protected int timeoutMs = 15000;
    protected String userAgent = "NitroWebExpress/CityAnalysis 1.0";

    protected String[] queryTemplates = {
        "%CITY% %STATE% real estate market trends",
        "%CITY% %COUNTY% county lending practices mortgage",
        "%CITY% %STATE% property values deed records",
        "%CITY% %STATE% foreclosure rates housing market",
        "%CITY% %COUNTY% county real estate investment"
    };

    protected List<String> searchResults = new ArrayList<>();

    public CityAnalysisSearchEngine()
    {
        loadConfig();
    }

    /**
     * Load search-engine config from city-analysis-config.xml
     */
    protected void loadConfig()
    {
        try
        {
            Document doc = DocumentBuilderFactory.newInstance().newDocumentBuilder().parse(new File(CONFIG_PATH));
            doc.getDocumentElement().normalize();

            NodeList seNodes = doc.getElementsByTagName("search-engine");
            if (seNodes.getLength() > 0)
            {
                Element se = (Element) seNodes.item(0);
                this.enabled = "true".equals(getTag(se, "enabled"));
                this.engine = getTag(se, "default-engine");
                this.apiKey = getTag(se, "api-key");
                this.cx = getTag(se, "cx");
                String mr = getTag(se, "max-results");
                if (!mr.isEmpty()) this.maxResults = Integer.parseInt(mr);

                // Load custom query templates if present
                NodeList qtNodes = se.getElementsByTagName("query");
                if (qtNodes.getLength() > 0)
                {
                    queryTemplates = new String[qtNodes.getLength()];
                    for (int i = 0; i < qtNodes.getLength(); i++)
                    {
                        queryTemplates[i] = qtNodes.item(i).getTextContent().trim();
                    }
                }
            }

            System.out.println("-- : [CityAnalysisSearchEngine] Config loaded. Engine:" + engine + " Enabled:" + enabled + " MaxResults:" + maxResults);
        }
        catch (Exception e)
        {
            System.err.println("-- : [CityAnalysisSearchEngine] Config load failed: " + e.getMessage());
        }
    }

    /**
     * Execute search queries for a given city and return combined results text
     */
    public String search(String cityName, String county, String state)
    {
        if (!enabled)
        {
            System.out.println("-- : [CityAnalysisSearchEngine] Search disabled in config.");
            return "";
        }

        searchResults.clear();
        StringBuilder combined = new StringBuilder();

        for (String template : queryTemplates)
        {
            String query = template
                    .replace("%CITY%", cityName)
                    .replace("%COUNTY%", county)
                    .replace("%STATE%", state);

            System.out.println("-- : [CityAnalysisSearchEngine] Searching [" + engine + "]: " + query);

            String result = executeSearch(query);
            if (result != null && !result.isEmpty())
            {
                searchResults.add(result);
                combined.append(result).append("\n");
            }

            // Rate limit between queries
            try { Thread.sleep(1500); } catch (InterruptedException e) { break; }
        }

        // Store results
        storeResults(cityName);

        System.out.println("-- : [CityAnalysisSearchEngine] Search complete. " + searchResults.size() + " results gathered. Total chars: " + combined.length());
        return combined.toString();
    }

    /**
     * Execute a single search query against the configured engine
     */
    protected String executeSearch(String query)
    {
        return switch (engine.toLowerCase())
        {
            case "google" -> searchGoogle(query);
            case "bing" -> searchBing(query);
            case "duckduckgo" -> searchDuckDuckGo(query);
            case "brave" -> searchBrave(query);
            default -> searchGoogle(query);
        };
    }

    /**
     * Google Custom Search JSON API
     * Requires: API key + Custom Search Engine ID (cx)
     * Docs: https://developers.google.com/custom-search/v1/overview
     */
    protected String searchGoogle(String query)
    {
        try
        {
            String encoded = URLEncoder.encode(query, StandardCharsets.UTF_8);
            String url = "https://www.googleapis.com/customsearch/v1?key=" + apiKey
                    + "&cx=" + cx
                    + "&q=" + encoded
                    + "&num=" + maxResults;

            String json = httpGet(url);
            if (json == null) return null;
            return parseGoogleResults(json, query);
        }
        catch (Exception e)
        {
            System.err.println("-- : [CityAnalysisSearchEngine] Google search error: " + e.getMessage());
            return null;
        }
    }

    /**
     * Bing Web Search API v7
     * Requires: Ocp-Apim-Subscription-Key header
     */
    protected String searchBing(String query)
    {
        try
        {
            String encoded = URLEncoder.encode(query, StandardCharsets.UTF_8);
            String url = "https://api.bing.microsoft.com/v7.0/search?q=" + encoded + "&count=" + maxResults;

            HttpURLConnection conn = (HttpURLConnection) new URL(url).openConnection();
            conn.setRequestMethod("GET");
            conn.setConnectTimeout(timeoutMs);
            conn.setReadTimeout(timeoutMs);
            conn.setRequestProperty("Ocp-Apim-Subscription-Key", apiKey);

            if (conn.getResponseCode() == 200)
            {
                String json = readStream(conn.getInputStream());
                return parseBingResults(json, query);
            }
        }
        catch (Exception e)
        {
            System.err.println("-- : [CityAnalysisSearchEngine] Bing search error: " + e.getMessage());
        }
        return null;
    }

    /**
     * DuckDuckGo Instant Answer API (no key required, limited results)
     */
    protected String searchDuckDuckGo(String query)
    {
        try
        {
            String encoded = URLEncoder.encode(query, StandardCharsets.UTF_8);
            String url = "https://api.duckduckgo.com/?q=" + encoded + "&format=json&no_html=1";
            String json = httpGet(url);
            if (json == null) return null;
            return parseDuckDuckGoResults(json, query);
        }
        catch (Exception e)
        {
            System.err.println("-- : [CityAnalysisSearchEngine] DuckDuckGo search error: " + e.getMessage());
            return null;
        }
    }

    /**
     * Brave Search API
     * Requires: X-Subscription-Token header
     */
    protected String searchBrave(String query)
    {
        try
        {
            String encoded = URLEncoder.encode(query, StandardCharsets.UTF_8);
            String url = "https://api.search.brave.com/res/v1/web/search?q=" + encoded + "&count=" + maxResults;

            HttpURLConnection conn = (HttpURLConnection) new URL(url).openConnection();
            conn.setRequestMethod("GET");
            conn.setConnectTimeout(timeoutMs);
            conn.setReadTimeout(timeoutMs);
            conn.setRequestProperty("X-Subscription-Token", apiKey);
            conn.setRequestProperty("Accept", "application/json");

            if (conn.getResponseCode() == 200)
            {
                String json = readStream(conn.getInputStream());
                return parseBraveResults(json, query);
            }
        }
        catch (Exception e)
        {
            System.err.println("-- : [CityAnalysisSearchEngine] Brave search error: " + e.getMessage());
        }
        return null;
    }

    /**
     * Parse Google JSON response — extract titles, snippets, links
     */
    protected String parseGoogleResults(String json, String query)
    {
        StringBuilder sb = new StringBuilder();
        sb.append("--- SEARCH RESULTS [Google]: ").append(query).append(" ---\n");

        // Simple JSON parsing without external library
        String[] items = json.split("\"title\"\\s*:");
        for (int i = 1; i < items.length && i <= maxResults; i++)
        {
            String title = extractJsonString(items[i]);
            String snippet = extractAfterKey(items[i], "snippet");
            String link = extractAfterKey(items[i], "link");
            sb.append("  [").append(i).append("] ").append(title).append("\n");
            if (link != null) sb.append("      URL: ").append(link).append("\n");
            if (snippet != null) sb.append("      ").append(snippet).append("\n");
        }
        return sb.toString();
    }

    protected String parseBingResults(String json, String query)
    {
        StringBuilder sb = new StringBuilder();
        sb.append("--- SEARCH RESULTS [Bing]: ").append(query).append(" ---\n");
        String[] items = json.split("\"name\"\\s*:");
        for (int i = 1; i < items.length && i <= maxResults; i++)
        {
            String name = extractJsonString(items[i]);
            String snippet = extractAfterKey(items[i], "snippet");
            String url = extractAfterKey(items[i], "url");
            sb.append("  [").append(i).append("] ").append(name).append("\n");
            if (url != null) sb.append("      URL: ").append(url).append("\n");
            if (snippet != null) sb.append("      ").append(snippet).append("\n");
        }
        return sb.toString();
    }

    protected String parseDuckDuckGoResults(String json, String query)
    {
        StringBuilder sb = new StringBuilder();
        sb.append("--- SEARCH RESULTS [DuckDuckGo]: ").append(query).append(" ---\n");
        String abstractText = extractAfterKey(json, "AbstractText");
        String abstractUrl = extractAfterKey(json, "AbstractURL");
        if (abstractText != null && !abstractText.isEmpty())
        {
            sb.append("  ").append(abstractText).append("\n");
            if (abstractUrl != null) sb.append("  URL: ").append(abstractUrl).append("\n");
        }
        // Related topics
        String[] topics = json.split("\"Text\"\\s*:");
        for (int i = 1; i < topics.length && i <= maxResults; i++)
        {
            String text = extractJsonString(topics[i]);
            String firstUrl = extractAfterKey(topics[i], "FirstURL");
            sb.append("  [").append(i).append("] ").append(text).append("\n");
            if (firstUrl != null) sb.append("      URL: ").append(firstUrl).append("\n");
        }
        return sb.toString();
    }

    protected String parseBraveResults(String json, String query)
    {
        StringBuilder sb = new StringBuilder();
        sb.append("--- SEARCH RESULTS [Brave]: ").append(query).append(" ---\n");
        String[] items = json.split("\"title\"\\s*:");
        for (int i = 1; i < items.length && i <= maxResults; i++)
        {
            String title = extractJsonString(items[i]);
            String description = extractAfterKey(items[i], "description");
            String url = extractAfterKey(items[i], "url");
            sb.append("  [").append(i).append("] ").append(title).append("\n");
            if (url != null) sb.append("      URL: ").append(url).append("\n");
            if (description != null) sb.append("      ").append(description).append("\n");
        }
        return sb.toString();
    }

    /**
     * Extract first JSON string value after current position
     */
    protected String extractJsonString(String segment)
    {
        int start = segment.indexOf("\"");
        if (start < 0) return "";
        int end = segment.indexOf("\"", start + 1);
        if (end < 0) return "";
        return segment.substring(start + 1, end);
    }

    /**
     * Extract JSON value for a given key within a segment
     */
    protected String extractAfterKey(String segment, String key)
    {
        int idx = segment.indexOf("\"" + key + "\"");
        if (idx < 0) return null;
        String after = segment.substring(idx + key.length() + 2);
        int colon = after.indexOf(":");
        if (colon < 0) return null;
        after = after.substring(colon + 1).trim();
        if (after.startsWith("\""))
        {
            int end = after.indexOf("\"", 1);
            if (end > 0) return after.substring(1, end);
        }
        return null;
    }

    /**
     * HTTP GET
     */
    protected String httpGet(String urlStr)
    {
        try
        {
            HttpURLConnection conn = (HttpURLConnection) new URL(urlStr).openConnection();
            conn.setRequestMethod("GET");
            conn.setConnectTimeout(timeoutMs);
            conn.setReadTimeout(timeoutMs);
            conn.setRequestProperty("User-Agent", userAgent);

            if (conn.getResponseCode() == 200)
            {
                return readStream(conn.getInputStream());
            }
            else
            {
                System.err.println("-- : [CityAnalysisSearchEngine] HTTP " + conn.getResponseCode() + " from " + urlStr);
            }
        }
        catch (Exception e)
        {
            System.err.println("-- : [CityAnalysisSearchEngine] HTTP error: " + e.getMessage());
        }
        return null;
    }

    protected String readStream(InputStream is) throws IOException
    {
        try (BufferedReader reader = new BufferedReader(new InputStreamReader(is, StandardCharsets.UTF_8)))
        {
            StringBuilder sb = new StringBuilder();
            String line;
            while ((line = reader.readLine()) != null) sb.append(line).append("\n");
            return sb.toString();
        }
    }

    /**
     * Store search results to file
     */
    protected void storeResults(String cityName)
    {
        try
        {
            Files.createDirectories(Paths.get(RESULTS_DIR));
            String timestamp = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMdd-HHmmss"));
            Path outPath = Paths.get(RESULTS_DIR, cityName + ".search." + timestamp + ".txt");
            Files.write(outPath, searchResults);
            System.out.println("-- : [CityAnalysisSearchEngine] Results stored: " + outPath);
        }
        catch (Exception e)
        {
            System.err.println("-- : [CityAnalysisSearchEngine] Store error: " + e.getMessage());
        }
    }

    /**
     * Get results as source URLs for adding back into CAS additional-sources
     */
    public List<String> getDiscoveredUrls()
    {
        List<String> urls = new ArrayList<>();
        for (String result : searchResults)
        {
            String[] lines = result.split("\n");
            for (String line : lines)
            {
                if (line.trim().startsWith("URL: "))
                {
                    urls.add(line.trim().substring(5).trim());
                }
            }
        }
        return urls;
    }

    public List<String> getSearchResults() { return searchResults; }
    public String getEngine() { return engine; }
    public boolean isEnabled() { return enabled; }

    /**
     * Extract typed input objects from search results for CSE consumption.
     * Targets ~1200 items across all input types defined in cse-allowance-config.xml.
     */
    public List<Map<String, String>> extractInputObjects()
    {
        List<Map<String, String>> objects = new ArrayList<>();

        java.util.regex.Pattern dollarPattern = java.util.regex.Pattern.compile("\\$[\\d,]+\\.?\\d*");
        java.util.regex.Pattern percentPattern = java.util.regex.Pattern.compile("\\d+\\.?\\d*\\s*%");
        java.util.regex.Pattern urlPattern = java.util.regex.Pattern.compile("https?://[^\\s<>\"]+");
        java.util.regex.Pattern datePattern = java.util.regex.Pattern.compile("\\b(\\d{1,2}/\\d{1,2}/\\d{2,4}|\\d{4}-\\d{2}-\\d{2}|(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]* \\d{1,2},? \\d{4})\\b");
        java.util.regex.Pattern legalRefPattern = java.util.regex.Pattern.compile("\\b(?:Book|Page|Instrument|Deed|Plat|Document)\\s*(?:#|No\\.?)?\\s*\\d+", java.util.regex.Pattern.CASE_INSENSITIVE);
        java.util.regex.Pattern parcelPattern = java.util.regex.Pattern.compile("\\b\\d{4,}[-.]\\d{2,}[-.]\\d{2,}\\b");
        java.util.regex.Pattern addressPattern = java.util.regex.Pattern.compile("\\d+\\s+[A-Z][a-zA-Z]+(?:\\s+[A-Z][a-zA-Z]+)*\\s+(?:St|Ave|Blvd|Dr|Rd|Ln|Way|Ct|Pl|Cir)", java.util.regex.Pattern.CASE_INSENSITIVE);
        java.util.regex.Pattern statisticPattern = java.util.regex.Pattern.compile("\\b(?:median|average|total|population|count|units)\\s*:?\\s*[\\d,]+", java.util.regex.Pattern.CASE_INSENSITIVE);

        String[] lenderKeywords = {"bank", "mortgage", "lending", "credit union", "financial", "savings", "loan", "capital", "trust"};
        String[] foreKeywords = {"foreclosure", "foreclosed", "default", "lis pendens", "notice of sale"};
        String[] transferKeywords = {"transfer", "convey", "grant", "deed of trust", "warranty deed", "quitclaim"};

        for (String result : searchResults)
        {
            String[] lines = result.split("\n");
            for (String line : lines)
            {
                // URLs
                java.util.regex.Matcher m = urlPattern.matcher(line);
                while (m.find()) objects.add(Map.of("type", "url", "value", m.group()));

                // Titles/snippets from bracketed results
                if (line.trim().startsWith("[") && line.contains("]"))
                {
                    String title = line.substring(line.indexOf("]") + 1).trim();
                    if (!title.isEmpty()) objects.add(Map.of("type", "title", "value", title));
                }
                else if (!line.startsWith("---") && !line.startsWith("  [") && !line.startsWith("      URL:") && line.trim().length() > 20)
                {
                    objects.add(Map.of("type", "snippet", "value", line.trim()));
                }

                // Dollar amounts
                m = dollarPattern.matcher(line);
                while (m.find()) objects.add(Map.of("type", "dollar-amount", "value", m.group()));

                // Percentages
                m = percentPattern.matcher(line);
                while (m.find()) objects.add(Map.of("type", "percentage", "value", m.group()));

                // Dates
                m = datePattern.matcher(line);
                while (m.find()) objects.add(Map.of("type", "date", "value", m.group()));

                // Legal references
                m = legalRefPattern.matcher(line);
                while (m.find()) objects.add(Map.of("type", "legal-ref", "value", m.group()));

                // Parcel IDs
                m = parcelPattern.matcher(line);
                while (m.find()) objects.add(Map.of("type", "parcel-id", "value", m.group()));

                // Addresses
                m = addressPattern.matcher(line);
                while (m.find()) objects.add(Map.of("type", "address", "value", m.group()));

                // Statistics
                m = statisticPattern.matcher(line);
                while (m.find()) objects.add(Map.of("type", "statistic", "value", m.group()));

                // Lender names
                String lower = line.toLowerCase();
                for (String kw : lenderKeywords)
                {
                    if (lower.contains(kw))
                    {
                        objects.add(Map.of("type", "lender", "value", line.trim()));
                        break;
                    }
                }

                // Foreclosures
                for (String kw : foreKeywords)
                {
                    if (lower.contains(kw))
                    {
                        objects.add(Map.of("type", "foreclosure", "value", line.trim()));
                        break;
                    }
                }

                // Transfers
                for (String kw : transferKeywords)
                {
                    if (lower.contains(kw))
                    {
                        objects.add(Map.of("type", "transfer", "value", line.trim()));
                        break;
                    }
                }

                // Mortgages
                if (lower.contains("mortgage") || lower.contains("deed of trust") || lower.contains("refinance"))
                {
                    objects.add(Map.of("type", "mortgage", "value", line.trim()));
                }
            }
        }

        System.out.println("-- : [CityAnalysisSearchEngine] Extracted " + objects.size() + " typed input objects from search results");
        return objects;
    }

    public int getTargetInputCount() { return 1200; }

    protected String getTag(Element parent, String tag)
    {
        NodeList nodes = parent.getElementsByTagName(tag);
        return nodes.getLength() > 0 ? nodes.item(0).getTextContent().trim() : "";
    }
}
