<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.*, java.io.*, java.net.*, javax.net.ssl.*, java.security.cert.X509Certificate" %>
<%!
    static String esc(String s) { if (s == null) return ""; return s.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;"); }
    static String truncate(String s, int max) { if (s == null) return ""; return s.length() > max ? s.substring(0, max) + "..." : s; }
%>
<%
    String dbUrl = "jdbc:mysql://127.0.0.1:3306/nwe_ncsu";
    String dbUser = "root";
    String dbPass = "";
    String targetHost = "www.ncsu.edu";
    int targetPort = 443;
    String targetSubmitUrl = "https://www.ncsu.edu/contact/";

    Connection conn = null;
    String statusMsg = "";
    String statusType = "";
    String certSubject = "";
    String certIssuer = "";
    String certSerial = "";
    String certNotBefore = "";
    String certNotAfter = "";
    String certSigAlg = "";
    String certFingerprint = "";

    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        conn = DriverManager.getConnection(dbUrl, dbUser, dbPass);
        Statement setup = conn.createStatement();

        setup.executeUpdate("CREATE TABLE IF NOT EXISTS site_public_keys (" +
            "id INT AUTO_INCREMENT PRIMARY KEY, " +
            "host VARCHAR(255) NOT NULL, " +
            "port INT NOT NULL, " +
            "subject_dn TEXT, " +
            "issuer_dn TEXT, " +
            "serial_number VARCHAR(255), " +
            "not_before DATETIME, " +
            "not_after DATETIME, " +
            "signature_algorithm VARCHAR(128), " +
            "fingerprint_sha256 VARCHAR(128), " +
            "public_key_pem TEXT, " +
            "fetched_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP" +
            ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");

        setup.executeUpdate("CREATE TABLE IF NOT EXISTS outbound_messages (" +
            "id INT AUTO_INCREMENT PRIMARY KEY, " +
            "sender_name VARCHAR(255), " +
            "sender_email VARCHAR(255), " +
            "subject VARCHAR(500), " +
            "message_category VARCHAR(128), " +
            "message_body TEXT, " +
            "target_url VARCHAR(1024), " +
            "response_code INT, " +
            "response_body TEXT, " +
            "sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP" +
            ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");

        setup.close();

        // Fetch TLS certificate on every page load
        try {
            SSLContext sslCtx = SSLContext.getInstance("TLS");
            TrustManager[] trustAll = new TrustManager[]{
                new X509TrustManager() {
                    public X509Certificate[] getAcceptedIssuers() { return null; }
                    public void checkClientTrusted(X509Certificate[] c, String a) {}
                    public void checkServerTrusted(X509Certificate[] c, String a) {}
                }
            };
            sslCtx.init(null, trustAll, new java.security.SecureRandom());
            SSLSocketFactory sf = sslCtx.getSocketFactory();
            SSLSocket sock = (SSLSocket) sf.createSocket(targetHost, targetPort);
            sock.setSoTimeout(10000);
            sock.startHandshake();
            Certificate[] certs = sock.getSession().getPeerCertificates();
            sock.close();

            if (certs != null && certs.length > 0 && certs[0] instanceof X509Certificate) {
                X509Certificate x509 = (X509Certificate) certs[0];
                certSubject = x509.getSubjectX500Principal().getName();
                certIssuer = x509.getIssuerX500Principal().getName();
                certSerial = x509.getSerialNumber().toString(16);
                certNotBefore = x509.getNotBefore().toString();
                certNotAfter = x509.getNotAfter().toString();
                certSigAlg = x509.getSigAlgName();

                java.security.MessageDigest md = java.security.MessageDigest.getInstance("SHA-256");
                byte[] digest = md.digest(x509.getEncoded());
                StringBuilder fp = new StringBuilder();
                for (byte b : digest) fp.append(String.format("%02X:", b & 0xff));
                certFingerprint = fp.length() > 0 ? fp.substring(0, fp.length() - 1) : "";

                String pemKey = Base64.getEncoder().encodeToString(x509.getPublicKey().getEncoded());

                PreparedStatement ps = conn.prepareStatement(
                    "INSERT INTO site_public_keys (host, port, subject_dn, issuer_dn, serial_number, not_before, not_after, signature_algorithm, fingerprint_sha256, public_key_pem) " +
                    "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");
                ps.setString(1, targetHost);
                ps.setInt(2, targetPort);
                ps.setString(3, certSubject);
                ps.setString(4, certIssuer);
                ps.setString(5, certSerial);
                ps.setString(6, certNotBefore);
                ps.setString(7, certNotAfter);
                ps.setString(8, certSigAlg);
                ps.setString(9, certFingerprint);
                ps.setString(10, pemKey);
                ps.executeUpdate();
                ps.close();
            }
        } catch (Exception sslEx) {
            certSubject = "Error fetching certificate: " + sslEx.getMessage();
        }

        // Handle POST — submit contact message
        if ("POST".equalsIgnoreCase(request.getMethod())) {
            String senderName = request.getParameter("sender_name");
            String senderEmail = request.getParameter("sender_email");
            String subject = request.getParameter("subject");
            String messageCategory = request.getParameter("message_category");
            String messageBody = request.getParameter("message_body");

            int responseCode = 0;
            String responseBody = "";

            try {
                URL url = new URL(targetSubmitUrl);
                HttpURLConnection hc = (HttpURLConnection) url.openConnection();
                if (hc instanceof HttpsURLConnection) {
                    SSLContext sc = SSLContext.getInstance("TLS");
                    TrustManager[] tm = new TrustManager[]{
                        new X509TrustManager() {
                            public X509Certificate[] getAcceptedIssuers() { return null; }
                            public void checkClientTrusted(X509Certificate[] c, String a) {}
                            public void checkServerTrusted(X509Certificate[] c, String a) {}
                        }
                    };
                    sc.init(null, tm, new java.security.SecureRandom());
                    ((HttpsURLConnection) hc).setSSLSocketFactory(sc.getSocketFactory());
                    ((HttpsURLConnection) hc).setHostnameVerifier((h, s) -> true);
                }
                hc.setRequestMethod("POST");
                hc.setDoOutput(true);
                hc.setConnectTimeout(15000);
                hc.setReadTimeout(15000);
                hc.setRequestProperty("Content-Type", "application/x-www-form-urlencoded");
                hc.setRequestProperty("User-Agent", "NCSUWolfpack/1.0");

                String postData = "name=" + URLEncoder.encode(senderName != null ? senderName : "", "UTF-8") +
                    "&email=" + URLEncoder.encode(senderEmail != null ? senderEmail : "", "UTF-8") +
                    "&subject=" + URLEncoder.encode(subject != null ? subject : "", "UTF-8") +
                    "&category=" + URLEncoder.encode(messageCategory != null ? messageCategory : "", "UTF-8") +
                    "&message=" + URLEncoder.encode(messageBody != null ? messageBody : "", "UTF-8");

                OutputStream os = hc.getOutputStream();
                os.write(postData.getBytes("UTF-8"));
                os.flush();
                os.close();

                responseCode = hc.getResponseCode();
                InputStream is = null;
                try { is = hc.getInputStream(); } catch (Exception e) { is = hc.getErrorStream(); }
                if (is != null) {
                    BufferedReader br = new BufferedReader(new InputStreamReader(is, "UTF-8"));
                    StringBuilder sb = new StringBuilder();
                    String line;
                    while ((line = br.readLine()) != null && sb.length() < 2000) sb.append(line).append("\n");
                    br.close();
                    responseBody = sb.length() > 2000 ? sb.substring(0, 2000) : sb.toString();
                }
                hc.disconnect();
            } catch (Exception httpEx) {
                responseCode = -1;
                responseBody = "Connection error: " + httpEx.getMessage();
            }

            PreparedStatement ps = conn.prepareStatement(
                "INSERT INTO outbound_messages (sender_name, sender_email, subject, message_category, message_body, target_url, response_code, response_body) " +
                "VALUES (?, ?, ?, ?, ?, ?, ?, ?)");
            ps.setString(1, senderName);
            ps.setString(2, senderEmail);
            ps.setString(3, subject);
            ps.setString(4, messageCategory);
            ps.setString(5, messageBody);
            ps.setString(6, targetSubmitUrl);
            ps.setInt(7, responseCode);
            ps.setString(8, responseBody);
            ps.executeUpdate();
            ps.close();

            statusMsg = "Message sent. Server responded with code: " + responseCode;
            statusType = (responseCode >= 200 && responseCode < 400) ? "success" : "warning";
        }

    } catch (Exception e) {
        statusMsg = "Database error: " + e.getMessage();
        statusType = "error";
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Contact NC State — NCSUWolfpack™</title>
    <link rel="stylesheet" href="css/style.css">
    <link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <style>
        :root {
            --accent: #CC0000;
            --accent-hover: #A00000;
            --accent-glow: rgba(204, 0, 0, 0.3);
        }
        body { font-family: 'IBM Plex Sans', sans-serif; background: #0a0a0a; color: #e0e0e0; margin: 0; padding: 0; }
        .navbar { background: #111; border-bottom: 1px solid #222; padding: 12px 24px; display: flex; align-items: center; gap: 32px; }
        .navbar .brand { font-size: 1.3em; font-weight: 700; color: var(--accent); text-decoration: none; }
        .navbar a { color: #aaa; text-decoration: none; font-size: 0.95em; padding: 6px 12px; border-radius: 4px; transition: all 0.2s; }
        .navbar a:hover { color: #fff; background: #1a1a1a; }
        .navbar a.active { color: #fff; background: var(--accent); }
        .hero { background: linear-gradient(135deg, #1a0000 0%, #0a0a0a 100%); border-bottom: 1px solid #222; padding: 48px 24px; text-align: center; }
        .hero .tag { color: var(--accent); font-size: 0.85em; text-transform: uppercase; letter-spacing: 2px; margin-bottom: 8px; }
        .hero h1 { font-size: 2.2em; font-weight: 700; margin: 8px 0; color: #fff; }
        .hero p { color: #888; font-size: 1.05em; max-width: 700px; margin: 12px auto 0; }
        .container { max-width: 1100px; margin: 0 auto; padding: 32px 24px; }
        .status-msg { padding: 12px 16px; border-radius: 6px; margin-bottom: 24px; font-size: 0.9em; }
        .status-msg.success { background: #0a2e0a; border: 1px solid #1a5c1a; color: #4caf50; }
        .status-msg.warning { background: #2e2a0a; border: 1px solid #5c4a1a; color: #ff9800; }
        .status-msg.error { background: #2e0a0a; border: 1px solid #5c1a1a; color: #f44336; }
        .card { background: #111; border: 1px solid #222; border-radius: 8px; padding: 24px; margin-bottom: 24px; }
        .card h2 { font-size: 1.3em; font-weight: 600; margin: 0 0 16px; color: #fff; }
        .card h3 { font-size: 1.1em; font-weight: 500; margin: 0 0 12px; color: #ccc; }
        .form-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; }
        .form-grid .full { grid-column: 1 / -1; }
        label { display: block; font-size: 0.85em; color: #888; margin-bottom: 4px; font-weight: 500; }
        input, select, textarea { width: 100%; padding: 10px 12px; background: #0a0a0a; border: 1px solid #333; border-radius: 4px; color: #e0e0e0; font-family: 'IBM Plex Sans', sans-serif; font-size: 0.95em; box-sizing: border-box; }
        input:focus, select:focus, textarea:focus { outline: none; border-color: var(--accent); box-shadow: 0 0 0 2px var(--accent-glow); }
        textarea { resize: vertical; min-height: 120px; }
        .btn { display: inline-block; padding: 10px 24px; background: var(--accent); color: #fff; border: none; border-radius: 4px; font-size: 0.95em; font-weight: 600; cursor: pointer; transition: all 0.2s; }
        .btn:hover { background: var(--accent-hover); box-shadow: 0 0 12px var(--accent-glow); }
        table { width: 100%; border-collapse: collapse; font-size: 0.85em; }
        th { text-align: left; padding: 8px 10px; background: #0a0a0a; color: #888; border-bottom: 1px solid #222; font-weight: 500; }
        td { padding: 8px 10px; border-bottom: 1px solid #1a1a1a; color: #ccc; }
        tr:hover td { background: #1a1a1a; }
        .cert-grid { display: grid; grid-template-columns: 160px 1fr; gap: 8px; font-size: 0.9em; }
        .cert-grid .label { color: #888; font-weight: 500; }
        .cert-grid .value { color: #ccc; word-break: break-all; }
        .badge { display: inline-block; padding: 2px 8px; border-radius: 3px; font-size: 0.8em; font-weight: 600; }
        .badge-success { background: #0a2e0a; color: #4caf50; }
        .badge-warning { background: #2e2a0a; color: #ff9800; }
        .badge-error { background: #2e0a0a; color: #f44336; }
        .footer { text-align: center; padding: 24px; color: #555; font-size: 0.85em; border-top: 1px solid #1a1a1a; margin-top: 48px; }
    </style>
</head>
<body>

<nav class="navbar">
    <a href="index.jsp" class="brand">NCSUWolfpack™</a>
    <a href="index.jsp">Overview</a>
    <a href="contact.jsp" class="active">Contact</a>
    <a href="messaging.jsp">Messages</a>
    <a href="status.jsp">Status</a>
</nav>

<div class="hero">
    <div class="tag">North Carolina State University</div>
    <h1>Contact NC State</h1>
    <p>Contact NC State University for admissions inquiries, academic programs, research partnerships, or general information.</p>
</div>

<div class="container">

    <% if (!statusMsg.isEmpty()) { %>
    <div class="status-msg <%= statusType %>"><%= esc(statusMsg) %></div>
    <% } %>

    <div class="card">
        <h2>Send Message</h2>
        <form method="POST" action="contact.jsp">
            <div class="form-grid">
                <div>
                    <label for="sender_name">Your Name</label>
                    <input type="text" id="sender_name" name="sender_name" required placeholder="Full name">
                </div>
                <div>
                    <label for="sender_email">Your Email</label>
                    <input type="email" id="sender_email" name="sender_email" required placeholder="email@example.com">
                </div>
                <div>
                    <label for="subject">Subject</label>
                    <input type="text" id="subject" name="subject" required placeholder="Message subject">
                </div>
                <div>
                    <label for="message_category">Category</label>
                    <select id="message_category" name="message_category" required>
                        <option value="">— Select Category —</option>
                        <option value="Admissions">Admissions</option>
                        <option value="Academic Programs">Academic Programs</option>
                        <option value="Research Partnerships">Research Partnerships</option>
                        <option value="Student Services">Student Services</option>
                        <option value="Financial Aid">Financial Aid</option>
                        <option value="Graduate Studies">Graduate Studies</option>
                        <option value="Career Services">Career Services</option>
                        <option value="General Inquiry">General Inquiry</option>
                    </select>
                </div>
                <div class="full">
                    <label for="message_body">Message</label>
                    <textarea id="message_body" name="message_body" required placeholder="Your message..."></textarea>
                </div>
                <div class="full">
                    <button type="submit" class="btn">Send Message</button>
                </div>
            </div>
        </form>
    </div>

    <div class="card">
        <h2>Recent Outbound Messages</h2>
        <table>
            <thead>
                <tr>
                    <th>Date</th>
                    <th>Sender</th>
                    <th>Subject</th>
                    <th>Category</th>
                    <th>Response</th>
                </tr>
            </thead>
            <tbody>
            <%
                if (conn != null) {
                    try {
                        Statement st = conn.createStatement();
                        ResultSet rs = st.executeQuery("SELECT * FROM outbound_messages ORDER BY sent_at DESC LIMIT 10");
                        while (rs.next()) {
                            int code = rs.getInt("response_code");
                            String badgeClass = (code >= 200 && code < 400) ? "badge-success" : (code < 0 ? "badge-error" : "badge-warning");
            %>
                <tr>
                    <td><%= esc(rs.getString("sent_at")) %></td>
                    <td><%= esc(truncate(rs.getString("sender_name"), 20)) %></td>
                    <td><%= esc(truncate(rs.getString("subject"), 30)) %></td>
                    <td><%= esc(rs.getString("message_category")) %></td>
                    <td><span class="badge <%= badgeClass %>"><%= code %></span></td>
                </tr>
            <%
                        }
                        rs.close();
                        st.close();
                    } catch (Exception e) { %>
                <tr><td colspan="5" style="color:#f44336;">Error loading messages: <%= esc(e.getMessage()) %></td></tr>
            <%  }
                }
            %>
            </tbody>
        </table>
    </div>

    <div class="card">
        <h3>SSL/TLS Certificate — <%= esc(targetHost) %></h3>
        <div class="cert-grid">
            <div class="label">Subject</div>
            <div class="value"><%= esc(certSubject) %></div>
            <div class="label">Issuer</div>
            <div class="value"><%= esc(certIssuer) %></div>
            <div class="label">Serial</div>
            <div class="value"><%= esc(certSerial) %></div>
            <div class="label">Valid From</div>
            <div class="value"><%= esc(certNotBefore) %></div>
            <div class="label">Valid Until</div>
            <div class="value"><%= esc(certNotAfter) %></div>
            <div class="label">Algorithm</div>
            <div class="value"><%= esc(certSigAlg) %></div>
            <div class="label">SHA-256 Fingerprint</div>
            <div class="value" style="font-family: monospace; font-size: 0.85em;"><%= esc(certFingerprint) %></div>
        </div>
    </div>

</div>

<div class="footer">
    &copy; 2026 MEARVK LLC. NCSUWolfpack&trade; &mdash; NC State Red.
</div>

<%
    if (conn != null) { try { conn.close(); } catch (Exception ignored) {} }
%>

</body>
</html>
