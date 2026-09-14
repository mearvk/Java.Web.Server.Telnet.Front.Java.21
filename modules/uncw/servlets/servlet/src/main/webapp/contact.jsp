<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.*, java.io.*, java.net.*, javax.net.ssl.*, java.security.cert.X509Certificate" %>
<%!
    static String esc(String s) { if (s == null) return ""; return s.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;"); }
    static String truncate(String s, int max) { if (s == null) return ""; return s.length() > max ? s.substring(0, max) + "..." : s; }
%>
<%
    String dbUrl = "jdbc:mysql://127.0.0.1:3306/nwe_uncw";
    String dbUser = "root";
    String dbPass = "";

    String targetHost = "uncw.edu";
    int targetPort = 443;
    String targetSubmitUrl = "https://uncw.edu/contact/";

    String statusMsg = "";
    String statusType = "";

    Connection conn = null;
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        conn = DriverManager.getConnection(dbUrl, dbUser, dbPass);

        // Auto-create tables
        Statement setup = conn.createStatement();
        setup.executeUpdate("CREATE TABLE IF NOT EXISTS site_public_keys (" +
            "id INT AUTO_INCREMENT PRIMARY KEY, " +
            "host VARCHAR(255) NOT NULL, " +
            "subject_dn TEXT, " +
            "issuer_dn TEXT, " +
            "serial_number VARCHAR(255), " +
            "not_before DATETIME, " +
            "not_after DATETIME, " +
            "sig_algorithm VARCHAR(128), " +
            "public_key_algorithm VARCHAR(64), " +
            "public_key_bits INT, " +
            "sha256_fingerprint VARCHAR(128), " +
            "fetched_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP" +
            ")");
        setup.executeUpdate("CREATE TABLE IF NOT EXISTS outbound_messages (" +
            "id INT AUTO_INCREMENT PRIMARY KEY, " +
            "sender_name VARCHAR(255), " +
            "sender_email VARCHAR(255), " +
            "subject VARCHAR(500), " +
            "message_category VARCHAR(128), " +
            "message_body TEXT, " +
            "target_url VARCHAR(500), " +
            "response_code INT, " +
            "response_body TEXT, " +
            "sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP" +
            ")");
        setup.close();

        // --- TLS Certificate Fetch ---
        String certSubject = "";
        String certIssuer = "";
        String certSerial = "";
        String certNotBefore = "";
        String certNotAfter = "";
        String certSigAlg = "";
        String certPubKeyAlg = "";
        int certKeyBits = 0;
        String certFingerprint = "";

        try {
            SSLSocketFactory factory = (SSLSocketFactory) SSLSocketFactory.getDefault();
            SSLSocket sslSocket = (SSLSocket) factory.createSocket(targetHost, targetPort);
            sslSocket.startHandshake();
            java.security.cert.Certificate[] certs = sslSocket.getSession().getPeerCertificates();
            sslSocket.close();

            if (certs.length > 0 && certs[0] instanceof X509Certificate) {
                X509Certificate x509 = (X509Certificate) certs[0];
                certSubject = x509.getSubjectX500Principal().getName();
                certIssuer = x509.getIssuerX500Principal().getName();
                certSerial = x509.getSerialNumber().toString(16);
                certNotBefore = x509.getNotBefore().toString();
                certNotAfter = x509.getNotAfter().toString();
                certSigAlg = x509.getSigAlgName();
                certPubKeyAlg = x509.getPublicKey().getAlgorithm();
                certKeyBits = x509.getPublicKey().getEncoded().length * 8;

                java.security.MessageDigest md = java.security.MessageDigest.getInstance("SHA-256");
                byte[] digest = md.digest(x509.getEncoded());
                StringBuilder sb = new StringBuilder();
                for (byte b : digest) sb.append(String.format("%02X:", b & 0xff));
                certFingerprint = sb.length() > 0 ? sb.substring(0, sb.length() - 1) : "";

                PreparedStatement ps = conn.prepareStatement(
                    "INSERT INTO site_public_keys (host, subject_dn, issuer_dn, serial_number, not_before, not_after, sig_algorithm, public_key_algorithm, public_key_bits, sha256_fingerprint) " +
                    "VALUES (?, ?, ?, ?, NOW(), NOW(), ?, ?, ?, ?)");
                ps.setString(1, targetHost);
                ps.setString(2, certSubject);
                ps.setString(3, certIssuer);
                ps.setString(4, certSerial);
                ps.setString(5, certSigAlg);
                ps.setString(6, certPubKeyAlg);
                ps.setInt(7, certKeyBits);
                ps.setString(8, certFingerprint);
                ps.executeUpdate();
                ps.close();
            }
        } catch (Exception e) {
            // TLS fetch failed silently — page still renders
        }

        // --- Handle POST ---
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
                HttpURLConnection http = (HttpURLConnection) url.openConnection();
                http.setRequestMethod("POST");
                http.setDoOutput(true);
                http.setRequestProperty("Content-Type", "application/x-www-form-urlencoded");
                http.setRequestProperty("User-Agent", "UNCWilmington/1.0 (NWE Contact Module)");
                http.setConnectTimeout(10000);
                http.setReadTimeout(10000);

                String postData = "name=" + URLEncoder.encode(senderName, "UTF-8") +
                    "&email=" + URLEncoder.encode(senderEmail, "UTF-8") +
                    "&subject=" + URLEncoder.encode(subject, "UTF-8") +
                    "&category=" + URLEncoder.encode(messageCategory, "UTF-8") +
                    "&message=" + URLEncoder.encode(messageBody, "UTF-8");

                OutputStream os = http.getOutputStream();
                os.write(postData.getBytes("UTF-8"));
                os.flush();
                os.close();

                responseCode = http.getResponseCode();
                InputStream is = (responseCode >= 400) ? http.getErrorStream() : http.getInputStream();
                if (is != null) {
                    BufferedReader br = new BufferedReader(new InputStreamReader(is, "UTF-8"));
                    StringBuilder respSb = new StringBuilder();
                    String line;
                    while ((line = br.readLine()) != null && respSb.length() < 2000) {
                        respSb.append(line).append("\n");
                    }
                    br.close();
                    responseBody = respSb.length() > 2000 ? respSb.substring(0, 2000) : respSb.toString();
                }
                http.disconnect();
            } catch (Exception e) {
                responseCode = -1;
                responseBody = "Connection failed: " + e.getMessage();
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

            statusMsg = "Message sent. Server responded with HTTP " + responseCode + ".";
            statusType = (responseCode >= 200 && responseCode < 400) ? "success" : "warning";
        }

        // --- Load recent messages ---
        List<Map<String, String>> messages = new ArrayList<>();
        Statement msgStmt = conn.createStatement();
        ResultSet msgRs = msgStmt.executeQuery("SELECT * FROM outbound_messages ORDER BY sent_at DESC LIMIT 10");
        while (msgRs.next()) {
            Map<String, String> row = new LinkedHashMap<>();
            row.put("id", msgRs.getString("id"));
            row.put("sender_name", msgRs.getString("sender_name"));
            row.put("sender_email", msgRs.getString("sender_email"));
            row.put("subject", msgRs.getString("subject"));
            row.put("message_category", msgRs.getString("message_category"));
            row.put("response_code", msgRs.getString("response_code"));
            row.put("sent_at", msgRs.getString("sent_at"));
            messages.add(row);
        }
        msgRs.close();
        msgStmt.close();

        // --- Load latest cert ---
        Map<String, String> latestCert = null;
        Statement certStmt = conn.createStatement();
        ResultSet certRs = certStmt.executeQuery("SELECT * FROM site_public_keys WHERE host = '" + targetHost + "' ORDER BY fetched_at DESC LIMIT 1");
        if (certRs.next()) {
            latestCert = new LinkedHashMap<>();
            latestCert.put("subject_dn", certRs.getString("subject_dn"));
            latestCert.put("issuer_dn", certRs.getString("issuer_dn"));
            latestCert.put("serial_number", certRs.getString("serial_number"));
            latestCert.put("sig_algorithm", certRs.getString("sig_algorithm"));
            latestCert.put("public_key_algorithm", certRs.getString("public_key_algorithm"));
            latestCert.put("public_key_bits", certRs.getString("public_key_bits"));
            latestCert.put("sha256_fingerprint", certRs.getString("sha256_fingerprint"));
            latestCert.put("fetched_at", certRs.getString("fetched_at"));
        }
        certRs.close();
        certStmt.close();
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Contact UNCW — UNCWilmington™</title>
    <link rel="stylesheet" href="css/style.css">
    <link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <style>
        :root {
            --accent: #00838F;
            --accent-gold: #C8A415;
            --bg-dark: #0d1117;
            --bg-card: #161b22;
            --bg-input: #0d1117;
            --border: #30363d;
            --text: #e6edf3;
            --text-muted: #8b949e;
            --success: #2ea043;
            --warning: #d29922;
        }
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'IBM Plex Sans', sans-serif; background: var(--bg-dark); color: var(--text); min-height: 100vh; }

        /* Navigation */
        .navbar { background: var(--bg-card); border-bottom: 1px solid var(--border); padding: 1rem 2rem; display: flex; align-items: center; justify-content: space-between; }
        .nav-brand { font-size: 1.4rem; font-weight: 700; color: var(--accent); text-decoration: none; }
        .nav-brand:hover { color: var(--accent-gold); }
        .nav-links { display: flex; gap: 1.5rem; }
        .nav-links a { color: var(--text-muted); text-decoration: none; font-weight: 500; transition: color 0.2s; }
        .nav-links a:hover, .nav-links a.active { color: var(--accent-gold); }

        /* Hero */
        .hero { background: linear-gradient(135deg, #00838F22, #C8A41522); border-bottom: 1px solid var(--border); padding: 3rem 2rem; text-align: center; }
        .hero-tag { color: var(--accent); font-size: 0.85rem; font-weight: 600; text-transform: uppercase; letter-spacing: 2px; margin-bottom: 0.5rem; }
        .hero h1 { font-size: 2.2rem; font-weight: 700; margin-bottom: 0.75rem; }
        .hero p { color: var(--text-muted); max-width: 650px; margin: 0 auto; line-height: 1.6; }

        /* Container */
        .container { max-width: 1100px; margin: 2rem auto; padding: 0 2rem; }

        /* Status */
        .status { padding: 1rem 1.5rem; border-radius: 8px; margin-bottom: 2rem; font-weight: 500; }
        .status.success { background: #2ea04322; border: 1px solid var(--success); color: var(--success); }
        .status.warning { background: #d2992222; border: 1px solid var(--warning); color: var(--warning); }

        /* Form */
        .form-card { background: var(--bg-card); border: 1px solid var(--border); border-radius: 12px; padding: 2rem; margin-bottom: 2rem; }
        .form-card h2 { font-size: 1.3rem; margin-bottom: 1.5rem; color: var(--accent-gold); }
        .form-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; }
        .form-group { display: flex; flex-direction: column; gap: 0.4rem; }
        .form-group.full { grid-column: 1 / -1; }
        .form-group label { font-size: 0.85rem; font-weight: 600; color: var(--text-muted); text-transform: uppercase; letter-spacing: 0.5px; }
        .form-group input, .form-group select, .form-group textarea {
            background: var(--bg-input); border: 1px solid var(--border); border-radius: 6px;
            padding: 0.75rem 1rem; color: var(--text); font-family: inherit; font-size: 0.95rem;
            transition: border-color 0.2s;
        }
        .form-group input:focus, .form-group select:focus, .form-group textarea:focus {
            outline: none; border-color: var(--accent);
        }
        .form-group textarea { min-height: 140px; resize: vertical; }
        .btn-submit {
            background: var(--accent); color: #fff; border: none; border-radius: 6px;
            padding: 0.85rem 2rem; font-size: 1rem; font-weight: 600; cursor: pointer;
            margin-top: 1rem; transition: background 0.2s;
        }
        .btn-submit:hover { background: var(--accent-gold); }

        /* Tables */
        .section-card { background: var(--bg-card); border: 1px solid var(--border); border-radius: 12px; padding: 2rem; margin-bottom: 2rem; }
        .section-card h2 { font-size: 1.3rem; margin-bottom: 1rem; color: var(--accent-gold); }
        table { width: 100%; border-collapse: collapse; font-size: 0.85rem; }
        th { text-align: left; padding: 0.6rem 0.75rem; border-bottom: 2px solid var(--border); color: var(--accent); font-weight: 600; text-transform: uppercase; letter-spacing: 0.5px; font-size: 0.75rem; }
        td { padding: 0.6rem 0.75rem; border-bottom: 1px solid var(--border); color: var(--text-muted); }
        tr:hover td { color: var(--text); }
        .code-val { color: var(--success); font-weight: 600; }
        .code-err { color: #f85149; font-weight: 600; }

        /* Cert info */
        .cert-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 0.75rem; }
        .cert-item { padding: 0.75rem 1rem; background: var(--bg-input); border-radius: 6px; border: 1px solid var(--border); }
        .cert-item .cert-label { font-size: 0.7rem; text-transform: uppercase; letter-spacing: 1px; color: var(--accent); font-weight: 600; margin-bottom: 0.25rem; }
        .cert-item .cert-value { font-size: 0.85rem; color: var(--text); word-break: break-all; }
        .cert-item.full { grid-column: 1 / -1; }

        /* Footer */
        .footer { text-align: center; padding: 2rem; color: var(--text-muted); font-size: 0.85rem; border-top: 1px solid var(--border); margin-top: 3rem; }

        @media (max-width: 768px) {
            .form-grid { grid-template-columns: 1fr; }
            .cert-grid { grid-template-columns: 1fr; }
            .navbar { flex-direction: column; gap: 1rem; }
        }
    </style>
</head>
<body>

<!-- Navigation -->
<nav class="navbar">
    <a href="index.jsp" class="nav-brand">UNCWilmington&#8482;</a>
    <div class="nav-links">
        <a href="index.jsp">Overview</a>
        <a href="contact.jsp" class="active">Contact</a>
        <a href="messaging.jsp">Messages</a>
        <a href="profile.jsp">Profile</a>
    </div>
</nav>

<!-- Hero -->
<section class="hero">
    <div class="hero-tag">University of North Carolina Wilmington</div>
    <h1>Contact UNCW</h1>
    <p>Contact UNC Wilmington for admissions, Computer Science programs, marine science, campus life, or general university inquiries.</p>
</section>

<!-- Main Content -->
<div class="container">

    <% if (!statusMsg.isEmpty()) { %>
    <div class="status <%= statusType %>"><%= esc(statusMsg) %></div>
    <% } %>

    <!-- Contact Form -->
    <div class="form-card">
        <h2>Send a Message</h2>
        <form method="POST" action="contact.jsp">
            <div class="form-grid">
                <div class="form-group">
                    <label for="sender_name">Your Name</label>
                    <input type="text" id="sender_name" name="sender_name" required placeholder="Full name">
                </div>
                <div class="form-group">
                    <label for="sender_email">Your Email</label>
                    <input type="email" id="sender_email" name="sender_email" required placeholder="you@example.com">
                </div>
                <div class="form-group">
                    <label for="subject">Subject</label>
                    <input type="text" id="subject" name="subject" required placeholder="Message subject">
                </div>
                <div class="form-group">
                    <label for="message_category">Category</label>
                    <select id="message_category" name="message_category" required>
                        <option value="">— Select Category —</option>
                        <option value="Admissions">Admissions</option>
                        <option value="Computer Science">Computer Science</option>
                        <option value="Marine Science">Marine Science</option>
                        <option value="Cameron School of Business">Cameron School of Business</option>
                        <option value="College of Arts & Sciences">College of Arts &amp; Sciences</option>
                        <option value="Student Affairs">Student Affairs</option>
                        <option value="Financial Aid">Financial Aid</option>
                        <option value="Chancellor's Office">Chancellor's Office</option>
                        <option value="General Inquiry">General Inquiry</option>
                    </select>
                </div>
                <div class="form-group full">
                    <label for="message_body">Message</label>
                    <textarea id="message_body" name="message_body" required placeholder="Write your message here..."></textarea>
                </div>
            </div>
            <button type="submit" class="btn-submit">Send Message</button>
        </form>
    </div>

    <!-- Recent Messages -->
    <div class="section-card">
        <h2>Recent Outbound Messages</h2>
        <% if (messages.isEmpty()) { %>
            <p style="color: var(--text-muted);">No messages sent yet.</p>
        <% } else { %>
        <div style="overflow-x: auto;">
            <table>
                <thead>
                    <tr>
                        <th>#</th>
                        <th>Sender</th>
                        <th>Subject</th>
                        <th>Category</th>
                        <th>Response</th>
                        <th>Sent</th>
                    </tr>
                </thead>
                <tbody>
                <% for (Map<String, String> msg : messages) { %>
                    <tr>
                        <td><%= esc(msg.get("id")) %></td>
                        <td><%= esc(msg.get("sender_name")) %></td>
                        <td><%= esc(truncate(msg.get("subject"), 40)) %></td>
                        <td><%= esc(msg.get("message_category")) %></td>
                        <td>
                            <% String code = msg.get("response_code");
                               int rc = 0; try { rc = Integer.parseInt(code); } catch(Exception e) {}
                               if (rc >= 200 && rc < 400) { %>
                                <span class="code-val"><%= code %></span>
                            <% } else { %>
                                <span class="code-err"><%= code %></span>
                            <% } %>
                        </td>
                        <td><%= esc(msg.get("sent_at")) %></td>
                    </tr>
                <% } %>
                </tbody>
            </table>
        </div>
        <% } %>
    </div>

    <!-- SSL Certificate Info -->
    <div class="section-card">
        <h2>SSL/TLS Certificate — <%= esc(targetHost) %></h2>
        <% if (latestCert == null) { %>
            <p style="color: var(--text-muted);">No certificate data available.</p>
        <% } else { %>
        <div class="cert-grid">
            <div class="cert-item full">
                <div class="cert-label">Subject</div>
                <div class="cert-value"><%= esc(latestCert.get("subject_dn")) %></div>
            </div>
            <div class="cert-item full">
                <div class="cert-label">Issuer</div>
                <div class="cert-value"><%= esc(latestCert.get("issuer_dn")) %></div>
            </div>
            <div class="cert-item">
                <div class="cert-label">Serial Number</div>
                <div class="cert-value"><%= esc(latestCert.get("serial_number")) %></div>
            </div>
            <div class="cert-item">
                <div class="cert-label">Signature Algorithm</div>
                <div class="cert-value"><%= esc(latestCert.get("sig_algorithm")) %></div>
            </div>
            <div class="cert-item">
                <div class="cert-label">Public Key Algorithm</div>
                <div class="cert-value"><%= esc(latestCert.get("public_key_algorithm")) %></div>
            </div>
            <div class="cert-item">
                <div class="cert-label">Key Size (bits)</div>
                <div class="cert-value"><%= esc(latestCert.get("public_key_bits")) %></div>
            </div>
            <div class="cert-item full">
                <div class="cert-label">SHA-256 Fingerprint</div>
                <div class="cert-value"><%= esc(latestCert.get("sha256_fingerprint")) %></div>
            </div>
            <div class="cert-item">
                <div class="cert-label">Fetched At</div>
                <div class="cert-value"><%= esc(latestCert.get("fetched_at")) %></div>
            </div>
        </div>
        <% } %>
    </div>

</div>

<!-- Footer -->
<div class="footer">
    &copy; 2026 MEARVK LLC. UNCWilmington&#8482; &mdash; Teal &amp; Gold.
</div>

</body>
</html>
<%
    } catch (Exception e) {
        out.println("<div style='color:#f85149;padding:2rem;font-family:monospace;'>Error: " + esc(e.getMessage()) + "</div>");
    } finally {
        if (conn != null) try { conn.close(); } catch (Exception e) {}
    }
%>
