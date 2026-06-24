package city_analysis;

import java.io.*;
import java.net.*;
import java.nio.charset.StandardCharsets;
import java.nio.file.*;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.regex.*;
import javax.net.ssl.*;
import javax.xml.parsers.*;
import org.w3c.dom.*;

/**
 * @author Max Rupplin
 *
 * @date June 23 2026
 *
 * CityAnalysisCrawler — Aware API approach for crawling property/deeds websites.
 * Follows links, stores raw HTML/XML/CSV to /raw/<datetime>/, respects depth and rate limits.
 * Driven by city-analysis-config.xml crawl-options.
 */
public class CityAnalysisCrawler
{
    protected String hash = "0xCA717018470E914C";

    protected static final String CONFIG_PATH = "source/city/analysis/city-analysis-config.xml";

    protected String rawDir = "source/city/analysis/raw/";
    protected boolean followLinks = true;
    protected int maxDepth = 3;
    protected int maxPages = 50;
    protected Set<String> acceptedTypes = new HashSet<>(Arrays.asList("html", "xml", "csv"));
    protected long delayMs = 2000;
    protected int timeoutMs = 15000;
    protected String userAgent = "NitroWebExpress/CityAnalysis 1.0";

    protected Set<String> visited = new HashSet<>();
    protected List<Path> storedFiles = new ArrayList<>();
    protected String sessionDir;

    public CityAnalysisCrawler()
    {
        loadConfig();
        sessionDir = rawDir + LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd/HH-mm-ss")) + "/";
    }

    protected void loadConfig()
    {
        try
        {
            Document doc = DocumentBuilderFactory.newInstance().newDocumentBuilder().parse(new File(CONFIG_PATH));
            doc.getDocumentElement().normalize();

            NodeList crawlNodes = doc.getElementsByTagName("crawl-options");
            if (crawlNodes.getLength() > 0)
            {
                Element crawl = (Element) crawlNodes.item(0);
                rawDir = getTag(crawl, "raw-dir");
                followLinks = "true".equals(getTag(crawl, "follow-links"));
                maxDepth = Integer.parseInt(getTag(crawl, "max-depth"));
                maxPages = Integer.parseInt(getTag(crawl, "max-pages"));
                delayMs = Long.parseLong(getTag(crawl, "delay-between-requests-ms"));
                String types = getTag(crawl, "accepted-types");
                if (!types.isEmpty()) acceptedTypes = new HashSet<>(Arrays.asList(types.split(",")));
            }

            NodeList connNodes = doc.getElementsByTagName("connection");
            if (connNodes.getLength() > 0)
            {
                Element conn = (Element) connNodes.item(0);
                timeoutMs = Integer.parseInt(getTag(conn, "timeout-ms"));
                userAgent = getTag(conn, "user-agent");
            }

            System.out.println("-- : [CityAnalysisCrawler] Config loaded. maxDepth:" + maxDepth + " maxPages:" + maxPages + " delay:" + delayMs + "ms");
        }
        catch (Exception e)
        {
            System.err.println("-- : [CityAnalysisCrawler] Config load failed: " + e.getMessage());
        }
    }

    /**
     * Crawl starting from a set of seed URLs
     */
    public List<Path> crawl(String... seedUrls)
    {
        try { Files.createDirectories(Paths.get(sessionDir)); }
        catch (Exception e) { /* ignore */ }

        Deque<String[]> queue = new ArrayDeque<>(); // [url, depth]
        for (String url : seedUrls)
        {
            queue.add(new String[]{url, "0"});
        }

        while (!queue.isEmpty() && visited.size() < maxPages)
        {
            String[] item = queue.poll();
            String url = item[0];
            int depth = Integer.parseInt(item[1]);

            if (visited.contains(url) || depth > maxDepth) continue;
            visited.add(url);

            System.out.println("-- : [CityAnalysisCrawler] Crawling (" + depth + "/" + maxDepth + "): " + url);

            String content = fetch(url);
            if (content == null) continue;

            // Determine content type and store
            String ext = inferExtension(url, content);
            if (acceptedTypes.contains(ext))
            {
                Path stored = storeRaw(url, content, ext);
                if (stored != null) storedFiles.add(stored);
            }

            // Extract and queue links if following
            if (followLinks && depth < maxDepth)
            {
                List<String> links = extractLinks(url, content);
                for (String link : links)
                {
                    if (!visited.contains(link))
                    {
                        queue.add(new String[]{link, String.valueOf(depth + 1)});
                    }
                }
            }

            // Rate limiting
            try { Thread.sleep(delayMs); } catch (InterruptedException e) { break; }
        }

        System.out.println("-- : [CityAnalysisCrawler] Crawl complete. Pages:" + visited.size() + " Files stored:" + storedFiles.size());
        return storedFiles;
    }

    /**
     * Fetch URL content with SSL support
     */
    protected String fetch(String urlStr)
    {
        try
        {
            URL url = new URL(urlStr);
            HttpURLConnection conn;

            if ("https".equalsIgnoreCase(url.getProtocol()))
            {
                HttpsURLConnection httpsConn = (HttpsURLConnection) url.openConnection();
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
                httpsConn.setSSLSocketFactory(ctx.getSocketFactory());
                httpsConn.setHostnameVerifier((h, s) -> true);
                conn = httpsConn;
            }
            else
            {
                conn = (HttpURLConnection) url.openConnection();
            }

            conn.setRequestMethod("GET");
            conn.setConnectTimeout(timeoutMs);
            conn.setReadTimeout(timeoutMs);
            conn.setRequestProperty("User-Agent", userAgent);
            conn.setInstanceFollowRedirects(true);

            int code = conn.getResponseCode();
            if (code == 200)
            {
                try (BufferedReader reader = new BufferedReader(new InputStreamReader(conn.getInputStream(), StandardCharsets.UTF_8)))
                {
                    StringBuilder sb = new StringBuilder();
                    String line;
                    while ((line = reader.readLine()) != null) sb.append(line).append("\n");
                    return sb.toString();
                }
            }
            else
            {
                System.err.println("-- : [CityAnalysisCrawler] HTTP " + code + " from " + urlStr);
            }
        }
        catch (Exception e)
        {
            System.err.println("-- : [CityAnalysisCrawler] Fetch error: " + urlStr + " — " + e.getMessage());
        }
        return null;
    }

    /**
     * Store raw content to /raw/<datetime>/<filename>
     */
    protected Path storeRaw(String url, String content, String ext)
    {
        try
        {
            String filename = url.replaceAll("https?://", "").replaceAll("[^a-zA-Z0-9.-]", "_");
            if (filename.length() > 100) filename = filename.substring(0, 100);
            filename += "." + ext;

            Path outPath = Paths.get(sessionDir, filename);
            Files.writeString(outPath, content);
            System.out.println("-- : [CityAnalysisCrawler] Stored: " + outPath + " (" + content.length() + " chars)");
            return outPath;
        }
        catch (Exception e)
        {
            System.err.println("-- : [CityAnalysisCrawler] Store error: " + e.getMessage());
            return null;
        }
    }

    /**
     * Extract links from HTML content, resolve relative to base URL
     */
    protected List<String> extractLinks(String baseUrl, String content)
    {
        List<String> links = new ArrayList<>();
        Pattern pattern = Pattern.compile("href=[\"']([^\"'#]+)[\"']", Pattern.CASE_INSENSITIVE);
        Matcher m = pattern.matcher(content);
        String baseHost;
        try { baseHost = new URL(baseUrl).getHost(); } catch (Exception e) { return links; }

        while (m.find())
        {
            String href = m.group(1).trim();
            try
            {
                URL resolved = new URL(new URL(baseUrl), href);
                // Stay on same host
                if (resolved.getHost().equals(baseHost))
                {
                    links.add(resolved.toString());
                }
            }
            catch (Exception e) { /* skip malformed */ }
        }
        return links;
    }

    /**
     * Infer file extension from URL or content
     */
    protected String inferExtension(String url, String content)
    {
        if (url.endsWith(".csv") || content.startsWith("\"") && content.contains(",")) return "csv";
        if (url.endsWith(".xml") || content.trim().startsWith("<?xml")) return "xml";
        return "html";
    }

    public List<Path> getStoredFiles()
    {
        return storedFiles;
    }

    protected String getTag(Element parent, String tag)
    {
        NodeList nodes = parent.getElementsByTagName(tag);
        return nodes.getLength() > 0 ? nodes.item(0).getTextContent().trim() : "";
    }
}
