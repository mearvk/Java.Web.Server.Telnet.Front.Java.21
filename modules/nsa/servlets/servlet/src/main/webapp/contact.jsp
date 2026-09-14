<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.Properties, java.io.*, java.net.*, javax.net.ssl.*, java.security.cert.X509Certificate, java.security.cert.Certificate, java.util.Base64, java.text.SimpleDateFormat" %>
<%!
    // --- Helper: Get DB connection ---
    private Connection getDbConnection(ServletContext ctx) throws Exception {
        Properties p = new Properties();
        InputStream is = ctx.getResourceAsStream("/WEB-INF/db.properties");
        if (is != null) { p.load(is); is.close(); }
        Class.forName(p.getProperty("db.driver", "com.mysql.cj.jdbc.Driver"));
        return DriverManager.getConnection(
            p.getProperty("db.url", "jdbc:mysql://127.0.0.1:3306/nwe_california_nsa"),
            p.getProperty("db.user", "root"),
            p.getProperty("db.password", "")
        );
    }

    // --- Helper: Fetch and store SSL public key ---
    private String fetchAndStoreSSLKey(String host, int port, Connection conn) {
        try {
            SSLSocketFactory factory = (SSLSocketFactory) SSLSocketFactory.getDefault();
            try (SSLSocket sslSocket = (SSLSocket) factory.createSocket(host, port)) {
                sslSocket.setSoTimeout(10000);
                sslSocket.startHandshake();
                Certificate[] certs = sslSocket.getSession().getPeerCertificates();
                if (certs.length == 0) return "No certificates returned.";

                X509Certificate x509 = (X509Certificate) certs[0];
                String subject = x509.getSubjectX500Principal().getName();
                String issuer = x509.getIssuerX500Principal().getName();
                String algo = x509.getPublicKey().getAlgorithm();
                String keyB64 = Base64.getEncoder().encodeToString(x509.getPublicKey().getEncoded());
                Timestamp validFrom = new Timestamp(x509.getNotBefore().getTime());
                Timestamp validTo = new Timestamp(x509.getNotAfter().getTime());
                Timestamp fetchedAt = new Timestamp(System.currentTimeMillis());

                // Create table if not exists
                try (Statement st = conn.createStatement()) {
                    st.executeUpdate("CREATE TABLE IF NOT EXISTS site_public_keys (" +
                        "id BIGINT AUTO_INCREMENT PRIMARY KEY, " +
                        "host VARCHAR(255) NOT NULL, " +
                        "port INT NOT NULL DEFAULT 443, " +
                        "certificate_subject TEXT, " +
                        "certificate_issuer TEXT, " +
                        "public_key_algorithm VARCHAR(32), " +
                        "public_key_base64 TEXT, " +
                        "valid_from DATETIME, " +
                        "valid_to DATETIME, " +
                        "fetched_at DATETIME NOT NULL" +
                        ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");
                }

                // Insert record
                try (PreparedStatement ps = conn.prepareStatement(
                    "INSERT INTO site_public_keys (host, port, certificate_subject, certificate_issuer, public_key_algorithm, public_key_base64, valid_from, valid_to, fetched_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)")) {
                    ps.setString(1, host);
                    ps.setInt(2, port);
                    ps.setString(3, subject);
                    ps.setString(4, issuer);
                    ps.setString(5, algo);
                    ps.setString(6, keyB64);
                    ps.setTimestamp(7, validFrom);
                    ps.setTimestamp(8, validTo);
                    ps.setTimestamp(9, fetchedAt);
                    ps.executeUpdate();
                }
                return "OK: " + algo + " key from " + host + " stored.";
            }
        } catch (Exception e) {
            return "SSL fetch error: " + e.getMessage();
        }
    }
%>
<%
    String msg = null;
    String msgColor = "#22c55e";
    String sslStatus = "";
    SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss z");
    Connection conn = null;

    try {
        conn = getDbConnection(application);

        // --- Ensure outbound_messages table exists ---
        try (Statement st = conn.createStatement()) {
            st.executeUpdate("CREATE TABLE IF NOT EXISTS outbound_messages (" +
                "id BIGINT AUTO_INCREMENT PRIMARY KEY, " +
                "sender_name VARCHAR(255), " +
                "sender_email VARCHAR(255), " +
                "subject VARCHAR(500), " +
                "category VARCHAR(100), " +
                "message_body TEXT, " +
                "target_site VARCHAR(500), " +
                "sent_at DATETIME NOT NULL, " +
                "response_text TEXT, " +
                "response_code INT DEFAULT 0" +
                ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");
        }

        // --- On GET: Fetch SSL public key from www.nsa.gov ---
        if ("GET".equals(request.getMethod())) {
            sslStatus = fetchAndStoreSSLKey("www.nsa.gov", 443, conn);
        }

        // --- On POST: Store message and attempt submission ---
        if ("POST".equals(request.getMethod())) {
            String senderName = request.getParameter("sender_name");
            String senderEmail = request.getParameter("sender_email");
            String subject = request.getParameter("subject");
            String category = request.getParameter("message_category");
            String messageBody = request.getParameter("message_body");

            if (senderName == null || senderName.trim().isEmpty() ||
                senderEmail == null || senderEmail.trim().isEmpty() ||
                subject == null || subject.trim().isEmpty() ||
                category == null || category.trim().isEmpty() ||
                messageBody == null || messageBody.trim().isEmpty()) {
                msg = "Please fill in all fields.";
                msgColor = "#ef4444";
            } else {
                String targetSite = "https://www.nsa.gov/About/Cryptologic-Heritage/Historical-Figures-Posters/Report-a-Vulnerability/";
                int responseCode = 0;
                String responseText = "";

                // Attempt HTTP POST to NSA
                try {
                    URL url = new URL(targetSite);
                    HttpURLConnection hc = (HttpURLConnection) url.openConnection();
                    hc.setRequestMethod("POST");
                    hc.setDoOutput(true);
                    hc.setConnectTimeout(10000);
                    hc.setReadTimeout(10000);
                    hc.setRequestProperty("Content-Type", "application/x-www-form-urlencoded");
                    hc.setRequestProperty("User-Agent", "CaliforniaNSA-Module/1.0");

                    String postData = "sender_name=" + URLEncoder.encode(senderName.trim(), "UTF-8") +
                                      "&sender_email=" + URLEncoder.encode(senderEmail.trim(), "UTF-8") +
                                      "&subject=" + URLEncoder.encode(subject.trim(), "UTF-8") +
                                      "&category=" + URLEncoder.encode(category.trim(), "UTF-8") +
                                      "&message_body=" + URLEncoder.encode(messageBody.trim(), "UTF-8");

                    try (OutputStream os = hc.getOutputStream()) {
                        os.write(postData.getBytes("UTF-8"));
                        os.flush();
                    }

                    responseCode = hc.getResponseCode();
                    InputStream respStream = (responseCode >= 400) ? hc.getErrorStream() : hc.getInputStream();
                    if (respStream != null) {
                        BufferedReader br = new BufferedReader(new InputStreamReader(respStream, "UTF-8"));
                        StringBuilder sb = new StringBuilder();
                        String line;
                        int charCount = 0;
                        while ((line = br.readLine()) != null && charCount < 2000) {
                            sb.append(line).append("\n");
                            charCount += line.length() + 1;
                        }
                        responseText = sb.toString();
                        if (responseText.length() > 2000) responseText = responseText.substring(0, 2000);
                        br.close();
                    }
                    hc.disconnect();
                } catch (Exception e) {
                    responseText = "Connection error: " + e.getMessage();
                    responseCode = -1;
                }

                // Store in outbound_messages
                try (PreparedStatement ps = conn.prepareStatement(
                    "INSERT INTO outbound_messages (sender_name, sender_email, subject, category, message_body, target_site, sent_at, response_text, response_code) VALUES (?, ?, ?, ?, ?, ?, NOW(), ?, ?)")) {
                    ps.setString(1, senderName.trim());
                    ps.setString(2, senderEmail.trim());
                    ps.setString(3, subject.trim());
                    ps.setString(4, category.trim());
                    ps.setString(5, messageBody.trim());
                    ps.setString(6, targetSite);
                    ps.setString(7, responseText);
                    ps.setInt(8, responseCode);
                    ps.executeUpdate();
                }

                // Also fetch SSL cert on POST
                sslStatus = fetchAndStoreSSLKey("www.nsa.gov", 443, conn);

                if (responseCode >= 200 && responseCode < 400) {
                    msg = "Message sent successfully. HTTP " + responseCode + " from nsa.gov.";
                } else if (responseCode == -1) {
                    msg = "Message stored locally. Could not reach nsa.gov: " + responseText;
                    msgColor = "#f59e0b";
                } else {
                    msg = "Message stored. nsa.gov returned HTTP " + responseCode + ".";
                    msgColor = "#f59e0b";
                }
            }
        }
    } catch (Exception e) {
        msg = "Database error: " + e.getMessage();
        msgColor = "#ef4444";
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>Contact — CaliforniaNSA™</title>
    <link rel="stylesheet" href="css/style.css"/>
    <link rel="preconnect" href="https://fonts.googleapis.com"/>
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin/>
    <link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:ital,wght@0,300;0,400;0,500;0,600;0,700;1,400;1,600&display=swap" rel="stylesheet"/>
    <script src="js/scroll-preserve.js"></script>
    <script src="js/nwe-readme-viewer.js"></script>
</head>
<body>
<nav class="nav"><div class="nav-inner">
    <span class="nav-brand">CaliforniaNSA™</span>
    <ul class="nav-links">
        <li><a href="index.jsp">Overview</a></li>
        <li><a href="report.jsp">Report</a></li>
        <li><a href="contact.jsp" class="active">Contact</a></li>
        <li><a href="status.jsp">Status</a></li>
    </ul>
</div></nav>

<section class="hero" style="padding:4rem 2rem;">
    <div class="hero-inner">
        <span class="hero-tag">Secure Communications</span>
        <h1>Contact NSA</h1>
        <p>Contact the National Security Agency for cybersecurity vulnerability reporting, advisory coordination, employment inquiries, or public affairs. Messages are stored locally and submitted to nsa.gov with full TLS verification.</p>
    </div>
</section>

<section class="section">
    <div class="section-inner" style="max-width:750px;">

        <% if (msg != null) { %>
        <div style="margin-bottom:1.5rem;padding:1rem;border:1px solid <%=msgColor%>;border-radius:8px;color:<%=msgColor%>;font-size:0.9rem;background:rgba(0,0,0,0.2);">
            <%=msg%>
        </div>
        <% } %>

        <% if (sslStatus != null && !sslStatus.isEmpty()) { %>
        <div style="margin-bottom:1.5rem;padding:0.75rem;border:1px solid #3b82f6;border-radius:8px;color:#60a5fa;font-size:0.8rem;background:rgba(59,130,246,0.05);">
            &#128274; SSL Key Fetch: <%=sslStatus%>
        </div>
        <% } %>

        <h2 style="margin-bottom:1.5rem;">Send Message</h2>

        <form method="POST" action="contact.jsp">
            <div class="form-group">
                <label>Your Name</label>
                <input type="text" name="sender_name" placeholder="Full name" required/>
            </div>
            <div class="form-group">
                <label>Your Email</label>
                <input type="email" name="sender_email" placeholder="email@example.com" required/>
            </div>
            <div class="form-group">
                <label>Subject</label>
                <input type="text" name="subject" placeholder="Brief subject line" required/>
            </div>
            <div class="form-group">
                <label>Category</label>
                <select name="message_category" required>
                    <option value="">— Select Category —</option>
                    <option value="Vulnerability Report">Vulnerability Report</option>
                    <option value="Cybersecurity Advisory">Cybersecurity Advisory</option>
                    <option value="Employment">Employment</option>
                    <option value="Media Inquiry">Media Inquiry</option>
                    <option value="General Inquiry">General Inquiry</option>
                    <option value="Contractor Support">Contractor Support</option>
                </select>
            </div>
            <div class="form-group">
                <label>Message</label>
                <textarea name="message_body" placeholder="Describe your inquiry, vulnerability details, or request..." rows="6" required></textarea>
            </div>
            <button type="submit" class="btn btn-primary" style="width:100%;">Send to NSA &#8594;</button>
        </form>

        <p style="margin-top:1.5rem;font-size:0.78rem;color:var(--text-muted);">
            Messages are submitted to <a href="https://www.nsa.gov/About/Cryptologic-Heritage/Historical-Figures-Posters/Report-a-Vulnerability/" target="_blank" style="color:#60a5fa;">nsa.gov — Report a Vulnerability</a>.
            TLS certificate chain is verified and stored on each submission.
        </p>
    </div>
</section>

<!-- Previous Messages -->
<section class="section">
    <div class="section-inner" style="max-width:900px;">
        <h2>Recent Outbound Messages</h2>
        <div class="table-wrap">
            <table>
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>Sender</th>
                        <th>Subject</th>
                        <th>Category</th>
                        <th>Sent</th>
                        <th>HTTP</th>
                    </tr>
                </thead>
                <tbody>
<%
    if (conn != null) {
        try (Statement st = conn.createStatement();
             ResultSet rs = st.executeQuery("SELECT id, sender_name, subject, category, sent_at, response_code FROM outbound_messages ORDER BY id DESC LIMIT 10")) {
            boolean hasRows = false;
            while (rs.next()) {
                hasRows = true;
                int rCode = rs.getInt("response_code");
                String codeColor = (rCode >= 200 && rCode < 400) ? "#22c55e" : (rCode == -1 ? "#ef4444" : "#f59e0b");
%>
                    <tr>
                        <td><%=rs.getLong("id")%></td>
                        <td><%=rs.getString("sender_name")%></td>
                        <td><%=rs.getString("subject")%></td>
                        <td><%=rs.getString("category")%></td>
                        <td style="font-size:0.78rem;"><%=rs.getTimestamp("sent_at")%></td>
                        <td style="color:<%=codeColor%>;font-weight:600;"><%=rCode%></td>
                    </tr>
<%
            }
            if (!hasRows) {
%>
                    <tr><td colspan="6" style="color:var(--text-muted);text-align:center;">No messages sent yet.</td></tr>
<%
            }
        } catch (Exception e) {
%>
                    <tr><td colspan="6" style="color:#ef4444;">Table query error: <%=e.getMessage()%></td></tr>
<%
        }
    }
%>
                </tbody>
            </table>
        </div>
    </div>
</section>

<!-- Stored Public Keys -->
<section class="section">
    <div class="section-inner" style="max-width:900px;">
        <h2>Stored TLS Public Keys</h2>
        <div class="table-wrap">
            <table>
                <thead>
                    <tr>
                        <th>Host</th>
                        <th>Algorithm</th>
                        <th>Subject</th>
                        <th>Valid From</th>
                        <th>Valid To</th>
                        <th>Fetched</th>
                    </tr>
                </thead>
                <tbody>
<%
    if (conn != null) {
        try (Statement st = conn.createStatement();
             ResultSet rs = st.executeQuery("SELECT host, public_key_algorithm, certificate_subject, valid_from, valid_to, fetched_at FROM site_public_keys ORDER BY fetched_at DESC LIMIT 5")) {
            boolean hasKeys = false;
            while (rs.next()) {
                hasKeys = true;
                String subj = rs.getString("certificate_subject");
                if (subj != null && subj.length() > 60) subj = subj.substring(0, 57) + "...";
%>
                    <tr>
                        <td><%=rs.getString("host")%></td>
                        <td><code><%=rs.getString("public_key_algorithm")%></code></td>
                        <td style="font-size:0.75rem;"><%=subj%></td>
                        <td style="font-size:0.75rem;"><%=rs.getTimestamp("valid_from")%></td>
                        <td style="font-size:0.75rem;"><%=rs.getTimestamp("valid_to")%></td>
                        <td style="font-size:0.75rem;"><%=rs.getTimestamp("fetched_at")%></td>
                    </tr>
<%
            }
            if (!hasKeys) {
%>
                    <tr><td colspan="6" style="color:var(--text-muted);text-align:center;">No keys stored yet.</td></tr>
<%
            }
        } catch (Exception e) {
%>
                    <tr><td colspan="6" style="color:#ef4444;">Key query error: <%=e.getMessage()%></td></tr>
<%
        }
    }
    // Close connection
    if (conn != null) { try { conn.close(); } catch (Exception ignore) {} }
%>
                </tbody>
            </table>
        </div>
    </div>
</section>

<footer class="footer"><div><span>&#169; 2026 MEARVK LLC. All rights reserved. CaliforniaNSA™ — Sky Blue.</span></div></footer>
</body>
</html>
