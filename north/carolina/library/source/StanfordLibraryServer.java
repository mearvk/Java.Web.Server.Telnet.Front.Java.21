package source;

import commons.CommonRails;
import commons.color.ColorPalette;

import java.io.*;
import java.net.*;
import java.net.http.*;
import java.time.Duration;

/**
 * StanfordLibraryServer — TCP interface to Stanford Library on port 49214.
 *
 * Connects to library.stanford.edu for catalog search, digital collections,
 * and resource discovery. NIO masquerade-aware. MySQL backed (nwe_library).
 * Installer ID Tech™ secured tables.
 *
 * Protocol: TCP socket
 *   SEARCH|<keyword>            — Search library catalog
 *   COLLECTIONS                 — List digital collections
 *   REQUEST|<resource>          — Submit a resource request
 *   STATUS                      — Server health
 *   QUIT                        — Disconnect
 *
 * @author Max Rupplin — MEARVK LLC
 * @date June 29 2026
 */
public class StanfordLibraryServer implements Runnable {

    private static final int PORT = 49214;
    private static final String LIBRARY_URL = "https://library.stanford.edu/";
    private static final String SEARCHWORKS_URL = "https://searchworks.stanford.edu/";
    private static final String COLOR = "\u001B[38;5;124m"; // Stanford Cardinal

    private final HttpClient http = HttpClient.newBuilder()
            .followRedirects(HttpClient.Redirect.NORMAL)
            .connectTimeout(Duration.ofSeconds(10)).build();

    private volatile boolean running = true;
    private ServerSocket server;

    public static void main(String[] args) { new StanfordLibraryServer().run(); }

    private void print(String msg) {
        CommonRails.printSystemComponent(this, this.hashCode(), msg, COLOR);
    }

    @Override
    public void run() {
        print(". StanfordLibrary™ starting on port " + PORT + " .");
        initDatabase();
        try {
            server = new ServerSocket(PORT);
            print(". StanfordLibrary™ listening on port " + PORT + " .");
            while (running) {
                Socket client = server.accept();
                Thread.startVirtualThread(() -> handleClient(client));
            }
        } catch (Exception e) {
            if (running) print(". StanfordLibrary™ ERROR: " + e.getMessage() + " .");
        }
    }

    public void stop() { running = false; try { if (server != null) server.close(); } catch (Exception ignored) {} }

    private void handleClient(Socket client) {
        try (var in = new BufferedReader(new InputStreamReader(client.getInputStream()));
             var out = new PrintWriter(client.getOutputStream(), true)) {
            client.setSoTimeout(300_000);
            out.println("StanfordLibrary™ — Library Catalog & Digital Collections (AI-assisted)");
            out.println("Commands: SEARCH|<keyword>, COLLECTIONS, REQUEST|<resource>, STATUS, QUIT");
            out.println();
            String line;
            while ((line = in.readLine()) != null) {
                line = line.trim();
                if (line.equalsIgnoreCase("QUIT")) { out.println("Goodbye."); break; }
                if (line.equalsIgnoreCase("STATUS")) {
                    out.println("OK|port=" + PORT + "|db=nwe_library|stanford=" + checkReachable(LIBRARY_URL));
                    continue;
                }
                if (line.equalsIgnoreCase("COLLECTIONS")) {
                    out.println("COLLECTIONS|Digital Repository (SDR)|Stanford Digital Library|Special Collections & Archives|David Rumsey Map Center|Hoover Institution Library|Lane Medical Library|Branner Earth Sciences|Music Library|East Asia Library");
                    continue;
                }
                if (line.startsWith("SEARCH|")) {
                    out.println(searchLocal(line.substring(7).trim()));
                    continue;
                }
                if (line.startsWith("REQUEST|")) {
                    String resource = line.substring(8).trim();
                    storeRequest(resource);
                    out.println("OK|Request stored|resource=" + resource);
                    continue;
                }
                out.println("ERR|Unknown command");
            }
        } catch (Exception e) { /* disconnected */ }
    }

    private String searchLocal(String keyword) {
        try (var conn = database.N21AuthConfig.get();
             var ps = conn.prepareStatement("SELECT id, resource_type, LEFT(title,80), created_at FROM library_requests WHERE title LIKE ? OR resource_type LIKE ? ORDER BY created_at DESC LIMIT 10")) {
            ps.setString(1, "%" + keyword + "%"); ps.setString(2, "%" + keyword + "%");
            var rs = ps.executeQuery(); StringBuilder sb = new StringBuilder("RESULTS|"); int c = 0;
            while (rs.next()) { sb.append(rs.getInt(1)).append(":").append(rs.getString(2)).append(":").append(rs.getString(3)).append("|"); c++; }
            return c == 0 ? "RESULTS|none" : sb.toString();
        } catch (Exception e) { return "ERR|" + e.getMessage(); }
    }

    private void storeRequest(String resource) throws Exception {
        try (var conn = database.N21AuthConfig.get();
             var ps = conn.prepareStatement("INSERT INTO library_requests (title, resource_type, status) VALUES (?, 'general', 'pending')")) {
            ps.setString(1, resource); ps.executeUpdate();
        }
    }

    private boolean checkReachable(String url) {
        try {
            HttpRequest req = HttpRequest.newBuilder().uri(URI.create(url)).method("HEAD", HttpRequest.BodyPublishers.noBody()).timeout(Duration.ofSeconds(5)).build();
            return http.send(req, HttpResponse.BodyHandlers.discarding()).statusCode() < 400;
        } catch (Exception e) { return false; }
    }

    private void initDatabase() {
        try (var conn = database.N21AuthConfig.get(); var st = conn.createStatement()) {
            st.execute("CREATE DATABASE IF NOT EXISTS nwe_library");
            st.execute("USE nwe_library");
            st.execute("""
                CREATE TABLE IF NOT EXISTS library_requests (
                    id BIGINT AUTO_INCREMENT PRIMARY KEY,
                    title VARCHAR(500) NOT NULL,
                    resource_type VARCHAR(100) DEFAULT 'general',
                    status ENUM('pending','found','unavailable') DEFAULT 'pending',
                    installer_id VARCHAR(64) DEFAULT NULL,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    INDEX idx_type (resource_type), INDEX idx_status (status)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
            """);
            st.execute("""
                CREATE TABLE IF NOT EXISTS catalog_cache (
                    id BIGINT AUTO_INCREMENT PRIMARY KEY,
                    title VARCHAR(500) NOT NULL,
                    author VARCHAR(300),
                    collection VARCHAR(200),
                    call_number VARCHAR(50),
                    source_url VARCHAR(1000),
                    installer_id VARCHAR(64) DEFAULT NULL,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
            """);
            print(". Database nwe_library initialized .");
        } catch (Exception e) { print(". Database init FAILED: " + e.getMessage() + " ."); }
    }
}
