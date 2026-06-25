/**
 * RodPropertyQueryEngine — Full-data query engine for Durham County Register of Deeds.
 *
 * Submits searches to DOCSEARCH5S1 using configurable search type selectors
 * (human/soundex), then follows each result link to the document detail page
 * (e.g., /web/document/DOC255S471?search=DOCSEARCH5S1) to extract:
 *   - Book type, Page, Recorded date, Filed date
 *   - All Grantors and Grantees
 *   - Legal description
 *   - Document type/group
 *
 * Results are stored in the output CSV with full named column headers.
 *
 * @author Max Rupplin
 * @javaowner Max Rupplin
 * @date June 24 2026 EST
 */

package city_analysis;

import javax.net.ssl.*;
import java.io.*;
import java.net.*;
import java.nio.charset.StandardCharsets;
import java.security.SecureRandom;
import java.util.*;
import java.util.regex.*;

public class RodPropertyQueryEngine
{
    private static final String ROD_BASE = "https://rodweb.dconc.gov";
    private static final String SEARCH_URL = ROD_BASE + "/web/search/DOCSEARCH5S1";
    private static final String DOCUMENT_URL_PREFIX = ROD_BASE + "/web/document/";

    // Search type selector options (configured via XML)
    public enum NameType { HUMAN, SOUNDEX }

    private final String sessionCookie;
    private NameType nameType = NameType.HUMAN;
    private String docGroup = "";  // empty = all document groups

    public RodPropertyQueryEngine(String sessionCookie)
    {
        this.sessionCookie = sessionCookie;
    }

    public void setNameType(NameType type) { this.nameType = type; }
    public void setDocGroup(String group) { this.docGroup = group; }

    /**
     * Queries all available data for a property using parcel ID, name, and address.
     * Submits search, follows result document links, extracts full detail.
     *
     * @return list of pipe-delimited result strings with full document data
     */
    public List<String> queryAllData(String parcelId, String pin, String address, String streetName)
    {
        Set<String> seen = new HashSet<>();
        List<String> allResults = new ArrayList<>();

        // Strategy 1: Search by name extracted from address/parcel data
        if (!streetName.isEmpty())
        {
            mergeResults(allResults, seen, submitSearch(streetName, "", ""));
        }

        // Strategy 2: Search by parcel ID as cross-reference
        if (!parcelId.isEmpty())
        {
            mergeResults(allResults, seen, submitSearch("", "", parcelId));
        }

        return allResults;
    }

    /**
     * Queries by explicit last/first name (for known names from property records).
     */
    public List<String> queryByName(String lastName, String firstName)
    {
        return submitSearch(lastName, firstName, "");
    }

    /**
     * Submits the DOCSEARCH5S1 search form and follows each result document link.
     */
    private List<String> submitSearch(String lastName, String firstName, String crossRef)
    {
        List<String> results = new ArrayList<>();
        try
        {
            // Build POST body matching the SelfService DOCSEARCH5S1 form
            StringBuilder params = new StringBuilder();
            params.append("nameType=").append(nameType == NameType.SOUNDEX ? "soundex" : "human");
            if (!lastName.isEmpty())
                params.append("&lastName=").append(URLEncoder.encode(lastName, StandardCharsets.UTF_8));
            if (!firstName.isEmpty())
                params.append("&firstName=").append(URLEncoder.encode(firstName, StandardCharsets.UTF_8));
            if (!crossRef.isEmpty())
                params.append("&crossRefNumber=").append(URLEncoder.encode(crossRef, StandardCharsets.UTF_8));
            if (!docGroup.isEmpty())
                params.append("&docGroup=").append(URLEncoder.encode(docGroup, StandardCharsets.UTF_8));

            // Submit search
            String searchResultsHtml = httpPost(SEARCH_URL, params.toString());
            if (searchResultsHtml == null || searchResultsHtml.isEmpty()) return results;

            // Extract document links from search results
            List<String> docLinks = extractDocumentLinks(searchResultsHtml);

            // Follow each document link and extract full detail
            for (String docLink : docLinks)
            {
                String fullUrl = docLink.startsWith("http") ? docLink : ROD_BASE + docLink;
                String docHtml = httpGet(fullUrl);
                if (docHtml == null) continue;

                String record = extractDocumentDetail(docHtml, fullUrl);
                if (record != null && !record.isEmpty()) results.add(record);

                try { Thread.sleep(1500); } catch (InterruptedException e) { break; }
            }
        }
        catch (Exception e) { /* silently skip failed queries */ }
        return results;
    }

    /**
     * Extracts document links from search results page.
     * Pattern: /web/document/DOC<id>S<step>?search=DOCSEARCH5S1
     */
    private List<String> extractDocumentLinks(String html)
    {
        List<String> links = new ArrayList<>();
        Pattern pattern = Pattern.compile(
            "href=[\"'](/web/document/DOC\\d+S\\d+\\?search=DOCSEARCH5S1)[\"']",
            Pattern.CASE_INSENSITIVE);
        Matcher m = pattern.matcher(html);
        Set<String> seen = new HashSet<>();
        while (m.find())
        {
            String link = m.group(1);
            if (seen.add(link)) links.add(link);
        }

        // Fallback: look for any /web/document/ links
        if (links.isEmpty())
        {
            Pattern fallback = Pattern.compile(
                "href=[\"'](/web/document/[^\"']+)[\"']", Pattern.CASE_INSENSITIVE);
            Matcher fm = fallback.matcher(html);
            while (fm.find())
            {
                String link = fm.group(1);
                if (seen.add(link)) links.add(link);
            }
        }

        return links;
    }

    /**
     * Extracts full document detail from a document page.
     * Returns pipe-delimited: bookType|book|page|recordedDate|filedDate|docType|grantors|grantees|legal
     */
    private String extractDocumentDetail(String html, String url)
    {
        String bookType = extractField(html, "Book Type", "bookType");
        String book = extractField(html, "Book", "book");
        String page = extractField(html, "Page", "page");
        String recordedDate = extractField(html, "Recorded Date", "recordedDate", "Recording Date", "Recorded");
        String filedDate = extractField(html, "Filed Date", "filedDate", "File Date", "Filed");
        String docType = extractField(html, "Document Type", "docType", "Doc Type", "Instrument");
        String grantors = extractPartyList(html, "Grantor", "Direct");
        String grantees = extractPartyList(html, "Grantee", "Reverse", "Indirect");
        String legal = extractField(html, "Legal", "legal", "Legal Description");

        // If we couldn't extract structured fields, try table-based extraction
        if (bookType.isEmpty() && book.isEmpty() && page.isEmpty())
        {
            return extractFromTable(html);
        }

        return String.join("|", bookType, book, page, recordedDate, filedDate,
            docType, grantors, grantees, legal);
    }

    /**
     * Extracts a field value from HTML by label text patterns.
     */
    private String extractField(String html, String... labels)
    {
        for (String label : labels)
        {
            // Pattern 1: <label>Label:</label><value>X</value> or <span>Label</span>...<span>Value</span>
            Pattern p1 = Pattern.compile(
                label + "\\s*:?\\s*</(?:label|span|th|td|dt|div)>\\s*<(?:span|td|dd|div)[^>]*>\\s*([^<]+)",
                Pattern.CASE_INSENSITIVE);
            Matcher m1 = p1.matcher(html);
            if (m1.find()) return m1.group(1).trim();

            // Pattern 2: <td>Label</td><td>Value</td>
            Pattern p2 = Pattern.compile(
                "<td[^>]*>\\s*" + label + "\\s*</td>\\s*<td[^>]*>\\s*([^<]+)",
                Pattern.CASE_INSENSITIVE);
            Matcher m2 = p2.matcher(html);
            if (m2.find()) return m2.group(1).trim();

            // Pattern 3: data-label="Label" ... value
            Pattern p3 = Pattern.compile(
                "data-label=[\"']" + label + "[\"'][^>]*>\\s*([^<]+)",
                Pattern.CASE_INSENSITIVE);
            Matcher m3 = p3.matcher(html);
            if (m3.find()) return m3.group(1).trim();

            // Pattern 4: ss-listview label: value
            Pattern p4 = Pattern.compile(
                "<[^>]+>\\s*" + label + "\\s*</[^>]+>\\s*<[^>]+>\\s*([^<]+)",
                Pattern.CASE_INSENSITIVE);
            Matcher m4 = p4.matcher(html);
            if (m4.find()) return m4.group(1).trim();
        }
        return "";
    }

    /**
     * Extracts a list of party names (grantor/grantee) from the document page.
     */
    private String extractPartyList(String html, String... partyLabels)
    {
        List<String> names = new ArrayList<>();
        for (String label : partyLabels)
        {
            // Find section with party label then collect all names
            Pattern sectionPattern = Pattern.compile(
                label + ".*?</(?:ul|table|div|section)>", Pattern.DOTALL | Pattern.CASE_INSENSITIVE);
            Matcher sm = sectionPattern.matcher(html);
            if (sm.find())
            {
                String section = sm.group();
                // Extract individual names from list items or table cells
                Pattern namePattern = Pattern.compile(
                    "<(?:li|td|span)[^>]*>\\s*([A-Z][A-Z\\s,.'\\-]+)\\s*</(?:li|td|span)>",
                    Pattern.CASE_INSENSITIVE);
                Matcher nm = namePattern.matcher(section);
                while (nm.find())
                {
                    String name = nm.group(1).trim();
                    if (name.length() > 2 && !name.equalsIgnoreCase(label))
                        names.add(name);
                }
            }
        }
        return names.isEmpty() ? "" : String.join("; ", names);
    }

    /**
     * Fallback: extract from table-style result rows.
     */
    private String extractFromTable(String html)
    {
        Pattern rowPattern = Pattern.compile("<tr[^>]*>(.*?)</tr>", Pattern.DOTALL);
        Matcher rm = rowPattern.matcher(html);
        while (rm.find())
        {
            String row = rm.group(1);
            Pattern cellPattern = Pattern.compile("<td[^>]*>(.*?)</td>", Pattern.DOTALL);
            Matcher cm = cellPattern.matcher(row);
            List<String> cells = new ArrayList<>();
            while (cm.find())
            {
                cells.add(cm.group(1).replaceAll("<[^>]+>", "").trim());
            }
            if (cells.size() >= 5) return String.join("|", cells);
        }
        return "";
    }

    private void mergeResults(List<String> all, Set<String> seen, List<String> newResults)
    {
        for (String r : newResults)
        {
            if (seen.add(r)) all.add(r);
        }
    }

    private String httpGet(String urlStr) throws Exception
    {
        HttpsURLConnection conn = openConnection(urlStr);
        conn.setRequestMethod("GET");
        int code = conn.getResponseCode();
        if (code == 200) return readBody(conn);
        if (code == 302 || code == 301)
        {
            String loc = conn.getHeaderField("Location");
            if (loc != null) return httpGet(loc.startsWith("http") ? loc : ROD_BASE + loc);
        }
        return null;
    }

    private String httpPost(String urlStr, String body) throws Exception
    {
        HttpsURLConnection conn = openConnection(urlStr);
        conn.setRequestMethod("POST");
        conn.setDoOutput(true);
        conn.setRequestProperty("Content-Type", "application/x-www-form-urlencoded");
        try (OutputStream os = conn.getOutputStream())
        {
            os.write(body.getBytes(StandardCharsets.UTF_8));
        }
        int code = conn.getResponseCode();
        if (code == 200) return readBody(conn);
        if (code == 302 || code == 301)
        {
            String loc = conn.getHeaderField("Location");
            if (loc != null) return httpGet(loc.startsWith("http") ? loc : ROD_BASE + loc);
        }
        return readBody(conn);
    }

    private HttpsURLConnection openConnection(String urlStr) throws Exception
    {
        URL url = new URL(urlStr);
        HttpsURLConnection conn = (HttpsURLConnection) url.openConnection();
        TrustManager[] trustAll = new TrustManager[]{
            new X509TrustManager()
            {
                public java.security.cert.X509Certificate[] getAcceptedIssuers() { return null; }
                public void checkClientTrusted(java.security.cert.X509Certificate[] c, String a) {}
                public void checkServerTrusted(java.security.cert.X509Certificate[] c, String a) {}
            }
        };
        SSLContext ctx = SSLContext.getInstance("TLS");
        ctx.init(null, trustAll, new SecureRandom());
        conn.setSSLSocketFactory(ctx.getSocketFactory());
        conn.setHostnameVerifier((h, s) -> true);
        conn.setConnectTimeout(15000);
        conn.setReadTimeout(15000);
        conn.setRequestProperty("User-Agent", "NitroWebExpress/CityAnalysis 1.0");
        if (sessionCookie != null) conn.setRequestProperty("Cookie", sessionCookie);
        conn.setInstanceFollowRedirects(false);
        return conn;
    }

    private String readBody(HttpURLConnection conn) throws IOException
    {
        InputStream is = (conn.getResponseCode() >= 400) ? conn.getErrorStream() : conn.getInputStream();
        if (is == null) return "";
        try (BufferedReader reader = new BufferedReader(new InputStreamReader(is, StandardCharsets.UTF_8)))
        {
            StringBuilder sb = new StringBuilder();
            String line;
            while ((line = reader.readLine()) != null) sb.append(line).append("\n");
            return sb.toString();
        }
    }
}
