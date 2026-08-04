<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="java.util.Date" %>
<%@ page import="java.io.*" %>
<%@ page import="java.net.*" %>
<%@ page import="java.security.cert.Certificate" %>
<%@ page import="java.security.cert.X509Certificate" %>
<%@ page import="javax.net.ssl.*" %>
<%!
    private static final String TARGET_SITE = "https://tips.fbi.gov";
    private static final String TARGET_HOST = "tips.fbi.gov";
    private static final int TARGET_PORT = 443;
    private static final String DB_URL = "jdbc:mysql://127.0.0.1:3306/nwe_california_fbi";

    private Connection getConnection(ServletContext ctx) throws Exception {
        Class.forName("com.mysql.cj.jdbc.Driver");
        String user = "root";
        String pass = "";
        try {
            Properties props = new Properties();
            InputStream is = ctx.getResourceAsStream("/WEB-INF/db.properties");
            if (is != null) {
                props.load(is);
                is.close();
                user = props.getProperty("db.user", "root");
                pass = props.getProperty("db.password", "");
            }
        } catch (Exception e) {
            // fallback to defaults
        }
        return DriverManager.getConnection(DB_URL, user, pass);
    }

    private void ensureTables(Connection conn) throws SQLException {
        Statement stmt = conn.createStatement();
        stmt.executeUpdate(
            "CREATE TABLE IF NOT EXISTS site_public_keys (" +
            "  id BIGINT AUTO_INCREMENT PRIMARY KEY," +
            "  host VARCHAR(255) NOT NULL," +
            "  port INT NOT NULL DEFAULT 443," +
            "  certificate_subject TEXT," +
            "  certificate_issuer TEXT," +
            "  public_key_algorithm VARCHAR(64)," +
            "  public_key_base64 TEXT," +
            "  valid_from DATETIME," +
            "  valid_to DATETIME," +
            "  fetched_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP" +
            ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4"
        );
        stmt.executeUpdate(
            "CREATE TABLE IF NOT EXISTS outbound_messages (" +
            "  id BIGINT AUTO_INCREMENT PRIMARY KEY," +
            "  sender_name VARCHAR(255)," +
            "  sender_email VARCHAR(255)," +
            "  subject VARCHAR(512)," +
            "  category VARCHAR(128)," +
            "  message_body TEXT," +
            "  target_site VARCHAR(512)," +
            "  sent_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP," +
            "  response_text TEXT," +
            "  response_code INT" +
            ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4"
        );
        stmt.close();
    }

    private void fetchAndStoreSSLKey(Connection conn) {
        try {
            SSLSocketFactory factory = (SSLSocketFactory) SSLSocketFactory.getDefault();
            try (SSLSocket sslSocket = (SSLSocket) factory.createSocket(TARGET_HOST, TARGET_PORT)) {
                sslSocket.setSoTimeout(10000);
                sslSocket.startHandshake();
                Certificate[] certs = sslSocket.getSession().getPeerCertificates();
                if (certs != null && certs.length > 0) {
                    X509Certificate x509 = (X509Certificate) certs[0];
                    String subject = x509.getSubjectX500Principal().getName();
                    String issuer = x509.getIssuerX500Principal().getName();
                    String algo = x509.getPublicKey().getAlgorithm();
                    String keyB64 = Base64.getEncoder().encodeToString(x509.getPublicKey().getEncoded());
                    java.util.Date validFrom = x509.getNotBefore();
                    java.util.Date validTo = x509.getNotAfter();

                    PreparedStatement ps = conn.prepareStatement(
                        "INSERT INTO site_public_keys (host, port, certificate_subject, certificate_issuer, " +
                        "public_key_algorithm, public_key_base64, valid_from, valid_to, fetched_at) " +
                        "VALUES (?, ?, ?, ?, ?, ?, ?, ?, NOW())"
                    );
                    ps.setString(1, TARGET_HOST);
                    ps.setInt(2, TARGET_PORT);
                    ps.setString(3, subject);
                    ps.setString(4, issuer);
                    ps.setString(5, algo);
                    ps.setString(6, keyB64);
                    ps.setTimestamp(7, new Timestamp(validFrom.getTime()));
                    ps.setTimestamp(8, new Timestamp(validTo.getTime()));
                    ps.executeUpdate();
                    ps.close();

                    // Store full chain
                    for (int i = 1; i < certs.length; i++) {
                        X509Certificate chainCert = (X509Certificate) certs[i];
                        PreparedStatement psc = conn.prepareStatement(
                            "INSERT INTO site_public_keys (host, port, certificate_subject, certificate_issuer, " +
                            "public_key_algorithm, public_key_base64, valid_from, valid_to, fetched_at) " +
                            "VALUES (?, ?, ?, ?, ?, ?, ?, ?, NOW())"
                        );
                        psc.setString(1, TARGET_HOST);
                        psc.setInt(2, TARGET_PORT);
                        psc.setString(3, chainCert.getSubjectX500Principal().getName());
                        psc.setString(4, chainCert.getIssuerX500Principal().getName());
                        psc.setString(5, chainCert.getPublicKey().getAlgorithm());
                        psc.setString(6, Base64.getEncoder().encodeToString(chainCert.getPublicKey().getEncoded()));
                        psc.setTimestamp(7, new Timestamp(chainCert.getNotBefore().getTime()));
                        psc.setTimestamp(8, new Timestamp(chainCert.getNotAfter().getTime()));
                        psc.executeUpdate();
                        psc.close();
                    }
                }
            }
        } catch (Exception e) {
            // SSL fetch failed — non-fatal, log silently
        }
    }

    private String[] submitToFBI(String senderName, String senderEmail, String subject, String category, String messageBody) {
        int responseCode = -1;
        String responseText = "";
        try {
            URL url = new URL(TARGET_SITE);
            HttpURLConnection httpConn = (HttpURLConnection) url.openConnection();
            httpConn.setRequestMethod("POST");
            httpConn.setDoOutput(true);
            httpConn.setConnectTimeout(15000);
            httpConn.setReadTimeout(15000);
            httpConn.setRequestProperty("Content-Type", "application/x-www-form-urlencoded");
            httpConn.setRequestProperty("User-Agent", "CaliforniaFBI-Module/1.0");

            String postData = "sender_name=" + URLEncoder.encode(senderName, "UTF-8") +
                              "&sender_email=" + URLEncoder.encode(senderEmail, "UTF-8") +
                              "&subject=" + URLEncoder.encode(subject, "UTF-8") +
                              "&category=" + URLEncoder.encode(category, "UTF-8") +
                              "&message_body=" + URLEncoder.encode(messageBody, "UTF-8");

            try (OutputStream os = httpConn.getOutputStream()) {
                os.write(postData.getBytes("UTF-8"));
                os.flush();
            }

            responseCode = httpConn.getResponseCode();

            InputStream is = null;
            try {
                is = httpConn.getInputStream();
            } catch (IOException e) {
                is = httpConn.getErrorStream();
            }

            if (is != null) {
                BufferedReader reader = new BufferedReader(new InputStreamReader(is, "UTF-8"));
                StringBuilder sb = new StringBuilder();
                String line;
                while ((line = reader.readLine()) != null && sb.length() < 2000) {
                    sb.append(line).append("\n");
                }
                reader.close();
                responseText = sb.length() > 2000 ? sb.substring(0, 2000) : sb.toString();
            }

            httpConn.disconnect();
        } catch (Exception e) {
            responseText = "Connection failed: " + e.getMessage();
            responseCode = -1;
        }
        return new String[]{String.valueOf(responseCode), responseText};
    }

    private String escapeHtml(String input) {
        if (input == null) return "";
        return input.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
                    .replace("\"", "&quot;").replace("'", "&#x27;");
    }
%>
<%
    String statusMessage = null;
    String statusType = null;

    Connection conn = null;
    try {
        conn = getConnection(application);
        ensureTables(conn);

        // On GET: fetch SSL key from tips.fbi.gov
        if ("GET".equalsIgnoreCase(request.getMethod())) {
            fetchAndStoreSSLKey(conn);
        }

        // On POST: process form submission
        if ("POST".equalsIgnoreCase(request.getMethod())) {
            String senderName = request.getParameter("sender_name");
            String senderEmail = request.getParameter("sender_email");
            String subject = request.getParameter("subject");
            String category = request.getParameter("message_category");
            String messageBody = request.getParameter("message_body");

            if (senderName != null && !senderName.trim().isEmpty() &&
                senderEmail != null && !senderEmail.trim().isEmpty() &&
                messageBody != null && !messageBody.trim().isEmpty()) {

                // Submit to FBI
                String[] result = submitToFBI(senderName, senderEmail, subject, category, messageBody);
                int respCode = Integer.parseInt(result[0]);
                String respText = result[1];

                // Fetch SSL cert on submission
                fetchAndStoreSSLKey(conn);

                // Store in outbound_messages
                PreparedStatement ps = conn.prepareStatement(
                    "INSERT INTO outbound_messages (sender_name, sender_email, subject, category, " +
                    "message_body, target_site, sent_at, response_text, response_code) " +
                    "VALUES (?, ?, ?, ?, ?, ?, NOW(), ?, ?)"
                );
                ps.setString(1, senderName.trim());
                ps.setString(2, senderEmail.trim());
                ps.setString(3, subject != null ? subject.trim() : "");
                ps.setString(4, category != null ? category.trim() : "General Inquiry");
                ps.setString(5, messageBody.trim());
                ps.setString(6, TARGET_SITE);
                ps.setString(7, respText);
                ps.setInt(8, respCode);
                ps.executeUpdate();
                ps.close();

                if (respCode >= 200 && respCode < 400) {
                    statusMessage = "Message submitted successfully. Response code: " + respCode;
                    statusType = "success";
                } else if (respCode == -1) {
                    statusMessage = "Message stored locally. Could not reach " + TARGET_SITE + ": " + escapeHtml(respText);
                    statusType = "warning";
                } else {
                    statusMessage = "Message stored. Site returned HTTP " + respCode + ". Response: " + escapeHtml(respText.length() > 200 ? respText.substring(0, 200) + "..." : respText);
                    statusType = "warning";
                }
            } else {
                statusMessage = "Please fill in all required fields (name, email, message).";
                statusType = "error";
            }
        }
    } catch (Exception e) {
        statusMessage = "System error: " + escapeHtml(e.getMessage());
        statusType = "error";
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Contact FBI — CaliforniaFBI&#8482;</title>
    <link rel="stylesheet" href="css/style.css">
    <style>
        @import url('https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:wght@300;400;500;600;700&display=swap');

        * { margin: 0; padding: 0; box-sizing: border-box; }

        body {
            font-family: 'IBM Plex Sans', -apple-system, BlinkMacSystemFont, sans-serif;
            background: #0a0a0f;
            color: #e0e0e0;
            min-height: 100vh;
            line-height: 1.6;
        }

        nav {
            background: #12121a;
            border-bottom: 1px solid #1e1e2e;
            padding: 0 2rem;
            display: flex;
            align-items: center;
            height: 64px;
            position: sticky;
            top: 0;
            z-index: 100;
        }

        .nav-brand {
            font-size: 1.25rem;
            font-weight: 700;
            color: #4fc3f7;
            margin-right: 2.5rem;
            letter-spacing: -0.02em;
        }

        .nav-links {
            display: flex;
            gap: 0.25rem;
            list-style: none;
        }

        .nav-links a {
            color: #9e9e9e;
            text-decoration: none;
            padding: 0.5rem 1rem;
            border-radius: 6px;
            font-size: 0.9rem;
            font-weight: 500;
            transition: all 0.2s;
        }

        .nav-links a:hover {
            color: #ffffff;
            background: #1a1a2e;
        }

        .nav-links a.active {
            color: #4fc3f7;
            background: #1a1a2e;
        }

        .hero {
            padding: 3rem 2rem 2rem;
            text-align: center;
            border-bottom: 1px solid #1e1e2e;
            background: linear-gradient(180deg, #12121a 0%, #0a0a0f 100%);
        }

        .hero h1 {
            font-size: 2.25rem;
            font-weight: 700;
            color: #ffffff;
            margin-bottom: 0.75rem;
            letter-spacing: -0.03em;
        }

        .hero p {
            color: #9e9e9e;
            font-size: 1.05rem;
            max-width: 640px;
            margin: 0 auto;
        }

        .container {
            max-width: 900px;
            margin: 0 auto;
            padding: 2rem;
        }

        .section-title {
            font-size: 1.1rem;
            font-weight: 600;
            color: #ffffff;
            margin-bottom: 1rem;
            padding-bottom: 0.5rem;
            border-bottom: 1px solid #1e1e2e;
        }

        .status-message {
            padding: 1rem 1.25rem;
            border-radius: 8px;
            margin-bottom: 1.5rem;
            font-size: 0.9rem;
            font-weight: 500;
        }

        .status-success {
            background: #0d2818;
            border: 1px solid #1b5e20;
            color: #66bb6a;
        }

        .status-warning {
            background: #2e1f05;
            border: 1px solid #e65100;
            color: #ffb74d;
        }

        .status-error {
            background: #2e0505;
            border: 1px solid #b71c1c;
            color: #ef5350;
        }

        .form-card {
            background: #12121a;
            border: 1px solid #1e1e2e;
            border-radius: 10px;
            padding: 2rem;
            margin-bottom: 2rem;
        }

        .form-group {
            margin-bottom: 1.25rem;
        }

        .form-group label {
            display: block;
            font-size: 0.85rem;
            font-weight: 500;
            color: #b0b0b0;
            margin-bottom: 0.4rem;
        }

        .form-group input,
        .form-group select,
        .form-group textarea {
            width: 100%;
            padding: 0.7rem 1rem;
            background: #0a0a0f;
            border: 1px solid #2a2a3e;
            border-radius: 6px;
            color: #e0e0e0;
            font-family: 'IBM Plex Sans', sans-serif;
            font-size: 0.9rem;
            transition: border-color 0.2s;
        }

        .form-group input:focus,
        .form-group select:focus,
        .form-group textarea:focus {
            outline: none;
            border-color: #4fc3f7;
        }

        .form-group textarea {
            min-height: 140px;
            resize: vertical;
        }

        .form-row {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 1rem;
        }

        .btn-submit {
            background: #4fc3f7;
            color: #0a0a0f;
            border: none;
            padding: 0.75rem 2rem;
            font-size: 0.9rem;
            font-weight: 600;
            border-radius: 6px;
            cursor: pointer;
            font-family: 'IBM Plex Sans', sans-serif;
            transition: all 0.2s;
        }

        .btn-submit:hover {
            background: #81d4fa;
            transform: translateY(-1px);
        }

        .data-table {
            width: 100%;
            border-collapse: collapse;
            font-size: 0.82rem;
            margin-top: 1rem;
        }

        .data-table th {
            background: #1a1a2e;
            color: #4fc3f7;
            padding: 0.6rem 0.75rem;
            text-align: left;
            font-weight: 600;
            border-bottom: 1px solid #2a2a3e;
        }

        .data-table td {
            padding: 0.55rem 0.75rem;
            border-bottom: 1px solid #1e1e2e;
            color: #c0c0c0;
            max-width: 200px;
            overflow: hidden;
            text-overflow: ellipsis;
            white-space: nowrap;
        }

        .data-table tr:hover td {
            background: #14141e;
        }

        .key-info {
            background: #12121a;
            border: 1px solid #1e1e2e;
            border-radius: 10px;
            padding: 1.5rem;
            margin-top: 2rem;
        }

        .key-detail {
            display: grid;
            grid-template-columns: 140px 1fr;
            gap: 0.4rem 1rem;
            font-size: 0.82rem;
        }

        .key-detail dt {
            color: #9e9e9e;
            font-weight: 500;
        }

        .key-detail dd {
            color: #e0e0e0;
            word-break: break-all;
        }

        .badge {
            display: inline-block;
            padding: 0.2rem 0.6rem;
            border-radius: 4px;
            font-size: 0.75rem;
            font-weight: 600;
        }

        .badge-ok { background: #1b5e20; color: #66bb6a; }
        .badge-warn { background: #e65100; color: #ffb74d; }
        .badge-err { background: #b71c1c; color: #ef5350; }

        .empty-state {
            text-align: center;
            padding: 2rem;
            color: #666;
            font-style: italic;
        }

        @media (max-width: 640px) {
            .form-row { grid-template-columns: 1fr; }
            nav { padding: 0 1rem; }
            .container { padding: 1.5rem 1rem; }
        }
    </style>
</head>
<body>

<nav>
    <div class="nav-brand">CaliforniaFBI&#8482;</div>
    <ul class="nav-links">
        <li><a href="index.jsp">Overview</a></li>
        <li><a href="report.jsp">Report</a></li>
        <li><a href="search.jsp">Search</a></li>
        <li><a href="contact.jsp" class="active">Contact</a></li>
        <li><a href="status.jsp">Status</a></li>
    </ul>
</nav>

<div class="hero">
    <h1>Contact FBI</h1>
    <p>Submit tips, complaints, or general inquiries to the Federal Bureau of Investigation. Messages are transmitted to <strong>tips.fbi.gov</strong> and stored locally for your records. All communications are logged with SSL certificate verification.</p>
</div>

<div class="container">

    <% if (statusMessage != null) { %>
    <div class="status-message status-<%= statusType %>">
        <%= statusMessage %>
    </div>
    <% } %>

    <!-- Contact Form -->
    <div class="form-card">
        <h2 class="section-title">Send Message</h2>
        <form method="POST" action="contact.jsp">
            <div class="form-row">
                <div class="form-group">
                    <label for="sender_name">Full Name *</label>
                    <input type="text" id="sender_name" name="sender_name" required
                           placeholder="Your full legal name" autocomplete="name">
                </div>
                <div class="form-group">
                    <label for="sender_email">Email Address *</label>
                    <input type="email" id="sender_email" name="sender_email" required
                           placeholder="your.email@example.com" autocomplete="email">
                </div>
            </div>
            <div class="form-row">
                <div class="form-group">
                    <label for="subject">Subject</label>
                    <input type="text" id="subject" name="subject"
                           placeholder="Brief subject line">
                </div>
                <div class="form-group">
                    <label for="message_category">Category</label>
                    <select id="message_category" name="message_category">
                        <option value="Tip">Tip</option>
                        <option value="Complaint">Complaint</option>
                        <option value="General Inquiry">General Inquiry</option>
                        <option value="FOIA Request">FOIA Request</option>
                        <option value="Public Corruption">Public Corruption</option>
                    </select>
                </div>
            </div>
            <div class="form-group">
                <label for="message_body">Message *</label>
                <textarea id="message_body" name="message_body" required
                          placeholder="Provide detailed information. Include dates, locations, names, and any supporting details."></textarea>
            </div>
            <button type="submit" class="btn-submit">Submit to FBI</button>
        </form>
    </div>

    <!-- Recent Messages -->
    <div class="form-card">
        <h2 class="section-title">Recent Outbound Messages</h2>
        <%
            try {
                if (conn != null && !conn.isClosed()) {
                    Statement msgStmt = conn.createStatement();
                    ResultSet msgRs = msgStmt.executeQuery(
                        "SELECT id, sender_name, subject, category, target_site, sent_at, response_code " +
                        "FROM outbound_messages ORDER BY sent_at DESC LIMIT 10"
                    );
                    boolean hasMessages = false;
        %>
        <table class="data-table">
            <thead>
                <tr>
                    <th>ID</th>
                    <th>Sender</th>
                    <th>Subject</th>
                    <th>Category</th>
                    <th>Sent</th>
                    <th>Response</th>
                </tr>
            </thead>
            <tbody>
        <%
                    while (msgRs.next()) {
                        hasMessages = true;
                        int rCode = msgRs.getInt("response_code");
                        String badgeClass = rCode >= 200 && rCode < 400 ? "badge-ok" : (rCode == -1 ? "badge-err" : "badge-warn");
                        String badgeLabel = rCode == -1 ? "FAIL" : String.valueOf(rCode);
        %>
                <tr>
                    <td><%= msgRs.getLong("id") %></td>
                    <td><%= escapeHtml(msgRs.getString("sender_name")) %></td>
                    <td><%= escapeHtml(msgRs.getString("subject")) %></td>
                    <td><%= escapeHtml(msgRs.getString("category")) %></td>
                    <td><%= msgRs.getTimestamp("sent_at") %></td>
                    <td><span class="badge <%= badgeClass %>"><%= badgeLabel %></span></td>
                </tr>
        <%
                    }
                    msgRs.close();
                    msgStmt.close();

                    if (!hasMessages) {
        %>
            </tbody>
        </table>
        <div class="empty-state">No messages sent yet.</div>
        <%
                    } else {
        %>
            </tbody>
        </table>
        <%
                    }
                }
            } catch (Exception e) {
        %>
        <div class="empty-state">Unable to load messages: <%= escapeHtml(e.getMessage()) %></div>
        <%
            }
        %>
    </div>

    <!-- SSL Public Key Info -->
    <div class="key-info">
        <h2 class="section-title">SSL Certificate — tips.fbi.gov</h2>
        <%
            try {
                if (conn != null && !conn.isClosed()) {
                    Statement keyStmt = conn.createStatement();
                    ResultSet keyRs = keyStmt.executeQuery(
                        "SELECT host, port, certificate_subject, certificate_issuer, " +
                        "public_key_algorithm, public_key_base64, valid_from, valid_to, fetched_at " +
                        "FROM site_public_keys WHERE host = 'tips.fbi.gov' " +
                        "ORDER BY fetched_at DESC LIMIT 1"
                    );
                    if (keyRs.next()) {
                        String certSubject = keyRs.getString("certificate_subject");
                        String certIssuer = keyRs.getString("certificate_issuer");
                        String keyAlgo = keyRs.getString("public_key_algorithm");
                        String keyB64 = keyRs.getString("public_key_base64");
                        Timestamp validFrom = keyRs.getTimestamp("valid_from");
                        Timestamp validTo = keyRs.getTimestamp("valid_to");
                        Timestamp fetchedAt = keyRs.getTimestamp("fetched_at");
                        String truncatedKey = keyB64 != null && keyB64.length() > 64 ?
                            keyB64.substring(0, 64) + "..." : (keyB64 != null ? keyB64 : "N/A");
        %>
        <dl class="key-detail">
            <dt>Host</dt>
            <dd><%= escapeHtml(keyRs.getString("host")) %>:<%= keyRs.getInt("port") %></dd>
            <dt>Subject</dt>
            <dd><%= escapeHtml(certSubject) %></dd>
            <dt>Issuer</dt>
            <dd><%= escapeHtml(certIssuer) %></dd>
            <dt>Algorithm</dt>
            <dd><%= escapeHtml(keyAlgo) %></dd>
            <dt>Public Key</dt>
            <dd><code><%= escapeHtml(truncatedKey) %></code></dd>
            <dt>Valid From</dt>
            <dd><%= validFrom %></dd>
            <dt>Valid To</dt>
            <dd><%= validTo %></dd>
            <dt>Fetched At</dt>
            <dd><%= fetchedAt %></dd>
        </dl>
        <%
                    } else {
        %>
        <div class="empty-state">No SSL certificate data available. Certificate will be fetched on next page load.</div>
        <%
                    }
                    keyRs.close();
                    keyStmt.close();
                }
            } catch (Exception e) {
        %>
        <div class="empty-state">Unable to load certificate info: <%= escapeHtml(e.getMessage()) %></div>
        <%
            }

            // Close connection
            if (conn != null && !conn.isClosed()) {
                conn.close();
            }
        %>
    </div>

</div>

</body>
</html>
