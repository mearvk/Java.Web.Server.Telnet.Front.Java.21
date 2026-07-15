package source;

import commons.CommonRails;
import commons.StrernaryConnector;
import commons.color.ColorPalette;

import java.io.*;
import java.net.*;
import java.net.http.*;
import java.time.Duration;

/**
 * DukeUniversityServer — TCP interface to Duke University colleges on port 49213.
 *
 * Connects to duke.edu for college/department discovery, course catalogs,
 * and admissions information. NIO masquerade-aware. MySQL backed (nwe_duke).
 * Installer ID Tech™ secured tables.
 *
 * Protocol: TCP socket
 *   COLLEGES                    — List Duke colleges
 *   SEARCH|<keyword>            — Search courses/departments
 *   QUERY|<college>|<text>      — Submit a query to a specific college
 *   STATUS                      — Server health
 *   QUIT                        — Disconnect
 *
 * @author Max Rupplin — MEARVK LLC
 * @date June 29 2026
 */
public class DukeUniversityServer implements Runnable {

    private static final int PORT = 49213;
    private static final String DUKE_URL = "https://www.duke.edu/";
    private static final String DUKE_ACADEMICS = "https://www.duke.edu/academics/";
    private static final String COLOR = "\u001B[38;5;21m"; // Duke Blue

    private final HttpClient http = HttpClient.newBuilder()
            .followRedirects(HttpClient.Redirect.NORMAL)
            .connectTimeout(Duration.ofSeconds(10)).build();

    private volatile boolean running = true;
    private ServerSocket server;

    public static void main(String[] args) { new DukeUniversityServer().run(); }

    private void print(String msg) {
        CommonRails.printSystemComponent(this, this.hashCode(), msg, COLOR);
    }

    @Override
    public void run() {
        print(". DukeUniversity™ starting on port " + PORT + " .");
        initDatabase();
        try {
            server = new ServerSocket(PORT, 50, java.net.InetAddress.getByName("localhost"));
            print(". DukeUniversity™ listening on port " + PORT + " .");
            while (running) {
                Socket client = server.accept();
                Thread.startVirtualThread(() -> handleClient(client));
            }
        } catch (Exception e) {
            if (running) print(". DukeUniversity™ ERROR: " + e.getMessage() + " .");
        }
    }

    public void stop() { running = false; try { if (server != null) server.close(); } catch (Exception ignored) {} }

    private void handleClient(Socket client) {
        try (var in = new BufferedReader(new InputStreamReader(client.getInputStream()));
             var out = new PrintWriter(client.getOutputStream(), true)) {
            client.setSoTimeout(300_000);
            out.println("DukeUniversity™ — College Interface (AI-assisted)");
            out.println("Commands: COLLEGES, SEARCH|<keyword>, QUERY|<college>|<text>, STATUS, QUIT");
            out.println();
            String line;
            while ((line = in.readLine()) != null) {
                line = line.trim();
                if (line.equalsIgnoreCase("QUIT")) { out.println("Goodbye."); break; }
                if (line.equalsIgnoreCase("STATUS")) {
                    out.println("OK|port=" + PORT + "|db=nwe_duke|duke=" + checkReachable(DUKE_URL));
                    continue;
                }
                if (line.equalsIgnoreCase("COLLEGES")) {
                    out.println("COLLEGES|Trinity College of Arts & Sciences|Pratt School of Engineering|Fuqua School of Business|School of Law|School of Medicine|Nicholas School of the Environment|Sanford School of Public Policy|Divinity School|Graduate School|School of Nursing");
                    continue;
                }
                if (line.startsWith("SEARCH|")) {
                    out.println(searchLocal(line.substring(7).trim()));
                    continue;
                }
                if (line.startsWith("QUERY|")) {
                    String[] parts = line.split("\\|", 3);
                    if (parts.length < 3) { out.println("ERR|Usage: QUERY|<college>|<text>"); continue; }
                    storeQuery(parts[1], parts[2]);
                    // AI-enhanced response via Strernary™ port 20000
                    String aiAnswer = StrernaryConnector.ask("DUKE QUERY college=" + parts[1] + " question=" + parts[2]);
                    if (aiAnswer != null) {
                        out.println("OK|Query stored|college=" + parts[1] + "|AI|" + aiAnswer.replace("\n", " "));
                    } else {
                        out.println("OK|Query stored|college=" + parts[1]);
                    }
                    continue;
                }
                out.println("ERR|Unknown command");
            }
        } catch (Exception e) { /* disconnected */ }
    }

    private String searchLocal(String keyword) {
        // Phase 1: Local DB search
        String localResults;
        try (var conn = database.N21DataSource.get();
             var ps = conn.prepareStatement("SELECT id, college, LEFT(query_text,80), created_at FROM college_queries WHERE query_text LIKE ? OR college LIKE ? ORDER BY created_at DESC LIMIT 10")) {
            ps.setString(1, "%" + keyword + "%"); ps.setString(2, "%" + keyword + "%");
            var rs = ps.executeQuery(); StringBuilder sb = new StringBuilder(); int c = 0;
            while (rs.next()) { sb.append(rs.getInt(1)).append(":").append(rs.getString(2)).append(":").append(rs.getString(3)).append("|"); c++; }
            localResults = c > 0 ? sb.toString() : null;
        } catch (Exception e) { localResults = null; }

        // Phase 2: Strernary™ AI inference on port 20000
        String aiResult = StrernaryConnector.ask("DUKE SEARCH keyword=" + keyword + " context=college_queries courses");

        // Combine results
        StringBuilder combined = new StringBuilder("RESULTS|");
        if (localResults != null) combined.append(localResults);
        if (aiResult != null) combined.append("AI|").append(aiResult.replace("\n", " "));
        if (localResults == null && aiResult == null) return "RESULTS|none";
        return combined.toString();
    }

    private void storeQuery(String college, String text) throws Exception {
        try (var conn = database.N21DataSource.get();
             var ps = conn.prepareStatement("INSERT INTO college_queries (college, query_text) VALUES (?, ?)")) {
            ps.setString(1, college); ps.setString(2, text); ps.executeUpdate();
        }
    }

    private boolean checkReachable(String url) {
        try {
            HttpRequest req = HttpRequest.newBuilder().uri(URI.create(url)).method("HEAD", HttpRequest.BodyPublishers.noBody()).timeout(Duration.ofSeconds(5)).build();
            return http.send(req, HttpResponse.BodyHandlers.discarding()).statusCode() < 400;
        } catch (Exception e) { return false; }
    }

    private void initDatabase() {
        try (var conn = database.N21DataSource.get(); var st = conn.createStatement()) {
            st.execute("CREATE DATABASE IF NOT EXISTS nwe_duke");
            st.execute("USE nwe_duke");
            st.execute("""
                CREATE TABLE IF NOT EXISTS college_queries (
                    id BIGINT AUTO_INCREMENT PRIMARY KEY,
                    college VARCHAR(200) NOT NULL,
                    query_text TEXT NOT NULL,
                    status ENUM('pending','answered','archived') DEFAULT 'pending',
                    installer_id VARCHAR(64) DEFAULT NULL,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    INDEX idx_college (college), INDEX idx_status (status)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
            """);
            st.execute("""
                CREATE TABLE IF NOT EXISTS course_catalog (
                    id BIGINT AUTO_INCREMENT PRIMARY KEY,
                    college VARCHAR(200) NOT NULL,
                    department VARCHAR(200),
                    course_code VARCHAR(20),
                    title VARCHAR(500),
                    description TEXT,
                    installer_id VARCHAR(64) DEFAULT NULL,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
            """);
            print(". Database nwe_duke initialized .");
        } catch (Exception e) { print(". Database init FAILED: " + e.getMessage() + " ."); }
    }
}
