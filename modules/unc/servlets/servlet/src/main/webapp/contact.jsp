<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.*, java.io.*, java.net.*, javax.net.ssl.*, java.security.cert.X509Certificate" %>
<%!
    static String esc(String s) { if (s == null) return ""; return s.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;"); }
    static String truncate(String s, int max) { if (s == null) return ""; return s.length() > max ? s.substring(0, max) + "..." : s; }
%>
<%
    String dbUrl = "jdbc:mysql://127.0.0.1:3306/nwe_unc";
    String dbUser = "root";
    String dbPass = "";
    String targetHost = "www.unc.edu";
    int targetPort = 443;
    String targetSubmitUrl = "https://www.unc.edu/contact/";

    Connection conn = null;
    String statusMsg = "";
    String statusType = "";

    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        conn = DriverManager.getConnection(dbUrl, dbUser, dbPass);

        // Auto-create tables
        Statement setup = conn.createStatement();
        setup.executeUpdate("CREATE TABLE IF NOT EXISTS site_public_keys ("
            + "id INT AUTO_INCREMENT PRIMARY KEY, "
            + "host VARCHAR(255) NOT NULL, "
            + "port INT NOT NULL DEFAULT 443, "
            + "subject_dn TEXT, "
            + "issuer_dn TEXT, "
            + "serial_number VARCHAR(255), "
            + "not_before DATETIME, "
            + "not_after DATETIME, "
            + "sig_algorithm VARCHAR(128), "
            + "public_key_algorithm VARCHAR(64), "
            + "public_key_size INT, "
            + "sha256_fingerprint VARCHAR(128), "
            + "pem_encoded TEXT, "
            + "fetched_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP"
            + ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");

        setup.executeUpdate("CREATE TABLE IF NOT EXISTS outbound_messages ("
            + "id INT AUTO_INCREMENT PRIMARY KEY, "
            + "sender_name VARCHAR(255), "
            + "sender_email VARCHAR(255), "
            + "subject VARCHAR(500), "
            + "message_category VARCHAR(128), "
            + "message_body TEXT, "
            + "target_url VARCHAR(1024), "
            + "http_response_code INT, "
            + "http_response_body TEXT, "
            + "sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP"
            + ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4");
        setup.close();

        // --- TLS Certificate Fetch on GET ---
        if ("GET".equalsIgnoreCase(request.getMethod())) {
            try {
                SSLContext ctx = SSLContext.getInstance("TLS");
                TrustManager[] trustAll = new TrustManager[]{ new X509TrustManager() {
                    public X509Certificate[] getAcceptedIssuers() { return null; }
                    public void checkClientTrusted(X509Certificate[] c, String a) {}
                    public void checkServerTrusted(X509Certificate[] c, String a) {}
                }};
                ctx.init(null, trustAll, new java.security.SecureRandom());
                SSLSocketFactory sf = ctx.getSocketFactory();
                SSLSocket sock = (SSLSocket) sf.createSocket(targetHost, targetPort);
                sock.startHandshake();
                Certificate[] certs = sock.getSession().getPeerCertificates();
                sock.close();

                if (certs != null && certs.length > 0 && certs[0] instanceof X509Certificate) {
                    X509Certificate x509 = (X509Certificate) certs[0];
                    String subjectDN = x509.getSubjectX500Principal().getName();
                    String issuerDN = x509.getIssuerX500Principal().getName();
                    String serial = x509.getSerialNumber().toString(16);
                    java.util.Date notBefore = x509.getNotBefore();
                    java.util.Date notAfter = x509.getNotAfter();
                    String sigAlg = x509.getSigAlgName();
                    String pubKeyAlg = x509.getPublicKey().getAlgorithm();
                    int keySize = 0;
                    if (x509.getPublicKey() instanceof java.security.interfaces.RSAPublicKey) {
                        keySize = ((java.security.interfaces.RSAPublicKey) x509.getPublicKey()).getModulus().bitLength();
                    } else if (x509.getPublicKey() instanceof java.security.interfaces.ECPublicKey) {
                        keySize = ((java.security.interfaces.ECPublicKey) x509.getPublicKey()).getParams().getOrder().bitLength();
                    }

                    // SHA-256 fingerprint
                    java.security.MessageDigest md = java.security.MessageDigest.getInstance("SHA-256");
                    byte[] digest = md.digest(x509.getEncoded());
                    StringBuilder fp = new StringBuilder();
                    for (int i = 0; i < digest.length; i++) {
                        if (i > 0) fp.append(":");
                        fp.append(String.format("%02X", digest[i]));
                    }

                    // PEM encode
                    String pem = "-----BEGIN CERTIFICATE-----\n"
                        + java.util.Base64.getMimeEncoder(64, "\n".getBytes()).encodeToString(x509.getEncoded())
                        + "\n-----END CERTIFICATE-----";

                    PreparedStatement ps = conn.prepareStatement(
                        "INSERT INTO site_public_keys (host, port, subject_dn, issuer_dn, serial_number, "
                        + "not_before, not_after, sig_algorithm, public_key_algorithm, public_key_size, "
                        + "sha256_fingerprint, pem_encoded) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)");
                    ps.setString(1, targetHost);
                    ps.setInt(2, targetPort);
                    ps.setString(3, subjectDN);
                    ps.setString(4, issuerDN);
                    ps.setString(5, serial);
                    ps.setTimestamp(6, new Timestamp(notBefore.getTime()));
                    ps.setTimestamp(7, new Timestamp(notAfter.getTime()));
                    ps.setString(8, sigAlg);
                    ps.setString(9, pubKeyAlg);
                    ps.setInt(10, keySize);
                    ps.setString(11, fp.toString());
                    ps.setString(12, pem);
                    ps.executeUpdate();
                    ps.close();
                }
            } catch (Exception tlsEx) {
                // TLS fetch is best-effort; don't block page render
            }
        }

        // --- Handle POST: store message and attempt delivery ---
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
                    SSLContext ctx2 = SSLContext.getInstance("TLS");
                    TrustManager[] trustAll2 = new TrustManager[]{ new X509TrustManager() {
                        public X509Certificate[] getAcceptedIssuers() { return null; }
                        public void checkClientTrusted(X509Certificate[] c, String a) {}
                        public void checkServerTrusted(X509Certificate[] c, String a) {}
                    }};
                    ctx2.init(null, trustAll2, new java.security.SecureRandom());
                    ((HttpsURLConnection) hc).setSSLSocketFactory(ctx2.getSocketFactory());
                }
                hc.setRequestMethod("POST");
                hc.setDoOutput(true);
                hc.setConnectTimeout(10000);
                hc.setReadTimeout(10000);
                hc.setRequestProperty("Content-Type", "application/x-www-form-urlencoded");
                hc.setRequestProperty("User-Agent", "NWE-UNC-Contact/1.0");

                String postData = "name=" + URLEncoder.encode(senderName != null ? senderName : "", "UTF-8")
                    + "&email=" + URLEncoder.encode(senderEmail != null ? senderEmail : "", "UTF-8")
                    + "&subject=" + URLEncoder.encode(subject != null ? subject : "", "UTF-8")
                    + "&category=" + URLEncoder.encode(messageCategory != null ? messageCategory : "", "UTF-8")
                    + "&message=" + URLEncoder.encode(messageBody != null ? messageBody : "", "UTF-8");

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
                    char[] buf = new char[1024];
                    int n;
                    while ((n = br.read(buf)) != -1 && sb.length() < 2000) { sb.append(buf, 0, n); }
                    br.close();
                    responseBody = sb.length() > 2000 ? sb.substring(0, 2000) : sb.toString();
                }
                hc.disconnect();
            } catch (Exception httpEx) {
                responseCode = -1;
                responseBody = "Connection failed: " + httpEx.getMessage();
            }

            PreparedStatement ps2 = conn.prepareStatement(
                "INSERT INTO outbound_messages (sender_name, sender_email, subject, message_category, "
                + "message_body, target_url, http_response_code, http_response_body) VALUES (?,?,?,?,?,?,?,?)");
            ps2.setString(1, senderName);
            ps2.setString(2, senderEmail);
            ps2.setString(3, subject);
            ps2.setString(4, messageCategory);
            ps2.setString(5, messageBody);
            ps2.setString(6, targetSubmitUrl);
            ps2.setInt(7, responseCode);
            ps2.setString(8, responseBody);
            ps2.executeUpdate();
            ps2.close();

            statusMsg = "Message stored and delivery attempted. HTTP response: " + responseCode;
            statusType = (responseCode >= 200 && responseCode < 400) ? "success" : "warning";
        }

        // --- Fetch recent messages ---
        List<Map<String, String>> messages = new ArrayList<>();
        Statement msgStmt = conn.createStatement();
        ResultSet msgRs = msgStmt.executeQuery("SELECT * FROM outbound_messages ORDER BY sent_at DESC LIMIT 10");
        while (msgRs.next()) {
            Map<String, String> row = new LinkedHashMap<>();
            row.put("id", String.valueOf(msgRs.getInt("id")));
            row.put("sender_name", msgRs.getString("sender_name"));
            row.put("sender_email", msgRs.getString("sender_email"));
            row.put("subject", msgRs.getString("subject"));
            row.put("message_category", msgRs.getString("message_category"));
            row.put("http_response_code", String.valueOf(msgRs.getInt("http_response_code")));
            row.put("sent_at", msgRs.getString("sent_at"));
            messages.add(row);
        }
        msgRs.close();
        msgStmt.close();

        // --- Fetch latest SSL cert ---
        Map<String, String> latestCert = null;
        Statement certStmt = conn.createStatement();
        ResultSet certRs = certStmt.executeQuery("SELECT * FROM site_public_keys WHERE host='" + targetHost + "' ORDER BY fetched_at DESC LIMIT 1");
        if (certRs.next()) {
            latestCert = new LinkedHashMap<>();
            latestCert.put("subject_dn", certRs.getString("subject_dn"));
            latestCert.put("issuer_dn", certRs.getString("issuer_dn"));
            latestCert.put("serial_number", certRs.getString("serial_number"));
            latestCert.put("not_before", certRs.getString("not_before"));
            latestCert.put("not_after", certRs.getString("not_after"));
            latestCert.put("sig_algorithm", certRs.getString("sig_algorithm"));
            latestCert.put("public_key_algorithm", certRs.getString("public_key_algorithm"));
            latestCert.put("public_key_size", String.valueOf(certRs.getInt("public_key_size")));
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
    <title>Contact — UNCChapelHill™</title>
    <link rel="stylesheet" href="css/style.css">
    <link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <style>
        :root { --accent: #4B9CD3; --accent-hover: #3a8bc2; }
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'IBM Plex Sans', sans-serif; background: #0a0a0a; color: #e0e0e0; min-height: 100vh; }
        a { color: var(--accent); text-decoration: none; }
        a:hover { text-decoration: underline; }

        /* Nav */
        .nav { background: #111; border-bottom: 1px solid #222; padding: 1rem 2rem; display: flex; align-items: center; gap: 2rem; flex-wrap: wrap; }
        .nav-brand { font-size: 1.3rem; font-weight: 700; color: var(--accent); }
        .nav-links { display: flex; gap: 1.5rem; flex-wrap: wrap; }
        .nav-links a { color: #aaa; font-size: 0.9rem; font-weight: 500; transition: color 0.2s; }
        .nav-links a:hover, .nav-links a.active { color: var(--accent); text-decoration: none; }

        /* Hero */
        .hero { background: linear-gradient(135deg, #0d1b2a 0%, #1b2d4a 100%); border-bottom: 2px solid var(--accent); padding: 3rem 2rem; text-align: center; }
        .hero-tag { font-size: 0.8rem; text-transform: uppercase; letter-spacing: 2px; color: var(--accent); margin-bottom: 0.5rem; }
        .hero-title { font-size: 2.2rem; font-weight: 700; color: #fff; margin-bottom: 0.75rem; }
        .hero-desc { font-size: 1rem; color: #aaa; max-width: 700px; margin: 0 auto; line-height: 1.6; }

        /* Container */
        .container { max-width: 1100px; margin: 2rem auto; padding: 0 2rem; }

        /* Status */
        .status-msg { padding: 1rem 1.5rem; border-radius: 8px; margin-bottom: 2rem; font-size: 0.9rem; }
        .status-msg.success { background: rgba(75, 156, 211, 0.15); border: 1px solid var(--accent); color: var(--accent); }
        .status-msg.warning { background: rgba(255, 193, 7, 0.1); border: 1px solid #ffc107; color: #ffc107; }

        /* Form */
        .form-section { background: #111; border: 1px solid #222; border-radius: 10px; padding: 2rem; margin-bottom: 2rem; }
        .form-section h2 { font-size: 1.3rem; color: var(--accent); margin-bottom: 1.5rem; }
        .form-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 1rem; }
        .form-grid .full-width { grid-column: 1 / -1; }
        label { display: block; font-size: 0.85rem; color: #888; margin-bottom: 0.3rem; font-weight: 500; }
        input, select, textarea { width: 100%; padding: 0.7rem 1rem; background: #0a0a0a; border: 1px solid #333; border-radius: 6px; color: #e0e0e0; font-family: inherit; font-size: 0.9rem; transition: border-color 0.2s; }
        input:focus, select:focus, textarea:focus { outline: none; border-color: var(--accent); }
        textarea { resize: vertical; min-height: 120px; }
        .btn-submit { grid-column: 1 / -1; padding: 0.8rem 2rem; background: var(--accent); color: #fff; border: none; border-radius: 6px; font-size: 1rem; font-weight: 600; cursor: pointer; transition: background 0.2s; }
        .btn-submit:hover { background: var(--accent-hover); }

        /* Tables */
        .section { background: #111; border: 1px solid #222; border-radius: 10px; padding: 2rem; margin-bottom: 2rem; }
        .section h2 { font-size: 1.3rem; color: var(--accent); margin-bottom: 1rem; }
        table { width: 100%; border-collapse: collapse; font-size: 0.85rem; }
        th { text-align: left; padding: 0.6rem 0.8rem; background: #1a1a1a; color: var(--accent); border-bottom: 1px solid #333; font-weight: 600; }
        td { padding: 0.6rem 0.8rem; border-bottom: 1px solid #1a1a1a; color: #ccc; }
        tr:hover td { background: #1a1a1a; }

        /* Cert info */
        .cert-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 0.8rem; }
        .cert-item { padding: 0.6rem; background: #0a0a0a; border: 1px solid #222; border-radius: 6px; }
        .cert-item .cert-label { font-size: 0.75rem; color: #666; text-transform: uppercase; letter-spacing: 1px; }
        .cert-item .cert-value { font-size: 0.85rem; color: #e0e0e0; margin-top: 0.2rem; word-break: break-all; }
        .cert-item.full { grid-column: 1 / -1; }

        /* Footer */
        .footer { text-align: center; padding: 2rem; color: #555; font-size: 0.8rem; border-top: 1px solid #1a1a1a; margin-top: 2rem; }

        /* Responsive */
        @media (max-width: 768px) {
            .form-grid { grid-template-columns: 1fr; }
            .cert-grid { grid-template-columns: 1fr; }
            .nav { padding: 1rem; gap: 1rem; }
        }
    </style>
</head>
<body>
    <nav class="nav">
        <div class="nav-brand">UNCChapelHill&#8482;</div>
        <div class="nav-links">
            <a href="index.jsp">Overview</a>
            <a href="schools.jsp">Schools</a>
            <a href="contact.jsp" class="active">Contact</a>
            <a href="messaging.jsp">Messages</a>
            <a href="status.jsp">Status</a>
        </div>
    </nav>

    <div class="hero">
        <div class="hero-tag">University of North Carolina at Chapel Hill</div>
        <h1 class="hero-title">Contact UNC</h1>
        <p class="hero-desc">Contact UNC Chapel Hill for admissions, academic programs, research collaboration, or general university inquiries.</p>
    </div>

    <div class="container">
        <% if (!statusMsg.isEmpty()) { %>
        <div class="status-msg <%= statusType %>"><%= esc(statusMsg) %></div>
        <% } %>

        <!-- Contact Form -->
        <div class="form-section">
            <h2>Send a Message</h2>
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
                            <option value="">Select a category...</option>
                            <option value="Admissions">Admissions</option>
                            <option value="Academic Programs">Academic Programs</option>
                            <option value="Research Collaboration">Research Collaboration</option>
                            <option value="Student Affairs">Student Affairs</option>
                            <option value="Financial Aid">Financial Aid</option>
                            <option value="Graduate School">Graduate School</option>
                            <option value="Health Affairs">Health Affairs</option>
                            <option value="General Inquiry">General Inquiry</option>
                        </select>
                    </div>
                    <div class="full-width">
                        <label for="message_body">Message</label>
                        <textarea id="message_body" name="message_body" required placeholder="Your message..."></textarea>
                    </div>
                    <button type="submit" class="btn-submit">Send Message</button>
                </div>
            </form>
        </div>

        <!-- Recent Messages -->
        <div class="section">
            <h2>Recent Outbound Messages</h2>
            <% if (messages.isEmpty()) { %>
                <p style="color:#666; font-size:0.9rem;">No messages sent yet.</p>
            <% } else { %>
            <div style="overflow-x:auto;">
            <table>
                <thead>
                    <tr>
                        <th>ID</th>
                        <th>Sender</th>
                        <th>Subject</th>
                        <th>Category</th>
                        <th>HTTP</th>
                        <th>Sent</th>
                    </tr>
                </thead>
                <tbody>
                <% for (Map<String, String> msg : messages) { %>
                    <tr>
                        <td><%= esc(msg.get("id")) %></td>
                        <td><%= esc(truncate(msg.get("sender_name"), 20)) %></td>
                        <td><%= esc(truncate(msg.get("subject"), 30)) %></td>
                        <td><%= esc(msg.get("message_category")) %></td>
                        <td><%= esc(msg.get("http_response_code")) %></td>
                        <td><%= esc(msg.get("sent_at")) %></td>
                    </tr>
                <% } %>
                </tbody>
            </table>
            </div>
            <% } %>
        </div>

        <!-- SSL Certificate Info -->
        <div class="section">
            <h2>TLS Certificate — <%= esc(targetHost) %></h2>
            <% if (latestCert == null) { %>
                <p style="color:#666; font-size:0.9rem;">No certificate data available.</p>
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
                    <div class="cert-label">Algorithm</div>
                    <div class="cert-value"><%= esc(latestCert.get("sig_algorithm")) %></div>
                </div>
                <div class="cert-item">
                    <div class="cert-label">Valid From</div>
                    <div class="cert-value"><%= esc(latestCert.get("not_before")) %></div>
                </div>
                <div class="cert-item">
                    <div class="cert-label">Valid Until</div>
                    <div class="cert-value"><%= esc(latestCert.get("not_after")) %></div>
                </div>
                <div class="cert-item">
                    <div class="cert-label">Public Key</div>
                    <div class="cert-value"><%= esc(latestCert.get("public_key_algorithm")) %> (<%= esc(latestCert.get("public_key_size")) %> bit)</div>
                </div>
                <div class="cert-item">
                    <div class="cert-label">Fetched</div>
                    <div class="cert-value"><%= esc(latestCert.get("fetched_at")) %></div>
                </div>
                <div class="cert-item full">
                    <div class="cert-label">SHA-256 Fingerprint</div>
                    <div class="cert-value" style="font-family:monospace; font-size:0.8rem;"><%= esc(latestCert.get("sha256_fingerprint")) %></div>
                </div>
            </div>
            <% } %>
        </div>
    </div>

    <footer class="footer">
        &copy; 2026 MEARVK LLC. UNCChapelHill&#8482; &mdash; Carolina Blue.
    </footer>
</body>
</html>
<%
    } catch (Exception e) {
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Error — UNCChapelHill™</title>
    <link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:wght@400;600&display=swap" rel="stylesheet">
    <style>
        body { font-family: 'IBM Plex Sans', sans-serif; background: #0a0a0a; color: #e0e0e0; display: flex; justify-content: center; align-items: center; min-height: 100vh; }
        .error-box { background: #111; border: 1px solid #333; border-radius: 10px; padding: 2rem; max-width: 600px; width: 90%; }
        .error-box h1 { color: #e74c3c; font-size: 1.4rem; margin-bottom: 1rem; }
        .error-box pre { background: #0a0a0a; padding: 1rem; border-radius: 6px; overflow-x: auto; font-size: 0.8rem; color: #aaa; }
        .error-box a { color: #4B9CD3; }
    </style>
</head>
<body>
    <div class="error-box">
        <h1>Database Connection Error</h1>
        <p>Could not connect to the UNC module database.</p>
        <pre><%= esc(e.getMessage()) %></pre>
        <p style="margin-top:1rem;"><a href="index.jsp">&larr; Return to Overview</a></p>
    </div>
</body>
</html>
<%
    } finally {
        if (conn != null) try { conn.close(); } catch (Exception ignored) {}
    }
%>
