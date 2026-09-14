package source;

import commons.CommonRails;
import commons.StrernaryConnector;
import commons.color.ColorPalette;

import java.io.*;
import java.net.*;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

/**
 * TandemEquals™ — Human Intellect Modulator Simplex & Control Curve
 * Port: 49223
 * Database: nwe_tandem_equals
 *
 * Four Layers:
 *   1. Perception  — intake signals, raw sensory data
 *   2. Cognition   — pattern recognition, logic gates, reasoning
 *   3. Modulation  — calibration, gain, bias, envelope shaping
 *   4. Expression  — output, control curve actuation, decision
 *
 * The Control Curve traces a simplex path from perception through to expression.
 * White and Red. Clean.
 *
 * Installer Tech ID: Max Rupplin
 * MEARVK LLC — NitroWebExpress™ 2026
 */
public class TandemEqualsServer implements Runnable {

    public static final int PORT = 49223;
    private static final String DB_URL = "jdbc:mysql://127.0.0.1:3306/nwe_tandem_equals";
    private static final String DB_USER = "root";
    private static final String INSTALLER_TECH_ID = "Max Rupplin";

    public TandemEqualsServer() {
        CommonRails.printSystemComponent(this, this.hashCode(),
                ". TandemEquals server starting on port " + PORT + " .",
                ColorPalette.COLOR_LIME_GREEN);
        initDatabase();
        Thread.ofVirtual().name("TANDEM_EQUALS_SERVER").start(this);
    }

    @Override
    public void run() {
        try (ServerSocket server = new ServerSocket(PORT)) {
            CommonRails.printSystemComponent(this, this.hashCode(),
                    ". TandemEquals listening on port " + PORT + " .");
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
            out.println("TANDEM_EQUALS|READY|port=" + PORT + "|layers=4|matrix=42x42|stereo_answers=12|installer=" + INSTALLER_TECH_ID);
            out.println("Commands: DOMAIN, ANSWER, RESOLVE, RESULT, DOMAINS, STEREO, PERCEPTION, COGNITION, MODULATION, EXPRESSION, CURVE, EVALUATE, STATUS, HELP, QUIT");

            String line;
            while ((line = in.readLine()) != null) {
                String response = processCommand(line.trim(), client.getInetAddress().getHostAddress());
                out.println(response);
                if ("QUIT".equalsIgnoreCase(line.trim())) break;
            }
        } catch (Exception ignored) {}
        try { client.close(); } catch (Exception ignored) {}
    }

    private String processCommand(String input, String clientIP) {
        if (input.isEmpty()) return "ERROR|Empty command.";

        String[] parts = input.split("\\|", 2);
        String cmd = parts[0].toUpperCase().trim();
        String args = parts.length > 1 ? parts[1] : "";

        switch (cmd) {
            case "STATUS":
                return getStatus();
            case "DOMAIN":
                return startDomain(args, clientIP);
            case "ANSWER":
                return processAnswer(args, clientIP);
            case "RESOLVE":
                return forceResolve(clientIP);
            case "RESULT":
                return getResult(clientIP);
            case "DOMAINS":
                return listDomains();
            case "STEREO":
                return getStereoState(clientIP);
            case "PERCEPTION":
                return queryPerception(args);
            case "COGNITION":
                return queryCognition(args);
            case "MODULATION":
                return queryModulation(args);
            case "EXPRESSION":
                return queryExpression(args);
            case "CURVE":
                return queryCurve(args);
            case "EVALUATE":
                return evaluateCurve(args, clientIP);
            case "HELP":
                return "COMMANDS|DOMAIN|ANSWER|RESOLVE|RESULT|DOMAINS|STEREO|PERCEPTION|COGNITION|MODULATION|EXPRESSION|CURVE|EVALUATE|STATUS|QUIT";
            case "QUIT":
                return "GOODBYE|TandemEquals";
            default:
                return "ERROR|Unknown command: " + cmd;
        }
    }

    private String getStatus() {
        try (Connection conn = getConnection()) {
            StringBuilder sb = new StringBuilder("STATUS");
            String[] tables = {"perception", "cognition", "modulation", "expression", "control_curve", "intellect_log"};
            for (String t : tables) {
                Statement st = conn.createStatement();
                ResultSet rs = st.executeQuery("SELECT COUNT(*) FROM " + t);
                rs.next();
                sb.append("|").append(t).append("=").append(rs.getInt(1));
                rs.close(); st.close();
            }
            return sb.toString();
        } catch (Exception e) {
            return "STATUS|ERROR|" + e.getMessage();
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // SAIMPTOM RESOLUTION (kernel-aligned: 42x42, stereo recovery)
    // ═══════════════════════════════════════════════════════════════

    private String startDomain(String domain, String clientIP) {
        if (domain.isEmpty()) return "ERROR|Usage: DOMAIN|<name> (e.g. DOMAIN|career)";
        try (Connection conn = getConnection()) {
            // Verify domain exists
            PreparedStatement ps = conn.prepareStatement("SELECT id FROM choice_domains WHERE domain_name = ?");
            ps.setString(1, domain.toLowerCase().trim());
            ResultSet rs = ps.executeQuery();
            if (!rs.next()) { rs.close(); ps.close(); return "ERROR|Unknown domain: " + domain + ". Send DOMAINS for list."; }
            rs.close(); ps.close();

            // Increment domain usage
            ps = conn.prepareStatement("UPDATE choice_domains SET times_selected = times_selected + 1 WHERE domain_name = ?");
            ps.setString(1, domain.toLowerCase().trim());
            ps.executeUpdate(); ps.close();

            // Create session
            ps = conn.prepareStatement("INSERT INTO saimptom_sessions (domain, user_hash, ip_address, state) VALUES (?, ?, ?, 'loaded')", Statement.RETURN_GENERATED_KEYS);
            ps.setString(1, domain.toLowerCase().trim());
            ps.setString(2, clientIP); // simplified hash
            ps.setString(3, clientIP);
            ps.executeUpdate();
            ResultSet keys = ps.getGeneratedKeys();
            long sessionId = keys.next() ? keys.getLong(1) : 0;
            keys.close(); ps.close();

            return "DOMAIN|" + domain + "|session=" + sessionId + "|matrix=42x42|cells=1764|answers_needed=12|" +
                   "Provide 12 answers: ANSWER|<-1000 to +1000>. Zero = genuine uncertainty.";
        } catch (Exception e) { return "ERROR|" + e.getMessage(); }
    }

    private String processAnswer(String args, String clientIP) {
        if (args.isEmpty()) return "ERROR|Usage: ANSWER|<value> (-1000 to +1000)";
        int value;
        try { value = Integer.parseInt(args.trim()); } catch (NumberFormatException e) { return "ERROR|Value must be integer -1000 to +1000"; }
        if (value < -1000 || value > 1000) return "ERROR|Value out of range (-1000 to +1000)";

        try (Connection conn = getConnection()) {
            // Find active session for this client
            PreparedStatement ps = conn.prepareStatement("SELECT id, answers_given, overconfidence FROM saimptom_sessions WHERE ip_address = ? AND state IN ('loaded','answering') ORDER BY id DESC LIMIT 1");
            ps.setString(1, clientIP);
            ResultSet rs = ps.executeQuery();
            if (!rs.next()) { rs.close(); ps.close(); return "ERROR|No active session. Send DOMAIN|<name> first."; }
            long sessionId = rs.getLong(1);
            int answersGiven = rs.getInt(2);
            rs.close(); ps.close();

            if (answersGiven >= 12) return "STEREO|Session already has 12 answers. Send RESOLVE or RESULT.";

            // Record answer
            int answerIndex = answersGiven + 1;
            ps = conn.prepareStatement("INSERT INTO saimptom_answers (session_id, answer_index, answer_value) VALUES (?, ?, ?)");
            ps.setLong(1, sessionId); ps.setInt(2, answerIndex); ps.setInt(3, value);
            ps.executeUpdate(); ps.close();

            // Compute overconfidence (mean magnitude + inverse variance)
            ps = conn.prepareStatement("SELECT answer_value FROM saimptom_answers WHERE session_id = ? ORDER BY answer_index");
            ps.setLong(1, sessionId);
            rs = ps.executeQuery();
            List<Integer> answers = new ArrayList<>();
            while (rs.next()) answers.add(rs.getInt(1));
            rs.close(); ps.close();

            int mean = answers.stream().mapToInt(Integer::intValue).sum() / answers.size();
            int variance = answers.stream().mapToInt(a -> ((a - mean) * (a - mean)) / 1000).sum() / answers.size();
            int overconfidence = Math.abs(mean);
            if (variance >= 100) overconfidence = Math.max(0, Math.abs(mean) - variance / 4);
            overconfidence = Math.min(1000, Math.max(0, overconfidence));

            boolean stereoRecovered = (answers.size() >= 12 && overconfidence < 750);

            // Update session
            ps = conn.prepareStatement("UPDATE saimptom_sessions SET answers_given = ?, overconfidence = ?, stereo_recovered = ?, state = ? WHERE id = ?");
            ps.setInt(1, answers.size());
            ps.setInt(2, overconfidence);
            ps.setBoolean(3, stereoRecovered);
            ps.setString(4, answers.size() >= 12 ? "resolving" : "answering");
            ps.setLong(5, sessionId);
            ps.executeUpdate(); ps.close();

            String response = "ANSWER|recorded=" + answerIndex + "/12|overconfidence=" + overconfidence + "/1000|stereo=" + (stereoRecovered ? "RECOVERED" : "not yet");
            if (answers.size() >= 12) response += "|READY — send RESOLVE to compute choice + noise.";
            return response;
        } catch (Exception e) { return "ERROR|" + e.getMessage(); }
    }

    private String forceResolve(String clientIP) {
        try (Connection conn = getConnection()) {
            PreparedStatement ps = conn.prepareStatement("SELECT id, domain, overconfidence, stereo_recovered FROM saimptom_sessions WHERE ip_address = ? AND state IN ('loaded','answering','resolving') ORDER BY id DESC LIMIT 1");
            ps.setString(1, clientIP);
            ResultSet rs = ps.executeQuery();
            if (!rs.next()) { rs.close(); ps.close(); return "ERROR|No active session."; }
            long sessionId = rs.getLong(1);
            String domain = rs.getString(2);
            int overconf = rs.getInt(3);
            boolean stereo = rs.getBoolean(4);
            rs.close(); ps.close();

            // Simulated resolution (kernel does matrix math; web stores the result)
            int choiceMag = 1000 - overconf; // inverse of overconfidence
            int noiseMag = overconf;
            String choiceSummary = "Choice resolves at tandem equilibrium (mag " + choiceMag + "/1000)";
            String noiseSummary = "Equal noise: " + noiseMag + "/1000 residual ambiguity";
            String wisdom = stereo ?
                "Stereo recovered: your real choices are visible. The noise was not noise — it was the other channel. Province wisdom: what applies HERE, to YOU, NOW." :
                "Overconfidence persists (" + overconf + "/1000). The mono mind still dominates. The unkind certainty hides province wisdom.";

            ps = conn.prepareStatement("UPDATE saimptom_sessions SET state = 'resolved', choice_magnitude = ?, noise_magnitude = ?, choice_summary = ?, noise_summary = ?, province_wisdom = ?, resolved_at = NOW() WHERE id = ?");
            ps.setInt(1, choiceMag); ps.setInt(2, noiseMag);
            ps.setString(3, choiceSummary); ps.setString(4, noiseSummary);
            ps.setString(5, wisdom); ps.setLong(6, sessionId);
            ps.executeUpdate(); ps.close();

            return "RESOLVED|domain=" + domain + "|CHOICE=" + choiceMag + "/1000|NOISE=" + noiseMag + "/1000|stereo=" + (stereo ? "YES" : "NO") + "|wisdom=" + wisdom;
        } catch (Exception e) { return "ERROR|" + e.getMessage(); }
    }

    private String getResult(String clientIP) {
        try (Connection conn = getConnection()) {
            PreparedStatement ps = conn.prepareStatement("SELECT domain, choice_magnitude, noise_magnitude, choice_summary, noise_summary, province_wisdom, stereo_recovered, overconfidence FROM saimptom_sessions WHERE ip_address = ? AND state = 'resolved' ORDER BY resolved_at DESC LIMIT 1");
            ps.setString(1, clientIP);
            ResultSet rs = ps.executeQuery();
            if (!rs.next()) { rs.close(); ps.close(); return "RESULT|No resolved session. Send DOMAIN then 12 ANSWER then RESOLVE."; }
            String result = String.format("RESULT|domain=%s|CHOICE=%d/1000|NOISE=%d/1000|stereo=%s|overconf=%d|choice=%s|noise=%s|wisdom=%s",
                rs.getString(1), rs.getInt(2), rs.getInt(3), rs.getBoolean(7) ? "RECOVERED" : "mono",
                rs.getInt(8), rs.getString(4), rs.getString(5), rs.getString(6));
            rs.close(); ps.close();
            return result;
        } catch (Exception e) { return "ERROR|" + e.getMessage(); }
    }

    private String listDomains() {
        try (Connection conn = getConnection()) {
            Statement st = conn.createStatement();
            ResultSet rs = st.executeQuery("SELECT domain_name, times_selected FROM choice_domains ORDER BY domain_name");
            StringBuilder sb = new StringBuilder("DOMAINS");
            while (rs.next()) sb.append("|").append(rs.getString(1)).append("(").append(rs.getInt(2)).append(")");
            rs.close(); st.close();
            return sb.toString();
        } catch (Exception e) { return "ERROR|" + e.getMessage(); }
    }

    private String getStereoState(String clientIP) {
        try (Connection conn = getConnection()) {
            PreparedStatement ps = conn.prepareStatement("SELECT domain, state, answers_given, overconfidence, stereo_recovered FROM saimptom_sessions WHERE ip_address = ? ORDER BY id DESC LIMIT 1");
            ps.setString(1, clientIP);
            ResultSet rs = ps.executeQuery();
            if (!rs.next()) { rs.close(); ps.close(); return "STEREO|No session. Send DOMAIN|<name> to begin."; }
            String result = String.format("STEREO|domain=%s|state=%s|answers=%d/12|overconfidence=%d/1000|stereo=%s",
                rs.getString(1), rs.getString(2), rs.getInt(3), rs.getInt(4), rs.getBoolean(5) ? "RECOVERED" : "not yet");
            rs.close(); ps.close();
            return result;
        } catch (Exception e) { return "ERROR|" + e.getMessage(); }
    }

    // ═══════════════════════════════════════════════════════════════
    // MODULATOR SIMPLEX QUERIES (4-layer control curve support)
    // ═══════════════════════════════════════════════════════════════

    private String queryPerception(String args) {
        try (Connection conn = getConnection()) {
            PreparedStatement ps;
            if (args.isEmpty()) {
                ps = conn.prepareStatement("SELECT id, signal_name, signal_type, amplitude, clarity FROM perception WHERE is_active = TRUE ORDER BY id");
            } else {
                ps = conn.prepareStatement("SELECT id, signal_name, signal_type, amplitude, clarity FROM perception WHERE signal_name LIKE ? AND is_active = TRUE");
                ps.setString(1, "%" + args + "%");
            }
            ResultSet rs = ps.executeQuery();
            StringBuilder sb = new StringBuilder("PERCEPTION");
            while (rs.next()) {
                sb.append("|").append(rs.getLong(1)).append(",")
                  .append(rs.getString(2)).append(",")
                  .append(rs.getString(3)).append(",")
                  .append(String.format("%.2f", rs.getDouble(4))).append(",")
                  .append(String.format("%.2f", rs.getDouble(5)));
            }
            rs.close(); ps.close();
            return sb.toString();
        } catch (Exception e) { return "ERROR|" + e.getMessage(); }
    }

    private String queryCognition(String args) {
        try (Connection conn = getConnection()) {
            PreparedStatement ps;
            if (args.isEmpty()) {
                ps = conn.prepareStatement("SELECT id, pattern_name, pattern_type, gate_type, confidence FROM cognition WHERE is_active = TRUE ORDER BY id");
            } else {
                ps = conn.prepareStatement("SELECT id, pattern_name, pattern_type, gate_type, confidence FROM cognition WHERE pattern_name LIKE ? AND is_active = TRUE");
                ps.setString(1, "%" + args + "%");
            }
            ResultSet rs = ps.executeQuery();
            StringBuilder sb = new StringBuilder("COGNITION");
            while (rs.next()) {
                sb.append("|").append(rs.getLong(1)).append(",")
                  .append(rs.getString(2)).append(",")
                  .append(rs.getString(3)).append(",")
                  .append(rs.getString(4)).append(",")
                  .append(String.format("%.2f", rs.getDouble(5)));
            }
            rs.close(); ps.close();
            return sb.toString();
        } catch (Exception e) { return "ERROR|" + e.getMessage(); }
    }

    private String queryModulation(String args) {
        try (Connection conn = getConnection()) {
            PreparedStatement ps;
            if (args.isEmpty()) {
                ps = conn.prepareStatement("SELECT id, modulator_name, modulator_type, gain, curve_type, simplex_order FROM modulation WHERE is_active = TRUE ORDER BY simplex_order, id");
            } else {
                ps = conn.prepareStatement("SELECT id, modulator_name, modulator_type, gain, curve_type, simplex_order FROM modulation WHERE modulator_name LIKE ? AND is_active = TRUE");
                ps.setString(1, "%" + args + "%");
            }
            ResultSet rs = ps.executeQuery();
            StringBuilder sb = new StringBuilder("MODULATION");
            while (rs.next()) {
                sb.append("|").append(rs.getLong(1)).append(",")
                  .append(rs.getString(2)).append(",")
                  .append(rs.getString(3)).append(",")
                  .append(String.format("%.2f", rs.getDouble(4))).append(",")
                  .append(rs.getString(5)).append(",")
                  .append(rs.getInt(6));
            }
            rs.close(); ps.close();
            return sb.toString();
        } catch (Exception e) { return "ERROR|" + e.getMessage(); }
    }

    private String queryExpression(String args) {
        try (Connection conn = getConnection()) {
            PreparedStatement ps;
            if (args.isEmpty()) {
                ps = conn.prepareStatement("SELECT id, expression_name, expression_type, control_value, direction, intensity FROM expression ORDER BY id");
            } else {
                ps = conn.prepareStatement("SELECT id, expression_name, expression_type, control_value, direction, intensity FROM expression WHERE expression_name LIKE ?");
                ps.setString(1, "%" + args + "%");
            }
            ResultSet rs = ps.executeQuery();
            StringBuilder sb = new StringBuilder("EXPRESSION");
            while (rs.next()) {
                sb.append("|").append(rs.getLong(1)).append(",")
                  .append(rs.getString(2)).append(",")
                  .append(rs.getString(3)).append(",")
                  .append(String.format("%.2f", rs.getDouble(4))).append(",")
                  .append(rs.getString(5)).append(",")
                  .append(String.format("%.2f", rs.getDouble(6)));
            }
            rs.close(); ps.close();
            return sb.toString();
        } catch (Exception e) { return "ERROR|" + e.getMessage(); }
    }

    private String queryCurve(String args) {
        try (Connection conn = getConnection()) {
            PreparedStatement ps;
            if (args.isEmpty()) {
                ps = conn.prepareStatement("SELECT id, curve_name, simplex_value, stability, is_complete FROM control_curve ORDER BY id");
            } else {
                ps = conn.prepareStatement("SELECT id, curve_name, simplex_value, stability, is_complete FROM control_curve WHERE curve_name LIKE ?");
                ps.setString(1, "%" + args + "%");
            }
            ResultSet rs = ps.executeQuery();
            StringBuilder sb = new StringBuilder("CURVE");
            while (rs.next()) {
                sb.append("|").append(rs.getLong(1)).append(",")
                  .append(rs.getString(2)).append(",")
                  .append(String.format("%.2f", rs.getDouble(3))).append(",")
                  .append(String.format("%.2f", rs.getDouble(4))).append(",")
                  .append(rs.getBoolean(5) ? "COMPLETE" : "PARTIAL");
            }
            rs.close(); ps.close();
            return sb.toString();
        } catch (Exception e) { return "ERROR|" + e.getMessage(); }
    }

    private String evaluateCurve(String args, String clientIP) {
        if (args.isEmpty()) return "ERROR|Usage: EVALUATE|curve_id";
        try (Connection conn = getConnection()) {
            long curveId = Long.parseLong(args.trim());
            PreparedStatement ps = conn.prepareStatement(
                "SELECT c.curve_name, c.simplex_value, c.stability, " +
                "p.signal_name, p.amplitude, p.clarity, " +
                "cog.pattern_name, cog.confidence, cog.gate_type, " +
                "m.modulator_name, m.gain, m.curve_type, " +
                "e.expression_name, e.control_value, e.direction " +
                "FROM control_curve c " +
                "LEFT JOIN perception p ON c.perception_id = p.id " +
                "LEFT JOIN cognition cog ON c.cognition_id = cog.id " +
                "LEFT JOIN modulation m ON c.modulation_id = m.id " +
                "LEFT JOIN expression e ON c.expression_id = e.id " +
                "WHERE c.id = ?");
            ps.setLong(1, curveId);
            ResultSet rs = ps.executeQuery();
            if (!rs.next()) { rs.close(); ps.close(); return "ERROR|Curve not found: " + curveId; }

            String curveName = rs.getString(1);
            double simplex = rs.getDouble(2);
            double stability = rs.getDouble(3);

            String result = String.format("EVALUATE|%s|simplex=%.3f|stability=%.3f|" +
                "L1=%s(amp=%.2f,clr=%.2f)|" +
                "L2=%s(conf=%.2f,gate=%s)|" +
                "L3=%s(gain=%.2f,curve=%s)|" +
                "L4=%s(ctrl=%.2f,dir=%s)",
                curveName, simplex, stability,
                rs.getString(4), rs.getDouble(5), rs.getDouble(6),
                rs.getString(7), rs.getDouble(8), rs.getString(9),
                rs.getString(10), rs.getDouble(11), rs.getString(12),
                rs.getString(13), rs.getDouble(14), rs.getString(15));
            rs.close(); ps.close();

            // Log evaluation
            PreparedStatement log = conn.prepareStatement(
                "INSERT INTO intellect_log (curve_id, layer_evaluated, input_vector, output_vector, simplex_delta, evaluator) VALUES (?, 4, ?, ?, 0.0, ?)");
            log.setLong(1, curveId);
            log.setString(2, "client=" + clientIP);
            log.setString(3, result);
            log.setString(4, clientIP);
            log.executeUpdate(); log.close();

            return result;
        } catch (NumberFormatException e) {
            return "ERROR|Invalid curve_id (must be integer)";
        } catch (Exception e) { return "ERROR|" + e.getMessage(); }
    }

    private Connection getConnection() throws Exception {
        return DriverManager.getConnection(DB_URL, DB_USER, "$$Ironman1");
    }

    private void initDatabase() {
        try (Connection conn = getConnection()) {
            Statement st = conn.createStatement();
            st.execute("CREATE DATABASE IF NOT EXISTS nwe_tandem_equals");
            st.close();
        } catch (Exception e) {
            CommonRails.printSystemComponent(this, this.hashCode(),
                    ". TandemEquals DB init: " + e.getMessage());
        }
    }
}
