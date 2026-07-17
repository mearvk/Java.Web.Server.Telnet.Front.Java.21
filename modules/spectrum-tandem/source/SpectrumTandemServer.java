package source;

import commons.CommonRails;
import commons.StrernaryConnector;
import commons.color.ColorPalette;

import java.io.*;
import java.net.*;
import java.sql.*;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

/**
 * SpectrumTandem™ — Dolyene Spectrum Server
 * Port: 49222
 * Database: nwe_spectrum_tandem
 *
 * Graphs the dolyene (spectrum of int discipline) of use of term for any special
 * spelling of term or radix or term or spelling of radix or other conditions of
 * spelling int. Stores term, definition, specialness, county (COUNTY), revisions,
 * pointers, and indirections. Word bank with timestamps and author/revisionist IDs.
 *
 * Installer Tech ID: Max Rupplin
 * MEARVK LLC — NitroWebExpress™ 2026
 */
public class SpectrumTandemServer implements Runnable {

    public static final int PORT = 49222;
    private static final String DB_URL = "jdbc:mysql://127.0.0.1:3306/nwe_spectrum_tandem";
    private static final String DB_USER = "root";
    private static final String INSTALLER_TECH_ID = "Max Rupplin";

    public SpectrumTandemServer() {
        CommonRails.printSystemComponent(this, this.hashCode(),
                ". SpectrumTandem server starting on port " + PORT + " .",
                ColorPalette.COLOR_LIME_GREEN);
        initDatabase();
        Thread.ofVirtual().name("SPECTRUM_TANDEM_SERVER").start(this);
    }

    @Override
    public void run() {
        try (ServerSocket server = new ServerSocket(PORT)) {
            CommonRails.printSystemComponent(this, this.hashCode(),
                    ". SpectrumTandem listening on port " + PORT + " .");
            while (!Thread.currentThread().isInterrupted()) {
                Socket client = server.accept();
                Thread.ofVirtual().start(() -> handleClient(client));
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void handleClient(Socket client) {
        try (BufferedReader in = new BufferedReader(new InputStreamReader(client.getInputStream()));
             PrintWriter out = new PrintWriter(client.getOutputStream(), true)) {

            client.setSoTimeout(300000);
            out.println("SPECTRUM_TANDEM|READY|port=" + PORT + "|installer=" + INSTALLER_TECH_ID);

            String line;
            while ((line = in.readLine()) != null) {
                String response = processCommand(line.trim());
                out.println(response);
                if ("QUIT".equalsIgnoreCase(line.trim())) break;
            }
        } catch (Exception ignored) {
        }
        try { client.close(); } catch (Exception ignored) {}
    }

    private String processCommand(String input) {
        if (input.isEmpty()) return "ERROR|Empty command. Type HELP for usage.";
        String upper = input.toUpperCase();

        if (upper.equals("QUIT")) return "BYE|SpectrumTandem session closed.";
        if (upper.equals("STATUS")) return "STATUS|OK|port=" + PORT + "|db=nwe_spectrum_tandem|module=SpectrumTandem|installer=" + INSTALLER_TECH_ID;
        if (upper.equals("HELP")) return "HELP|Commands: DEFINE|<term>, LOOKUP|<term>, RADIX|<radix>, SPECTRUM|<term>, COUNTY|<county>, REVISE|<term>|<definition>|<authorId>, ADD|<term>|<definition>|<specialness>|<authorId>, HISTORY|<term>, WORDBANK, STATUS, HELP, QUIT";

        // DEFINE|<term> — get full definition of a term
        if (upper.startsWith("DEFINE|")) {
            return queryWordBank("term", input.substring(7).trim());
        }

        // LOOKUP|<term> — search by spelling/radix
        if (upper.startsWith("LOOKUP|")) {
            return lookupSpelling(input.substring(7).trim());
        }

        // RADIX|<radix> — search by radix
        if (upper.startsWith("RADIX|")) {
            return queryWordBank("radix", input.substring(6).trim());
        }

        // SPECTRUM|<term> — get the dolyene spectrum for a term
        if (upper.startsWith("SPECTRUM|")) {
            return getDolyeneSpectrum(input.substring(9).trim());
        }

        // COUNTY|<county> — search by county (full capitalized term of precedent)
        if (upper.startsWith("COUNTY|")) {
            return queryCounty(input.substring(7).trim());
        }

        // REVISE|<term>|<newDef>|<authorId> — revise a term's definition
        if (upper.startsWith("REVISE|")) {
            String[] parts = input.substring(7).split("\\|", 3);
            if (parts.length < 3) return "ERROR|Usage: REVISE|<term>|<definition>|<authorId>";
            return reviseTerm(parts[0].trim(), parts[1].trim(), parts[2].trim());
        }

        // ADD|<term>|<definition>|<specialness>|<authorId> — add new term to word bank
        if (upper.startsWith("ADD|")) {
            String[] parts = input.substring(4).split("\\|", 4);
            if (parts.length < 4) return "ERROR|Usage: ADD|<term>|<definition>|<specialness>|<authorId>";
            return addTerm(parts[0].trim(), parts[1].trim(), parts[2].trim(), parts[3].trim());
        }

        // HISTORY|<term> — get revision history
        if (upper.startsWith("HISTORY|")) {
            return getHistory(input.substring(8).trim());
        }

        // WORDBANK — list all terms
        if (upper.equals("WORDBANK")) {
            return listWordBank();
        }

        // AI-assisted search via Strernary
        if (upper.startsWith("SEARCH|")) {
            String kw = input.substring(7).trim();
            String ai = StrernaryConnector.ask("SPECTRUM_TANDEM SEARCH keyword=" + kw);
            return "SEARCH|" + (ai != null ? ai : "No results") + "|keyword=" + kw;
        }

        return "ERROR|Unknown command. Type HELP.";
    }

    // ── Query Methods ──────────────────────────────────────────────────────────

    private String queryWordBank(String column, String value) {
        try (Connection c = DriverManager.getConnection(DB_URL, DB_USER, getPassword())) {
            PreparedStatement ps = c.prepareStatement(
                    "SELECT * FROM word_bank WHERE " + column + " LIKE ? ORDER BY created_at DESC LIMIT 10");
            ps.setString(1, "%" + value + "%");
            ResultSet rs = ps.executeQuery();
            StringBuilder sb = new StringBuilder("WORDBANK|");
            while (rs.next()) {
                sb.append(rs.getString("term")).append("=")
                        .append(rs.getString("definition")).append("~")
                        .append(rs.getString("specialness")).append("|");
            }
            return sb.length() > 9 ? sb.toString() : "WORDBANK|NONE";
        } catch (Exception e) {
            return "ERROR|" + e.getMessage();
        }
    }

    private String lookupSpelling(String spelling) {
        try (Connection c = DriverManager.getConnection(DB_URL, DB_USER, getPassword())) {
            PreparedStatement ps = c.prepareStatement(
                    "SELECT * FROM word_bank WHERE term LIKE ? OR radix LIKE ? OR spelling_variant LIKE ? ORDER BY created_at DESC LIMIT 10");
            ps.setString(1, "%" + spelling + "%");
            ps.setString(2, "%" + spelling + "%");
            ps.setString(3, "%" + spelling + "%");
            ResultSet rs = ps.executeQuery();
            StringBuilder sb = new StringBuilder("LOOKUP|");
            while (rs.next()) {
                sb.append(rs.getString("term")).append("[")
                        .append(rs.getString("radix")).append("]=")
                        .append(rs.getString("definition")).append("|");
            }
            return sb.length() > 7 ? sb.toString() : "LOOKUP|NONE";
        } catch (Exception e) {
            return "ERROR|" + e.getMessage();
        }
    }

    private String getDolyeneSpectrum(String term) {
        try (Connection c = DriverManager.getConnection(DB_URL, DB_USER, getPassword())) {
            // Query spectrum data for the term
            PreparedStatement ps = c.prepareStatement(
                    "SELECT ds.*, wb.term, wb.radix, wb.specialness FROM dolyene_spectrum ds " +
                            "JOIN word_bank wb ON ds.word_bank_id = wb.id WHERE wb.term LIKE ? ORDER BY ds.discipline_index ASC");
            ps.setString(1, "%" + term + "%");
            ResultSet rs = ps.executeQuery();
            StringBuilder sb = new StringBuilder("SPECTRUM|");
            while (rs.next()) {
                sb.append("idx=").append(rs.getInt("discipline_index"))
                        .append(",int=").append(rs.getInt("int_value"))
                        .append(",spelling=").append(rs.getString("spelling_condition"))
                        .append(",weight=").append(rs.getDouble("weight"))
                        .append("|");
            }
            if (sb.length() <= 9) {
                // Fallback to AI inference
                String ai = StrernaryConnector.ask("SPECTRUM_TANDEM DOLYENE term=" + term);
                return "SPECTRUM|AI|" + (ai != null ? ai : "No spectrum data for: " + term);
            }
            return sb.toString();
        } catch (Exception e) {
            return "ERROR|" + e.getMessage();
        }
    }

    private String queryCounty(String county) {
        try (Connection c = DriverManager.getConnection(DB_URL, DB_USER, getPassword())) {
            PreparedStatement ps = c.prepareStatement(
                    "SELECT * FROM county_precedent WHERE county = ? ORDER BY revision_number DESC LIMIT 10");
            ps.setString(1, county.toUpperCase());
            ResultSet rs = ps.executeQuery();
            StringBuilder sb = new StringBuilder("COUNTY|");
            while (rs.next()) {
                sb.append(rs.getString("county")).append("[r")
                        .append(rs.getInt("revision_number")).append("]=")
                        .append(rs.getString("pointer")).append("→")
                        .append(rs.getString("indirection")).append("|");
            }
            return sb.length() > 7 ? sb.toString() : "COUNTY|NONE";
        } catch (Exception e) {
            return "ERROR|" + e.getMessage();
        }
    }

    private String reviseTerm(String term, String newDefinition, String authorId) {
        try (Connection c = DriverManager.getConnection(DB_URL, DB_USER, getPassword())) {
            // Get current term
            PreparedStatement ps = c.prepareStatement("SELECT id, definition FROM word_bank WHERE term = ?");
            ps.setString(1, term);
            ResultSet rs = ps.executeQuery();
            if (!rs.next()) return "ERROR|Term not found: " + term;

            int termId = rs.getInt("id");
            String oldDef = rs.getString("definition");

            // Get next revision number
            PreparedStatement revPs = c.prepareStatement(
                    "SELECT COALESCE(MAX(revision_number), 0) + 1 AS next_rev FROM revisions WHERE word_bank_id = ?");
            revPs.setInt(1, termId);
            ResultSet revRs = revPs.executeQuery();
            revRs.next();
            int nextRev = revRs.getInt("next_rev");

            // Insert revision record
            PreparedStatement ins = c.prepareStatement(
                    "INSERT INTO revisions (word_bank_id, revision_number, old_definition, new_definition, revisionist_id, revised_at) VALUES (?, ?, ?, ?, ?, NOW())");
            ins.setInt(1, termId);
            ins.setInt(2, nextRev);
            ins.setString(3, oldDef);
            ins.setString(4, newDefinition);
            ins.setString(5, authorId);
            ins.executeUpdate();

            // Update term
            PreparedStatement upd = c.prepareStatement("UPDATE word_bank SET definition = ?, updated_at = NOW() WHERE id = ?");
            upd.setString(1, newDefinition);
            upd.setInt(2, termId);
            upd.executeUpdate();

            return "REVISE|OK|term=" + term + "|revision=" + nextRev + "|by=" + authorId;
        } catch (Exception e) {
            return "ERROR|" + e.getMessage();
        }
    }

    private String addTerm(String term, String definition, String specialness, String authorId) {
        try (Connection c = DriverManager.getConnection(DB_URL, DB_USER, getPassword())) {
            PreparedStatement ps = c.prepareStatement(
                    "INSERT INTO word_bank (term, definition, specialness, radix, spelling_variant, author_id, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, NOW(), NOW())");
            ps.setString(1, term);
            ps.setString(2, definition);
            ps.setString(3, specialness);
            ps.setString(4, extractRadix(term));
            ps.setString(5, term);
            ps.setString(6, authorId);
            ps.executeUpdate();
            return "ADD|OK|term=" + term + "|specialness=" + specialness + "|by=" + authorId;
        } catch (Exception e) {
            return "ERROR|" + e.getMessage();
        }
    }

    private String getHistory(String term) {
        try (Connection c = DriverManager.getConnection(DB_URL, DB_USER, getPassword())) {
            PreparedStatement ps = c.prepareStatement(
                    "SELECT r.*, wb.term FROM revisions r JOIN word_bank wb ON r.word_bank_id = wb.id WHERE wb.term LIKE ? ORDER BY r.revision_number DESC LIMIT 20");
            ps.setString(1, "%" + term + "%");
            ResultSet rs = ps.executeQuery();
            StringBuilder sb = new StringBuilder("HISTORY|");
            while (rs.next()) {
                sb.append("r").append(rs.getInt("revision_number"))
                        .append("@").append(rs.getTimestamp("revised_at"))
                        .append(" by ").append(rs.getString("revisionist_id"))
                        .append("|");
            }
            return sb.length() > 8 ? sb.toString() : "HISTORY|NONE";
        } catch (Exception e) {
            return "ERROR|" + e.getMessage();
        }
    }

    private String listWordBank() {
        try (Connection c = DriverManager.getConnection(DB_URL, DB_USER, getPassword())) {
            Statement st = c.createStatement();
            ResultSet rs = st.executeQuery("SELECT term, specialness, radix FROM word_bank ORDER BY term ASC LIMIT 50");
            StringBuilder sb = new StringBuilder("WORDBANK|");
            while (rs.next()) {
                sb.append(rs.getString("term")).append("[")
                        .append(rs.getString("specialness")).append(",")
                        .append(rs.getString("radix")).append("]|");
            }
            return sb.length() > 9 ? sb.toString() : "WORDBANK|EMPTY";
        } catch (Exception e) {
            return "ERROR|" + e.getMessage();
        }
    }

    // ── Utility ────────────────────────────────────────────────────────────────

    private String extractRadix(String term) {
        // Extract root/radix from term (first meaningful morpheme)
        if (term == null || term.isEmpty()) return "";
        String lower = term.toLowerCase().replaceAll("[^a-z]", "");
        if (lower.length() <= 4) return lower;
        return lower.substring(0, Math.min(lower.length(), 6));
    }

    // ── Database Initialization ────────────────────────────────────────────────

    private void initDatabase() {
        try (Connection c = DriverManager.getConnection("jdbc:mysql://127.0.0.1:3306/", DB_USER, getPassword())) {
            Statement st = c.createStatement();
            st.executeUpdate("CREATE DATABASE IF NOT EXISTS nwe_spectrum_tandem");
            st.execute("USE nwe_spectrum_tandem");

            // Word Bank — stores term, definition, specialness, radix, author
            st.executeUpdate("CREATE TABLE IF NOT EXISTS word_bank (" +
                    "id INT AUTO_INCREMENT PRIMARY KEY, " +
                    "term VARCHAR(256) NOT NULL, " +
                    "definition TEXT, " +
                    "specialness VARCHAR(128), " +
                    "radix VARCHAR(64), " +
                    "spelling_variant VARCHAR(256), " +
                    "author_id VARCHAR(128) NOT NULL, " +
                    "created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, " +
                    "updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP, " +
                    "INDEX idx_term (term), " +
                    "INDEX idx_radix (radix), " +
                    "INDEX idx_spelling (spelling_variant), " +
                    "INDEX idx_author (author_id)" +
                    ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");

            // Dolyene Spectrum — graphing int discipline spectrum per term
            st.executeUpdate("CREATE TABLE IF NOT EXISTS dolyene_spectrum (" +
                    "id INT AUTO_INCREMENT PRIMARY KEY, " +
                    "word_bank_id INT NOT NULL, " +
                    "discipline_index INT NOT NULL, " +
                    "int_value INT NOT NULL DEFAULT 0, " +
                    "spelling_condition VARCHAR(256), " +
                    "weight DOUBLE DEFAULT 1.0, " +
                    "radix_condition VARCHAR(64), " +
                    "created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, " +
                    "FOREIGN KEY (word_bank_id) REFERENCES word_bank(id), " +
                    "INDEX idx_word_bank (word_bank_id), " +
                    "INDEX idx_discipline (discipline_index)" +
                    ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");

            // County Precedent — full capitalized term of precedent with pointers/indirections
            st.executeUpdate("CREATE TABLE IF NOT EXISTS county_precedent (" +
                    "id INT AUTO_INCREMENT PRIMARY KEY, " +
                    "county VARCHAR(128) NOT NULL, " +
                    "pointer VARCHAR(512), " +
                    "indirection VARCHAR(512), " +
                    "revision_number INT NOT NULL DEFAULT 1, " +
                    "caliber VARCHAR(64) DEFAULT 'STANDARD', " +
                    "author_id VARCHAR(128) NOT NULL, " +
                    "created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, " +
                    "INDEX idx_county (county), " +
                    "INDEX idx_pointer (pointer(255)), " +
                    "INDEX idx_caliber (caliber)" +
                    ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");

            // Revisions — immutable revision log
            st.executeUpdate("CREATE TABLE IF NOT EXISTS revisions (" +
                    "id INT AUTO_INCREMENT PRIMARY KEY, " +
                    "word_bank_id INT NOT NULL, " +
                    "revision_number INT NOT NULL, " +
                    "old_definition TEXT, " +
                    "new_definition TEXT, " +
                    "revisionist_id VARCHAR(128) NOT NULL, " +
                    "revised_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, " +
                    "FOREIGN KEY (word_bank_id) REFERENCES word_bank(id), " +
                    "INDEX idx_word_bank (word_bank_id), " +
                    "INDEX idx_revisionist (revisionist_id)" +
                    ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");

            // Seed data
            st.executeUpdate("INSERT IGNORE INTO word_bank (id, term, definition, specialness, radix, spelling_variant, author_id) VALUES " +
                    "(1, 'dolyene', 'The spectrum of int discipline; the graphical representation of term usage frequency across radix conditions', 'CORE_CONCEPT', 'doly', 'dolyene', '" + INSTALLER_TECH_ID + "'), " +
                    "(2, 'spectrum', 'A range or continuum of values representing the spread of a term across its int discipline', 'MEASURE', 'spect', 'spectrum', '" + INSTALLER_TECH_ID + "'), " +
                    "(3, 'radix', 'The root or base form of a term from which spelling variants derive', 'LINGUISTIC', 'radix', 'radix', '" + INSTALLER_TECH_ID + "'), " +
                    "(4, 'tandem', 'Two or more elements operating in conjunction; parallel execution of spectrum analysis', 'OPERATIONAL', 'tand', 'tandem', '" + INSTALLER_TECH_ID + "'), " +
                    "(5, 'int discipline', 'The integer classification system governing term ordering and spectral weight', 'MATHEMATICAL', 'intdi', 'int discipline', '" + INSTALLER_TECH_ID + "'), " +
                    "(6, 'pointer', 'A reference to another term or county precedent; indirection target', 'REFERENCE', 'point', 'pointer', '" + INSTALLER_TECH_ID + "'), " +
                    "(7, 'indirection', 'A layer of abstraction between a pointer and its final resolution', 'REFERENCE', 'indir', 'indirection', '" + INSTALLER_TECH_ID + "'), " +
                    "(8, 'county', 'Full capitalized term of precedent; jurisdictional authority over term definitions', 'GOVERNANCE', 'count', 'COUNTY', '" + INSTALLER_TECH_ID + "'), " +
                    "(9, 'caliber', 'The quality or grade of a revision; measure of revision significance', 'QUALITY', 'calib', 'caliber', '" + INSTALLER_TECH_ID + "'), " +
                    "(10, 'specialness', 'The categorical classification of a term within the word bank hierarchy', 'META', 'speci', 'specialness', '" + INSTALLER_TECH_ID + "')");

            // Seed county precedent
            st.executeUpdate("INSERT IGNORE INTO county_precedent (id, county, pointer, indirection, revision_number, caliber, author_id) VALUES " +
                    "(1, 'DURHAM', 'dolyene→spectrum', 'word_bank.id=1', 1, 'STANDARD', '" + INSTALLER_TECH_ID + "'), " +
                    "(2, 'WAKE', 'radix→spelling_variant', 'word_bank.id=3', 1, 'STANDARD', '" + INSTALLER_TECH_ID + "'), " +
                    "(3, 'ORANGE', 'int discipline→discipline_index', 'dolyene_spectrum.discipline_index', 1, 'HIGH', '" + INSTALLER_TECH_ID + "')");

            // Seed dolyene spectrum
            st.executeUpdate("INSERT IGNORE INTO dolyene_spectrum (id, word_bank_id, discipline_index, int_value, spelling_condition, weight, radix_condition) VALUES " +
                    "(1, 1, 1, 100, 'dolyene', 1.0, 'doly'), " +
                    "(2, 1, 2, 85, 'Dolyene', 0.85, 'doly'), " +
                    "(3, 1, 3, 60, 'DOLYENE', 0.6, 'DOLY'), " +
                    "(4, 2, 1, 95, 'spectrum', 1.0, 'spect'), " +
                    "(5, 2, 2, 70, 'Spectrum', 0.7, 'Spect'), " +
                    "(6, 3, 1, 90, 'radix', 1.0, 'radix'), " +
                    "(7, 5, 1, 100, 'int discipline', 1.0, 'intdi'), " +
                    "(8, 5, 2, 50, 'INT DISCIPLINE', 0.5, 'INTDI')");

        } catch (Exception e) {
            CommonRails.printSystemComponent(this, this.hashCode(),
                    ". SpectrumTandem DB: " + e.getMessage() + " .");
        }
    }

    private String getPassword() {
        try {
            return new String(java.nio.file.Files.readAllBytes(java.nio.file.Paths.get(".nwe-credentials")))
                    .lines()
                    .filter(l -> l.startsWith("NWE_DB_PASS="))
                    .map(l -> l.split("='")[1].replace("'", ""))
                    .findFirst().orElse("");
        } catch (Exception e) {
            return "";
        }
    }
}
