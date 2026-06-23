/**
 * StrernaryKnowledgeFetcher — Reaches out to Wikipedia and web search
 * to populate the nwe_strernary knowledge base. Port 20000 references
 * this database to answer factual questions not covered by the DJL model.
 *
 * Also stores training pairs and persists model state to MySQL.
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
import java.util.regex.*;

public class StrernaryKnowledgeFetcher
{
    private static final String WIKIPEDIA_API = "https://en.wikipedia.org/api/rest_v1/page/summary/";
    private static final String WIKIPEDIA_SEARCH = "https://en.wikipedia.org/w/api.php?action=query&list=search&srsearch=%s&format=json&srlimit=3";

    private Connection dbConn;

    public StrernaryKnowledgeFetcher()
    {
        initDatabase();
    }

    private void initDatabase()
    {
        try
        {
            dbConn = DriverManager.getConnection("jdbc:mysql://localhost:3306/nwe_strernary", "mearvk", "$$Ironman1");
            CommonRails.printSystemComponent(this, this.hashCode(),
                ". Strernary\u2122 knowledge database nwe_strernary connected .");
        }
        catch (SQLException e)
        {
            ExceptionHandler.dispatch(e);
        }
    }

    /**
     * Looks up a question in the knowledge base. Returns answer or null.
     */
    public String lookup(String question)
    {
        if (dbConn == null) return null;
        try (PreparedStatement ps = dbConn.prepareStatement(
            "SELECT answer, confidence FROM knowledge_base WHERE question = ? ORDER BY confidence DESC LIMIT 1"))
        {
            ps.setString(1, question.toLowerCase().trim());
            ResultSet rs = ps.executeQuery();
            if (rs.next())
            {
                // Increment access count
                try (PreparedStatement up = dbConn.prepareStatement(
                    "UPDATE knowledge_base SET access_count = access_count + 1 WHERE question = ?"))
                {
                    up.setString(1, question.toLowerCase().trim());
                    up.executeUpdate();
                }
                return rs.getString("answer");
            }
        }
        catch (SQLException e) { ExceptionHandler.dispatch(e); }
        return null;
    }

    /**
     * Fetches answer from Wikipedia and stores in knowledge base.
     */
    public String fetchAndStore(String question)
    {
        String answer = fetchFromWikipedia(question);
        if (answer != null && !answer.isEmpty())
        {
            store(question, answer, "wikipedia");
            storeTrainingPair(question, answer, "wikipedia");
            return answer;
        }

        // Try web search summary
        answer = fetchFromSearch(question);
        if (answer != null && !answer.isEmpty())
        {
            store(question, answer, "search");
            storeTrainingPair(question, answer, "search");
            return answer;
        }

        return null;
    }

    /**
     * Fetches a summary from Wikipedia REST API.
     */
    private String fetchFromWikipedia(String query)
    {
        try
        {
            // Extract key term for Wikipedia lookup
            String term = extractKeyTerm(query);
            String url = WIKIPEDIA_API + URLEncoder.encode(term, StandardCharsets.UTF_8);
            String json = httpGet(url);

            // Parse extract field from JSON
            String extract = extractJsonField(json, "extract");
            if (extract != null && extract.length() > 10) return extract;

            // Try search if direct lookup fails
            return searchWikipedia(query);
        }
        catch (Exception e) { return null; }
    }

    /**
     * Searches Wikipedia and returns the first result's extract.
     */
    private String searchWikipedia(String query)
    {
        try
        {
            String url = String.format(WIKIPEDIA_SEARCH, URLEncoder.encode(query, StandardCharsets.UTF_8));
            String json = httpGet(url);

            // Extract first snippet from search results
            String snippet = extractJsonField(json, "snippet");
            if (snippet != null)
            {
                // Strip HTML tags from snippet
                snippet = snippet.replaceAll("<[^>]+>", "").trim();
                if (snippet.length() > 10) return snippet;
            }
        }
        catch (Exception e) { /* fall through */ }
        return null;
    }

    /**
     * Fetches from a search engine summary (DuckDuckGo instant answer API).
     */
    private String fetchFromSearch(String query)
    {
        try
        {
            String url = "https://api.duckduckgo.com/?q=" +
                URLEncoder.encode(query, StandardCharsets.UTF_8) + "&format=json&no_html=1";
            String json = httpGet(url);

            String abstractText = extractJsonField(json, "AbstractText");
            if (abstractText != null && abstractText.length() > 10) return abstractText;

            String answer = extractJsonField(json, "Answer");
            if (answer != null && answer.length() > 2) return answer;
        }
        catch (Exception e) { /* fall through */ }
        return null;
    }

    /**
     * Stores a question/answer pair in the knowledge base.
     */
    public void store(String question, String answer, String source)
    {
        if (dbConn == null) return;
        try (PreparedStatement ps = dbConn.prepareStatement(
            "INSERT INTO knowledge_base (question, answer, source, confidence) VALUES (?, ?, ?, ?) " +
            "ON DUPLICATE KEY UPDATE answer = VALUES(answer), confidence = confidence + 0.1"))
        {
            ps.setString(1, question.toLowerCase().trim());
            ps.setString(2, answer);
            ps.setString(3, source);
            ps.setFloat(4, 0.7f);
            ps.executeUpdate();
        }
        catch (SQLException e) { ExceptionHandler.dispatch(e); }
    }

    /**
     * Stores a training pair for model fine-tuning.
     */
    public void storeTrainingPair(String input, String output, String source)
    {
        if (dbConn == null) return;
        try (PreparedStatement ps = dbConn.prepareStatement(
            "INSERT INTO training_pairs (input_text, output_text, source) VALUES (?, ?, ?)"))
        {
            ps.setString(1, input);
            ps.setString(2, output);
            ps.setString(3, source);
            ps.executeUpdate();
        }
        catch (SQLException e) { ExceptionHandler.dispatch(e); }
    }

    /**
     * Saves model state (weights/vocab) to the database.
     */
    public void saveModelState(String modelName, byte[] modelData, String vocabData, int sampleCount)
    {
        if (dbConn == null) return;
        try (PreparedStatement ps = dbConn.prepareStatement(
            "INSERT INTO model_state (model_name, model_data, vocab_data, sample_count) VALUES (?, ?, ?, ?)"))
        {
            ps.setString(1, modelName);
            ps.setBytes(2, modelData);
            ps.setString(3, vocabData);
            ps.setInt(4, sampleCount);
            ps.executeUpdate();
        }
        catch (SQLException e) { ExceptionHandler.dispatch(e); }
    }

    /**
     * Loads the latest model state from the database.
     */
    public byte[] loadModelState(String modelName)
    {
        if (dbConn == null) return null;
        try (PreparedStatement ps = dbConn.prepareStatement(
            "SELECT model_data FROM model_state WHERE model_name = ? ORDER BY trained_at DESC LIMIT 1"))
        {
            ps.setString(1, modelName);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) return rs.getBytes("model_data");
        }
        catch (SQLException e) { ExceptionHandler.dispatch(e); }
        return null;
    }

    private String extractKeyTerm(String query)
    {
        // Remove question words and extract the core topic
        return query.replaceAll("(?i)^(what|who|where|when|why|how|is|are|was|were|do|does|did|can|could|tell me about)\\s+", "")
                    .replaceAll("[?!.,]", "").trim();
    }

    private String extractJsonField(String json, String field)
    {
        Pattern p = Pattern.compile("\"" + field + "\"\\s*:\\s*\"((?:[^\"\\\\]|\\\\.)*)\"");
        Matcher m = p.matcher(json);
        if (m.find()) return m.group(1).replace("\\\"", "\"").replace("\\n", "\n");
        return null;
    }

    private String httpGet(String url) throws IOException
    {
        HttpURLConnection conn = (HttpURLConnection) new URL(url).openConnection();
        conn.setRequestMethod("GET");
        conn.setConnectTimeout(8000);
        conn.setReadTimeout(8000);
        conn.setRequestProperty("User-Agent", "NitroWebExpress-Strernary/1.0");
        conn.setRequestProperty("Accept", "application/json");

        StringBuilder sb = new StringBuilder();
        try (BufferedReader reader = new BufferedReader(
            new InputStreamReader(conn.getInputStream(), StandardCharsets.UTF_8)))
        {
            String line;
            while ((line = reader.readLine()) != null) sb.append(line).append("\n");
        }
        return sb.toString();
    }
}
