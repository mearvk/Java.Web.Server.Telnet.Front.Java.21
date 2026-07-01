package source;

import commons.CommonRails;
import commons.StrernaryConnector;
import commons.color.ColorPalette;

import java.io.*;
import java.net.*;
import java.net.http.*;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.concurrent.*;

/**
 * CaliforniaFBIServer — TCP AI-assisted crime reporting module on port 49210.
 *
 * Connects to tips.fbi.gov for form submission and tip forwarding.
 * NIO masquerade-aware. MySQL backed (nwe_california_fbi).
 * Installer ID Tech™ secured tables.
 *
 * Protocol: TCP socket
 *   REPORT|<category>|<text>   — Submit a crime report/tip
 *   STATUS                     — Server health check
 *   SEARCH|<keyword>           — AI-assisted search of local report DB
 *   QUIT                       — Disconnect
 *
 * @author Max Rupplin — MEARVK LLC
 * @date June 29 2026
 */
public class CaliforniaFBIServer implements Runnable {

    private static final int PORT = 49210;
    private static final String FBI_TIPS_URL = "https://tips.fbi.gov/";
    private static final String FBI_IC3_URL = "https://www.ic3.gov/";
    private static final String COLOR = ColorPalette.COLOR_STANDARD_RED;

    private final HttpClient http = HttpClient.newBuilder()
            .followRedirects(HttpClient.Redirect.NORMAL)
            .connectTimeout(Duration.ofSeconds(10))
            .build();

    private volatile boolean running = true;
    private ServerSocket server;

    public static void main(String[] args) { new CaliforniaFBIServer().run(); }

    private void print(String msg) {
        CommonRails.printSystemComponent(this, this.hashCode(), msg, COLOR);
    }

    @Override
    public void run() {
        print(". CaliforniaFBI™ starting on port " + PORT + " .");
        initDatabase();
        try {
            server = new ServerSocket(PORT);
            print(". CaliforniaFBI™ listening on port " + PORT + " .");
            while (running) {
                Socket client = server.accept();
                Thread.startVirtualThread(() -> handleClient(client));
            }
        } catch (Exception e) {
            if (running) print(". CaliforniaFBI™ ERROR: " + e.getMessage() + " .");
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
            out.println("CaliforniaFBI™ — Crime Reporting & Tips (AI-assisted)");
            out.println("Commands: REPORT|<category>|<text>, SEARCH|<keyword>, STATUS, QUIT");
            out.println();

            String line;
            while ((line = in.readLine()) != null) {
                line = line.trim();
                if (line.equalsIgnoreCase("QUIT")) { out.println("Goodbye."); break; }
                if (line.equalsIgnoreCase("STATUS")) {
                    out.println("OK|port=" + PORT + "|db=nwe_california_fbi|fbi=" + checkFbiReachable());
                    continue;
                }
                if (line.startsWith("REPORT|")) {
                    String[] parts = line.split("\\|", 3);
                    if (parts.length < 3) { out.println("ERR|Usage: REPORT|<category>|<text>"); continue; }
                    String result = submitReport(parts[1], parts[2]);
                    out.println(result);
                    continue;
                }
                if (line.startsWith("SEARCH|")) {
                    String keyword = line.substring(7).trim();
                    String result = searchReports(keyword);
                    out.println(result);
                    continue;
                }
                out.println("ERR|Unknown command");
            }
        } catch (Exception e) { /* client disconnected */ }
    }

    private String submitReport(String category, String text) {
        try {
            storeReport(category, text);
            return "OK|Report stored locally|category=" + category + "|fbi_forward=queued";
        } catch (Exception e) {
            return "ERR|" + e.getMessage();
        }
    }

    private String searchReports(String keyword) {
        // Phase 1: Local DB search
        String localResults;
        try (var conn = database.N21AuthConfig.get();
             var ps = conn.prepareStatement(
                     "SELECT id, category, LEFT(report_text, 80), created_at FROM crime_reports WHERE report_text LIKE ? OR category LIKE ? ORDER BY created_at DESC LIMIT 10")) {
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
        String aiResult = StrernaryConnector.ask("FBI SEARCH category=" + keyword + " context=crime_reports");

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
                     "INSERT INTO crime_reports (category, report_text, status) VALUES (?, ?, 'pending')")) {
            ps.setString(1, category);
            ps.setString(2, text);
            ps.executeUpdate();
        }
    }

    private boolean checkFbiReachable() {
        try {
            HttpRequest req = HttpRequest.newBuilder().uri(URI.create(FBI_TIPS_URL))
                    .method("HEAD", HttpRequest.BodyPublishers.noBody()).timeout(Duration.ofSeconds(5)).build();
            return http.send(req, HttpResponse.BodyHandlers.discarding()).statusCode() == 200;
        } catch (Exception e) { return false; }
    }

    private void initDatabase() {
        try (var conn = database.N21AuthConfig.get(); var st = conn.createStatement()) {
            st.execute("CREATE DATABASE IF NOT EXISTS nwe_california_fbi");
            st.execute("USE nwe_california_fbi");
            st.execute("""
                CREATE TABLE IF NOT EXISTS crime_reports (
                    id BIGINT AUTO_INCREMENT PRIMARY KEY,
                    category VARCHAR(100) NOT NULL,
                    report_text TEXT NOT NULL,
                    status ENUM('pending','forwarded','closed') DEFAULT 'pending',
                    installer_id VARCHAR(64) DEFAULT NULL,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    INDEX idx_category (category),
                    INDEX idx_status (status),
                    INDEX idx_created (created_at)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
            """);
            st.execute("""
                CREATE TABLE IF NOT EXISTS fbi_forwarded_tips (
                    id BIGINT AUTO_INCREMENT PRIMARY KEY,
                    report_id BIGINT NOT NULL,
                    forwarded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    response_code INT,
                    installer_id VARCHAR(64) NOT NULL,
                    FOREIGN KEY (report_id) REFERENCES crime_reports(id)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
            """);
            print(". Database nwe_california_fbi initialized .");
        } catch (Exception e) {
            print(". Database init FAILED: " + e.getMessage() + " .");
        }
    }
}
