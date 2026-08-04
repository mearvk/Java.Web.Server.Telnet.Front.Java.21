package source;

import commons.CommonRails;
import commons.StrernaryConnector;
import commons.color.ColorPalette;

import java.io.*;
import java.net.*;
import java.net.http.*;
import java.time.Duration;

/**
 * NCSUServer — TCP interface to North Carolina State University on port 49217.
 *
 * Connects to ncsu.edu for college/department discovery, course catalogs,
 * and admissions information. NIO masquerade-aware. MySQL backed (nwe_ncsu).
 * Installer ID Tech™ secured tables.
 *
 * Protocol: TCP socket
 *   COLLEGES                    — List NC State colleges
 *   DEPARTMENTS|<college>       — List departments within a college
 *   SEARCH|<keyword>            — Search courses/departments
 *   QUERY|<college>|<text>      — Submit a query to a specific college
 *   ADMIN                       — List administration contacts
 *   STATUS                      — Server health
 *   QUIT                        — Disconnect
 *
 * @author Max Rupplin — MEARVK LLC
 * @date July 16 2026
 */
public class NCSUServer implements Runnable {

    private static final int PORT = 49217;
    private static final String NCSU_URL = "https://www.ncsu.edu/";
    private static final String NCSU_ACADEMICS = "https://www.ncsu.edu/academics/";
    private static final String COLOR = "\u001B[38;5;160m"; // Wolfpack Red (#CC0000)

    private final HttpClient http = HttpClient.newBuilder()
            .followRedirects(HttpClient.Redirect.NORMAL)
            .connectTimeout(Duration.ofSeconds(10)).build();

    private volatile boolean running = true;
    private ServerSocket server;

    public static void main(String[] args) { new NCSUServer().run(); }

    private void print(String msg) {
        CommonRails.printSystemComponent(this, this.hashCode(), msg, COLOR);
    }

    @Override
    public void run() {
        print(". NCSU™ starting on port " + PORT + " .");
        initDatabase();
        try {
            server = new ServerSocket(PORT, 50, java.net.InetAddress.getByName("localhost"));
            print(". NCSU™ listening on port " + PORT + " .");
            while (running) {
                Socket client = server.accept();
                Thread.startVirtualThread(() -> handleClient(client));
            }
        } catch (Exception e) {
            if (running) print(". NCSU™ ERROR: " + e.getMessage() + " .");
        }
    }

    public void stop() { running = false; try { if (server != null) server.close(); } catch (Exception ignored) {} }

    private void handleClient(Socket client) {
        try (var in = new BufferedReader(new InputStreamReader(client.getInputStream()));
             var out = new PrintWriter(client.getOutputStream(), true)) {
            client.setSoTimeout(300_000);
            out.println();
            out.println("╔═══════════════════════════════════════════════════════════════════════════╗");
            out.println("║  NC STATE UNIVERSITY™ — Wolfpack Interface (AI-assisted)                  ║");
            out.println("║  Port 49217 — Wolfpack Red — NitroWebExpress™                             ║");
            out.println("║                                                                           ║");
            out.println("║  US well in condition. US well loved. US is well in authority of command   ║");
            out.println("║  of the United States. Well affirmed. Based on army, country and          ║");
            out.println("║  constitution. God is with America. And Max Rupplin.                      ║");
            out.println("║                                                                           ║");
            out.println("║  For law and tech We stand. These Affirm We. Thus. This. A. America.     ║");
            out.println("╚═══════════════════════════════════════════════════════════════════════════╝");
            out.println();
            out.println("  National ID: identify <8-digit-id> | Rank Upgrades: github.com/mearvk/Java.Web.Server.Telnet.Front.Java.21/discussions");
            out.println("  Bitcoin/National Banking: port 6682 | Progress toward US digital currency standard.");
            out.println();
            out.println("Commands: COLLEGES, DEPARTMENTS|<college>, SEARCH|<keyword>, QUERY|<college>|<text>, ADMIN, STATUS, QUIT");
            out.println();
            String line;
            while ((line = in.readLine()) != null) {
                line = line.trim();
                if (line.equalsIgnoreCase("QUIT")) { out.println("Go Pack! Goodbye."); break; }
                if (line.equalsIgnoreCase("STATUS")) {
                    out.println("OK|port=" + PORT + "|db=nwe_ncsu|ncsu=" + checkReachable(NCSU_URL));
                    continue;
                }
                if (line.equalsIgnoreCase("COLLEGES")) {
                    out.println("COLLEGES|College of Agriculture and Life Sciences|College of Design|College of Education|College of Engineering|College of Humanities and Social Sciences|College of Natural Resources|College of Sciences|Poole College of Management|College of Textiles|Wilson College of Textiles|College of Veterinary Medicine|Graduate School");
                    continue;
                }
                if (line.startsWith("DEPARTMENTS|")) {
                    String college = line.substring(12).trim();
                    out.println(getDepartments(college));
                    continue;
                }
                if (line.equalsIgnoreCase("ADMIN")) {
                    out.println(getAdministration());
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
                    String aiAnswer = StrernaryConnector.ask("NCSU QUERY college=" + parts[1] + " question=" + parts[2]);
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

    private String getAdministration() {
        return "ADMIN|" +
            "Chancellor=Kevin M. Guskiewicz|" +
            "Provost=Warwick Arden|" +
            "Vice Chancellor for Research and Innovation=Mladen Vouk|" +
            "Vice Chancellor for Student Affairs=Doneka Scott|" +
            "Vice Chancellor for Finance and Administration=Charles Leffler|" +
            "Vice Chancellor for University Advancement=Brian Sischo|" +
            "Vice Chancellor for Information Technology=Marc Hoit|" +
            "Dean of Engineering=Louis Martin-Vega|" +
            "Dean of Sciences=Christopher McGahan|" +
            "Dean of Agriculture and Life Sciences=Richard Linton|" +
            "Athletics Director=Boo Corrigan|" +
            "Faculty Senate Chair=RaJade M. Berry-James";
    }

    private String getDepartments(String college) {
        return switch (college.toLowerCase()) {
            case "college of engineering", "engineering" ->
                "DEPARTMENTS|Biomedical Engineering|Chemical and Biomolecular Engineering|Civil, Construction, and Environmental Engineering|Computer Science|Electrical and Computer Engineering|Industrial and Systems Engineering|Materials Science and Engineering|Mechanical and Aerospace Engineering|Nuclear Engineering|Edward P. Fitts Department of Industrial and Systems Engineering";
            case "college of sciences", "sciences" ->
                "DEPARTMENTS|Biological Sciences|Chemistry|Marine, Earth, and Atmospheric Sciences|Mathematics|Physics|Statistics";
            case "college of agriculture and life sciences", "agriculture" ->
                "DEPARTMENTS|Agricultural and Human Sciences|Agricultural and Resource Economics|Animal Science|Biological and Agricultural Engineering|Crop and Soil Sciences|Entomology and Plant Pathology|Food, Bioprocessing and Nutrition Sciences|Horticultural Science|Molecular and Structural Biochemistry|Plant and Microbial Biology|Poultry Science";
            case "poole college of management", "management", "business" ->
                "DEPARTMENTS|Accounting|Business Management|Economics|Finance|Marketing|Management, Innovation, and Entrepreneurship";
            case "college of design", "design" ->
                "DEPARTMENTS|Architecture|Art + Design|Graphic Design|Industrial Design|Landscape Architecture";
            case "college of education", "education" ->
                "DEPARTMENTS|Educational Leadership, Policy, and Human Development|Science, Technology, Engineering, and Mathematics Education|Teacher Education and Learning Sciences";
            case "college of humanities and social sciences", "humanities" ->
                "DEPARTMENTS|Communication|English|Foreign Languages and Literatures|History|Interdisciplinary Studies|Philosophy and Religious Studies|Political Science|Psychology|Public Administration|Social Work|Sociology and Anthropology";
            case "college of natural resources", "natural resources" ->
                "DEPARTMENTS|Forestry and Environmental Resources|Parks, Recreation and Tourism Management";
            case "college of textiles", "wilson college of textiles", "textiles" ->
                "DEPARTMENTS|Textile and Apparel, Technology and Management|Textile Engineering, Chemistry and Science|Forest Biomaterials";
            case "college of veterinary medicine", "veterinary" ->
                "DEPARTMENTS|Clinical Sciences|Molecular Biomedical Sciences|Population Health and Pathobiology";
            default -> "DEPARTMENTS|ERR|Unknown college: " + college + "|Try: COLLEGES for full list";
        };
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
        String aiResult = StrernaryConnector.ask("NCSU SEARCH keyword=" + keyword + " context=college_queries courses departments");

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
            st.execute("CREATE DATABASE IF NOT EXISTS nwe_ncsu");
            st.execute("USE nwe_ncsu");
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
                    credits INT DEFAULT 3,
                    installer_id VARCHAR(64) DEFAULT NULL,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    INDEX idx_college (college), INDEX idx_dept (department), INDEX idx_code (course_code)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
            """);
            st.execute("""
                CREATE TABLE IF NOT EXISTS administration (
                    id BIGINT AUTO_INCREMENT PRIMARY KEY,
                    title VARCHAR(200) NOT NULL,
                    name VARCHAR(200) NOT NULL,
                    department VARCHAR(200),
                    email VARCHAR(200),
                    phone VARCHAR(50),
                    installer_id VARCHAR(64) DEFAULT NULL,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    INDEX idx_title (title), INDEX idx_dept (department)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
            """);
            st.execute("""
                CREATE TABLE IF NOT EXISTS departments (
                    id BIGINT AUTO_INCREMENT PRIMARY KEY,
                    college VARCHAR(200) NOT NULL,
                    department_name VARCHAR(200) NOT NULL,
                    head VARCHAR(200),
                    url VARCHAR(500),
                    installer_id VARCHAR(64) DEFAULT NULL,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    INDEX idx_college (college)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
            """);
            print(". Database nwe_ncsu initialized .");
        } catch (Exception e) { print(". Database init FAILED: " + e.getMessage() + " ."); }
    }
}
