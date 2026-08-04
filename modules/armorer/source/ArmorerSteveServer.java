package source;

import commons.CommonRails;
import commons.StrernaryConnector;

import java.io.*;
import java.net.*;
import java.sql.*;
import java.util.concurrent.ConcurrentHashMap;

/**
 * ArmorerSteveServer — TCP Q&A interface on port 49235.
 *
 * Armorer Steve™ is a modest AI assistant for plate armor knowledge:
 * - Forging methods, modern metal theory, metallurgy
 * - Cost estimation for shop setup, equipment, materials
 * - Known armorers (historical & modern)
 * - Competition series (HMB, BUHURT, SCA, IMCF)
 * - Armor regulations and standards
 * - Trade records, locations, final capacitor trade
 *
 * Database: nwe_armorer (MySQL)
 * Theme: Dark Blue with White font
 *
 * Protocol: TCP socket
 *   ASK|<question>              — Q&A with Armorer Steve
 *   COST|<item_or_category>     — Cost estimation
 *   ARMORERS                    — List known armorers
 *   REGS                        — List regulations
 *   TRADE|<keyword>             — Search trade records
 *   STATUS                      — Server health
 *   HELP                        — Command list
 *   QUIT                        — Disconnect
 *
 * @author Max Rupplin — MEARVK LLC
 * @date August 3 2026
 */
public class ArmorerSteveServer implements Runnable {

    public static final int PORT = 49235;
    private static final String DB_URL = "jdbc:mysql://127.0.0.1:3306/nwe_armorer";
    private static final String DB_USER = "root";
    private static final String DB_PASS = "";
    private static final String COLOR = "\u001B[38;5;17m"; // Dark Blue

    private volatile boolean running = true;
    private ServerSocket server;
    private final ConcurrentHashMap<String, String> cache = new ConcurrentHashMap<>();

    public ArmorerSteveServer() {
        print(". ArmorerSteve\u2122 starting on port " + PORT + " .");
        initDatabase();
        Thread.ofVirtual().name("ARMORER_STEVE_SERVER").start(this);
        print(". ArmorerSteve\u2122 listening on port " + PORT + " .");
    }

    private void print(String msg) {
        CommonRails.printSystemComponent(this, this.hashCode(), msg, COLOR);
    }

    @Override
    public void run() {
        try {
            server = new ServerSocket(PORT, 50, InetAddress.getByName("localhost"));
            while (running) {
                Socket client = server.accept();
                Thread.ofVirtual().start(() -> handleClient(client));
            }
        } catch (Exception e) {
            if (running) print(". ArmorerSteve\u2122 ERROR: " + e.getMessage() + " .");
        }
    }

    public void stop() { running = false; try { if (server != null) server.close(); } catch (Exception ignored) {} }

    private void handleClient(Socket client) {
        try (var in = new BufferedReader(new InputStreamReader(client.getInputStream()));
             var out = new PrintWriter(client.getOutputStream(), true)) {
            client.setSoTimeout(300_000);
            out.println();
            out.println("╔═══════════════════════════════════════════════════════════════════════════╗");
            out.println("║  ARMORER STEVE™ — Plate Armor Q&A & Cost Estimator                        ║");
            out.println("║  Port 49235 — Dark Blue — NitroWebExpress™                                ║");
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
            out.println("Commands: ASK|<question>, COST|<item>, ARMORERS, REGS, TRADE|<kw>, STATUS, HELP, QUIT");
            out.println();
            String line;
            while ((line = in.readLine()) != null) {
                line = line.trim();
                if (line.equalsIgnoreCase("QUIT")) { out.println("Farewell, armorer. May your steel ring true."); break; }
                if (line.equalsIgnoreCase("STATUS")) { out.println("OK|port=" + PORT + "|db=nwe_armorer|module=ArmorerSteve"); continue; }
                if (line.equalsIgnoreCase("HELP")) { out.println("HELP|ASK|<question>, COST|<item_or_category>, ARMORERS, REGS, TRADE|<keyword>, STATUS, QUIT"); continue; }
                if (line.equalsIgnoreCase("ARMORERS")) { out.println(queryArmorers()); continue; }
                if (line.equalsIgnoreCase("REGS")) { out.println(queryRegulations()); continue; }
                if (line.startsWith("ASK|")) { out.println(askQuestion(line.substring(4).trim())); continue; }
                if (line.startsWith("COST|")) { out.println(queryCosts(line.substring(5).trim())); continue; }
                if (line.startsWith("TRADE|")) { out.println(queryTrade(line.substring(6).trim())); continue; }
                // Default: treat as question
                out.println(askQuestion(line));
            }
        } catch (Exception ignored) {}
        try { client.close(); } catch (Exception ignored) {}
    }

    private String askQuestion(String question) {
        // Check cache
        String cached = cache.get(question.toLowerCase());
        if (cached != null) return cached;

        // Query knowledge base
        try (Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS)) {
            PreparedStatement ps = conn.prepareStatement(
                "SELECT answer, category, confidence FROM knowledge_base " +
                "WHERE question LIKE ? OR answer LIKE ? ORDER BY confidence DESC LIMIT 1");
            ps.setString(1, "%" + question + "%");
            ps.setString(2, "%" + question + "%");
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                String answer = "STEVE|[" + rs.getString("category") + "] " + rs.getString("answer");
                cache.put(question.toLowerCase(), answer);
                storeSession(question, answer);
                return answer;
            }
        } catch (Exception e) { return "ERROR|" + e.getMessage(); }

        // Fallback to Strernary AI
        String ai = StrernaryConnector.ask("ARMORER armor forging metal " + question);
        if (ai != null) {
            String answer = "STEVE_AI|" + ai;
            storeSession(question, answer);
            return answer;
        }

        return "STEVE|I don't have specific information on that. Try: plate armor, forging, tempering, costs, armorers, regulations, trade.";
    }

    private String queryCosts(String item) {
        try (Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS)) {
            PreparedStatement ps = conn.prepareStatement(
                "SELECT item, description, cost_low, cost_high, currency, source FROM cost_estimates " +
                "WHERE item LIKE ? OR description LIKE ? OR category LIKE ? ORDER BY cost_low LIMIT 10");
            ps.setString(1, "%" + item + "%");
            ps.setString(2, "%" + item + "%");
            ps.setString(3, "%" + item + "%");
            ResultSet rs = ps.executeQuery();
            StringBuilder sb = new StringBuilder("COSTS|");
            while (rs.next()) {
                sb.append(rs.getString("item")).append(": $")
                  .append(rs.getBigDecimal("cost_low")).append("-$")
                  .append(rs.getBigDecimal("cost_high")).append(" ")
                  .append(rs.getString("currency")).append(" (")
                  .append(rs.getString("source")).append(")|");
            }
            return sb.length() > 6 ? sb.toString() : "COSTS|No estimates found for: " + item;
        } catch (Exception e) { return "ERROR|" + e.getMessage(); }
    }

    private String queryArmorers() {
        try (Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS)) {
            PreparedStatement ps = conn.prepareStatement(
                "SELECT name, location, specialty, era, series_wins FROM armorers ORDER BY series_wins DESC");
            ResultSet rs = ps.executeQuery();
            StringBuilder sb = new StringBuilder("ARMORERS|");
            while (rs.next()) {
                sb.append(rs.getString("name")).append(" (")
                  .append(rs.getString("location")).append(", ")
                  .append(rs.getString("era")).append(") — ")
                  .append(rs.getString("specialty"))
                  .append(" [wins: ").append(rs.getInt("series_wins")).append("]|");
            }
            return sb.toString();
        } catch (Exception e) { return "ERROR|" + e.getMessage(); }
    }

    private String queryRegulations() {
        try (Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS)) {
            PreparedStatement ps = conn.prepareStatement(
                "SELECT body, regulation_name, scope, series FROM regulations ORDER BY body");
            ResultSet rs = ps.executeQuery();
            StringBuilder sb = new StringBuilder("REGS|");
            while (rs.next()) {
                sb.append("[").append(rs.getString("body")).append("] ")
                  .append(rs.getString("regulation_name")).append(" (")
                  .append(rs.getString("scope")).append(", ")
                  .append(rs.getString("series")).append(")|");
            }
            return sb.toString();
        } catch (Exception e) { return "ERROR|" + e.getMessage(); }
    }

    private String queryTrade(String keyword) {
        try (Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS)) {
            PreparedStatement ps = conn.prepareStatement(
                "SELECT item_type, seller, buyer, price, currency, location, series, capacitor_grade " +
                "FROM trade_records WHERE item_type LIKE ? OR seller LIKE ? OR series LIKE ? ORDER BY trade_date DESC LIMIT 10");
            ps.setString(1, "%" + keyword + "%");
            ps.setString(2, "%" + keyword + "%");
            ps.setString(3, "%" + keyword + "%");
            ResultSet rs = ps.executeQuery();
            StringBuilder sb = new StringBuilder("TRADE|");
            boolean found = false;
            while (rs.next()) {
                found = true;
                sb.append(rs.getString("item_type")).append(": ")
                  .append(rs.getString("seller")).append("→").append(rs.getString("buyer"))
                  .append(" $").append(rs.getBigDecimal("price")).append(" ")
                  .append(rs.getString("currency")).append(" at ")
                  .append(rs.getString("location"))
                  .append(" [").append(rs.getString("series")).append(", cap:")
                  .append(rs.getString("capacitor_grade")).append("]|");
            }
            if (!found) return "TRADE|No trade records found for: " + keyword + ". The market is quiet on that front.";
            return sb.toString();
        } catch (Exception e) { return "ERROR|" + e.getMessage(); }
    }

    private void storeSession(String question, String answer) {
        try (Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS)) {
            PreparedStatement ps = conn.prepareStatement(
                "INSERT INTO sessions (question, answer) VALUES (?, ?)");
            ps.setString(1, question);
            ps.setString(2, answer);
            ps.executeUpdate();
        } catch (Exception ignored) {}
    }

    private void initDatabase() {
        try (Connection conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS)) {
            Statement s = conn.createStatement();
            s.executeUpdate("CREATE TABLE IF NOT EXISTS knowledge_base (id BIGINT AUTO_INCREMENT PRIMARY KEY, question VARCHAR(512), answer TEXT, category VARCHAR(64), confidence INT DEFAULT 85, access_count INT DEFAULT 0, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)");
            s.executeUpdate("CREATE TABLE IF NOT EXISTS cost_estimates (id BIGINT AUTO_INCREMENT PRIMARY KEY, item VARCHAR(128), description VARCHAR(512), cost_low DECIMAL(10,2), cost_high DECIMAL(10,2), currency VARCHAR(8) DEFAULT 'USD', category VARCHAR(64), source VARCHAR(256), updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)");
            s.executeUpdate("CREATE TABLE IF NOT EXISTS armorers (id BIGINT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(128), location VARCHAR(256), specialty VARCHAR(256), era VARCHAR(64), notable_works TEXT, series_wins INT DEFAULT 0, active BOOLEAN DEFAULT TRUE)");
            s.executeUpdate("CREATE TABLE IF NOT EXISTS regulations (id BIGINT AUTO_INCREMENT PRIMARY KEY, body VARCHAR(128), regulation_name VARCHAR(256), scope VARCHAR(128), description TEXT, series VARCHAR(64), effective_date DATE)");
            s.executeUpdate("CREATE TABLE IF NOT EXISTS trade_records (id BIGINT AUTO_INCREMENT PRIMARY KEY, item_type VARCHAR(128), seller VARCHAR(128), buyer VARCHAR(128), price DECIMAL(12,2), currency VARCHAR(8), trade_date DATE, location VARCHAR(128), series VARCHAR(64), capacitor_grade VARCHAR(32))");
            s.executeUpdate("CREATE TABLE IF NOT EXISTS sessions (id BIGINT AUTO_INCREMENT PRIMARY KEY, question TEXT, answer TEXT, session_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP)");
            s.close();
            print(". ArmorerSteve\u2122 database nwe_armorer ready .");
        } catch (Exception e) {
            print(". ArmorerSteve\u2122 DB error: " + e.getMessage() + " .");
        }
    }
}
