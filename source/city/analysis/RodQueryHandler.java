/**
 * RodQueryHandler — Reads local property data from /data CSV files, queries the
 * Durham County Register of Deeds (DOCSEARCH5S1) via RodPropertyQueryEngine,
 * follows document result pages, and appends full detail to an output CSV.
 *
 * Uses RodDisclaimerHandler to get past the accept gate, then the engine submits
 * searches (human/soundex) and follows document links to extract book type, page,
 * dates, grantors, grantees, and legal descriptions.
 *
 * @author Max Rupplin
 * @javaowner Max Rupplin
 * @date June 24 2026 EST
 */

package city.analysis;

import commons.CommonRails;
import exceptions.ExceptionHandler;

import java.io.*;
import java.nio.file.*;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;


public class RodQueryHandler
{
    private static final String DATA_DIR = "source/city/analysis/data/";
    private static final String INPUT_CSV = DATA_DIR + "durham.nc.addresses.csv";
    private static final String OUTPUT_CSV = DATA_DIR + "durham.nc.rod.query.results.csv";
    private static final String CONFIG_PATH = "source/city/analysis/configuration/city-analysis-config.xml";

    private static final String CSV_HEADER =
        "QUERY_DATE,PARCEL_ID,PIN,ADDRESS,SEARCH_TYPE,BOOK_TYPE,BOOK,PAGE,RECORDED_DATE,FILED_DATE," +
        "DOCUMENT_TYPE,GRANTORS,GRANTEES,LEGAL_DESCRIPTION,SOURCE_URL\n";

    private static final int BATCH_SIZE = 25;
    private static final long DELAY_MS = 3000;

    private final RodDisclaimerHandler disclaimerHandler = new RodDisclaimerHandler();

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
                ". CityAnalysis\u2122 ROD query handler starting .");

            // Step 1: Accept disclaimer and establish session
            String postDisclaimer = disclaimerHandler.acceptAndFetch();
            if (postDisclaimer == null)
            {
                CommonRails.printSystemComponent(this, this.hashCode(),
                    ". CityAnalysis\u2122 ROD disclaimer accept failed \u2014 aborting queries .",
                    commons.color.ColorPalette.COLOR_STANDARD_RED);
                return 0;
            }

            String cookie = disclaimerHandler.getSessionCookie();

            // Step 2: Read local property data
            List<String[]> records = readInputCsv(maxQueries);
            if (records.isEmpty()) return 0;

            CommonRails.printSystemComponent(this, this.hashCode(),
                ". CityAnalysis\u2122 ROD querying " + records.size() + " property records .");

            // Step 3: Ensure output CSV header exists
            ensureOutputHeader();

            // Step 4: Create engine and query each record
            RodPropertyQueryEngine engine = new RodPropertyQueryEngine(cookie);
            int total = 0;

            for (int i = 0; i < records.size(); i++)
            {
                String[] record = records.get(i);
                String parcelId = record[0];
                String pin = record[1];
                String address = record[2];
                String streetName = record[3];

                // Try HUMAN first
                engine.setNameType(RodPropertyQueryEngine.NameType.HUMAN);
                List<String> results = engine.queryAllData(parcelId, pin, address, streetName);
                String searchType = "human";

                // Fallback to SOUNDEX
                if (results.isEmpty())
                {
                    engine.setNameType(RodPropertyQueryEngine.NameType.SOUNDEX);
                    results = engine.queryAllData(parcelId, pin, address, streetName);
                    searchType = "soundex";
                }

                if (!results.isEmpty())
                {
                    appendResults(parcelId, pin, address, searchType, results);
                    total += results.size();
                }

                if (i > 0 && i % BATCH_SIZE == 0)
                {
                    CommonRails.printSystemComponent(this, this.hashCode(),
                        ". CityAnalysis\u2122 ROD progress: " + i + "/" + records.size() + " queried, " + total + " results .");
                }

                Thread.sleep(DELAY_MS);
            }

            // Step 5: Query known names from config (histogram-driven)
            List<String[]> knownNames = loadKnownNames();
            if (!knownNames.isEmpty())
            {
                CommonRails.printSystemComponent(this, this.hashCode(),
                    ". CityAnalysis\u2122 ROD querying " + knownNames.size() + " known names from config .");
                for (String[] name : knownNames)
                {
                    engine.setNameType(RodPropertyQueryEngine.NameType.HUMAN);
                    List<String> results = engine.queryByName(name[0], name[1]);
                    if (!results.isEmpty())
                    {
                        appendResults("", "", name[0] + " " + name[1], "known-name", results);
                        total += results.size();
                    }
                    Thread.sleep(DELAY_MS);
                }
            }

            // Step 6: Query known addresses from config
            List<String> knownAddresses = loadKnownAddresses();
            if (!knownAddresses.isEmpty())
            {
                CommonRails.printSystemComponent(this, this.hashCode(),
                    ". CityAnalysis\u2122 ROD querying " + knownAddresses.size() + " known addresses from config .");
                for (String addr : knownAddresses)
                {
                    engine.setNameType(RodPropertyQueryEngine.NameType.HUMAN);
                    List<String> results = engine.queryAllData("", "", addr, "");
                    if (!results.isEmpty())
                    {
                        appendResults("", "", addr, "known-address", results);
                        total += results.size();
                    }
                    Thread.sleep(DELAY_MS);
                }
            }

            CommonRails.printSystemComponent(this, this.hashCode(),
                ". CityAnalysis\u2122 ROD query complete: " + total + " results from " + records.size() + " records .");

            return total;
        }
        catch (Exception e)
        {
            ExceptionHandler.dispatch(e);
            return 0;
        }
    }

    private List<String[]> loadKnownNames()
    {
        List<String[]> names = new ArrayList<>();
        try
        {
            org.w3c.dom.Document doc = javax.xml.parsers.DocumentBuilderFactory.newInstance()
                .newDocumentBuilder().parse(new java.io.File(CONFIG_PATH));
            org.w3c.dom.NodeList knNodes = doc.getElementsByTagName("known-names");
            if (knNodes.getLength() == 0) return names;
            org.w3c.dom.Element kn = (org.w3c.dom.Element) knNodes.item(0);
            if (!"true".equals(kn.getAttribute("enabled"))) return names;
            org.w3c.dom.NodeList nameNodes = kn.getElementsByTagName("name");
            for (int i = 0; i < nameNodes.getLength(); i++)
            {
                org.w3c.dom.Element el = (org.w3c.dom.Element) nameNodes.item(i);
                names.add(new String[]{el.getAttribute("lastName"), el.getAttribute("firstName")});
            }
        }
        catch (Exception e) { /* config parse error — skip */ }
        return names;
    }

    private List<String> loadKnownAddresses()
    {
        List<String> addresses = new ArrayList<>();
        try
        {
            org.w3c.dom.Document doc = javax.xml.parsers.DocumentBuilderFactory.newInstance()
                .newDocumentBuilder().parse(new java.io.File(CONFIG_PATH));
            org.w3c.dom.NodeList kaNodes = doc.getElementsByTagName("known-addresses");
            if (kaNodes.getLength() == 0) return addresses;
            org.w3c.dom.Element ka = (org.w3c.dom.Element) kaNodes.item(0);
            if (!"true".equals(ka.getAttribute("enabled"))) return addresses;

            // Load from source CSV (durham.nc.addresses.csv) — column 12 = SITE_ADDRE
            String source = ka.getAttribute("source");
            if (source != null && !source.isEmpty())
            {
                Path csvPath = Path.of(DATA_DIR + source);
                if (Files.exists(csvPath))
                {
                    try (BufferedReader reader = Files.newBufferedReader(csvPath))
                    {
                        reader.readLine(); // skip header
                        String line;
                        Set<String> seen = new HashSet<>();
                        while ((line = reader.readLine()) != null && addresses.size() < 100)
                        {
                            String[] cols = parseCsvLine(line);
                            if (cols.length < 13) continue;
                            String addr = cols[12].trim();
                            if (!addr.isEmpty() && seen.add(addr)) addresses.add(addr);
                        }
                    }
                    java.util.Collections.shuffle(addresses);
                    if (addresses.size() > 50) addresses = addresses.subList(0, 50);
                    return addresses;
                }
            }

            // Fallback: load from inline <address> elements
            org.w3c.dom.NodeList addrNodes = ka.getElementsByTagName("address");
            for (int i = 0; i < addrNodes.getLength(); i++)
            {
                String addr = addrNodes.item(i).getTextContent().trim();
                if (!addr.isEmpty()) addresses.add(addr);
            }
        }
        catch (Exception e) { /* config parse error — skip */ }
        return addresses;
    }

    private List<String[]> readInputCsv(int maxQueries)
    {
        List<String[]> records = new ArrayList<>();
        Path inputPath = Path.of(INPUT_CSV);
        if (!Files.exists(inputPath)) return records;

        try (BufferedReader reader = Files.newBufferedReader(inputPath))
        {
            String header = reader.readLine();
            if (header == null) return records;

            String line;
            while ((line = reader.readLine()) != null)
            {
                if (maxQueries > 0 && records.size() >= maxQueries) break;

                String[] cols = parseCsvLine(line);
                if (cols.length < 13) continue;

                String parcelId = cols[7].trim();   // PARCEL_ID
                String pin = cols[8].trim();        // PIN
                String siteAddress = cols[12].trim(); // SITE_ADDRE
                String streetName = cols[4].trim();  // STREETNAME

                if (parcelId.isEmpty() && siteAddress.isEmpty()) continue;
                records.add(new String[]{parcelId, pin, siteAddress, streetName});
            }
        }
        catch (IOException e) { ExceptionHandler.dispatch(e); }

        return records;
    }

    private void ensureOutputHeader()
    {
        Path outputPath = Path.of(OUTPUT_CSV);
        if (!Files.exists(outputPath))
        {
            try { Files.writeString(outputPath, CSV_HEADER); }
            catch (IOException e) { ExceptionHandler.dispatch(e); }
        }
    }

    private void appendResults(String parcelId, String pin, String address,
                               String searchType, List<String> results)
    {
        Path outputPath = Path.of(OUTPUT_CSV);
        String date = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));

        try (BufferedWriter writer = Files.newBufferedWriter(outputPath, StandardOpenOption.APPEND))
        {
            for (String result : results)
            {
                String[] parts = result.split("\\|", -1);
                String bookType = parts.length > 0 ? parts[0] : "";
                String book = parts.length > 1 ? parts[1] : "";
                String page = parts.length > 2 ? parts[2] : "";
                String recordedDate = parts.length > 3 ? parts[3] : "";
                String filedDate = parts.length > 4 ? parts[4] : "";
                String docType = parts.length > 5 ? parts[5] : "";
                String grantors = parts.length > 6 ? parts[6] : "";
                String grantees = parts.length > 7 ? parts[7] : "";
                String legal = parts.length > 8 ? parts[8] : "";

                writer.write(String.format("%s,\"%s\",\"%s\",\"%s\",\"%s\",\"%s\",\"%s\",\"%s\",\"%s\",\"%s\",\"%s\",\"%s\",\"%s\",\"%s\",\"%s\"\n",
                    date, parcelId, pin, address, searchType,
                    bookType, book, page, recordedDate, filedDate,
                    docType, esc(grantors), esc(grantees), esc(legal), ""));
            }
        }
        catch (IOException e) { ExceptionHandler.dispatch(e); }
    }

    private String esc(String s) { return s.replace("\"", "''"); }

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
}
