package source;

import commons.CommonRails;
import commons.StrernaryConnector;
import commons.color.ColorPalette;

import java.io.*;
import java.net.*;
import java.net.http.*;
import java.time.Duration;

/**
 * UNCChapelHillServer — TCP interface to UNC Chapel Hill on port 49218.
 *
 * Connects to unc.edu for college/department discovery, course catalogs,
 * and admissions information. NIO masquerade-aware. MySQL backed (nwe_unc).
 * Installer ID Tech™ secured tables.
 *
 * Protocol: TCP socket
 *   COLLEGES                    — List UNC schools
 *   DEPARTMENTS|<school>        — List departments within a school
 *   SEARCH|<keyword>            — Search courses/departments
 *   QUERY|<school>|<text>       — Submit a query to a specific school
 *   ADMIN                       — List administration contacts
 *   STATUS                      — Server health
 *   QUIT                        — Disconnect
 *
 * @author Max Rupplin — MEARVK LLC
 * @date July 16 2026
 */
public class UNCChapelHillServer implements Runnable {

    private static final int PORT = 49218;
    private static final String UNC_URL = "https://www.unc.edu/";
    private static final String UNC_ACADEMICS = "https://www.unc.edu/academics/";
    private static final String COLOR = "\u001B[38;5;74m"; // Carolina Blue (#4B9CD3)

    private final HttpClient http = HttpClient.newBuilder()
            .followRedirects(HttpClient.Redirect.NORMAL)
            .connectTimeout(Duration.ofSeconds(10)).build();

    private volatile boolean running = true;
    private ServerSocket server;

    public static void main(String[] args) { new UNCChapelHillServer().run(); }

    private void print(String msg) {
        CommonRails.printSystemComponent(this, this.hashCode(), msg, COLOR);
    }

    @Override
    public void run() {
        print(". UNCChapelHill™ starting on port " + PORT + " .");
        initDatabase();
        try {
            server = new ServerSocket(PORT, 50, java.net.InetAddress.getByName("localhost"));
            print(". UNCChapelHill™ listening on port " + PORT + " .");
            while (running) {
                Socket client = server.accept();
                Thread.startVirtualThread(() -> handleClient(client));
            }
        } catch (Exception e) {
            if (running) print(". UNCChapelHill™ ERROR: " + e.getMessage() + " .");
        }
    }

    public void stop() { running = false; try { if (server != null) server.close(); } catch (Exception ignored) {} }

    private void handleClient(Socket client) {
        try (var in = new BufferedReader(new InputStreamReader(client.getInputStream()));
             var out = new PrintWriter(client.getOutputStream(), true)) {
            client.setSoTimeout(300_000);
            out.println("UNCChapelHill™ — University of North Carolina at Chapel Hill (AI-assisted)");
            out.println("Commands: COLLEGES, DEPARTMENTS|<school>, SEARCH|<keyword>, QUERY|<school>|<text>, ADMIN, STATUS, QUIT");
            out.println();
            String line;
            while ((line = in.readLine()) != null) {
                line = line.trim();
                if (line.equalsIgnoreCase("QUIT")) { out.println("Go Heels! Goodbye."); break; }
                if (line.equalsIgnoreCase("STATUS")) {
                    out.println("OK|port=" + PORT + "|db=nwe_unc|unc=" + checkReachable(UNC_URL));
                    continue;
                }
                if (line.equalsIgnoreCase("COLLEGES")) {
                    out.println("COLLEGES|College of Arts and Sciences|Kenan-Flagler Business School|School of Dentistry|School of Education|Gillings School of Global Public Health|Graduate School|School of Information and Library Science|School of Law|School of Medicine|School of Nursing|Eshelman School of Pharmacy|School of Social Work|Hussman School of Journalism and Media|School of Government");
                    continue;
                }
                if (line.startsWith("DEPARTMENTS|")) {
                    String school = line.substring(12).trim();
                    out.println(getDepartments(school));
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
                    if (parts.length < 3) { out.println("ERR|Usage: QUERY|<school>|<text>"); continue; }
                    storeQuery(parts[1], parts[2]);
                    String aiAnswer = StrernaryConnector.ask("UNC QUERY school=" + parts[1] + " question=" + parts[2]);
                    if (aiAnswer != null) {
                        out.println("OK|Query stored|school=" + parts[1] + "|AI|" + aiAnswer.replace("\n", " "));
                    } else {
                        out.println("OK|Query stored|school=" + parts[1]);
                    }
                    continue;
                }
                out.println("ERR|Unknown command");
            }
        } catch (Exception e) { /* disconnected */ }
    }

    private String getAdministration() {
        return "ADMIN|" +
            "Chancellor=Lee H. Roberts|" +
            "Provost and Chief Academic Officer=Christopher Clemens|" +
            "Executive Vice Chancellor and Provost=Robert A. Blouin|" +
            "Vice Chancellor for Research=Penny Gordon-Larsen|" +
            "Vice Chancellor for Student Affairs=Amy Johnson|" +
            "Vice Chancellor for Finance and Operations=Nate Knuffman|" +
            "Vice Chancellor for University Development=David Routh|" +
            "Vice Chancellor for Information Technology and CIO=Chris Kielt|" +
            "Dean of Arts and Sciences=Terry Rhodes|" +
            "Dean of Kenan-Flagler Business School=Mary-Ann Fitzgerald|" +
            "Dean of School of Medicine=Wesley Burks|" +
            "Athletics Director=Bubba Cunningham|" +
            "Faculty Chair=Mimi Chapman";
    }

    private String getDepartments(String school) {
        return switch (school.toLowerCase()) {
            case "college of arts and sciences", "arts and sciences" ->
                "DEPARTMENTS|African, African American, and Diaspora Studies|American Studies|Anthropology|Art and Art History|Asian and Middle Eastern Studies|Biology|Chemistry|Classics|Communication|Computer Science|Dramatic Art|Economics|English and Comparative Literature|Exercise and Sport Science|Geography|Germanic and Slavic Languages|History|Linguistics|Mathematics|Music|Philosophy|Physics and Astronomy|Political Science|Psychology and Neuroscience|Religious Studies|Romance Studies|Sociology|Statistics and Operations Research|Women's and Gender Studies";
            case "kenan-flagler business school", "business" ->
                "DEPARTMENTS|Accounting|Finance|Marketing|Operations|Organizational Behavior|Strategy and Entrepreneurship";
            case "school of medicine", "medicine" ->
                "DEPARTMENTS|Allied Health Sciences|Anesthesiology|Biochemistry and Biophysics|Biomedical Engineering|Cell Biology and Physiology|Dermatology|Emergency Medicine|Family Medicine|Genetics|Internal Medicine|Microbiology and Immunology|Neurology|Neuroscience|Obstetrics and Gynecology|Ophthalmology|Orthopaedics|Otolaryngology|Pathology and Laboratory Medicine|Pediatrics|Pharmacology|Physical Medicine and Rehabilitation|Psychiatry|Radiation Oncology|Radiology|Surgery";
            case "gillings school of global public health", "public health" ->
                "DEPARTMENTS|Biostatistics|Environmental Sciences and Engineering|Epidemiology|Health Behavior|Health Policy and Management|Maternal and Child Health|Nutrition";
            case "school of education", "education" ->
                "DEPARTMENTS|Educational Leadership|Human Development and Family Studies|Learning Sciences and Psychological Studies|School Psychology";
            case "school of information and library science", "library science", "sils" ->
                "DEPARTMENTS|Information Science|Library Science|Bioinformatics and Information Science";
            case "hussman school of journalism and media", "journalism" ->
                "DEPARTMENTS|Advertising and Public Relations|Journalism|Media and Communication";
            case "school of law", "law" ->
                "DEPARTMENTS|Constitutional Law|Corporate Law|Criminal Law|Environmental Law|Health Law|Intellectual Property|International Law";
            case "school of nursing", "nursing" ->
                "DEPARTMENTS|Adult-Gerontology|Family Nurse Practitioner|Nursing Administration|Psychiatric-Mental Health";
            case "eshelman school of pharmacy", "pharmacy" ->
                "DEPARTMENTS|Chemical Biology and Medicinal Chemistry|Molecular Pharmaceutics|Pharmacoengineering and Molecular Pharmaceutics|Pharmacotherapy and Experimental Therapeutics";
            default -> "DEPARTMENTS|ERR|Unknown school: " + school + "|Try: COLLEGES for full list";
        };
    }

    private String searchLocal(String keyword) {
        String localResults;
        try (var conn = database.N21DataSource.get();
             var ps = conn.prepareStatement("SELECT id, school, LEFT(query_text,80), created_at FROM school_queries WHERE query_text LIKE ? OR school LIKE ? ORDER BY created_at DESC LIMIT 10")) {
            ps.setString(1, "%" + keyword + "%"); ps.setString(2, "%" + keyword + "%");
            var rs = ps.executeQuery(); StringBuilder sb = new StringBuilder(); int c = 0;
            while (rs.next()) { sb.append(rs.getInt(1)).append(":").append(rs.getString(2)).append(":").append(rs.getString(3)).append("|"); c++; }
            localResults = c > 0 ? sb.toString() : null;
        } catch (Exception e) { localResults = null; }

        String aiResult = StrernaryConnector.ask("UNC SEARCH keyword=" + keyword + " context=school_queries courses departments");

        StringBuilder combined = new StringBuilder("RESULTS|");
        if (localResults != null) combined.append(localResults);
        if (aiResult != null) combined.append("AI|").append(aiResult.replace("\n", " "));
        if (localResults == null && aiResult == null) return "RESULTS|none";
        return combined.toString();
    }

    private void storeQuery(String school, String text) throws Exception {
        try (var conn = database.N21DataSource.get();
             var ps = conn.prepareStatement("INSERT INTO school_queries (school, query_text) VALUES (?, ?)")) {
            ps.setString(1, school); ps.setString(2, text); ps.executeUpdate();
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
            st.execute("CREATE DATABASE IF NOT EXISTS nwe_unc");
            st.execute("USE nwe_unc");
            st.execute("""
                CREATE TABLE IF NOT EXISTS school_queries (
                    id BIGINT AUTO_INCREMENT PRIMARY KEY,
                    school VARCHAR(200) NOT NULL,
                    query_text TEXT NOT NULL,
                    status ENUM('pending','answered','archived') DEFAULT 'pending',
                    installer_id VARCHAR(64) DEFAULT NULL,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    INDEX idx_school (school), INDEX idx_status (status)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
            """);
            st.execute("""
                CREATE TABLE IF NOT EXISTS course_catalog (
                    id BIGINT AUTO_INCREMENT PRIMARY KEY,
                    school VARCHAR(200) NOT NULL,
                    department VARCHAR(200),
                    course_code VARCHAR(20),
                    title VARCHAR(500),
                    description TEXT,
                    credits INT DEFAULT 3,
                    installer_id VARCHAR(64) DEFAULT NULL,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    INDEX idx_school (school), INDEX idx_dept (department), INDEX idx_code (course_code)
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
                    school VARCHAR(200) NOT NULL,
                    department_name VARCHAR(200) NOT NULL,
                    head VARCHAR(200),
                    url VARCHAR(500),
                    installer_id VARCHAR(64) DEFAULT NULL,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    INDEX idx_school (school)
                ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
            """);
            print(". Database nwe_unc initialized .");
        } catch (Exception e) { print(". Database init FAILED: " + e.getMessage() + " ."); }
    }
}
