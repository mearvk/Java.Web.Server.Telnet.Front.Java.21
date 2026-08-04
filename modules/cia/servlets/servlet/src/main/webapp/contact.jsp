<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.*, java.io.*, java.net.*, javax.net.ssl.*, java.security.cert.X509Certificate" %>
<%!
    static String esc(String s) { if (s == null) return ""; return s.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;"); }
    static String truncate(String s, int max) { if (s == null) return ""; return s.length() > max ? s.substring(0, max) + "..." : s; }
%>
<%
    String DB_URL = "jdbc:mysql://127.0.0.1:3306/nwe_california_cia";
    String DB_USER = "root";
    String DB_PASS = "";
    try {
        Properties dbProps = new Properties();
        InputStream dbIs = application.getResourceAsStream("/WEB-INF/db.properties");
        if (dbIs != null) { dbProps.load(dbIs); dbIs.close(); }
        if (dbProps.containsKey("db.url")) DB_URL = dbProps.getProperty("db.url");
        if (dbProps.containsKey("db.user")) DB_USER = dbProps.getProperty("db.user");
        if (dbProps.containsKey("db.password")) DB_PASS = dbProps.getProperty("db.password");
    } catch (Exception ignored) {}

    Connection conn = null;
    String msg = null;
    String msgColor = "#22c55e";
    String sslSubject = null, sslIssuer = null, sslAlgo = null, sslKeyB64 = null;
    String sslValidFrom = null, sslValidTo = null;

    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);

        // Auto-create tables
        Statement stmt = conn.createStatement();
        stmt.executeUpdate("CREATE TABLE IF NOT EXISTS site_public_keys (" +
            "id BIGINT AUTO_INCREMENT PRIMARY KEY, host VARCHAR(255), port INT DEFAULT 443, " +
            "certificate_subject TEXT, certificate_issuer TEXT, public_key_algorithm VARCHAR(32), " +
            "public_key_base64 TEXT, valid_from DATETIME, valid_to DATETIME, fetched_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)");
        stmt.executeUpdate("CREATE TABLE IF NOT EXISTS outbound_messages (" +
            "id BIGINT AUTO_INCREMENT PRIMARY KEY, sender_name VARCHAR(255), sender_email VARCHAR(255), " +
            "subject VARCHAR(500), category VARCHAR(100), message_body TEXT, target_site VARCHAR(255), " +
            "sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, response_text TEXT, response_code INT DEFAULT 0)");
        stmt.close();

        // Fetch SSL cert from cia.gov on every page load
        String targetHost = "www.cia.gov";
        try {
            SSLSocketFactory factory = (SSLSocketFactory) SSLSocketFactory.getDefault();
            try (SSLSocket sslSocket = (SSLSocket) factory.createSocket(targetHost, 443)) {
                sslSocket.setSoTimeout(5000);
                sslSocket.startHandshake();
                java.security.cert.Certificate[] certs = sslSocket.getSession().getPeerCertificates();
                if (certs.length > 0) {
                    X509Certificate x509 = (X509Certificate) certs[0];
                    sslSubject = x509.getSubjectX500Principal().getName();
                    sslIssuer = x509.getIssuerX500Principal().getName();
                    sslAlgo = x509.getPublicKey().getAlgorithm();
                    sslKeyB64 = java.util.Base64.getEncoder().encodeToString(x509.getPublicKey().getEncoded());
                    sslValidFrom = x509.getNotBefore().toString();
                    sslValidTo = x509.getNotAfter().toString();

                    // Store in DB
                    PreparedStatement ps = conn.prepareStatement(
                        "INSERT INTO site_public_keys (host, port, certificate_subject, certificate_issuer, " +
                        "public_key_algorithm, public_key_base64, valid_from, valid_to) VALUES (?, 443, ?, ?, ?, ?, ?, ?)");
                    ps.setString(1, targetHost);
                    ps.setString(2, sslSubject);
                    ps.setString(3, sslIssuer);
                    ps.setString(4, sslAlgo);
                    ps.setString(5, sslKeyB64);
                    ps.setString(6, sslValidFrom);
                    ps.setString(7, sslValidTo);
                    ps.executeUpdate();
                    ps.close();
                }
            }
        } catch (Exception sslEx) {
            // SSL fetch may fail in some environments — non-fatal
        }

        // Handle POST — submit message
        if ("POST".equals(request.getMethod())) {
            String senderName = request.getParameter("sender_name");
            String senderEmail = request.getParameter("sender_email");
            String subject = request.getParameter("subject");
            String category = request.getParameter("message_category");
            String messageBody = request.getParameter("message_body");

            if (messageBody != null && !messageBody.trim().isEmpty()) {
                int responseCode = 0;
                String responseText = "";

                // Attempt to submit to CIA report-information page
                try {
                    String postData = "name=" + URLEncoder.encode(senderName != null ? senderName : "", "UTF-8")
                        + "&email=" + URLEncoder.encode(senderEmail != null ? senderEmail : "", "UTF-8")
                        + "&subject=" + URLEncoder.encode(subject != null ? subject : "", "UTF-8")
                        + "&category=" + URLEncoder.encode(category != null ? category : "", "UTF-8")
                        + "&message=" + URLEncoder.encode(messageBody, "UTF-8");

                    URL url = new URL("https://www.cia.gov/report-information/");
                    HttpURLConnection hc = (HttpURLConnection) url.openConnection();
                    hc.setRequestMethod("POST");
                    hc.setConnectTimeout(10000);
                    hc.setReadTimeout(10000);
                    hc.setDoOutput(true);
                    hc.setRequestProperty("Content-Type", "application/x-www-form-urlencoded");
                    hc.setRequestProperty("User-Agent", "NWE-CaliforniaCIA/1.0 MEARVK-LLC");
                    hc.getOutputStream().write(postData.getBytes("UTF-8"));
                    hc.getOutputStream().flush();

                    responseCode = hc.getResponseCode();
                    InputStream respIs = (responseCode >= 400) ? hc.getErrorStream() : hc.getInputStream();
                    if (respIs != null) {
                        BufferedReader br = new BufferedReader(new InputStreamReader(respIs));
                        StringBuilder sb = new StringBuilder();
                        String line;
                        int chars = 0;
                        while ((line = br.readLine()) != null && chars < 2000) {
                            sb.append(line).append("\n");
                            chars += line.length();
                        }
                        responseText = sb.toString();
                        br.close();
                    }
                    hc.disconnect();
                } catch (Exception httpEx) {
                    responseCode = -1;
                    responseText = "Connection error: " + httpEx.getMessage();
                }

                // Store in local database
                PreparedStatement ps = conn.prepareStatement(
                    "INSERT INTO outbound_messages (sender_name, sender_email, subject, category, message_body, target_site, response_text, response_code) " +
                    "VALUES (?, ?, ?, ?, ?, ?, ?, ?)");
                ps.setString(1, senderName);
                ps.setString(2, senderEmail);
                ps.setString(3, subject);
                ps.setString(4, category);
                ps.setString(5, messageBody.trim());
                ps.setString(6, "https://www.cia.gov/report-information/");
                ps.setString(7, responseText);
                ps.setInt(8, responseCode);
                ps.executeUpdate();
                ps.close();

                if (responseCode >= 200 && responseCode < 400) {
                    msg = "Message submitted and sent to cia.gov (HTTP " + responseCode + "). Stored locally.";
                    msgColor = "#22c55e";
                } else if (responseCode == -1) {
                    msg = "Message stored locally. Could not reach cia.gov: " + truncate(responseText, 200);
                    msgColor = "#f59e0b";
                } else {
                    msg = "Message stored locally. CIA responded with HTTP " + responseCode + ".";
                    msgColor = "#f59e0b";
                }
            } else {
                msg = "Please enter a message body.";
                msgColor = "#ef4444";
            }
        }
    } catch (Exception e) {
        msg = "Database error: " + e.getMessage();
        msgColor = "#ef4444";
    }

    // Fetch recent messages
    List<Map<String, String>> recentMessages = new ArrayList<>();
    if (conn != null) {
        try {
            PreparedStatement ps = conn.prepareStatement(
                "SELECT id, sender_name, subject, category, sent_at, response_code FROM outbound_messages ORDER BY sent_at DESC LIMIT 10");
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                Map<String, String> row = new HashMap<>();
                row.put("id", String.valueOf(rs.getLong("id")));
                row.put("sender_name", rs.getString("sender_name"));
                row.put("subject", rs.getString("subject"));
                row.put("category", rs.getString("category"));
                row.put("sent_at", rs.getTimestamp("sent_at") != null ? rs.getTimestamp("sent_at").toString() : "");
                row.put("response_code", String.valueOf(rs.getInt("response_code")));
                recentMessages.add(row);
            }
            rs.close(); ps.close();
        } catch (Exception ignored) {}
    }

    if (conn != null) try { conn.close(); } catch (Exception ignored) {}
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>Contact — CaliforniaCIA™</title>
    <link rel="stylesheet" href="css/style.css"/>
    <link rel="preconnect" href="https://fonts.googleapis.com"/>
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin/>
    <link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:ital,wght@0,300;0,400;0,500;0,600;0,700;1,400;1,600&display=swap" rel="stylesheet"/>
    <script src="js/scroll-preserve.js"></script>
</head>
<body>
<nav class="nav"><div class="nav-inner">
    <span class="nav-brand">CaliforniaCIA™</span>
    <ul class="nav-links">
        <li><a href="index.jsp">Overview</a></li>
        <li><a href="report.jsp">Report</a></li>
        <li><a href="foia.jsp">FOIA</a></li>
        <li><a href="contact.jsp" class="active">Contact</a></li>
        <li><a href="status.jsp">Status</a></li>
    </ul>
    <div class="nav-actions"><a href="report.jsp" class="nav-cta">File Report →</a></div>
</div></nav>

<section class="hero" style="padding:4rem 2rem;">
    <div class="hero-inner">
        <span class="hero-tag">Central Intelligence Agency</span>
        <h1>Contact CIA</h1>
        <p>Submit intelligence reports, FOIA requests, or general inquiries. Messages are stored locally and forwarded to cia.gov. The site's public TLS key is captured and stored for fiduciary record.</p>
    </div>
</section>

<section class="section">
    <div class="section-inner" style="max-width:750px;">

        <% if (msg != null) { %>
        <div style="margin-bottom:1.5rem;padding:1rem;border:1px solid <%=msgColor%>;border-radius:8px;color:<%=msgColor%>;font-size:0.9rem;background:rgba(0,0,0,0.3);">
            <%= esc(msg) %>
        </div>
        <% } %>

        <h2>Send Message to CIA</h2>
        <form method="POST" action="contact.jsp" style="margin-top:1rem;">
            <div class="form-group">
                <label>Your Name</label>
                <input type="text" name="sender_name" required placeholder="Full name"/>
            </div>
            <div class="form-group">
                <label>Your Email</label>
                <input type="email" name="sender_email" required placeholder="email@example.com"/>
            </div>
            <div class="form-group">
                <label>Subject</label>
                <input type="text" name="subject" required placeholder="Subject of your message"/>
            </div>
            <div class="form-group">
                <label>Category</label>
                <select name="message_category" required>
                    <option value="">— Select —</option>
                    <option value="Intelligence Tip">Intelligence Tip</option>
                    <option value="FOIA Request">FOIA Request</option>
                    <option value="Media Inquiry">Media Inquiry</option>
                    <option value="Employment">Employment</option>
                    <option value="General Inquiry">General Inquiry</option>
                    <option value="Whistleblower">Whistleblower</option>
                </select>
            </div>
            <div class="form-group">
                <label>Message</label>
                <textarea name="message_body" rows="6" required placeholder="Your message to the CIA..."></textarea>
            </div>
            <button type="submit" class="btn btn-primary">Send Message</button>
        </form>
    </div>
</section>

<% if (!recentMessages.isEmpty()) { %>
<section class="section">
    <div class="section-inner" style="max-width:900px;">
        <h2>Recent Outbound Messages</h2>
        <div class="table-wrap">
            <table>
                <thead><tr><th>ID</th><th>Sender</th><th>Subject</th><th>Category</th><th>Sent</th><th>Response</th></tr></thead>
                <tbody>
                <% for (Map<String, String> row : recentMessages) {
                    int rc = Integer.parseInt(row.get("response_code"));
                    String rcColor = (rc >= 200 && rc < 400) ? "#22c55e" : (rc == -1 ? "#ef4444" : "#f59e0b");
                %>
                    <tr>
                        <td><%= row.get("id") %></td>
                        <td><%= esc(row.get("sender_name")) %></td>
                        <td><%= esc(truncate(row.get("subject"), 40)) %></td>
                        <td><%= esc(row.get("category")) %></td>
                        <td style="font-size:0.75rem;"><%= row.get("sent_at") %></td>
                        <td style="color:<%=rcColor%>;font-weight:600;">HTTP <%= row.get("response_code") %></td>
                    </tr>
                <% } %>
                </tbody>
            </table>
        </div>
    </div>
</section>
<% } %>

<section class="section">
    <div class="section-inner" style="max-width:900px;">
        <h2>CIA Public TLS Certificate (Latest Fetch)</h2>
        <% if (sslSubject != null) { %>
        <div class="table-wrap">
            <table>
                <tr><th>Host</th><td>www.cia.gov:443</td></tr>
                <tr><th>Subject</th><td style="font-size:0.8rem;"><%= esc(sslSubject) %></td></tr>
                <tr><th>Issuer</th><td style="font-size:0.8rem;"><%= esc(sslIssuer) %></td></tr>
                <tr><th>Algorithm</th><td><%= esc(sslAlgo) %></td></tr>
                <tr><th>Public Key</th><td style="font-family:monospace;font-size:0.7rem;word-break:break-all;"><%= esc(truncate(sslKeyB64, 120)) %></td></tr>
                <tr><th>Valid From</th><td><%= esc(sslValidFrom) %></td></tr>
                <tr><th>Valid To</th><td><%= esc(sslValidTo) %></td></tr>
            </table>
        </div>
        <% } else { %>
        <p style="color:var(--text-muted);font-size:0.85rem;">SSL certificate fetch was not successful. This may be due to network restrictions or firewall policy.</p>
        <% } %>
    </div>
</section>

<footer class="footer"><div><span>© 2026 MEARVK LLC. All rights reserved. CaliforniaCIA™ — Intelligence Reporting.</span></div></footer>
</body>
</html>
