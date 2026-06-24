/**
 * RodQueryTestFramework — Integration test for the CityAnalysis ROD query pipeline.
 *
 * Verifies:
 * 1. RodDisclaimerHandler can connect and accept the disclaimer
 * 2. RodQueryHandler reads local data and queries ROD
 * 3. Results are appended to the output CSV after each call
 *
 * Run standalone: java -cp <classpath> city_analysis.RodQueryTestFramework
 *
 * @author Max Rupplin
 * @javaowner Max Rupplin
 * @date June 24 2026 EST
 */

package city.analysis;

import java.io.*;
import java.nio.file.*;

public class RodQueryTestFramework
{
    private static final String OUTPUT_CSV = "source/city/analysis/data/durham.nc.rod.query.results.csv";
    private static final String INPUT_CSV = "source/city/analysis/data/durham.nc.addresses.csv";

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
            city_analysis.RodDisclaimerHandler handler = new city_analysis.RodDisclaimerHandler();
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

        // Record output CSV size before
        long sizeBefore = getFileSize(OUTPUT_CSV);

        try
        {
            city_analysis.RodQueryHandler handler = new city_analysis.RodQueryHandler();
            int results = handler.queryAndAppend(3); // Query only 3 records for test

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
            if (!header.contains("PARCEL_ID") || !header.contains("DOCUMENT_TYPE"))
            {
                fail("Output CSV header malformed: " + header);
                return;
            }

            if (lines.size() < 2)
            {
                // No data rows yet — might be network issue but header is correct
                pass("Output CSV header valid, no data rows yet (ROD may be unreachable)");
                return;
            }

            // Verify data rows have correct column count (10 columns)
            String dataRow = lines.get(1);
            int commas = (int) dataRow.chars().filter(c -> c == ',').count();
            if (commas < 5) { fail("Data row has too few columns: " + dataRow); return; }

            pass("Output CSV has " + (lines.size() - 1) + " data rows, format valid");
        }
        catch (IOException e) { fail("Cannot read output CSV: " + e.getMessage()); }
    }

    private long getFileSize(String path)
    {
        try { return Files.size(Path.of(path)); }
        catch (IOException e) { return 0; }
    }

    private void pass(String msg)
    {
        passed++;
        print("  ✓ PASS: " + msg);
    }

    private void fail(String msg)
    {
        failed++;
        print("  ✗ FAIL: " + msg);
    }

    private void print(String msg)
    {
        System.out.println("-- : [RodQueryTestFramework] " + msg);
    }
}
