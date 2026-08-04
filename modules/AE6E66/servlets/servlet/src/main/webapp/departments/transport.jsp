<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.*, java.io.*, java.net.*, javax.net.ssl.*, java.security.cert.X509Certificate" %>
<%!
    static String esc(String s) { if (s == null) return ""; return s.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;"); }
    static String truncate(String s, int max) { if (s == null) return ""; return s.length() > max ? s.substring(0, max) + "..." : s; }
%>
<%
    String DB_URL = "jdbc:mysql://127.0.0.1:3306/nwe_ae6e66";
    String DB_USER = "root";
    String DB_PASS = "";
    try { Properties dp = new Properties(); InputStream dis = application.getResourceAsStream("/WEB-INF/db.properties");
        if (dis != null) { dp.load(dis); dis.close(); if (dp.containsKey("db.url")) DB_URL = dp.getProperty("db.url");
        if (dp.containsKey("db.user")) DB_USER = dp.getProperty("db.user"); if (dp.containsKey("db.password")) DB_PASS = dp.getProperty("db.password"); }
    } catch (Exception ignored) {}

    Connection conn = null; String msg = null; String msgColor = "#22c55e";
    String sslSubject = null, sslIssuer = null, sslAlgo = null, sslKeyB64 = null, sslValidFrom = null, sslValidTo = null;
    String targetHost = "www.gov.uk";
    String targetUrl = "https://www.gov.uk/government/organisations/department-for-transport";
    String deptName = "Department for Transport";

    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        conn = DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);
        Statement setup = conn.createStatement();
        setup.executeUpdate("CREATE TABLE IF NOT EXISTS site_public_keys (id BIGINT AUTO_INCREMENT PRIMARY KEY, host VARCHAR(255), port INT DEFAULT 443, certificate_subject TEXT, certificate_issuer TEXT, public_key_algorithm VARCHAR(32), public_key_base64 TEXT, valid_from DATETIME, valid_to DATETIME, fetched_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)");
        setup.executeUpdate("CREATE TABLE IF NOT EXISTS outbound_messages (id BIGINT AUTO_INCREMENT PRIMARY KEY, sender_name VARCHAR(255), sender_email VARCHAR(255), subject VARCHAR(500), category VARCHAR(100), department VARCHAR(100), message_body TEXT, target_site VARCHAR(500), sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, response_text LONGTEXT, response_code INT DEFAULT 0)");
        setup.close();

        // Fetch TLS certificate on every page load
        try {
            SSLSocketFactory factory = (SSLSocketFactory) SSLSocketFactory.getDefault();
            try (SSLSocket sslSocket = (SSLSocket) factory.createSocket(targetHost, 443)) {
                sslSocket.setSoTimeout(5000); sslSocket.startHandshake();
                java.security.cert.Certificate[] certs = sslSocket.getSession().getPeerCertificates();
                if (certs.length > 0) {
                    X509Certificate x509 = (X509Certificate) certs[0];
                    sslSubject = x509.getSubjectX500Principal().getName();
                    sslIssuer = x509.getIssuerX500Principal().getName();
                    sslAlgo = x509.getPublicKey().getAlgorithm();
                    sslKeyB64 = java.util.Base64.getEncoder().encodeToString(x509.getPublicKey().getEncoded());
                    sslValidFrom = x509.getNotBefore().toString(); sslValidTo = x509.getNotAfter().toString();
                    PreparedStatement ps = conn.prepareStatement("INSERT INTO site_public_keys (host,port,certificate_subject,certificate_issuer,public_key_algorithm,public_key_base64,valid_from,valid_to) VALUES (?,443,?,?,?,?,?,?)");
                    ps.setString(1,targetHost); ps.setString(2,sslSubject); ps.setString(3,sslIssuer); ps.setString(4,sslAlgo); ps.setString(5,sslKeyB64); ps.setString(6,sslValidFrom); ps.setString(7,sslValidTo);
                    ps.executeUpdate(); ps.close();
                }
            }
        } catch (Exception sslEx) { /* non-fatal */ }

        // Handle POST
        if ("POST".equals(request.getMethod())) {
            String senderName = request.getParameter("sender_name");
            String senderEmail = request.getParameter("sender_email");
            String subj = request.getParameter("subject");
            String category = request.getParameter("message_category");
            String messageBody = request.getParameter("message_body");
            if (messageBody != null && !messageBody.trim().isEmpty()) {
                int responseCode = 0; String responseText = "";
                try {
                    String postData = "name=" + URLEncoder.encode(senderName != null ? senderName : "", "UTF-8")
                        + "&email=" + URLEncoder.encode(senderEmail != null ? senderEmail : "", "UTF-8")
                        + "&subject=" + URLEncoder.encode(subj != null ? subj : "", "UTF-8")
                        + "&category=" + URLEncoder.encode(category != null ? category : "", "UTF-8")
                        + "&message=" + URLEncoder.encode(messageBody, "UTF-8");
                    URL url = new URL(targetUrl);
                    HttpURLConnection hc = (HttpURLConnection) url.openConnection();
                    hc.setRequestMethod("POST"); hc.setConnectTimeout(10000); hc.setReadTimeout(15000);
                    hc.setDoOutput(true); hc.setRequestProperty("Content-Type","application/x-www-form-urlencoded");
                    hc.setRequestProperty("User-Agent","NWE-AE6E66/1.0 MEARVK-LLC");
                    hc.getOutputStream().write(postData.getBytes("UTF-8")); hc.getOutputStream().flush();
                    responseCode = hc.getResponseCode();
                    InputStream ris = (responseCode >= 400) ? hc.getErrorStream() : hc.getInputStream();
                    if (ris != null) { BufferedReader br = new BufferedReader(new InputStreamReader(ris, "UTF-8"));
                        StringBuilder sb = new StringBuilder(); String ln;
                        while ((ln = br.readLine()) != null) sb.append(ln).append("\n");
                        responseText = sb.toString(); br.close(); }
                    hc.disconnect();
                } catch (Exception httpEx) { responseCode = -1; responseText = "Connection error: " + httpEx.getMessage(); }
                PreparedStatement ps = conn.prepareStatement("INSERT INTO outbound_messages (sender_name,sender_email,subject,category,department,message_body,target_site,response_text,response_code) VALUES (?,?,?,?,?,?,?,?,?)");
                ps.setString(1,senderName); ps.setString(2,senderEmail); ps.setString(3,subj); ps.setString(4,category);
                ps.setString(5,deptName); ps.setString(6,messageBody.trim()); ps.setString(7,targetUrl);
                ps.setString(8,responseText); ps.setInt(9,responseCode); ps.executeUpdate(); ps.close();
                if (responseCode >= 200 && responseCode < 400) { msg = "Message sent to " + deptName + " (HTTP " + responseCode + "). Stored locally with full response."; }
                else if (responseCode == -1) { msg = "Message stored locally. Could not reach " + targetHost + ": " + truncate(responseText, 200); msgColor = "#f59e0b"; }
                else { msg = "Message stored. " + deptName + " responded HTTP " + responseCode + ". Full response saved."; msgColor = "#f59e0b"; }
            } else { msg = "Please enter a message body."; msgColor = "#ef4444"; }
        }
    } catch (Exception e) { msg = "Database error: " + e.getMessage(); msgColor = "#ef4444"; }

    // Fetch recent messages for this department
    List<Map<String,String>> recent = new ArrayList<>();
    if (conn != null) { try { PreparedStatement ps = conn.prepareStatement("SELECT id,sender_name,subject,category,sent_at,response_code FROM outbound_messages WHERE department=? ORDER BY sent_at DESC LIMIT 10");
        ps.setString(1, deptName); ResultSet rs = ps.executeQuery();
        while (rs.next()) { Map<String,String> r = new HashMap<>(); r.put("id",String.valueOf(rs.getLong("id"))); r.put("sender",rs.getString("sender_name")); r.put("subject",rs.getString("subject")); r.put("category",rs.getString("category")); r.put("sent",rs.getTimestamp("sent_at")!=null?rs.getTimestamp("sent_at").toString():""); r.put("code",String.valueOf(rs.getInt("response_code"))); recent.add(r); }
        rs.close(); ps.close(); } catch(Exception ignored){} }
    if (conn != null) try { conn.close(); } catch (Exception ignored) {}
%>
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"/><meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title><%= esc(deptName) %> \u2014 AE6E66\u2122</title>
    <link rel="stylesheet" href="../css/style.css"/>
    <link rel="preconnect" href="https://fonts.googleapis.com"/><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin/>
    <link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:wght@300;400;500;600;700&display=swap" rel="stylesheet"/>
</head>
<body>
<nav class="nav"><div class="nav-inner"><span class="nav-brand">AE6E66\u2122</span>
    <ul class="nav-links"><li><a href="../index.jsp">Overview</a></li><li><a href="../contacts.jsp">Contacts</a></li><li><a href="../departments.jsp" class="active">Departments</a></li><li><a href="../sent.jsp">Sent</a></li><li><a href="../status.jsp">Status</a></li></ul>
</div></nav>

<section class="hero" style="padding:4rem 2rem;"><div class="hero-inner">
    <span class="hero-tag">UK Government</span>
    <h1><%= esc(deptName) %></h1>
    <p>Roads, rail, aviation, maritime, driving licences, and road safety.</p>
</div></section>

<section class="section"><div class="section-inner" style="max-width:750px;">
    <% if (msg != null) { %><div style="margin-bottom:1.5rem;padding:1rem;border:1px solid <%=msgColor%>;border-radius:8px;color:<%=msgColor%>;font-size:0.9rem;background:rgba(0,0,0,0.3);"><%= esc(msg) %></div><% } %>
    <h2>Contact <%= esc(deptName) %></h2>
    <p style="font-size:0.85rem;color:#a1b5a1;margin-bottom:1rem;">Messages are stored locally and forwarded to <a href="<%= esc(targetUrl) %>" target="_blank" style="color:#22c55e;"><%= esc(targetHost) %></a>. Public TLS key captured on each interaction.</p>
    <form method="POST" action="">
        <div class="form-group"><label>Your Name</label><input type="text" name="sender_name" required placeholder="Full name"/></div>
        <div class="form-group"><label>Your Email</label><input type="email" name="sender_email" required placeholder="email@example.com"/></div>
        <div class="form-group"><label>Subject</label><input type="text" name="subject" required placeholder="Subject of inquiry"/></div>
        <div class="form-group"><label>Category</label><select name="message_category" required>
                    <option value="">-- Select --</option>
                    <option value="Roads & Highways">Roads & Highways</option>
                    <option value="Rail Services">Rail Services</option>
                    <option value="Aviation">Aviation</option>
                    <option value="Maritime">Maritime</option>
                    <option value="Driving Licences">Driving Licences</option>
                    <option value="Road Safety">Road Safety</option>
                    <option value="General Inquiry">General Inquiry</option>
        </select></div>
        <div class="form-group"><label>Message</label><textarea name="message_body" rows="6" required placeholder="Your message..."></textarea></div>
        <button type="submit" class="btn btn-primary">Send to <%= esc(deptName) %></button>
    </form>
</div></section>

<% if (!recent.isEmpty()) { %>
<section class="section"><div class="section-inner" style="max-width:900px;">
    <h2>Recent Messages to <%= esc(deptName) %></h2>
    <div class="table-wrap"><table><thead><tr><th>ID</th><th>Sender</th><th>Subject</th><th>Category</th><th>Sent</th><th>Response</th></tr></thead><tbody>
    <% for (Map<String,String> r : recent) { int rc = Integer.parseInt(r.get("code")); String rcC = (rc>=200&&rc<400)?"#22c55e":(rc==-1?"#ef4444":"#f59e0b"); %>
        <tr><td><%= r.get("id") %></td><td><%= esc(r.get("sender")) %></td><td><%= esc(truncate(r.get("subject"),40)) %></td><td><%= esc(r.get("category")) %></td><td style="font-size:0.7rem;"><%= r.get("sent") %></td><td style="color:<%=rcC%>;font-weight:600;">HTTP <%= r.get("code") %></td></tr>
    <% } %>
    </tbody></table></div>
</div></section>
<% } %>

<section class="section"><div class="section-inner" style="max-width:900px;">
    <h2>TLS Certificate \u2014 <%= esc(targetHost) %></h2>
    <% if (sslSubject != null) { %>
    <div class="table-wrap"><table>
        <tr><th>Host</th><td><%= esc(targetHost) %>:443</td></tr>
        <tr><th>Subject</th><td style="font-size:0.8rem;"><%= esc(sslSubject) %></td></tr>
        <tr><th>Issuer</th><td style="font-size:0.8rem;"><%= esc(sslIssuer) %></td></tr>
        <tr><th>Algorithm</th><td><%= esc(sslAlgo) %></td></tr>
        <tr><th>Public Key</th><td style="font-family:monospace;font-size:0.65rem;word-break:break-all;"><%= esc(truncate(sslKeyB64, 120)) %></td></tr>
        <tr><th>Valid From</th><td><%= esc(sslValidFrom) %></td></tr>
        <tr><th>Valid To</th><td><%= esc(sslValidTo) %></td></tr>
    </table></div>
    <% } else { %><p style="color:#5f7a5f;font-size:0.85rem;">TLS certificate fetch not successful. May be due to network restrictions.</p><% } %>
</div></section>

<footer class="footer"><div><span>\u00a9 2026 MEARVK LLC. AE6E66\u2122 \u2014 Emerald Green. UK Government Contact Module.</span></div></footer>
</body></html>
