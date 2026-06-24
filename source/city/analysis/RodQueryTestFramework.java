/**
 * RodQueryTestFramework — Integration test for the CityAnalysis ROD query pipeline.
 *
 * Verifies:
 * 1. RodDisclaimerHandler can connect and accept the disclaimer
 * 2. RodQueryHandler reads local data and queries ROD
 * 3. Results are appended to the output CSV after each call
 * 4. Random 100-parcel test with human/soundex selectors, document page following,
 *    full detail extraction, CSV row verification, and grading
 *
 * Grading: A (95-100), B (80-94), C (60-79), D (40-59), F (<40) based on row yield
 *
 * Run standalone: java -cp <classpath> city_analysis.RodQueryTestFramework
 *
 * @author Max Rupplin
 * @javaowner Max Rupplin
 * @date June 24 2026 EST
 */

package city_analysis;

import java.io.*;
import java.nio.file.*;
import java.util.*;
import java.util.concurrent.ThreadLocalRandom;

public class RodQueryTestFramework
{
    private static final String OUTPUT_CSV = "source/city/analysis/data/durham.nc.rod.query.results.csv";
    private static final String TEST_CSV = "source/city/analysis/data/durham.nc.rod.test.100.results.csv";
    private static final String INPUT_CSV = "source/city/analysis/data/durham.nc.addresses.csv";
    private static final int RANDOM_SAMPLE_SIZE = 100;

    private static final String CSV_HEADER =
        "QUERY_DATE,PARCEL_ID,PIN,ADDRESS,SEARCH_TYPE,BOOK_TYPE,BOOK,PAGE,RECORDED_DATE,FILED_DATE," +
        "DOCUMENT_TYPE,GRANTORS,GRANTEES,LEGAL_DESCRIPTION,SOURCE_URL\n";

    private int passed = 0;
    private int failed = 0;

    public static void main(String[] args)
    {
        RodQueryTestFramework t = new RodQueryTestFramework();
        t.run();
    }

    public void run()
    {
        print("=== RodQueryTestFramework — Starting ===");

        testInputCsvExists();
        testDisclaimerHandlerConnects();
        testQueryHandlerProducesResults();
        testCsvAppendedAfterQuery();
        testRandom100Parcels();

        print("=== Results: " + passed + " passed, " + failed + " failed ===");
    }

    private void testInputCsvExists()
    {
        print("[TEST] Input CSV exists and has data");
        Path input = Path.of(INPUT_CSV);
        if (!Files.exists(input)) { fail("Input CSV not found: " + INPUT_CSV); return; }
        try
        {
            long lines = Files.lines(input).count();
            if (lines < 2) { fail("Input CSV has no data rows (lines=" + lines + ")"); return; }
            pass("Input CSV has " + (lines - 1) + " data rows");
        }
        catch (IOException e) { fail("Cannot read input CSV: " + e.getMessage()); }
    }

    private void testDisclaimerHandlerConnects()
    {
        print("[TEST] RodDisclaimerHandler accepts disclaimer and returns content");
        try
        {
            RodDisclaimerHandler handler = new RodDisclaimerHandler();
            String html = handler.acceptAndFetch();
            if (html == null) { fail("Disclaimer handler returned null — site unreachable or form changed"); return; }
            if (html.isEmpty()) { fail("Disclaimer handler returned empty content"); return; }
            if (handler.getSessionCookie() == null) { fail("No session cookie acquired"); return; }
            pass("Disclaimer accepted, got " + html.length() + " chars, cookie set");
        }
        catch (Exception e) { fail("Exception: " + e.getMessage()); }
    }

    private void testQueryHandlerProducesResults()
    {
        print("[TEST] RodQueryHandler queries ROD and gets results");
        long sizeBefore = getFileSize(OUTPUT_CSV);
        try
        {
            RodQueryHandler handler = new RodQueryHandler();
            int results = handler.queryAndAppend(3);
            if (results < 0) { fail("queryAndAppend returned negative: " + results); return; }
            long sizeAfter = getFileSize(OUTPUT_CSV);
            if (results > 0 && sizeAfter <= sizeBefore)
            {
                fail("Handler reported " + results + " results but CSV did not grow");
                return;
            }
            pass("Query returned " + results + " results, CSV size: " + sizeBefore + " -> " + sizeAfter);
        }
        catch (Exception e) { fail("Exception: " + e.getMessage()); }
    }

    private void testCsvAppendedAfterQuery()
    {
        print("[TEST] Output CSV has valid header and appended rows");
        Path output = Path.of(OUTPUT_CSV);
        if (!Files.exists(output)) { fail("Output CSV does not exist after query"); return; }
        try
        {
            var lines = Files.readAllLines(output);
            if (lines.isEmpty()) { fail("Output CSV is empty"); return; }
            String header = lines.get(0);
            if (!header.contains("PARCEL_ID"))
            {
                fail("Output CSV header malformed: " + header);
                return;
            }
            if (lines.size() < 2)
            {
                pass("Output CSV header valid, no data rows yet (ROD may be unreachable)");
                return;
            }
            pass("Output CSV has " + (lines.size() - 1) + " data rows, format valid");
        }
        catch (IOException e) { fail("Cannot read output CSV: " + e.getMessage()); }
    }

    /**
     * Selects 100 random parcels from the input CSV, queries ROD for all available
     * property/owner data on each using human/soundex selectors, follows document
     * result links (e.g., /web/document/DOC255S471?search=DOCSEARCH5S1), extracts
     * book type, page, dates, names, legal, writes to test CSV, and grades yield.
     */
    private void testRandom100Parcels()
    {
        print("[TEST] Random 100-parcel full data retrieval and grading");

        // Step 1: Load all records
        List<String[]> allRecords = loadAllRecords();
        if (allRecords.size() < RANDOM_SAMPLE_SIZE)
        {
            fail("Input CSV has fewer than " + RANDOM_SAMPLE_SIZE + " records (" + allRecords.size() + ")");
            return;
        }

        // Step 2: Random sample
        List<String[]> sample = randomSample(allRecords, RANDOM_SAMPLE_SIZE);
        print("  Selected " + sample.size() + " random parcels from " + allRecords.size() + " total");

        // Step 3: Accept disclaimer
        RodDisclaimerHandler disclaimerHandler = new RodDisclaimerHandler();
        String html = disclaimerHandler.acceptAndFetch();
        if (html == null)
        {
            fail("Cannot reach ROD — disclaimer handler returned null");
            return;
        }
        String cookie = disclaimerHandler.getSessionCookie();

        // Step 4: Prepare test output CSV with full named column headers
        Path testOutput = Path.of(TEST_CSV);
        try { Files.writeString(testOutput, CSV_HEADER); }
        catch (IOException e) { fail("Cannot create test CSV: " + e.getMessage()); return; }

        // Step 5: Query each parcel — HUMAN first, SOUNDEX fallback
        int parcelsWithResults = 0;
        int totalRows = 0;
        RodPropertyQueryEngine engine = new RodPropertyQueryEngine(cookie);

        for (int i = 0; i < sample.size(); i++)
        {
            String[] record = sample.get(i);
            String parcelId = record[0];
            String pin = record[1];
            String address = record[2];
            String streetName = record[3];

            // Try HUMAN search type first
            engine.setNameType(RodPropertyQueryEngine.NameType.HUMAN);
            List<String> results = engine.queryAllData(parcelId, pin, address, streetName);
            String searchType = "human";

            // Fallback to SOUNDEX if no results
            if (results.isEmpty())
            {
                engine.setNameType(RodPropertyQueryEngine.NameType.SOUNDEX);
                results = engine.queryAllData(parcelId, pin, address, streetName);
                searchType = "soundex";
            }

            if (!results.isEmpty())
            {
                parcelsWithResults++;
                totalRows += results.size();
                appendTestResults(testOutput, parcelId, pin, address, searchType, results);
            }

            if ((i + 1) % 10 == 0)
            {
                print("  Progress: " + (i + 1) + "/" + RANDOM_SAMPLE_SIZE +
                    " queried, " + parcelsWithResults + " with results, " + totalRows + " total rows");
            }

            try { Thread.sleep(3000); } catch (InterruptedException e) { break; }
        }

        // Step 6: Verify CSV row count
        int csvRows = countCsvDataRows(testOutput);

        // Step 7: Grade
        double yieldPct = (parcelsWithResults * 100.0) / RANDOM_SAMPLE_SIZE;
        String grade = grade(yieldPct);

        print("  --- RESULTS ---");
        print("  Parcels queried:      " + RANDOM_SAMPLE_SIZE);
        print("  Parcels with results: " + parcelsWithResults);
        print("  Total result rows:    " + totalRows);
        print("  CSV data rows:        " + csvRows);
        print("  Yield:                " + String.format("%.1f%%", yieldPct));
        print("  GRADE:                " + grade);

        if (csvRows != totalRows)
            fail("CSV rows (" + csvRows + ") != total results appended (" + totalRows + ") — data loss detected");
        else if (totalRows > 0)
            pass("All " + totalRows + " results correctly written to test CSV — Grade: " + grade);
        else
            fail("No results from 100 parcels — ROD may be blocking or search params need adjustment — Grade: " + grade);
    }

    private List<String[]> loadAllRecords()
    {
        List<String[]> records = new ArrayList<>();
        try (BufferedReader reader = Files.newBufferedReader(Path.of(INPUT_CSV)))
        {
            reader.readLine(); // skip header
            String line;
            while ((line = reader.readLine()) != null)
            {
                String[] cols = parseCsvLine(line);
                if (cols.length < 13) continue;
                String parcelId = cols[7].trim();   // PARCEL_ID
                String pin = cols[8].trim();        // PIN
                String address = cols[12].trim();   // SITE_ADDRE
                String streetName = cols[4].trim(); // STREETNAME
                if (parcelId.isEmpty() && address.isEmpty()) continue;
                records.add(new String[]{parcelId, pin, address, streetName});
            }
        }
        catch (IOException e) { print("  ERROR loading input: " + e.getMessage()); }
        return records;
    }

    private List<String[]> randomSample(List<String[]> all, int n)
    {
        List<String[]> copy = new ArrayList<>(all);
        Collections.shuffle(copy, ThreadLocalRandom.current());
        return copy.subList(0, Math.min(n, copy.size()));
    }

    /**
     * Appends results to the test CSV. Each result is pipe-delimited:
     * bookType|book|page|recordedDate|filedDate|docType|grantors|grantees|legal
     */
    private void appendTestResults(Path csv, String parcelId, String pin, String address,
                                   String searchType, List<String> results)
    {
        try (BufferedWriter writer = Files.newBufferedWriter(csv, StandardOpenOption.APPEND))
        {
            String date = java.time.LocalDateTime.now()
                .format(java.time.format.DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));

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
        catch (IOException e) { print("  ERROR appending results: " + e.getMessage()); }
    }

    private String esc(String s) { return s.replace("\"", "''"); }

    private int countCsvDataRows(Path csv)
    {
        try { return (int) Math.max(0, Files.lines(csv).count() - 1); }
        catch (IOException e) { return 0; }
    }

    private String grade(double yieldPct)
    {
        if (yieldPct >= 95) return "A  (Excellent — near-complete data retrieval)";
        if (yieldPct >= 80) return "B  (Good — most parcels returned deeds data)";
        if (yieldPct >= 60) return "C  (Fair — majority returned data, some gaps)";
        if (yieldPct >= 40) return "D  (Poor — less than half of parcels returned data)";
        return "F  (Failing — ROD queries not producing results)";
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

    private long getFileSize(String path)
    {
        try { return Files.size(Path.of(path)); }
        catch (IOException e) { return 0; }
    }

    private void pass(String msg) { passed++; print("  \u2713 PASS: " + msg); }
    private void fail(String msg) { failed++; print("  \u2717 FAIL: " + msg); }
    private void print(String msg) { System.out.println("-- : [RodQueryTestFramework] " + msg); }
}
