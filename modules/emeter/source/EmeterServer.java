package source;

import commons.CommonRails;
import commons.StrernaryConnector;
import commons.color.ColorPalette;

import java.io.*;
import java.net.*;
import java.sql.*;

/**
 * EmeterServer — TCP module for E-Meter instruction and calibration.
 * Port 49216. MySQL backed (nwe_emeter). NIO masquerade-aware.
 *
 * Protocol:
 *   INSTRUCT|<topic>        — Query instruction content
 *   CALIBRATE|<level>       — Calibration instructions
 *   READINGS|<session_id>   — Get session readings
 *   SUBMIT|<reading_data>   — Submit a reading
 *   TRAIN|<text>            — Submit to Strernary for training
 *   STATUS                  — Health check
 *   HELP                    — List commands
 *   QUIT                    — Disconnect
 *
 * @author Max Rupplin — MEARVK LLC
 * @date July 2026
 */
public class EmeterServer implements Runnable {

    public static final int PORT = 49216;
    private static final String DB_URL = "jdbc:mysql://127.0.0.1:3306/nwe_emeter";
    private static final String DB_USER = "root";

    public EmeterServer() {
        CommonRails.printSystemComponent(this, this.hashCode(),
            ". Emeter\u2122 server starting on port " + PORT + " .",
            ColorPalette.COLOR_LIME_GREEN);
        initDatabase();
        Thread.ofVirtual().name("EMETER_SERVER").start(this);
    }

    @Override
    public void run() {
        try (ServerSocket server = new ServerSocket(PORT)) {
            CommonRails.printSystemComponent(this, this.hashCode(),
                ". Emeter\u2122 listening on port " + PORT + " .");
            while (!Thread.currentThread().isInterrupted()) {
                Socket client = server.accept();
                Thread.ofVirtual().start(() -> handleClient(client));
            }
        } catch (Exception e) { e.printStackTrace(); }
    }

    private void handleClient(Socket client) {
        try (BufferedReader in = new BufferedReader(new InputStreamReader(client.getInputStream()));
             PrintWriter out = new PrintWriter(client.getOutputStream(), true)) {
            client.setSoTimeout(300000);
            out.println("EMETER|READY|port=" + PORT);
            String line;
            while ((line = in.readLine()) != null) {
                String response = processCommand(line.trim());
                out.println(response);
                if ("QUIT".equalsIgnoreCase(line.trim())) break;
            }
        } catch (Exception ignored) {}
        try { client.close(); } catch (Exception ignored) {}
    }

    private String processCommand(String input) {
        if (input.isEmpty()) return "ERROR|Empty command. Type HELP for usage.";
        String upper = input.toUpperCase();

        if (upper.equals("QUIT")) return "BYE|Emeter\u2122 session closed.";
        if (upper.equals("STATUS")) return "STATUS|OK|port=" + PORT + "|db=nwe_emeter|module=Emeter";
        if (upper.equals("HELP")) return "HELP|Commands: INSTRUCT|<topic>, CALIBRATE|<level>, READINGS|<session_id>, SUBMIT|<data>, TRAIN|<text>, STATUS, HELP, QUIT";

        if (upper.startsWith("INSTRUCT|")) {
            String topic = input.substring(9).trim();
            return queryInstructions(topic);
        }
        if (upper.startsWith("CALIBRATE|")) {
            String level = input.substring(10).trim();
            return queryCalibration(level);
        }
        if (upper.startsWith("READINGS|")) {
            String sessionId = input.substring(9).trim();
            return queryReadings(sessionId);
        }
        if (upper.startsWith("SUBMIT|")) {
            String data = input.substring(7).trim();
            return submitReading(data);
        }
        if (upper.startsWith("TRAIN|")) {
            String text = input.substring(6).trim();
            String ai = StrernaryConnector.ask("EMETER TRAIN text=" + text);
            return "TRAIN|ACK|" + (ai != null ? ai : "queued");
        }
        return "ERROR|Unknown command: " + input + ". Type HELP.";
    }

    private String queryInstructions(String topic) {
        try (Connection conn = DriverManager.getConnection(DB_URL, DB_USER, getPassword())) {
            PreparedStatement ps = conn.prepareStatement(
                "SELECT topic, level, content FROM instructions WHERE topic LIKE ? LIMIT 5");
            ps.setString(1, "%" + topic + "%");
            ResultSet rs = ps.executeQuery();
            StringBuilder sb = new StringBuilder("INSTRUCT|");
            while (rs.next()) {
                sb.append(rs.getString("topic")).append(":").append(rs.getString("level"))
                  .append(":").append(rs.getString("content").substring(0, Math.min(100, rs.getString("content").length()))).append("|");
            }
            return sb.length() > 9 ? sb.toString() : "INSTRUCT|NONE|No results for: " + topic;
        } catch (Exception e) { return "ERROR|DB: " + e.getMessage(); }
    }

    private String queryCalibration(String level) {
        try (Connection conn = DriverManager.getConnection(DB_URL, DB_USER, getPassword())) {
            PreparedStatement ps = conn.prepareStatement(
                "SELECT level_name, description, procedure_steps FROM calibration WHERE level_name LIKE ? LIMIT 3");
            ps.setString(1, "%" + level + "%");
            ResultSet rs = ps.executeQuery();
            StringBuilder sb = new StringBuilder("CALIBRATE|");
            while (rs.next()) {
                sb.append(rs.getString("level_name")).append(":").append(rs.getString("description")).append("|");
            }
            return sb.length() > 10 ? sb.toString() : "CALIBRATE|NONE|No results for: " + level;
        } catch (Exception e) { return "ERROR|DB: " + e.getMessage(); }
    }

    private String queryReadings(String sessionId) {
        try (Connection conn = DriverManager.getConnection(DB_URL, DB_USER, getPassword())) {
            PreparedStatement ps = conn.prepareStatement(
                "SELECT timestamp, ta_value, tone_level, notes FROM readings WHERE session_id = ? ORDER BY timestamp DESC LIMIT 10");
            ps.setString(1, sessionId);
            ResultSet rs = ps.executeQuery();
            StringBuilder sb = new StringBuilder("READINGS|");
            while (rs.next()) {
                sb.append(rs.getTimestamp("timestamp")).append(":").append(rs.getFloat("ta_value"))
                  .append(":").append(rs.getString("tone_level")).append("|");
            }
            return sb.length() > 9 ? sb.toString() : "READINGS|NONE|session=" + sessionId;
        } catch (Exception e) { return "ERROR|DB: " + e.getMessage(); }
    }

    private String submitReading(String data) {
        try (Connection conn = DriverManager.getConnection(DB_URL, DB_USER, getPassword())) {
            String[] parts = data.split(",", 4);
            if (parts.length < 3) return "ERROR|Format: SUBMIT|session_id,ta_value,tone_level[,notes]";
            PreparedStatement ps = conn.prepareStatement(
                "INSERT INTO readings (session_id, ta_value, tone_level, notes) VALUES (?, ?, ?, ?)");
            ps.setString(1, parts[0].trim());
            ps.setFloat(2, Float.parseFloat(parts[1].trim()));
            ps.setString(3, parts[2].trim());
            ps.setString(4, parts.length > 3 ? parts[3].trim() : "");
            ps.executeUpdate();
            return "SUBMIT|OK|session=" + parts[0].trim();
        } catch (Exception e) { return "ERROR|DB: " + e.getMessage(); }
    }

    private void initDatabase() {
        try (Connection conn = DriverManager.getConnection("jdbc:mysql://127.0.0.1:3306/", DB_USER, getPassword())) {
            Statement st = conn.createStatement();
            st.executeUpdate("CREATE DATABASE IF NOT EXISTS nwe_emeter");
            st.execute("USE nwe_emeter");
            st.executeUpdate("CREATE TABLE IF NOT EXISTS instructions (id INT AUTO_INCREMENT PRIMARY KEY, topic VARCHAR(128) NOT NULL, level VARCHAR(64), content TEXT, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)");
            st.executeUpdate("CREATE TABLE IF NOT EXISTS readings (id INT AUTO_INCREMENT PRIMARY KEY, session_id VARCHAR(64) NOT NULL, timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP, ta_value FLOAT, tone_level VARCHAR(64), notes TEXT)");
            st.executeUpdate("CREATE TABLE IF NOT EXISTS calibration (id INT AUTO_INCREMENT PRIMARY KEY, level_name VARCHAR(64) NOT NULL, description TEXT, procedure_steps TEXT)");
            st.executeUpdate("INSERT IGNORE INTO instructions (id,topic,level,content) VALUES (1,'Introduction','Beginner','The E-Meter is a precision instrument that measures changes in electrical resistance. It is used as a pastoral counseling aid.'),(2,'Theory of Operation','Intermediate','The meter passes a small electrical current through the body via two electrodes held in the hands. Changes in resistance correspond to mental and emotional states.'),(3,'Calibration Procedure','All','Before each session: set tone arm to 2.0, adjust sensitivity to produce a 1/3 dial drop on a known squeeze, verify needle is at Set.'),(4,'Reading Interpretation','Advanced','A falling needle indicates discharge. A rising needle indicates charge building. A floating needle indicates release of attention from a subject.'),(5,'Session Protocols','Professional','Begin with can squeeze test. Verify TA range 2.0-3.5. Note all reads: fall, rise, theta bop, rock slam, floating needle.'),(6,'Advanced Techniques','Expert','Rock slam reads indicate evil intention areas. Theta bop indicates exterior state. Stage four needle indicates clear.')");
            st.executeUpdate("INSERT IGNORE INTO calibration (id,level_name,description,procedure_steps) VALUES (1,'Set','Needle at rest position on dial face','1. Turn on meter 2. Have subject hold cans 3. Adjust trim knob until needle rests at Set mark'),(2,'Sensitivity','Response amplitude calibration','1. Set sensitivity to 16 initially 2. Have subject squeeze cans firmly 3. Adjust until squeeze produces 1/3 to 1/2 dial drop'),(3,'Range','Tone Arm operational range','1. TA should read between 2.0 and 3.5 2. Below 2.0 indicates overrun 3. Above 3.5 indicates heavy charge'),(4,'Tone Arm','Counter-force positioning','1. TA knob controls counter-weight 2. Adjust to keep needle at Set 3. Read TA position from dial (2.0 nominal)')");
        } catch (Exception e) {
            CommonRails.printSystemComponent(this, this.hashCode(),
                ". Emeter DB init: " + e.getMessage() + " .");
        }
    }

    private String getPassword() {
        try { return new String(java.nio.file.Files.readAllBytes(java.nio.file.Paths.get(".nwe-credentials"))).lines().filter(l -> l.startsWith("NWE_DB_PASS=")).map(l -> l.split("='")[1].replace("'","")).findFirst().orElse(""); } catch (Exception e) { return ""; }
    }
}
