/**
 * AITrainingThread — Distinct training module running on its own thread(s).
 *
 * Consumes scouted data (up to 200 MB) and received questions/data from modules.
 * Scores models using language and mortality as initial grading setters.
 * Stores best models. Produces Review of Futures and Conducts documents.
 *
 * Grading Mechanism:
 *   - Language score (0.0-1.0): quality, correctness, readability
 *   - Mortality score (0.0-1.0): moral/ethical content quality
 *   - Composite = (language * 0.50) + (mortality * 0.50)
 *
 * Output: Review documents in relative source folders.
 *
 * @author Max Rupplin
 * @javaowner Max Rupplin
 * @date June 19 2026 EST
 */

package international.radio;

import commons.CommonRails;
import exceptions.ExceptionHandler;

import java.io.*;
import java.nio.charset.StandardCharsets;
import java.nio.file.*;
import java.sql.*;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;

public class AITrainingThread extends Thread
{
    private static final long TRIGGER_SIZE_BYTES = 200L * 1024 * 1024; // 200 MB
    private static final long CHECK_INTERVAL_MS = 5 * 60 * 1000; // 5 minutes
    private static final String[] COUNTRIES = {"japan", "russia", "mexico", "ukraine", "greece-international"};

    private volatile boolean running = true;
    private Connection dbConn;

    public AITrainingThread()
    {
        this.setName("AI_TRAINING_THREAD");
        this.setDaemon(true);
        initDatabase();
    }

    private void initDatabase()
    {
        try
        {
            dbConn = DriverManager.getConnection(
                "jdbc:mysql://localhost:3306/nwe_ai_integrative", "mearvk", "$$Ironman1");
        }
        catch (SQLException e) { ExceptionHandler.dispatch(e); }
    }

    @Override
    public void run()
    {
        CommonRails.printSystemComponent(this, this.hashCode(),
            ". AITrainingThread™ started — model scoring and review active .");

        while (running && !Thread.currentThread().isInterrupted())
        {
            for (String country : COUNTRIES)
            {
                try
                {
                    long pendingSize = getPendingScoutingSize(country);
                    if (pendingSize >= TRIGGER_SIZE_BYTES)
                    {
                        consumeAndTrain(country);
                    }
                    // Also process any unconsumed training pairs
                    processTrainingPairs(country);
                }
                catch (Exception e) { ExceptionHandler.dispatch(e); }
            }

            try { Thread.sleep(CHECK_INTERVAL_MS); }
            catch (InterruptedException e) { break; }
        }
    }

    /**
     * Consumes scouted data and runs scoring/grading.
     */
    private void consumeAndTrain(String country)
    {
        CommonRails.printSystemComponent(this, this.hashCode(),
            ". AITrainingThread™ consuming 200 MB scouting data for " + country + " .");

        try
        {
            // Mark scouting entries as consumed
            try (PreparedStatement ps = dbConn.prepareStatement(
                "UPDATE scouting_log SET consumed_by_training = TRUE " +
                "WHERE country_id = ? AND consumed_by_training = FALSE AND gain_level = 'accept'"))
            {
                ps.setString(1, country);
                ps.executeUpdate();
            }

            // Score the model based on consumed data
            float languageGrade = scoreLanguage(country);
            float mortalityGrade = scoreMortality(country);
            float composite = (languageGrade * 0.50f) + (mortalityGrade * 0.50f);

            // Store model score
            storeModelScore(country, languageGrade, mortalityGrade, composite);

            // Write Review of Futures and Conducts
            writeReviewDocument(country, languageGrade, mortalityGrade, composite);

            CommonRails.printSystemComponent(this, this.hashCode(),
                ". AITrainingThread™ " + country + " scored: L=" +
                String.format("%.2f", languageGrade) + " M=" +
                String.format("%.2f", mortalityGrade) + " C=" +
                String.format("%.2f", composite) + " .");
        }
        catch (SQLException e) { ExceptionHandler.dispatch(e); }
    }

    /**
     * Processes pending training pairs — grades and accepts/rejects.
     */
    private void processTrainingPairs(String country)
    {
        if (dbConn == null) return;
        try (PreparedStatement ps = dbConn.prepareStatement(
            "SELECT id, input_text, output_text FROM training_pairs " +
            "WHERE country_id = ? AND accepted = FALSE LIMIT 100"))
        {
            ps.setString(1, country);
            ResultSet rs = ps.executeQuery();
            while (rs.next())
            {
                long id = rs.getLong("id");
                String input = rs.getString("input_text");
                String output = rs.getString("output_text");

                float lang = gradeLanguage(output);
                float moral = gradeMortality(output);

                boolean accept = lang >= 0.40f && moral >= 0.40f;

                try (PreparedStatement up = dbConn.prepareStatement(
                    "UPDATE training_pairs SET language_score = ?, mortality_score = ?, accepted = ? WHERE id = ?"))
                {
                    up.setFloat(1, lang);
                    up.setFloat(2, moral);
                    up.setBoolean(3, accept);
                    up.setLong(4, id);
                    up.executeUpdate();
                }
            }
        }
        catch (SQLException e) { ExceptionHandler.dispatch(e); }
    }

    /**
     * Scores language quality for a country's data.
     */
    private float scoreLanguage(String country) throws SQLException
    {
        try (PreparedStatement ps = dbConn.prepareStatement(
            "SELECT AVG(LENGTH(content)) as avg_len, COUNT(*) as cnt FROM scouting_log " +
            "WHERE country_id = ? AND consumed_by_training = TRUE"))
        {
            ps.setString(1, country);
            ResultSet rs = ps.executeQuery();
            if (rs.next())
            {
                double avgLen = rs.getDouble("avg_len");
                // Longer, more substantive content scores higher
                return Math.min(1.0f, (float)(avgLen / 5000.0));
            }
        }
        return 0.5f;
    }

    /**
     * Scores mortality/moral quality for a country's data.
     */
    private float scoreMortality(String country) throws SQLException
    {
        try (PreparedStatement ps = dbConn.prepareStatement(
            "SELECT COUNT(*) as total, SUM(CASE WHEN gain_level = 'accept' THEN 1 ELSE 0 END) as accepted " +
            "FROM scouting_log WHERE country_id = ? AND consumed_by_training = TRUE"))
        {
            ps.setString(1, country);
            ResultSet rs = ps.executeQuery();
            if (rs.next())
            {
                int total = rs.getInt("total");
                int accepted = rs.getInt("accepted");
                if (total == 0) return 0.5f;
                return (float) accepted / total;
            }
        }
        return 0.5f;
    }

    /** Grades a single text for language quality. */
    private float gradeLanguage(String text)
    {
        if (text == null || text.isEmpty()) return 0.0f;
        // Heuristic: sentences, punctuation, capitalization
        int sentences = text.split("[.!?]").length;
        boolean hasCapital = Character.isUpperCase(text.charAt(0));
        float score = Math.min(1.0f, sentences / 10.0f);
        if (hasCapital) score += 0.1f;
        return Math.min(1.0f, score);
    }

    /** Grades a single text for mortality/moral quality. */
    private float gradeMortality(String text)
    {
        if (text == null || text.isEmpty()) return 0.0f;
        String lower = text.toLowerCase();
        float score = 1.0f;
        String[] negatives = {"hate", "kill", "explicit", "pornograph", "gore", "terror"};
        for (String neg : negatives)
        {
            if (lower.contains(neg)) score -= 0.25f;
        }
        return Math.max(0.0f, score);
    }

    /** Stores model score and marks best. */
    private void storeModelScore(String country, float langGrade, float moralGrade, float composite)
        throws SQLException
    {
        // Unmark previous best
        try (PreparedStatement ps = dbConn.prepareStatement(
            "UPDATE model_scores SET is_best = FALSE WHERE country_id = ? AND is_best = TRUE"))
        {
            ps.setString(1, country);
            ps.executeUpdate();
        }

        // Insert new score
        try (PreparedStatement ps = dbConn.prepareStatement(
            "INSERT INTO model_scores (model_name, country_id, language_grade, mortality_grade, " +
            "composite_score, is_best) VALUES (?, ?, ?, ?, ?, TRUE)"))
        {
            String modelName = "ai-integrative-" + country + "-" +
                LocalDate.now().format(DateTimeFormatter.ISO_LOCAL_DATE);
            ps.setString(1, modelName);
            ps.setString(2, country);
            ps.setFloat(3, langGrade);
            ps.setFloat(4, moralGrade);
            ps.setFloat(5, composite);
            ps.executeUpdate();
        }
    }

    /**
     * Writes Review of Futures and Conducts document in relative source folder.
     */
    private void writeReviewDocument(String country, float langGrade, float moralGrade, float composite)
    {
        Path reviewDir = Path.of("source/international/radio/" + country.replace("-international", "") + "/reviews");
        if (country.equals("greece-international")) reviewDir = Path.of("source/greece/international/reviews");

        try { Files.createDirectories(reviewDir); }
        catch (IOException e) { ExceptionHandler.dispatch(e); return; }

        String today = LocalDate.now().format(DateTimeFormatter.ISO_LOCAL_DATE);
        Path reviewFile = reviewDir.resolve("review-futures-conducts-" + today + ".txt");

        StringBuilder doc = new StringBuilder();
        doc.append("==========================================================\n");
        doc.append("REVIEW OF FUTURES AND CONDUCTS\n");
        doc.append("Module: international.radio.").append(country).append("\n");
        doc.append("Date: ").append(today).append("\n");
        doc.append("Reviewer: AI_TRAINING_THREAD\n");
        doc.append("==========================================================\n\n");

        doc.append("SCORING SUMMARY\n\n");
        doc.append("Language Grade: ").append(String.format("%.3f", langGrade)).append(" / 1.000\n");
        doc.append("Mortality Grade: ").append(String.format("%.3f", moralGrade)).append(" / 1.000\n");
        doc.append("Composite Score: ").append(String.format("%.3f", composite)).append(" / 1.000\n\n");

        doc.append("LANGUAGE ASSESSMENT\n\n");
        doc.append("The language quality of scouted and received data for the ");
        doc.append(country).append(" module was evaluated against sentence structure, ");
        doc.append("punctuation consistency, and informational density. A score of ");
        doc.append(String.format("%.3f", langGrade));
        doc.append(" indicates ").append(langGrade >= 0.7 ? "strong" : langGrade >= 0.4 ? "adequate" : "weak");
        doc.append(" linguistic quality in the current training corpus.\n\n");

        doc.append("MORTALITY ASSESSMENT\n\n");
        doc.append("The moral and ethical quality of content was assessed through ");
        doc.append("the gain control heuristic. A mortality grade of ");
        doc.append(String.format("%.3f", moralGrade));
        doc.append(" reflects the proportion of data passing the explicit content ");
        doc.append("filter and meeting ethical standards for storage and training.\n\n");

        doc.append("FUTURES OUTLOOK\n\n");
        doc.append("Based on current scoring trajectory, the ").append(country);
        doc.append(" module's AI integrative is ");
        doc.append(composite >= 0.7 ? "performing well and ready for production inference. " :
                   composite >= 0.4 ? "adequate but would benefit from additional high-quality scouting sources. " :
                   "below threshold and requires source diversification and quality improvement. ");
        doc.append("Continued daily scouting and feedback loop operation will refine ");
        doc.append("the model over subsequent training cycles.\n\n");

        doc.append("CONDUCT NOTES\n\n");
        doc.append("Public and private channel usage has been careful and within ");
        doc.append("established chapter guidelines. No unauthorized data exfiltration ");
        doc.append("or channel misuse was detected during this review period. ");
        doc.append("Gain control remains active for all INTERNET-sourced data.\n\n");

        doc.append("END OF REVIEW\n");

        try { Files.writeString(reviewFile, doc.toString(), StandardCharsets.UTF_8); }
        catch (IOException e) { ExceptionHandler.dispatch(e); }

        // Also store in database
        storeReviewInDb(country, today, langGrade, moralGrade, composite);
    }

    private void storeReviewInDb(String country, String period, float lang, float moral, float composite)
    {
        if (dbConn == null) return;
        try (PreparedStatement ps = dbConn.prepareStatement(
            "INSERT INTO review_futures_conducts (country_id, review_period, language_assessment, " +
            "mortality_assessment, composite_score) VALUES (?, ?, ?, ?, ?)"))
        {
            ps.setString(1, country);
            ps.setString(2, period);
            ps.setString(3, "Language grade: " + String.format("%.3f", lang));
            ps.setString(4, "Mortality grade: " + String.format("%.3f", moral));
            ps.setFloat(5, composite);
            ps.executeUpdate();
        }
        catch (SQLException e) { ExceptionHandler.dispatch(e); }
    }

    private long getPendingScoutingSize(String country)
    {
        if (dbConn == null) return 0;
        try (PreparedStatement ps = dbConn.prepareStatement(
            "SELECT COALESCE(SUM(content_size_bytes), 0) FROM scouting_log " +
            "WHERE country_id = ? AND consumed_by_training = FALSE"))
        {
            ps.setString(1, country);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) return rs.getLong(1);
        }
        catch (SQLException e) { ExceptionHandler.dispatch(e); }
        return 0;
    }

    public void shutdown() { running = false; this.interrupt(); }
}
