<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.Properties, java.io.*" %>
<%
    if (session.getAttribute("admin") == null) { response.sendRedirect("login.jsp"); return; }
    String admin = (String) session.getAttribute("admin");

    // DB stats
    String dbStatus = "Offline"; String reportCount = "?"; String queryCount = "?";
    try {
        Properties p = new Properties();
        try (InputStream is = application.getResourceAsStream("/WEB-INF/db.properties")) { if (is != null) p.load(is); }
        Class.forName(p.getProperty("db.driver", "com.mysql.cj.jdbc.Driver"));
        try (Connection conn = DriverManager.getConnection(p.getProperty("db.url", "jdbc:mysql://127.0.0.1:3306/BrarnerScience"), p.getProperty("db.user", "root"), p.getProperty("db.password", ""))) {
            dbStatus = "Online";
            try (ResultSet rs = conn.createStatement().executeQuery("SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='BrarnerScience'")) {
                if (rs.next()) reportCount = rs.getInt(1) + " tables";
            }
        }
    } catch (Exception e) { dbStatus = "Error"; }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/>
    <link rel="preconnect" href="https://fonts.googleapis.com"/><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin/><link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:ital,wght@0,300;0,400;0,500;0,600;0,700;1,400;1,600&display=swap" rel="stylesheet"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>Admin Dashboard — Brarner.M.Alete™</title>
    <link rel="stylesheet" href="../css/style.css"/>
<script src="../js/scroll-preserve.js"></script>
</head>
<body>
<nav class="nav"><div class="nav-inner">
    <a href="../index.jsp" class="nav-brand">Brarner.M.Alete™</a>
    <ul class="nav-links">
        <li><a href="../index.jsp">Overview</a></li>
        <li><a href="../species.jsp">Species</a></li>
        <li><a href="../status.jsp">Status</a></li>
    </ul>
    <div class="nav-actions">
        <span style="font-size:0.8rem;color:var(--text-muted);">Admin: <%= admin %></span>
        <a href="logout.jsp" class="nav-cta">Logout</a>
    </div>
</div></nav>

<section class="hero" style="padding:4rem 2rem;">
    <div class="hero-inner">
        <span class="hero-tag">Admin Dashboard</span>
        <h1>Brarner.M.Alete™</h1>
    </div>
</section>

<section class="section">
    <div class="section-inner">
        <h2>System Status</h2>
        <div class="table-wrap"><table><thead><tr><th>Component</th><th>Status</th></tr></thead><tbody>
            <tr><td>Database (BrarnerScience)</td><td style="color:<%= "Online".equals(dbStatus) ? "#22c55e" : "#ef4444" %>;"><%= dbStatus %> — <%= reportCount %></td></tr>
            <tr><td>Admin Session</td><td style="color:#22c55e;">Active — <%= admin %></td></tr>
            <tr><td>Servlet Container</td><td style="color:#22c55e;"><%= application.getServerInfo() %></td></tr>
            <tr><td>JVM</td><td><%= System.getProperty("java.version") %></td></tr>
        </tbody></table></div>
    </div>
</section>

<section class="section">
    <div class="section-inner">
        <h2>Quick Actions</h2>
        <div style="display:flex;gap:1rem;flex-wrap:wrap;">
            <a href="../species.jsp" class="btn btn-primary">Species Browser</a>
            <a href="../status.jsp" class="btn btn-primary">Health Check</a>
            <a href="documents.jsp" class="btn btn-primary">Documents</a>
            <a href="logout.jsp" class="btn btn-ghost">Logout</a>
        </div>
    </div>
</section>

<footer class="footer"><div><span>&#169; 2026 MEARVK LLC. All rights reserved.</span></div></footer>
</body>
</html>
