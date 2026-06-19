/**
 * AIIntegrativeEngine — Shared AI inference engine for all international.radio modules.
 *
 * Architecture:
 *   - Singular DJL model shared across Japan, Russia, Mexico, Ukraine, Greece modules
 *   - Feedback loop with moral verdict sourcing (HOUSING, LOCAL, INTERNET)
 *   - Heuristics and gain control over explicit content
 *   - NWE connector interface for Strernary, AIProctor, and other modules
 *
 * Verdict Sourcing:
 *   HOUSING  — from this module's own innate knowledge XML (trust 0.95)
 *   LOCAL    — from a local NWE connector (trust 0.80)
 *   INTERNET — from public internet scouting (trust 0.40)
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
import java.sql.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicBoolean;

public class AIIntegrativeEngine
{
    private static final AIIntegrativeEngine INSTANCE = new AIIntegrativeEngine();

    private Connection dbConn;
    private final ConcurrentHashMap<String, String> housingKnowledge = new ConcurrentHashMap<>();
    private final AtomicBoolean ready = new AtomicBoolean(false);

    public enum VerdictSource { HOUSING, LOCAL, INTERNET }

    private AIIntegrativeEngine() { initDatabase(); }

    public static AIIntegrativeEngine getInstance() { return INSTANCE; }

    private void initDatabase()
    {
        try
        {
            dbConn = DriverManager.getConnection(
                "jdbc:mysql://localhost:3306/nwe_ai_integrative", "mearvk", "$$Ironman1");
            ready.set(true);
            CommonRails.printSystemComponent(this, this.hashCode(),
                ". AIIntegrativeEngine™ database nwe_ai_integrative connected .");
        }
        catch (SQLException e)
        {
            ExceptionHandler.dispatch(e);
            CommonRails.printSystemComponent(this, this.hashCode(),
                ". AIIntegrativeEngine™ database init failed .",
                commons.color.ColorPalette.COLOR_STANDARD_RED);
        }
    }

    /**
     * Processes a query with moral verdict sourcing.
     * Priority: HOUSING -> LOCAL (Strernary/AIProctor) -> INTERNET
     */
    public String query(String countryId, String question)
    {
        // 1. Check housing (own innate knowledge)
        String housingAnswer = lookupHousing(countryId, question);
        if (housingAnswer != null)
        {
            recordFeedback(countryId, question, housingAnswer, VerdictSource.HOUSING, true);
            return housingAnswer;
        }

        // 2. Check local connectors (Strernary port 20000)
        String localAnswer = queryLocalConnector(question);
        if (localAnswer != null)
        {
            recordFeedback(countryId, question, localAnswer, VerdictSource.LOCAL, true);
            storeKnowledge(countryId, question, localAnswer, "local-connector", VerdictSource.LOCAL);
            return localAnswer;
        }

        // 3. Fallback to internet (lower trust, requires gain control)
        String internetAnswer = queryInternet(question);
        if (internetAnswer != null)
        {
            boolean moralPass = gainControl(internetAnswer);
            recordFeedback(countryId, question, internetAnswer, VerdictSource.INTERNET, moralPass);
            if (moralPass)
            {
                storeKnowledge(countryId, question, internetAnswer, "internet-scout", VerdictSource.INTERNET);
            }
            return moralPass ? internetAnswer : "[CONTENT REJECTED BY GAIN CONTROL]";
        }

        return null;
    }

    /** Looks up answer from this module's innate housing knowledge. */
    private String lookupHousing(String countryId, String question)
    {
        if (!ready.get()) return null;
        try (PreparedStatement ps = dbConn.prepareStatement(
            "SELECT answer FROM country_knowledge WHERE country_id = ? AND question = ? " +
            "AND verdict_source = 'HOUSING' AND gain_level = 'accept' ORDER BY confidence DESC LIMIT 1"))
        {
            ps.setString(1, countryId);
            ps.setString(2, question.toLowerCase().trim());
            ResultSet rs = ps.executeQuery();
            if (rs.next()) return rs.getString("answer");
        }
        catch (SQLException e) { ExceptionHandler.dispatch(e); }
        return null;
    }

    /** Queries local NWE connector (Strernary on port 20000). */
    private String queryLocalConnector(String question)
    {
        try (Socket s = new Socket("localhost", 20000))
        {
            s.setSoTimeout(3000);
            OutputStream out = s.getOutputStream();
            out.write(("ASK|" + question + "\n").getBytes(StandardCharsets.UTF_8));
            out.flush();
            BufferedReader in = new BufferedReader(new InputStreamReader(s.getInputStream()));
            String response = in.readLine();
            if (response != null && !response.startsWith("ERR")) return response;
        }
        catch (Exception e) { /* Strernary not available — fall through */ }
        return null;
    }

    /** Queries internet via DuckDuckGo instant answer. */
    private String queryInternet(String question)
    {
        try
        {
            String url = "https://api.duckduckgo.com/?q=" +
                URLEncoder.encode(question, StandardCharsets.UTF_8) + "&format=json&no_html=1";
            HttpURLConnection conn = (HttpURLConnection) new URI(url).toURL().openConnection();
            conn.setRequestMethod("GET");
            conn.setConnectTimeout(5000);
            conn.setReadTimeout(5000);
            StringBuilder sb = new StringBuilder();
            try (BufferedReader reader = new BufferedReader(
                new InputStreamReader(conn.getInputStream(), StandardCharsets.UTF_8)))
            {
                String line;
                while ((line = reader.readLine()) != null) sb.append(line);
            }
            String json = sb.toString();
            // Extract AbstractText
            int idx = json.indexOf("\"AbstractText\":\"");
            if (idx > 0)
            {
                int start = idx + 16;
                int end = json.indexOf("\"", start);
                if (end > start) return json.substring(start, end);
            }
        }
        catch (Exception e) { /* fall through */ }
        return null;
    }

    /**
     * Gain control — moral classifier that rejects explicit content.
     * Returns true if content is acceptable for training/storage.
     */
    private boolean gainControl(String content)
    {
        if (content == null || content.isEmpty()) return false;
        String lower = content.toLowerCase();
        // Basic explicit content detection
        String[] rejectPatterns = {"explicit", "pornograph", "gore", "hate speech"};
        for (String p : rejectPatterns)
        {
            if (lower.contains(p)) return false;
        }
        return true;
    }

    /** Stores knowledge in the country_knowledge table. */
    private void storeKnowledge(String countryId, String question, String answer,
                                String source, VerdictSource verdict)
    {
        if (!ready.get()) return;
        try (PreparedStatement ps = dbConn.prepareStatement(
            "INSERT INTO country_knowledge (country_id, category, question, answer, source, verdict_source, gain_level) " +
            "VALUES (?, 'general', ?, ?, ?, ?, 'accept') " +
            "ON DUPLICATE KEY UPDATE answer = VALUES(answer), confidence = confidence + 0.05"))
        {
            ps.setString(1, countryId);
            ps.setString(2, question.toLowerCase().trim());
            ps.setString(3, answer);
            ps.setString(4, source);
            ps.setString(5, verdict.name());
            ps.executeUpdate();
        }
        catch (SQLException e) { ExceptionHandler.dispatch(e); }
    }

    /** Records feedback loop entry with moral classification. */
    private void recordFeedback(String countryId, String question, String response,
                                VerdictSource verdict, boolean moralPass)
    {
        if (!ready.get()) return;
        float trust = switch (verdict) {
            case HOUSING -> 0.95f;
            case LOCAL -> 0.80f;
            case INTERNET -> 0.40f;
        };
        try (PreparedStatement ps = dbConn.prepareStatement(
            "INSERT INTO feedback_loop (country_id, query_text, response_text, verdict_source, " +
            "trust_level, moral_pass) VALUES (?, ?, ?, ?, ?, ?)"))
        {
            ps.setString(1, countryId);
            ps.setString(2, question);
            ps.setString(3, response);
            ps.setString(4, verdict.name());
            ps.setFloat(5, trust);
            ps.setBoolean(6, moralPass);
            ps.executeUpdate();
        }
        catch (SQLException e) { ExceptionHandler.dispatch(e); }
    }

    /** Stores a training pair from received questions/data. */
    public void storeTrainingPair(String countryId, String input, String output,
                                  String source, VerdictSource verdict)
    {
        if (!ready.get()) return;
        try (PreparedStatement ps = dbConn.prepareStatement(
            "INSERT INTO training_pairs (country_id, input_text, output_text, source, verdict_source) " +
            "VALUES (?, ?, ?, ?, ?)"))
        {
            ps.setString(1, countryId);
            ps.setString(2, input);
            ps.setString(3, output);
            ps.setString(4, source);
            ps.setString(5, verdict.name());
            ps.executeUpdate();
        }
        catch (SQLException e) { ExceptionHandler.dispatch(e); }
    }

    /** Logs connector activity for integrity verification. */
    public void logConnectorActivity(String countryId, String connectorId,
                                     String direction, String query, String response, int latencyMs)
    {
        if (!ready.get()) return;
        try (PreparedStatement ps = dbConn.prepareStatement(
            "INSERT INTO connector_activity (country_id, connector_id, direction, query_text, response_text, latency_ms) " +
            "VALUES (?, ?, ?, ?, ?, ?)"))
        {
            ps.setString(1, countryId);
            ps.setString(2, connectorId);
            ps.setString(3, direction);
            ps.setString(4, query);
            ps.setString(5, response);
            ps.setInt(6, latencyMs);
            ps.executeUpdate();
        }
        catch (SQLException e) { ExceptionHandler.dispatch(e); }
    }

    public boolean isReady() { return ready.get(); }
}
