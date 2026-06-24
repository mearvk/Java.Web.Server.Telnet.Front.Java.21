/**
 * RodQueryHandler — Reads local property data from /data CSV files, queries the
 * Durham County Register of Deeds (rodweb.dconc.gov) document search, and appends
 * results to an output CSV in /data.
 *
 * Uses RodDisclaimerHandler to get past the accept gate, then submits name/address
 * queries derived from the local property CSV records.
 *
 * @author Max Rupplin
 * @javaowner Max Rupplin
 * @date June 24 2026 EST
 */

package city_analysis;

import commons.CommonRails;
import exceptions.ExceptionHandler;

import javax.net.ssl.*;
import java.io.*;
import java.net.*;
import java.nio.charset.StandardCharsets;
import java.nio.file.*;
import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.regex.*;

public class RodQueryHandler
{
    private static final String DATA_DIR = "source/city/analysis/data/";
    private static final String INPUT_CSV = DATA_DIR + "durham.nc.addresses.csv";
    private static final String OUTPUT_CSV = DATA_DIR + "durham.nc.rod.query.results.csv";
    private static final String ROD_SEARCH_URL = "https://rodweb.dconc.gov/web/search/DOCSEARCH5S1";
    private static final String ROD_BASE = "https://rodweb.dconc.gov";

    private static final int BATCH_SIZE = 25;
    private static final long DELAY_MS = 3000;

    private final RodDisclaimerHandler disclaimerHandler = new RodDisclaimerHandler();
    private String sessionCookie;

    /**
     * Main entry: reads property records from local CSV, queries ROD, appends results.
     *
     * @param maxQueries max number of records to query (0 = all)
     * @return number of results appended
     */
    public int queryAndAppend(int maxQueries)
    {
        try
        {
            CommonRails.printSystemComponent(this, this.hashCode(),
                ". CityAnalysis™ ROD query handler starting .");

            // Step 1: Accept disclaimer and establish session
            String postDisclaimer = disclaimerHandler.acceptAndFetch();
            if (postDisclaimer == null)
            {
                CommonRails.printSystemComponent(this, this.hashCode(),
                    ". CityAnalysis™ ROD disclaimer accept failed — aborting queries .",
                    commons.color.ColorPalette.COLOR_STANDARD_RED);
                return 0;
            }

            // Capture session from disclaimer handler
            sessionCookie = disclaimerHandler.getSessionCookie();

            // Step 2: Read local property data
            List<String[]> records = readInputCsv(maxQueries);
            if (records.isEmpty()) return 0;

            CommonRails.printSystemComponent(this, this.hashCode(),
                ". CityAnalysis™ ROD querying " + records.size() + " property records .");

            // Step 3: Ensure output CSV header exists
            ensureOutputHeader();

            // Step 4: Query ROD for each record and append results
            int total = 0;
            for (int i = 0; i < records.size(); i++)
            {
                String[] record = records.get(i);
                String parcelId = record[0];
                String address = record[1];
                String streetName = record[2];

                List<String> results = queryRod(parcelId, address, streetName);
                if (!results.isEmpty())
                {
                    appendResults(parcelId, address, results);
                    total += results.size();
                }

                if (i > 0 && i % BATCH_SIZE == 0)
                {
                    CommonRails.printSystemComponent(this, this.hashCode(),
                        ". CityAnalysis™ ROD progress: " + i + "/" + records.size() + " queried, " + total + " results .");
                }

                Thread.sleep(DELAY_MS);
            }

            CommonRails.printSystemComponent(this, this.hashCode(),
                ". CityAnalysis™ ROD query complete: " + total + " results from " + records.size() + " records .");

            return total;
        }
        catch (Exception e)
        {
            ExceptionHandler.dispatch(e);
            return 0;
        }
    }

    /**
     * Reads input CSV and extracts parcel_id, address, street name for querying.
     */
    private List<String[]> readInputCsv(int maxQueries)
    {
        List<String[]> records = new ArrayList<>();
        Path inputPath = Path.of(INPUT_CSV);
        if (!Files.exists(inputPath)) return records;

        try (BufferedReader reader = Files.newBufferedReader(inputPath))
        {
            String header = reader.readLine(); // skip header
            if (header == null) return records;

            // Column indices: PARCEL_ID=7, SITE_ADDRE=12, STREETNAME=4
            String line;
            while ((line = reader.readLine()) != null)
            {
                if (maxQueries > 0 && records.size() >= maxQueries) break;

                String[] cols = parseCsvLine(line);
                if (cols.length < 13) continue;

                String parcelId = cols[7].trim();
                String siteAddress = cols[12].trim();
                String streetName = cols[4].trim();

                if (parcelId.isEmpty() && siteAddress.isEmpty()) continue;

                records.add(new String[]{parcelId, siteAddress, streetName});
            }
        }
        catch (IOException e) { ExceptionHandler.dispatch(e); }

        return records;
    }

    /**
     * Queries the ROD DOCSEARCH5S1 endpoint with the property address/parcel.
     * Returns list of result lines (document descriptions found).
     */
    private List<String> queryRod(String parcelId, String address, String streetName)
    {
        List<String> results = new ArrayList<>();
        try
        {
            // Build search query URL — ROD uses GET params on DOCSEARCH5S1
            String searchQuery = streetName.isEmpty() ? parcelId : streetName;
            String queryUrl = ROD_SEARCH_URL + "?searchCategory=P&searchCriteria=" +
                URLEncoder.encode(searchQuery, StandardCharsets.UTF_8);

            String html = httpGet(queryUrl);
            if (html == null || html.isEmpty()) return results;

            // Parse result rows from HTML response
            results = extractSearchResults(html);
        }
        catch (Exception e) { ExceptionHandler.dispatch(e); }
        return results;
    }

    /**
     * Extracts document search results from the ROD response HTML.
     */
    private List<String> extractSearchResults(String html)
    {
        List<String> results = new ArrayList<>();

        // Look for result table rows — ROD uses ss-listview or table with document data
        Pattern rowPattern = Pattern.compile(
            "<tr[^>]*class=\"[^\"]*ss-row[^\"]*\"[^>]*>(.*?)</tr>", Pattern.DOTALL);
        Matcher rowMatcher = rowPattern.matcher(html);

        while (rowMatcher.find())
        {
            String row = rowMatcher.group(1);
            // Extract cell contents
            Pattern cellPattern = Pattern.compile("<td[^>]*>(.*?)</td>", Pattern.DOTALL);
            Matcher cellMatcher = cellPattern.matcher(row);
            StringBuilder line = new StringBuilder();
            while (cellMatcher.find())
            {
                String cell = cellMatcher.group(1).replaceAll("<[^>]+>", "").trim();
                if (!cell.isEmpty())
                {
                    if (line.length() > 0) line.append("|");
                    line.append(cell);
                }
            }
            if (line.length() > 0) results.add(line.toString());
        }

        // Fallback: look for ss-listview items
        if (results.isEmpty())
        {
            Pattern itemPattern = Pattern.compile(
                "<li[^>]*class=\"[^\"]*ss-listview[^\"]*\"[^>]*>(.*?)</li>", Pattern.DOTALL);
            Matcher itemMatcher = itemPattern.matcher(html);
            while (itemMatcher.find())
            {
                String item = itemMatcher.group(1).replaceAll("<[^>]+>", "").trim();
                if (!item.isEmpty() && item.length() > 5) results.add(item);
            }
        }

        return results;
    }

    private void ensureOutputHeader()
    {
        Path outputPath = Path.of(OUTPUT_CSV);
        if (!Files.exists(outputPath))
        {
            try
            {
                Files.writeString(outputPath,
                    "QUERY_DATE,PARCEL_ID,ADDRESS,DOCUMENT_TYPE,BOOK,PAGE,GRANTOR,GRANTEE,RECORD_DATE,RAW_RESULT\n");
            }
            catch (IOException e) { ExceptionHandler.dispatch(e); }
        }
    }

    private void appendResults(String parcelId, String address, List<String> results)
    {
        Path outputPath = Path.of(OUTPUT_CSV);
        String date = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));

        try (BufferedWriter writer = Files.newBufferedWriter(outputPath, StandardOpenOption.APPEND))
        {
            for (String result : results)
            {
                String[] parts = result.split("\\|", -1);
                String docType = parts.length > 0 ? parts[0] : "";
                String book = parts.length > 1 ? parts[1] : "";
                String page = parts.length > 2 ? parts[2] : "";
                String grantor = parts.length > 3 ? parts[3] : "";
                String grantee = parts.length > 4 ? parts[4] : "";
                String recordDate = parts.length > 5 ? parts[5] : "";

                writer.write(String.format("%s,\"%s\",\"%s\",\"%s\",\"%s\",\"%s\",\"%s\",\"%s\",\"%s\",\"%s\"\n",
                    date, parcelId, address, docType, book, page, grantor, grantee, recordDate,
                    result.replace("\"", "''")));
            }
        }
        catch (IOException e) { ExceptionHandler.dispatch(e); }
    }

    private String[] parseCsvLine(String line)
    {
        List<String> fields = new ArrayList<>();
        boolean inQuotes = false;
        StringBuilder field = new StringBuilder();

        for (int i = 0; i < line.length(); i++)
        {
            char c = line.charAt(i);
            if (c == '"') { inQuotes = !inQuotes; }
            else if (c == ',' && !inQuotes) { fields.add(field.toString()); field.setLength(0); }
            else { field.append(c); }
        }
        fields.add(field.toString());
        return fields.toArray(new String[0]);
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
