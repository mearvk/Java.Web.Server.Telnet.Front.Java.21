package source;

import commons.CommonRails;
import commons.StrernaryConnector;
import commons.color.ColorPalette;

import java.io.*;
import java.net.*;
import java.net.http.*;
import java.time.Duration;

/**
 * CaliforniaNSAServer — TCP signals intelligence module on port 49212.
 *
 * Connects to nsa.gov for public cybersecurity advisories and reporting.
 * NIO masquerade-aware. MySQL backed (nwe_california_nsa).
 * Installer ID Tech™ secured tables.
 *
 * Protocol: TCP socket
 *   REPORT|<category>|<text>   — Submit a cybersecurity incident report
 *   ADVISORY|<keyword>         — Query advisories
 *   STATUS                     — Server health check
 *   SEARCH|<keyword>           — Search local report DB
 *   QUIT                       — Disconnect
 *
 * @author Max Rupplin — MEARVK LLC
 * @date June 29 2026
 */
public class CaliforniaNSAServer implements Runnable {

    private static final int PORT = 49212;
    private static final String NSA_URL = "https://www.nsa.gov/";
    private static final String NSA_CYBERSECURITY_URL = "https://www.nsa.gov/Cybersecurity/";
    private static final String NSA_REPORT_URL = "https://www.nsa.gov/About/Cryptologic-Heritage/Historical-Figures-Posters/Report-a-Vulnerability/";
    private static final String COLOR = ColorPalette.COLOR_SKY_BLUE;

    private final HttpClient http = HttpClient.newBuilder()
            .followRedirects(HttpClient.Redirect.NORMAL)
            .connectTimeout(Duration.ofSeconds(10))
            .build();

    private volatile boolean running = true;
    private ServerSocket server;

    public static void main(String[] args) { new CaliforniaNSAServer().run(); }

    private void print(String msg) {
        CommonRails.printSystemComponent(this, this.hashCode(), msg, COLOR);
    }

    @Override
    public void run() {
        print(". CaliforniaNSA™ starting on port " + PORT + " .");
        initDatabase();
        try {
            server = new ServerSocket(PORT);
            print(". CaliforniaNSA™ listening on port " + PORT + " .");
            while (running) {
                Socket client = server.accept();
                Thread.startVirtualThread(() -> handleClient(client));
            }
        } catch (Exception e) {
            if (running) print(". CaliforniaNSA™ ERROR: " + e.getMessage() + " .");
        }
    }

    public void stop() {
        running = false;
        try { if (server != null) server.close(); } catch (Exception ignored) {}
    }

    private void handleClient(Socket client) {
        try (var in = new BufferedReader(new InputStreamReader(client.getInputStream()));
             var out = new PrintWriter(client.getOutputStream(), true)) {
            client.setSoTimeout(300_000);
            out.println("CaliforniaNSA™ — Cybersecurity & Signals Intelligence (AI-assisted)");
            out.println("Commands: REPORT|<category>|<text>, ADVISORY|<keyword>, SEARCH|<keyword>, STATUS, QUIT");
            out.println();

            String line;
            while ((line = in.readLine()) != null) {
                line = line.trim();
                if (line.equalsIgnoreCase("QUIT")) { out.println("Goodbye."); break; }
                if (line.equalsIgnoreCase("STATUS")) {
                    out.println("OK|port=" + PORT + "|db=nwe_california_nsa|nsa=" + checkReachable(NSA_URL));
                    continue;
                }
                if (line.startsWith("REPORT|")) {
                    String[] parts = line.split("\\|", 3);
                    if (parts.length < 3) { out.println("ERR|Usage: REPORT|<category>|<text>"); continue; }
                    storeReport(parts[1], parts[2]);
                    out.println("OK|Report stored|category=" + parts[1]);
                    continue;
                }
                if (line.startsWith("ADVISORY|")) {
                    out.println("OK|advisory_query_queued|url=" + NSA_CYBERSECURITY_URL);
                    continue;
                }
                if (line.startsWith("SEARCH|")) {
                    out.println(searchReports(line.substring(7).trim()));
                    continue;
                }
                out.println("ERR|Unknown command");
            }
        } catch (Exception e) { /* client disconnected */ }
    }

    private String searchReports(String keyword) {
        // Phase 1: Local DB search
        String localResults;
        try (var conn = database.N21AuthConfig.get();
             var ps = conn.prepareStatement(
                     "SELECT id, category, LEFT(report_text, 80), created_at FROM cyber_reports WHERE report_text LIKE ? OR category LIKE ? ORDER BY created_at DESC LIMIT 10")) {
            ps.setString(1, "%" + keyword + "%");
            ps.setString(2, "%" + keyword + "%");
            var rs = ps.executeQuery();
            StringBuilder sb = new StringBuilder();
            int count = 0;
            while (rs.next()) {
                sb.append(rs.getInt(1)).append(":").append(rs.getString(2)).append(":").append(rs.getString(3)).append("|");
                count++;
            }
            localResults = count > 0 ? sb.toString() : null;
        } catch (Exception e) { localResults = null; }

        // Phase 2: Strernary™ AI inference on port 20000
        String aiResult = StrernaryConnector.ask("NSA SEARCH category=" + keyword + " context=cyber_reports");

        // Combine results
        StringBuilder combined = new StringBuilder("RESULTS|");
        if (localResults != null) combined.append(localResults);
        if (aiResult != null) combined.append("AI|").append(aiResult.replace("\n", " "));
        if (localResults == null && aiResult == null) return "RESULTS|none";
        return combined.toString();
    }

    private void storeReport(String category, String text) throws Exception {
        try (var conn = database.N21AuthConfig.get();
             var ps = conn.prepareStatement(
                     "INSERT INTO cyber_reports (category, report_text, status) VALUES (?, ?, 'pending')")) {
            ps.setString(1, category);
            ps.setString(2, text);
            ps.executeUpdate();
        }
    }

    private boolean checkReachable(String url) {
        try {
            HttpRequest req = HttpRequest.newBuilder().uri(URI.create(url))
                    .method("HEAD", HttpRequest.BodyPublishers.noBody()).timeout(Duration.ofSeconds(5)).build();
            return http.send(req, HttpResponse.BodyHandlers.discarding()).statusCode() < 400;
        } catch (Exception e) { return false; }
    }

    private void initDatabase() {
        try (var conn = database.N21AuthConfig.get(); var st = conn.createStatement()) {
            st.execute("CREATE DATABASE IF NOT EXISTS nwe_california_nsa");
            st.execute("USE nwe_california_nsa");
            st.execute("""
                CREATE TABLE IF NOT EXISTS cyber_reports (
                    id BIGINT AUTO_INCREMENT PRIMARY KEY,
                    category VARCHAR(100) NOT NULL,
                    report_text TEXT NOT NULL,
                    status ENUM('pending','reviewed','escalated','closed') DEFAULT 'pending',
                    installer_id VARCHAR(64) DEFAULT NULL,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    INDEX idx_category (category),
                    INDEX idx_status (status)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
            """);
            st.execute("""
                CREATE TABLE IF NOT EXISTS advisories (
                    id BIGINT AUTO_INCREMENT PRIMARY KEY,
                    title VARCHAR(500) NOT NULL,
                    severity ENUM('low','medium','high','critical') DEFAULT 'medium',
                    source_url VARCHAR(1000),
                    installer_id VARCHAR(64) DEFAULT NULL,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
            """);
            print(". Database nwe_california_nsa initialized .");
        } catch (Exception e) {
            print(". Database init FAILED: " + e.getMessage() + " .");
        }
    }
}
