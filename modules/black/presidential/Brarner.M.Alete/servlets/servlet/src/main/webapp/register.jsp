<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.Properties, java.io.*, java.nio.file.*" %>
<%
    String message = null;
    String messageColor = "#ef4444";
    String clientIp = request.getHeader("X-Forwarded-For");
    if (clientIp == null || clientIp.isEmpty()) clientIp = request.getRemoteAddr();

    // Handle multipart form submission
    if ("POST".equalsIgnoreCase(request.getMethod()) && request.getContentType() != null && request.getContentType().contains("multipart")) {
        String displayName = "";
        byte[] keyData = null;
        String keyFilename = "";

        // Use Part API (Servlet 6.0 / Jakarta)
        try {
            displayName = request.getParameter("display_name");
            jakarta.servlet.http.Part filePart = request.getPart("auth_key");
            if (filePart != null && filePart.getSize() > 0) {
                // Validate file size (max 1MB for a key file)
                if (filePart.getSize() > 1048576) {
                    message = "Key file too large (max 1MB).";
                } else {
                    // Sanitize filename: strip path, allow only safe characters
                    String rawName = filePart.getSubmittedFileName();
                    keyFilename = Paths.get(rawName).getFileName().toString()
                        .replaceAll("[^a-zA-Z0-9._\\-]", "_");
                    // Validate extension
                    String ext = keyFilename.contains(".") ? keyFilename.substring(keyFilename.lastIndexOf('.') + 1).toLowerCase() : "";
                    if (!ext.matches("key|pem|pub|txt|crt|der")) {
                        message = "Invalid file type. Allowed: .key, .pem, .pub, .txt, .crt, .der";
                        keyFilename = "";
                    } else {
                        // Read bytes safely
                        InputStream fis = filePart.getInputStream();
                        keyData = fis.readAllBytes();
                        fis.close();
                    }
                }
            }
        } catch (Exception pe) {
            message = "Upload error: " + (pe.getMessage() != null ? pe.getMessage().replace("<","&lt;") : "unknown");
        }

        if (displayName == null || displayName.trim().isEmpty()) {
            displayName = "";
        }
        // Sanitize display name (max 100 chars, strip HTML)
        displayName = displayName.trim();
        if (displayName.length() > 100) displayName = displayName.substring(0, 100);
        displayName = displayName.replaceAll("<[^>]*>", "");

        if (message == null && !displayName.isEmpty()) {
            // Save registration
            Properties dbProps = new Properties();
            InputStream dbIn = application.getResourceAsStream("/WEB-INF/db.properties");
            if (dbIn != null) { dbProps.load(dbIn); dbIn.close(); }
            else {
                String[] tryPaths = { "/opt/tomcat/webapps/brarner.m.alete/WEB-INF/db.properties" };
                for (String tp : tryPaths) { File f = new File(tp);
                    if (f.exists()) { FileInputStream fi = new FileInputStream(f); dbProps.load(fi); fi.close(); break; } }
            }

            Connection conn = null;
            try {
                Class.forName(dbProps.getProperty("db.driver", "com.mysql.cj.jdbc.Driver"));
                conn = DriverManager.getConnection(
                    dbProps.getProperty("db.url", "jdbc:mysql://127.0.0.1:3306/BrarnerScience"),
                    dbProps.getProperty("db.user", "root"),
                    dbProps.getProperty("db.password", ""));

                // Create table if not exists
                conn.createStatement().executeUpdate(
                    "CREATE TABLE IF NOT EXISTS registrations (" +
                    "id INT AUTO_INCREMENT PRIMARY KEY, " +
                    "display_name VARCHAR(255) NOT NULL, " +
                    "ip_address VARCHAR(45) NOT NULL, " +
                    "auth_key MEDIUMBLOB, " +
                    "key_filename VARCHAR(255), " +
                    "key_sha256 CHAR(64), " +
                    "authorized BOOLEAN DEFAULT FALSE, " +
                    "registered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)");

                // Compute SHA-256 of key if present
                String keySha256 = null;
                if (keyData != null) {
                    java.security.MessageDigest md = java.security.MessageDigest.getInstance("SHA-256");
                    byte[] hash = md.digest(keyData);
                    StringBuilder sb = new StringBuilder();
                    for (byte b : hash) sb.append(String.format("%02x", b));
                    keySha256 = sb.toString();
                }

                PreparedStatement ps = conn.prepareStatement(
                    "INSERT INTO registrations (display_name, ip_address, auth_key, key_filename, key_sha256, authorized) VALUES (?, ?, ?, ?, ?, ?)");
                ps.setString(1, displayName.trim());
                ps.setString(2, clientIp);
                if (keyData != null && keyData.length > 0) {
                    ps.setBytes(3, keyData);
                    ps.setString(4, keyFilename);
                    ps.setString(5, keySha256);
                    ps.setBoolean(6, true);
                } else {
                    ps.setNull(3, java.sql.Types.BLOB);
                    ps.setNull(4, java.sql.Types.VARCHAR);
                    ps.setNull(5, java.sql.Types.VARCHAR);
                    ps.setBoolean(6, false);
                }
                ps.executeUpdate();
                ps.close();

                message = "Registered successfully as \"" + displayName.trim() + "\" (IP: " + clientIp + ")" + (keyData != null ? " — Key uploaded, authorized for private work." : "");
                messageColor = "#22c55e";
            } catch (Exception e) {
                message = "Registration error: " + (e.getMessage() != null ? e.getMessage().replace("<","&lt;") : "unknown");
            } finally {
                if (conn != null) try { conn.close(); } catch (Exception ignored) {}
            }
        } else if (message == null) {
            message = "Display name is required.";
        }
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <link rel="icon" type="image/png" href="images/favicon.png"/>
    <title>Register — Brarner.M.Alete™</title>
    <link rel="stylesheet" href="css/style.css"/>
</head>
<body>
<nav class="nav"><div class="nav-inner">
    <a href="index.jsp" class="nav-brand"><img src="images/mearvk.ltd.logo.left.png" alt="" style="height:40px;vertical-align:middle;margin-right:8px;background:transparent;"/>Brarner.M.Alete™<img src="images/mearvk.ltd.logo.right.png" alt="" style="height:40px;vertical-align:middle;margin-left:8px;background:transparent;"/></a>
    <ul class="nav-links">
        <li><a href="index.jsp">Overview</a></li>
        <li><a href="species.jsp">Species</a></li>
        <li><a href="postal.jsp">Postal</a></li>
        <li><a href="art.jsp">Art</a></li>
        <li><a href="science.jsp">Science</a></li>
        <li><a href="status.jsp">Status</a></li>
    </ul>
    <div class="nav-actions">
        <a href="guest.jsp" class="nav-cta">Guest</a>
        <span class="nav-cta" style="opacity:0.7;cursor:default;">Register</span>
        <a href="admin/login.xhtml" class="nav-cta">Admin →</a>
    </div>
</div></nav>

<section class="hero" style="padding:4rem 2rem;">
    <div class="hero-inner">
        <span class="hero-tag">Account Registration</span>
        <h1>Register</h1>
        <p>Register your identity. Upload an authorization key for private work access.</p>
    </div>
</section>

<section class="section">
    <div class="section-inner" style="max-width:520px;">
<% if (message != null) { %>
        <div style="padding:1rem;border:1px solid <%= messageColor %>;border-radius:8px;margin-bottom:1.5rem;background:rgba(0,0,0,0.2);">
            <p style="color:<%= messageColor %>;margin:0;font-size:0.9rem;"><%= message %></p>
        </div>
<% } %>
        <form method="post" enctype="multipart/form-data" action="register.jsp">
            <div style="margin-bottom:1.25rem;">
                <label style="display:block;font-size:0.8rem;color:#a1a1aa;margin-bottom:0.35rem;">Display Name *</label>
                <input type="text" name="display_name" required placeholder="Your name or handle" style="width:100%;padding:0.6rem 0.75rem;background:#1a1a24;border:1px solid #27272a;border-radius:8px;color:#fff;font-size:0.9rem;"/>
            </div>
            <div style="margin-bottom:1.25rem;">
                <label style="display:block;font-size:0.8rem;color:#a1a1aa;margin-bottom:0.35rem;">Your IP Address</label>
                <input type="text" value="<%= clientIp %>" readonly style="width:100%;padding:0.6rem 0.75rem;background:#0a0a0f;border:1px solid #27272a;border-radius:8px;color:#71717a;font-size:0.9rem;"/>
            </div>
            <div style="margin-bottom:1.25rem;">
                <label style="display:block;font-size:0.8rem;color:#a1a1aa;margin-bottom:0.35rem;">Authorization Key (file upload, optional)</label>
                <input type="file" name="auth_key" accept=".key,.pem,.pub,.txt" style="width:100%;padding:0.5rem;background:#1a1a24;border:1px solid #27272a;border-radius:8px;color:#a1a1aa;font-size:0.85rem;"/>
                <p style="font-size:0.75rem;color:#71717a;margin-top:0.35rem;">Upload your public.key or authorization key for private work access. Without a key, you register as a public guest.</p>
            </div>
            <button type="submit" style="width:100%;padding:0.7rem;background:#3b82f6;color:#fff;border:none;border-radius:8px;font-size:0.9rem;font-weight:600;cursor:pointer;">Register</button>
        </form>
    </div>
</section>

<footer class="footer"><div class="footer-bottom" style="border:none;padding:0;">
    <span>&#169; 2026 MEARVK LLC. All rights reserved.</span>
</div></footer>
</body>
</html>
