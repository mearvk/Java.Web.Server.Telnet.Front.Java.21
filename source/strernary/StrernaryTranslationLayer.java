/**
 * StrernaryTranslationLayer — Translation and cross-module inference for Strernary.
 *
 * When a user asks in English on port 20000, this layer can:
 * 1. Route to national signal servers (Japan, Russia, Mexico, Greece, etc.)
 * 2. Translate the query to the target language
 * 3. Fetch data from national databases
 * 4. Translate the response back to English
 * 5. Store translation pairs for future reference
 *
 * @author Max Rupplin
 * @javaowner Max Rupplin
 * @date June 19 2026 EST
 */

package strernary;

import exceptions.ExceptionHandler;

import java.io.*;
import java.net.*;
import java.nio.charset.StandardCharsets;
import java.sql.*;
import java.util.*;

public class StrernaryTranslationLayer
{
    private Connection dbConn;

    private static final Map<String, NationalEndpoint> NATIONALS = Map.of(
        "japan",   new NationalEndpoint("localhost", 49201, "ja", "nwe_japan"),
        "russia",  new NationalEndpoint("localhost", 49202, "ru", "nwe_russia"),
        "mexico",  new NationalEndpoint("localhost", 49203, "es", "nwe_mexico"),
        "greece",  new NationalEndpoint("localhost", 49204, "el", "nwe_greece_intl")
    );

    record NationalEndpoint(String host, int port, String lang, String database) {}

    public StrernaryTranslationLayer()
    {
        initDatabase();
    }

    private void initDatabase()
    {
        try
        {
            dbConn = DriverManager.getConnection("jdbc:mysql://localhost:3306/nwe_strernary", "mearvk", "$$Ironman1");
            try (Statement stmt = dbConn.createStatement())
            {
                stmt.executeUpdate(
                    "CREATE TABLE IF NOT EXISTS translations (" +
                    "  id BIGINT AUTO_INCREMENT PRIMARY KEY," +
                    "  source_lang VARCHAR(8) DEFAULT 'en'," +
                    "  target_lang VARCHAR(8) NOT NULL," +
                    "  source_text VARCHAR(1024) NOT NULL," +
                    "  translated_text VARCHAR(1024) NOT NULL," +
                    "  nation VARCHAR(32)," +
                    "  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP," +
                    "  INDEX idx_src (source_text(255))," +
                    "  INDEX idx_lang (target_lang)" +
                    ")"
                );
                stmt.executeUpdate(
                    "CREATE TABLE IF NOT EXISTS national_inferences (" +
                    "  id BIGINT AUTO_INCREMENT PRIMARY KEY," +
                    "  query_en VARCHAR(1024) NOT NULL," +
                    "  nation VARCHAR(32) NOT NULL," +
                    "  national_response LONGTEXT," +
                    "  response_en LONGTEXT," +
                    "  inferred_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP," +
                    "  INDEX idx_query (query_en(255))," +
                    "  INDEX idx_nation (nation)" +
                    ")"
                );
            }
        }
        catch (SQLException e) { ExceptionHandler.dispatch(e); }
    }

    /**
     * Routes an English query to the appropriate national server(s),
     * fetches their data, and returns a combined English response.
     */
    public String queryNationals(String englishQuery)
    {
        // Detect which nation(s) are relevant
        List<String> targets = detectTargetNations(englishQuery);
        if (targets.isEmpty()) return null;

        StringBuilder combined = new StringBuilder();
        for (String nation : targets)
        {
            String result = queryNational(nation, englishQuery);
            if (result != null) combined.append("[").append(nation.toUpperCase()).append("] ").append(result).append(" | ");
        }

        return combined.length() > 0 ? combined.toString().trim() : null;
    }

    /**
     * Queries a specific national server and translates response to English.
     */
    public String queryNational(String nation, String englishQuery)
    {
        NationalEndpoint ep = NATIONALS.get(nation.toLowerCase());
        if (ep == null) return null;

        // Check cached inference first
        String cached = lookupCachedInference(englishQuery, nation);
        if (cached != null) return cached;

        // Translate query to national language
        String translated = translate(englishQuery, "en", ep.lang());

        // Send SIGNAL or FETCH to the national server
        String nationalResponse = sendToNational(ep, translated);
        if (nationalResponse == null) return null;

        // Translate response back to English
        String responseEn = translate(nationalResponse, ep.lang(), "en");

        // Store for future reference
        storeInference(englishQuery, nation, nationalResponse, responseEn);
        storeTranslation("en", ep.lang(), englishQuery, translated, nation);

        return responseEn;
    }

    /**
     * Translates text between languages using stored pairs and heuristic mapping.
     * For production, this would call a translation API; here we use stored pairs
     * and a lightweight approach.
     */
    public String translate(String text, String fromLang, String toLang)
    {
        if (fromLang.equals(toLang)) return text;

        // Check stored translations
        String stored = lookupTranslation(text, toLang);
        if (stored != null) return stored;

        // Use MyMemory free translation API
        try
        {
            String url = "https://api.mymemory.translated.net/get?q=" +
                URLEncoder.encode(text, StandardCharsets.UTF_8) +
                "&langpair=" + fromLang + "|" + toLang;

            String json = httpGet(url);
            String translated = extractJsonField(json, "translatedText");
            if (translated != null && !translated.isEmpty())
            {
                storeTranslation(fromLang, toLang, text, translated, null);
                return translated;
            }
        }
        catch (Exception e) { /* fall through to original */ }

        return text; // Return original if translation fails
    }

    /**
     * Sends a query to a national signal server via TCP socket.
     */
    private String sendToNational(NationalEndpoint ep, String query)
    {
        try (Socket sock = new Socket())
        {
            sock.connect(new InetSocketAddress(ep.host(), ep.port()), 3000);
            sock.setSoTimeout(5000);

            OutputStream out = sock.getOutputStream();
            out.write(("SIGNAL|" + query + "\n").getBytes(StandardCharsets.UTF_8));
            out.flush();

            BufferedReader in = new BufferedReader(new InputStreamReader(sock.getInputStream()));
            return in.readLine();
        }
        catch (Exception e) { return null; }
    }

    private List<String> detectTargetNations(String query)
    {
        String lower = query.toLowerCase();
        List<String> targets = new ArrayList<>();

        if (lower.contains("japan") || lower.contains("nikkei") || lower.contains("tokyo") || lower.contains("yen"))
            targets.add("japan");
        if (lower.contains("russia") || lower.contains("moscow") || lower.contains("ruble") || lower.contains("moex"))
            targets.add("russia");
        if (lower.contains("mexico") || lower.contains("peso") || lower.contains("bmv") || lower.contains("pemex"))
            targets.add("mexico");
        if (lower.contains("greece") || lower.contains("athens") || lower.contains("euro") || lower.contains("baltic"))
            targets.add("greece");

        // If no specific nation detected but query seems international
        if (targets.isEmpty() && (lower.contains("international") || lower.contains("global") || lower.contains("world")))
            targets.addAll(List.of("japan", "russia", "mexico", "greece"));

        return targets;
    }

    private String lookupCachedInference(String query, String nation)
    {
        if (dbConn == null) return null;
        try (PreparedStatement ps = dbConn.prepareStatement(
            "SELECT response_en FROM national_inferences WHERE query_en = ? AND nation = ? ORDER BY inferred_at DESC LIMIT 1"))
        {
            ps.setString(1, query.toLowerCase().trim());
            ps.setString(2, nation);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) return rs.getString("response_en");
        }
        catch (SQLException e) { ExceptionHandler.dispatch(e); }
        return null;
    }

    private String lookupTranslation(String text, String toLang)
    {
        if (dbConn == null) return null;
        try (PreparedStatement ps = dbConn.prepareStatement(
            "SELECT translated_text FROM translations WHERE source_text = ? AND target_lang = ? LIMIT 1"))
        {
            ps.setString(1, text);
            ps.setString(2, toLang);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) return rs.getString("translated_text");
        }
        catch (SQLException e) { ExceptionHandler.dispatch(e); }
        return null;
    }

    private void storeInference(String queryEn, String nation, String nationalResponse, String responseEn)
    {
        if (dbConn == null) return;
        try (PreparedStatement ps = dbConn.prepareStatement(
            "INSERT INTO national_inferences (query_en, nation, national_response, response_en) VALUES (?, ?, ?, ?)"))
        {
            ps.setString(1, queryEn.toLowerCase().trim());
            ps.setString(2, nation);
            ps.setString(3, nationalResponse);
            ps.setString(4, responseEn);
            ps.executeUpdate();
        }
        catch (SQLException e) { ExceptionHandler.dispatch(e); }
    }

    private void storeTranslation(String fromLang, String toLang, String source, String translated, String nation)
    {
        if (dbConn == null) return;
        try (PreparedStatement ps = dbConn.prepareStatement(
            "INSERT INTO translations (source_lang, target_lang, source_text, translated_text, nation) VALUES (?, ?, ?, ?, ?)"))
        {
            ps.setString(1, fromLang);
            ps.setString(2, toLang);
            ps.setString(3, source);
            ps.setString(4, translated);
            ps.setString(5, nation);
            ps.executeUpdate();
        }
        catch (SQLException e) { ExceptionHandler.dispatch(e); }
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
        conn.setConnectTimeout(8000);
        conn.setReadTimeout(8000);
        conn.setRequestProperty("User-Agent", "NitroWebExpress-Strernary/1.0");

        StringBuilder sb = new StringBuilder();
        try (BufferedReader reader = new BufferedReader(new InputStreamReader(conn.getInputStream(), StandardCharsets.UTF_8)))
        {
            String line;
            while ((line = reader.readLine()) != null) sb.append(line).append("\n");
        }
        return sb.toString();
    }
}
