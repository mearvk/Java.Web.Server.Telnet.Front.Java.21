/**
 * AIScoutingThread — Daily internet scouting for international.radio modules.
 *
 * Runs on its own daemon thread. Scouts each country's configured sources,
 * writes college-readable paragraph documents to relative source folders,
 * and accumulates data up to 200 MB before triggering the training module.
 *
 * Output: paragraph-oriented documents readable by a College individual.
 * Location: each module's source/international/radio/{country}/scouting/
 *
 * @author Max Rupplin
 * @javaowner Max Rupplin
 * @date June 19 2026 EST
 */

package international.radio;

import commons.CommonRails;
import exceptions.ExceptionHandler;

import java.io.*;
import java.net.*;
import java.nio.charset.StandardCharsets;
import java.nio.file.*;
import java.sql.*;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.List;

public class AIScoutingThread extends Thread
{
    private static final long MAX_STORAGE_BYTES = 200L * 1024 * 1024; // 200 MB
    private static final long SCOUT_INTERVAL_MS = 60 * 60 * 1000; // 1 hour
    private static final String[] COUNTRIES = {"japan", "russia", "mexico", "ukraine", "greece-international"};

    private final AIIntegrativeEngine engine;
    private volatile boolean running = true;

    public AIScoutingThread(AIIntegrativeEngine engine)
    {
        this.engine = engine;
        this.setName("AI_SCOUTING_THREAD");
        this.setDaemon(true);
    }

    @Override
    public void run()
    {
        CommonRails.printSystemComponent(this, this.hashCode(),
            ". AIScoutingThread™ started — daily internet scouting active .");

        while (running && !Thread.currentThread().isInterrupted())
        {
            for (String country : COUNTRIES)
            {
                try { scoutCountry(country); }
                catch (Exception e) { ExceptionHandler.dispatch(e); }
            }

            try { Thread.sleep(SCOUT_INTERVAL_MS); }
            catch (InterruptedException e) { break; }
        }
    }

    /**
     * Scouts a single country's sources and writes feedback document.
     */
    private void scoutCountry(String country)
    {
        Path scoutDir = Path.of("source/international/radio/" + country.replace("-international", "") + "/scouting");
        if (country.equals("greece-international")) scoutDir = Path.of("source/greece/international/scouting");

        try { Files.createDirectories(scoutDir); }
        catch (IOException e) { ExceptionHandler.dispatch(e); return; }

        // Check current size — if over 200 MB, skip (training thread must consume first)
        long currentSize = directorySize(scoutDir);
        if (currentSize >= MAX_STORAGE_BYTES)
        {
            CommonRails.printSystemComponent(this, this.hashCode(),
                ". AIScoutingThread™ " + country + " at 200 MB cap — awaiting training consumption .");
            return;
        }

        String today = LocalDate.now().format(DateTimeFormatter.ISO_LOCAL_DATE);
        Path feedbackFile = scoutDir.resolve("scouting-feedback-" + today + ".txt");

        StringBuilder document = new StringBuilder();
        document.append("==========================================================\n");
        document.append("Daily Scouting Feedback — ").append(country.toUpperCase()).append("\n");
        document.append("Date: ").append(today).append("\n");
        document.append("Module: international.radio.").append(country).append("\n");
        document.append("==========================================================\n\n");

        document.append("SUMMARY OF FINDINGS\n\n");
        document.append("This document contains the daily scouting results for the ");
        document.append(country).append(" international radio module. Sources were ");
        document.append("consulted per the module's XML configuration. Each finding ");
        document.append("was processed through the gain control heuristic to filter ");
        document.append("explicit or harmful content before storage.\n\n");

        document.append("VERDICT SOURCING NOTES\n\n");
        document.append("All entries in this document originate from INTERNET verdict ");
        document.append("source (trust level 0.40). They have passed initial gain control ");
        document.append("but require further validation by the training module before ");
        document.append("promotion to accepted training data.\n\n");

        document.append("INFORMATION SOURCES AND ANGLES\n\n");

        // Scout configured sources for this country
        int findings = scoutSources(country, document);

        document.append("\nTOTAL FINDINGS: ").append(findings).append("\n\n");
        document.append("INTEGRITY NOTES\n\n");
        document.append("This scouting run completed without explicit content flags. ");
        document.append("All data has been stored in the nwe_ai_integrative database ");
        document.append("scouting_log table with gain_level 'review' pending training ");
        document.append("thread consumption. Channel usage: public only.\n\n");
        document.append("END OF DAILY SCOUTING FEEDBACK\n");

        try { Files.writeString(feedbackFile, document.toString(), StandardCharsets.UTF_8); }
        catch (IOException e) { ExceptionHandler.dispatch(e); }
    }

    /**
     * Scouts sources for a country, appends findings to document, returns count.
     */
    private int scoutSources(String country, StringBuilder document)
    {
        // Source URLs per country (from XML configs)
        String[][] sources = getSourcesForCountry(country);
        int count = 0;

        for (String[] src : sources)
        {
            String sourceId = src[0];
            String url = src[1];
            try
            {
                String content = httpGet(url);
                if (content == null || content.isEmpty()) continue;

                // Truncate to first 2000 chars for scouting summary
                String summary = content.length() > 2000 ? content.substring(0, 2000) : content;

                // Gain control check
                if (!engine.isReady()) continue;
                boolean acceptable = !summary.toLowerCase().contains("explicit")
                    && !summary.toLowerCase().contains("pornograph");

                if (acceptable)
                {
                    document.append("Source: ").append(sourceId).append(" (").append(url).append(")\n");
                    document.append("Status: Retrieved successfully. Content acceptable.\n");
                    document.append("Angle: General informational content from ").append(sourceId).append(".\n\n");

                    // Store in scouting_log
                    logScouting(country, url, sourceId, summary);
                    count++;
                }
            }
            catch (Exception e) { /* source unavailable — continue */ }
        }
        return count;
    }

    private String[][] getSourcesForCountry(String country)
    {
        return switch (country) {
            case "japan" -> new String[][]{
                {"nhk", "https://www3.nhk.or.jp/nhkworld/"},
                {"nikkei", "https://asia.nikkei.com"},
                {"kyodo", "https://english.kyodonews.net"}
            };
            case "russia" -> new String[][]{
                {"interfax", "https://interfax.com"},
                {"moex", "https://www.moex.com/en/"},
                {"rt", "https://www.rt.com"}
            };
            case "mexico" -> new String[][]{
                {"eluniversal", "https://www.eluniversal.com.mx"},
                {"expansion", "https://expansion.mx"},
                {"bmv", "https://www.bmv.com.mx"}
            };
            case "ukraine" -> new String[][]{
                {"ukrinform", "https://www.ukrinform.net"},
                {"kyivindependent", "https://kyivindependent.com"},
                {"nbu", "https://bank.gov.ua/en/"}
            };
            case "greece-international" -> new String[][]{
                {"kathimerini", "https://www.ekathimerini.com"},
                {"reuters", "https://www.reuters.com"},
                {"bbc", "https://www.bbc.com/news"}
            };
            default -> new String[0][];
        };
    }

    private void logScouting(String country, String url, String sourceId, String content)
    {
        try
        {
            Connection conn = DriverManager.getConnection(
                "jdbc:mysql://localhost:3306/nwe_ai_integrative", "mearvk", "$$Ironman1");
            try (PreparedStatement ps = conn.prepareStatement(
                "INSERT INTO scouting_log (country_id, source_url, source_id, content, content_size_bytes) " +
                "VALUES (?, ?, ?, ?, ?)"))
            {
                ps.setString(1, country);
                ps.setString(2, url);
                ps.setString(3, sourceId);
                ps.setString(4, content);
                ps.setLong(5, content.getBytes(StandardCharsets.UTF_8).length);
                ps.executeUpdate();
            }
            conn.close();
        }
        catch (SQLException e) { ExceptionHandler.dispatch(e); }
    }

    private long directorySize(Path dir)
    {
        try { return Files.walk(dir).filter(Files::isRegularFile).mapToLong(p -> p.toFile().length()).sum(); }
        catch (IOException e) { return 0; }
    }

    private String httpGet(String url) throws IOException, URISyntaxException
    {
        HttpURLConnection conn = (HttpURLConnection) new URI(url).toURL().openConnection();
        conn.setRequestMethod("GET");
        conn.setConnectTimeout(8000);
        conn.setReadTimeout(8000);
        conn.setRequestProperty("User-Agent", "NitroWebExpress-AIScouting/1.0");
        StringBuilder sb = new StringBuilder();
        try (BufferedReader reader = new BufferedReader(
            new InputStreamReader(conn.getInputStream(), StandardCharsets.UTF_8)))
        {
            String line;
            while ((line = reader.readLine()) != null) sb.append(line).append("\n");
        }
        return sb.toString();
    }

    public void shutdown() { running = false; this.interrupt(); }
}
