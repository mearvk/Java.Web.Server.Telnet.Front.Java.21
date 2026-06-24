/**
 * RodPropertyQueryEngine — Queries ALL available data for a given property from
 * the Durham County Register of Deeds (rodweb.dconc.gov/web/search/DOCSEARCH5S1).
 *
 * Searches by parcel ID, PIN, address, and street name to maximize data retrieval.
 * Returns all document records (deeds, mortgages, liens, plats, etc.) found for
 * the property or its owners.
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
    private static final String ROD_SEARCH_URL = "https://rodweb.dconc.gov/web/search/DOCSEARCH5S1";
    private static final String ROD_BASE = "https://rodweb.dconc.gov";

    private final String sessionCookie;

    public RodPropertyQueryEngine(String sessionCookie)
    {
        this.sessionCookie = sessionCookie;
    }

    /**
     * Queries all available data for the property using multiple search strategies.
     * Tries parcel ID, PIN, street name, and full address to capture all documents.
     *
     * @return list of pipe-delimited result strings (docType|book|page|grantor|grantee|date|...)
     */
    public List<String> queryAllData(String parcelId, String pin, String address, String streetName)
    {
        Set<String> seen = new HashSet<>();
        List<String> allResults = new ArrayList<>();

        // Strategy 1: Search by parcel ID (property-based)
        if (!parcelId.isEmpty())
        {
            mergeResults(allResults, seen, querySearch("P", parcelId));
        }

        // Strategy 2: Search by PIN
        if (!pin.isEmpty())
        {
            mergeResults(allResults, seen, querySearch("P", pin));
        }

        // Strategy 3: Search by street name (catches all docs on that street)
        if (!streetName.isEmpty())
        {
            mergeResults(allResults, seen, querySearch("A", streetName.trim()));
        }

        // Strategy 4: Search by full address
        if (!address.isEmpty() && !address.equals(streetName))
        {
            mergeResults(allResults, seen, querySearch("A", address));
        }

        return allResults;
    }

    private List<String> querySearch(String category, String criteria)
    {
        List<String> results = new ArrayList<>();
        try
        {
            String queryUrl = ROD_SEARCH_URL + "?searchCategory=" + category +
                "&searchCriteria=" + URLEncoder.encode(criteria, StandardCharsets.UTF_8);

            String html = httpGet(queryUrl);
            if (html == null || html.isEmpty()) return results;

            results = extractResults(html);
        }
        catch (Exception e) { /* silently skip failed queries */ }
        return results;
    }

    private List<String> extractResults(String html)
    {
        List<String> results = new ArrayList<>();

        // Pattern 1: Table rows with ss-row class
        Pattern rowPattern = Pattern.compile(
            "<tr[^>]*>(.*?)</tr>", Pattern.DOTALL | Pattern.CASE_INSENSITIVE);
        Matcher rowMatcher = rowPattern.matcher(html);

        while (rowMatcher.find())
        {
            String row = rowMatcher.group(1);
            if (!row.contains("<td")) continue;

            Pattern cellPattern = Pattern.compile("<td[^>]*>(.*?)</td>", Pattern.DOTALL);
            Matcher cellMatcher = cellPattern.matcher(row);
            List<String> cells = new ArrayList<>();
            while (cellMatcher.find())
            {
                String cell = cellMatcher.group(1).replaceAll("<[^>]+>", "").trim();
                cells.add(cell);
            }
            if (cells.size() >= 3)
            {
                results.add(String.join("|", cells));
            }
        }

        // Pattern 2: SelfService list items with document data
        if (results.isEmpty())
        {
            Pattern liPattern = Pattern.compile(
                "<li[^>]*data-[^>]*>(.*?)</li>", Pattern.DOTALL | Pattern.CASE_INSENSITIVE);
            Matcher liMatcher = liPattern.matcher(html);
            while (liMatcher.find())
            {
                String item = liMatcher.group(1).replaceAll("<[^>]+>", "").trim();
                if (item.length() > 10) results.add(item);
            }
        }

        // Pattern 3: Divs with result class
        if (results.isEmpty())
        {
            Pattern divPattern = Pattern.compile(
                "<div[^>]*class=\"[^\"]*result[^\"]*\"[^>]*>(.*?)</div>", Pattern.DOTALL | Pattern.CASE_INSENSITIVE);
            Matcher divMatcher = divPattern.matcher(html);
            while (divMatcher.find())
            {
                String item = divMatcher.group(1).replaceAll("<[^>]+>", "").trim();
                if (item.length() > 10) results.add(item);
            }
        }

        return results;
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
        conn.setRequestMethod("GET");
        conn.setConnectTimeout(15000);
        conn.setReadTimeout(15000);
        conn.setRequestProperty("User-Agent", "NitroWebExpress/CityAnalysis 1.0");
        if (sessionCookie != null) conn.setRequestProperty("Cookie", sessionCookie);
        conn.setInstanceFollowRedirects(true);

        int code = conn.getResponseCode();
        if (code == 200)
        {
            try (BufferedReader reader = new BufferedReader(
                new InputStreamReader(conn.getInputStream(), StandardCharsets.UTF_8)))
            {
                StringBuilder sb = new StringBuilder();
                String l;
                while ((l = reader.readLine()) != null) sb.append(l).append("\n");
                return sb.toString();
            }
        }
        return null;
    }
}
