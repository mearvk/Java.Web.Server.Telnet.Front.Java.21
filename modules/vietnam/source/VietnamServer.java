package source;
import commons.CommonRails;
import commons.StrernaryConnector;
import commons.color.ColorPalette;
import java.io.*;
import java.net.*;
import java.sql.*;
public class VietnamServer implements Runnable {
    public static final int PORT = 49215;
    private static final String DB_URL = "jdbc:mysql://127.0.0.1:3306/nwe_vietnam";
    private static final String DB_USER = "root";
    public VietnamServer() {
        CommonRails.printSystemComponent(this, this.hashCode(), ". Vietnam server starting on port " + PORT + " .", ColorPalette.COLOR_LIME_GREEN);
        initDatabase();
        Thread.ofVirtual().name("VIETNAM_SERVER").start(this);
    }
    @Override public void run() {
        try (ServerSocket server = new ServerSocket(PORT)) {
            CommonRails.printSystemComponent(this, this.hashCode(), ". Vietnam listening on port " + PORT + " .");
            while (!Thread.currentThread().isInterrupted()) { Socket client = server.accept(); Thread.ofVirtual().start(() -> handleClient(client)); }
        } catch (Exception e) { e.printStackTrace(); }
    }
    private void handleClient(Socket client) {
        try (BufferedReader in = new BufferedReader(new InputStreamReader(client.getInputStream())); PrintWriter out = new PrintWriter(client.getOutputStream(), true)) {
            client.setSoTimeout(300000); out.println("VIETNAM|READY|port=" + PORT);
            String line; while ((line = in.readLine()) != null) { String response = processCommand(line.trim()); out.println(response); if ("QUIT".equalsIgnoreCase(line.trim())) break; }
        } catch (Exception ignored) {} try { client.close(); } catch (Exception ignored) {}
    }
    private String processCommand(String input) {
        if (input.isEmpty()) return "ERROR|Empty command. Type HELP for usage.";
        String upper = input.toUpperCase();
        if (upper.equals("QUIT")) return "BYE|Vietnam session closed.";
        if (upper.equals("STATUS")) return "STATUS|OK|port=" + PORT + "|db=nwe_vietnam|module=Vietnam";
        if (upper.equals("HELP")) return "HELP|Commands: STYLES|<name>, LANGUAGES|<name>, SEARCH|<keyword>, TRAIN|<text>, STATUS, HELP, QUIT";
        if (upper.startsWith("STYLES|")) { return queryDB("fighting_styles", "name", input.substring(7).trim()); }
        if (upper.startsWith("LANGUAGES|")) { return queryDB("languages", "name", input.substring(10).trim()); }
        if (upper.startsWith("SEARCH|")) { String kw = input.substring(7).trim(); String ai = StrernaryConnector.ask("VIETNAM SEARCH keyword=" + kw); return "SEARCH|" + (ai != null ? ai : "No results") + "|keyword=" + kw; }
        if (upper.startsWith("TRAIN|")) { String ai = StrernaryConnector.ask("VIETNAM TRAIN text=" + input.substring(6).trim()); return "TRAIN|ACK|" + (ai != null ? ai : "queued"); }
        return "ERROR|Unknown command. Type HELP.";
    }
    private String queryDB(String table, String col, String val) {
        try (Connection c = DriverManager.getConnection(DB_URL, DB_USER, getPassword())) {
            PreparedStatement ps = c.prepareStatement("SELECT * FROM " + table + " WHERE " + col + " LIKE ? LIMIT 5");
            ps.setString(1, "%" + val + "%"); ResultSet rs = ps.executeQuery();
            StringBuilder sb = new StringBuilder(table.toUpperCase() + "|");
            while (rs.next()) sb.append(rs.getString("name")).append("|");
            return sb.length() > table.length() + 1 ? sb.toString() : table.toUpperCase() + "|NONE";
        } catch (Exception e) { return "ERROR|" + e.getMessage(); }
    }
    private void initDatabase() {
        try (Connection c = DriverManager.getConnection("jdbc:mysql://127.0.0.1:3306/", DB_USER, getPassword())) {
            Statement st = c.createStatement();
            st.executeUpdate("CREATE DATABASE IF NOT EXISTS nwe_vietnam");
            st.execute("USE nwe_vietnam");
            st.executeUpdate("CREATE TABLE IF NOT EXISTS fighting_styles (id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(128), region VARCHAR(128), era VARCHAR(64), description TEXT, techniques TEXT, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)");
            st.executeUpdate("CREATE TABLE IF NOT EXISTS languages (id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(128), family VARCHAR(128), speakers VARCHAR(64), script_type VARCHAR(64), notes TEXT, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)");
            st.executeUpdate("INSERT IGNORE INTO fighting_styles (id,name,region,era,description,techniques) VALUES (1,'Vovinam','Vietnam','1938-present','Founded by Nguyen Loc','Scissors kicks, joint locks, weapon forms'),(2,'Viet Vo Dao','Vietnam','Ancient','Umbrella term for Vietnamese martial arts','Strikes, grappling, weapons'),(3,'Binh Dinh','Central Vietnam','10th century','Regional fighting tradition','Staff, sword, animal forms'),(4,'Cuong Nhu','Vietnam/USA','1965-present','Hard-soft blend by Ngo Dong','Wing Chun, Judo, Tai Chi blend'),(5,'Nhat Nam','Northern Vietnam','Ancient','Northern combat system','Internal energy, pressure strikes')");
            st.executeUpdate("INSERT IGNORE INTO languages (id,name,family,speakers,script_type,notes) VALUES (1,'Vietnamese','Austroasiatic','85 million','Latin (Quoc Ngu)','Official, 6 tones'),(2,'Tay','Tai-Kadai','1.7 million','Latin','Northern highlands'),(3,'Muong','Austroasiatic','1.2 million','Latin','Related to Vietnamese'),(4,'Khmer Krom','Austroasiatic','1 million','Khmer script','Mekong Delta'),(5,'Cham','Austronesian','100000','Cham/Latin','Champa kingdom'),(6,'Hmong','Hmong-Mien','1 million','RPA Latin','Highland dialects')");
        } catch (Exception e) { CommonRails.printSystemComponent(this, this.hashCode(), ". Vietnam DB: " + e.getMessage() + " ."); }
    }
    private String getPassword() { try { return new String(java.nio.file.Files.readAllBytes(java.nio.file.Paths.get(".nwe-credentials"))).lines().filter(l->l.startsWith("NWE_DB_PASS=")).map(l->l.split("='")[1].replace("'","")).findFirst().orElse(""); } catch (Exception e) { return ""; } }
}
