/**
 * StrernaryLaborLawFetcher — Gathers labor law data from internet sources
 * for US, Europe, and Asia. Stores in nwe_strernary.labor_laws and trains
 * the Strernary knowledge base for labor law questions.
 *
 * Sources:
 *   - US DOL (Department of Labor)
 *   - ILO (International Labour Organization)
 *   - EUR-Lex (EU labor directives)
 *   - Wikipedia labor law articles
 *   - DuckDuckGo instant answers
 *
 * @author Max Rupplin
 * @javaowner Max Rupplin
 * @date June 19 2026 EST
 */

package strernary;

import commons.CommonRails;
import exceptions.ExceptionHandler;

import java.io.*;
import java.net.*;
import java.nio.charset.StandardCharsets;
import java.sql.*;
import java.util.*;

public class StrernaryLaborLawFetcher
{
    private Connection dbConn;
    private StrernaryKnowledgeFetcher knowledgeFetcher;

    private static final String[][] US_LABOR_TOPICS = {
        {"US", "Fair Labor Standards Act (FLSA)", "https://en.wikipedia.org/api/rest_v1/page/summary/Fair_Labor_Standards_Act_of_1938"},
        {"US", "Family and Medical Leave Act (FMLA)", "https://en.wikipedia.org/api/rest_v1/page/summary/Family_and_Medical_Leave_Act_of_1993"},
        {"US", "Occupational Safety and Health Act (OSHA)", "https://en.wikipedia.org/api/rest_v1/page/summary/Occupational_Safety_and_Health_Act_(United_States)"},
        {"US", "National Labor Relations Act", "https://en.wikipedia.org/api/rest_v1/page/summary/National_Labor_Relations_Act_of_1935"},
        {"US", "Equal Pay Act", "https://en.wikipedia.org/api/rest_v1/page/summary/Equal_Pay_Act_of_1963"},
        {"US", "Americans with Disabilities Act", "https://en.wikipedia.org/api/rest_v1/page/summary/Americans_with_Disabilities_Act_of_1990"},
        {"US", "Title VII Civil Rights Act", "https://en.wikipedia.org/api/rest_v1/page/summary/Civil_Rights_Act_of_1964"},
        {"US", "Worker Adjustment and Retraining (WARN)", "https://en.wikipedia.org/api/rest_v1/page/summary/Worker_Adjustment_and_Retraining_Notification_Act_of_1988"},
        {"US", "Employment at will", "https://en.wikipedia.org/api/rest_v1/page/summary/At-will_employment"},
        {"US", "Minimum wage", "https://en.wikipedia.org/api/rest_v1/page/summary/Minimum_wage_in_the_United_States"},
    };

    private static final String[][] EU_LABOR_TOPICS = {
        {"EU", "Working Time Directive", "https://en.wikipedia.org/api/rest_v1/page/summary/Working_Time_Directive_2003"},
        {"EU", "EU Employment Law", "https://en.wikipedia.org/api/rest_v1/page/summary/European_labour_law"},
        {"EU", "Posted Workers Directive", "https://en.wikipedia.org/api/rest_v1/page/summary/Posted_Workers_Directive"},
        {"EU", "European Works Council", "https://en.wikipedia.org/api/rest_v1/page/summary/European_works_council"},
        {"EU", "EU Minimum Wage Directive", "https://en.wikipedia.org/api/rest_v1/page/summary/Directive_on_adequate_minimum_wages"},
        {"Germany", "German labour law", "https://en.wikipedia.org/api/rest_v1/page/summary/German_labour_law"},
        {"France", "French labour law", "https://en.wikipedia.org/api/rest_v1/page/summary/French_labour_law"},
        {"UK", "UK employment law", "https://en.wikipedia.org/api/rest_v1/page/summary/United_Kingdom_labour_law"},
    };

    private static final String[][] ASIA_LABOR_TOPICS = {
        {"Japan", "Japanese labour law", "https://en.wikipedia.org/api/rest_v1/page/summary/Japanese_labour_law"},
        {"China", "Chinese labour law", "https://en.wikipedia.org/api/rest_v1/page/summary/Chinese_labour_law"},
        {"South Korea", "South Korean labour law", "https://en.wikipedia.org/api/rest_v1/page/summary/South_Korean_labour_law"},
        {"India", "Indian labour law", "https://en.wikipedia.org/api/rest_v1/page/summary/Indian_labour_law"},
        {"Singapore", "Employment Act Singapore", "https://en.wikipedia.org/api/rest_v1/page/summary/Employment_Act_(Singapore)"},
    };

    public StrernaryLaborLawFetcher(StrernaryKnowledgeFetcher knowledgeFetcher)
    {
        this.knowledgeFetcher = knowledgeFetcher;
        initDatabase();
    }

    private void initDatabase()
    {
        try
        {
            dbConn = DriverManager.getConnection("jdbc:mysql://localhost:3306/nwe_strernary", "mearvk", "$$Ironman1");
        }
        catch (SQLException e) { ExceptionHandler.dispatch(e); }
    }

    /**
     * Fetches all labor law data from internet sources and stores in database.
     * Call this on a background thread — it takes time.
     */
    public void fetchAll()
    {
        CommonRails.printSystemComponent(this, this.hashCode(),
            ". Strernary\u2122 labor law data gathering started .");

        int count = 0;
        count += fetchTopics("US", US_LABOR_TOPICS);
        count += fetchTopics("Europe", EU_LABOR_TOPICS);
        count += fetchTopics("Asia", ASIA_LABOR_TOPICS);

        // Additional ILO conventions
        count += fetchIloConventions();

        CommonRails.printSystemComponent(this, this.hashCode(),
            ". Strernary\u2122 labor law gathering complete: " + count + " entries stored .");

        // Save model state snapshot
        if (knowledgeFetcher != null)
        {
            String vocab = buildLaborLawVocab();
            knowledgeFetcher.saveModelState("labor_law_v1", vocab.getBytes(StandardCharsets.UTF_8), vocab, count);
        }
    }

    private int fetchTopics(String region, String[][] topics)
    {
        int stored = 0;
        for (String[] topic : topics)
        {
            try
            {
                String country = topic[0];
                String name = topic[1];
                String url = topic[2];

                String json = httpGet(url);
                String extract = extractJsonField(json, "extract");
                if (extract == null || extract.length() < 20) continue;

                storeLaborLaw(region, country, name, extract, url);

                // Also store as training pair and knowledge base entry
                String question = "What is " + name + " in " + country + "?";
                if (knowledgeFetcher != null)
                {
                    knowledgeFetcher.store(question, extract, "labor_law");
                    knowledgeFetcher.storeTrainingPair(question, extract, "labor_law");
                }

                stored++;
                Thread.sleep(500); // Rate limiting
            }
            catch (Exception e) { /* continue to next topic */ }
        }
        return stored;
    }

    private int fetchIloConventions()
    {
        String[][] ilo = {
            {"ILO", "Freedom of Association", "https://en.wikipedia.org/api/rest_v1/page/summary/Freedom_of_Association_and_Protection_of_the_Right_to_Organise_Convention"},
            {"ILO", "Forced Labour Convention", "https://en.wikipedia.org/api/rest_v1/page/summary/Forced_Labour_Convention"},
            {"ILO", "Equal Remuneration Convention", "https://en.wikipedia.org/api/rest_v1/page/summary/Equal_Remuneration_Convention,_1951"},
            {"ILO", "Minimum Age Convention", "https://en.wikipedia.org/api/rest_v1/page/summary/Minimum_Age_Convention,_1973"},
        };
        return fetchTopics("International", ilo);
    }

    private void storeLaborLaw(String region, String country, String topic, String summary, String sourceUrl)
    {
        if (dbConn == null) return;
        try (PreparedStatement ps = dbConn.prepareStatement(
            "INSERT INTO labor_laws (region, country, topic, summary, source_url) VALUES (?, ?, ?, ?, ?) " +
            "ON DUPLICATE KEY UPDATE summary = VALUES(summary)"))
        {
            ps.setString(1, region);
            ps.setString(2, country);
            ps.setString(3, topic);
            ps.setString(4, summary);
            ps.setString(5, sourceUrl);
            ps.executeUpdate();
        }
        catch (SQLException e) { ExceptionHandler.dispatch(e); }
    }

    /**
     * Queries labor laws for a given question.
     */
    public String queryLaborLaw(String question)
    {
        if (dbConn == null) return null;
        String lower = question.toLowerCase();

        // Determine country/region filter
        String countryFilter = "%";
        if (lower.contains("us") || lower.contains("america") || lower.contains("united states")) countryFilter = "US";
        else if (lower.contains("eu") || lower.contains("europe")) countryFilter = "%";
        else if (lower.contains("japan")) countryFilter = "Japan";
        else if (lower.contains("china")) countryFilter = "China";
        else if (lower.contains("germany")) countryFilter = "Germany";
        else if (lower.contains("france")) countryFilter = "France";
        else if (lower.contains("uk") || lower.contains("britain")) countryFilter = "UK";
        else if (lower.contains("india")) countryFilter = "India";
        else if (lower.contains("korea")) countryFilter = "South Korea";

        try (PreparedStatement ps = dbConn.prepareStatement(
            "SELECT topic, country, summary FROM labor_laws WHERE country LIKE ? " +
            "AND (LOWER(topic) LIKE ? OR LOWER(summary) LIKE ?) LIMIT 3"))
        {
            ps.setString(1, countryFilter);
            String searchTerm = "%" + extractKeywords(lower) + "%";
            ps.setString(2, searchTerm);
            ps.setString(3, searchTerm);
            ResultSet rs = ps.executeQuery();

            StringBuilder sb = new StringBuilder();
            while (rs.next())
            {
                sb.append("[").append(rs.getString("country")).append("] ")
                  .append(rs.getString("topic")).append(": ")
                  .append(truncate(rs.getString("summary"), 200)).append(" | ");
            }
            return sb.length() > 0 ? sb.toString().trim() : null;
        }
        catch (SQLException e) { ExceptionHandler.dispatch(e); return null; }
    }

    private String buildLaborLawVocab()
    {
        if (dbConn == null) return "";
        try (Statement stmt = dbConn.createStatement();
             ResultSet rs = stmt.executeQuery("SELECT topic, country, summary FROM labor_laws"))
        {
            StringBuilder vocab = new StringBuilder();
            while (rs.next())
            {
                vocab.append(rs.getString("country")).append("|")
                     .append(rs.getString("topic")).append("|")
                     .append(truncate(rs.getString("summary"), 500)).append("\n");
            }
            return vocab.toString();
        }
        catch (SQLException e) { return ""; }
    }

    private String extractKeywords(String text)
    {
        return text.replaceAll("(?i)(what|is|are|the|in|about|tell|me|law|laws|labor|labour|of|and|for|a|an)", "")
                   .replaceAll("\\s+", "%").trim();
    }

    private String truncate(String s, int max)
    {
        return s != null && s.length() > max ? s.substring(0, max) + "..." : s;
    }

    private String extractJsonField(String json, String field)
    {
        java.util.regex.Pattern p = java.util.regex.Pattern.compile("\"" + field + "\"\\s*:\\s*\"((?:[^\"\\\\]|\\\\.)*)\"");
        java.util.regex.Matcher m = p.matcher(json);
        if (m.find()) return m.group(1).replace("\\\"", "\"").replace("\\n", "\n");
        return null;
    }

    private String httpGet(String url) throws IOException
    {
        HttpURLConnection conn = (HttpURLConnection) new URL(url).openConnection();
        conn.setRequestMethod("GET");
        conn.setConnectTimeout(10000);
        conn.setReadTimeout(10000);
        conn.setRequestProperty("User-Agent", "NitroWebExpress-Strernary/1.0");
        conn.setRequestProperty("Accept", "application/json");

        StringBuilder sb = new StringBuilder();
        try (BufferedReader reader = new BufferedReader(new InputStreamReader(conn.getInputStream(), StandardCharsets.UTF_8)))
        {
            String line;
            while ((line = reader.readLine()) != null) sb.append(line).append("\n");
        }
        return sb.toString();
    }
}
