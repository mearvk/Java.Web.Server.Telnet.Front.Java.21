<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.Properties, java.io.*" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/>
    <link rel="preconnect" href="https://fonts.googleapis.com"/><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin/><link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:ital,wght@0,300;0,400;0,500;0,600;0,700;1,400;1,600&display=swap" rel="stylesheet"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>Sent — AE6E66™</title>
    <link rel="stylesheet" href="css/style.css"/>
<script src="js/scroll-preserve.js"></script>
    <script src="js/nwe-readme-viewer.js"></script>
</head>
<body>
<nav class="nav"><div class="nav-inner">
    <span class="nav-brand">AE6E66™</span>
    <ul class="nav-links">
        <li><a href="index.jsp">Overview</a></li>
        <li><a href="contacts.jsp">Contacts</a></li>
        <li><a href="sent.jsp" class="active">Sent</a></li>
        <li><a href="status.jsp">Status</a></li>
    </ul>
    <div class="nav-actions"><a href="crawl.jsp" class="nav-cta">Crawl</a></div>
</div></nav>

<section class="hero" style="padding:4rem 2rem;">
    <div class="hero-inner">
        <span class="hero-tag">Distribution Archive</span>
        <h1>Sent Messages</h1>
        <p>DKIM-signed messages with SHA-256 receipts.</p>
    </div>
</section>

<section class="section">
    <div class="section-inner">
<%
    Properties dbProps = new Properties();
    boolean propsLoaded = false;
    Connection conn = null;
    try {
        InputStream dbIn = application.getResourceAsStream("/WEB-INF/db.properties");
        if (dbIn != null) { dbProps.load(dbIn); dbIn.close(); propsLoaded = true; }
        if (!propsLoaded) {
            File f = new File("/opt/tomcat/webapps/ae6e66/WEB-INF/db.properties");
            if (f.exists()) { FileInputStream fis = new FileInputStream(f); dbProps.load(fis); fis.close(); propsLoaded = true; }
        }
        Class.forName(dbProps.getProperty("db.driver", "com.mysql.cj.jdbc.Driver"));
        conn = DriverManager.getConnection(
            dbProps.getProperty("db.url", "jdbc:mysql://127.0.0.1:3306/nwe_ae6e66"),
            dbProps.getProperty("db.user", "root"),
            dbProps.getProperty("db.password", ""));

        ResultSet rs = conn.createStatement().executeQuery(
            "SELECT id, recipient, sha256, status, sent_at FROM sent_log ORDER BY sent_at DESC LIMIT 100");
%>
        <div class="table-wrap">
            <table>
                <thead><tr><th>ID</th><th>Recipient</th><th>SHA-256</th><th>Status</th><th>Sent</th></tr></thead>
                <tbody>
<%
        boolean hasRows = false;
        while (rs.next()) {
            hasRows = true;
            String sha = rs.getString("sha256");
%>
                    <tr>
                        <td><%= rs.getInt("id") %></td>
                        <td><%= rs.getString("recipient") != null ? rs.getString("recipient") : "" %></td>
                        <td><code style="font-size:0.7rem;"><%= sha != null ? sha.substring(0, Math.min(16, sha.length())) + "…" : "—" %></code></td>
                        <td style="color:<%= "success".equals(rs.getString("status")) ? "#22c55e" : "#ef4444" %>;"><%= rs.getString("status") %></td>
                        <td><%= rs.getTimestamp("sent_at") %></td>
                    </tr>
<%      }
        if (!hasRows) { %>
                    <tr><td colspan="5" style="text-align:center;color:var(--text-muted);">No messages sent yet. Draft a .txt in marrister/ and run the module.</td></tr>
<%      }
        rs.close();
    } catch (Exception e) {
%>
        <p style="color:#ef4444;">Database error: <%= e.getMessage() != null ? e.getMessage().replace("<","&lt;") : "unknown" %></p>
<%
    } finally {
        if (conn != null) try { conn.close(); } catch (Exception ignored) {}
    }
%>
                </tbody>
            </table>
        </div>
    </div>
</section>

<footer class="footer"><div><span>&#169; 2026 MEARVK LLC. All rights reserved.</span></div></footer>
</body>
</html>
