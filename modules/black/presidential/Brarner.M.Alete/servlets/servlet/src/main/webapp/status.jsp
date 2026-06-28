<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.Properties, java.io.InputStream" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <link rel="icon" type="image/png" href="images/favicon.png"/>
    <title>Status — Brarner.M.Alete™</title>
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
        <li><a href="status.jsp" class="active">Status</a></li>
    </ul>
    <div class="nav-actions"><a href="admin/login.xhtml" class="nav-cta">Admin →</a></div>
</div></nav>

<section class="hero" style="padding:4rem 2rem;">
    <div class="hero-inner">
        <span class="hero-tag">System Health</span>
        <h1>Status</h1>
        <p>Real-time module status and connection health.</p>
    </div>
</section>

<section class="section">
    <div class="section-inner">
        <h3>Database Connectivity</h3>
<%
    Connection conn = null;
    String dbStatus = "Offline";
    String dbVersion = "";
    try {
        Properties dbProps = new Properties();
        InputStream dbIn = application.getResourceAsStream("/WEB-INF/db.properties");
        if (dbIn != null) { dbProps.load(dbIn); dbIn.close(); }
        Class.forName(dbProps.getProperty("db.driver", "com.mysql.cj.jdbc.Driver"));
        conn = DriverManager.getConnection(
            dbProps.getProperty("db.url", "jdbc:mysql://localhost:3306/BrarnerScience"),
            dbProps.getProperty("db.user", "root"),
            dbProps.getProperty("db.password", ""));
        DatabaseMetaData md = conn.getMetaData();
        dbStatus = "Online";
        dbVersion = md.getDatabaseProductName() + " " + md.getDatabaseProductVersion();
    } catch (Exception e) {
        dbStatus = "Error: " + (e.getMessage() != null ? e.getMessage().replace("<","&lt;") : "unknown");
    } finally {
        if (conn != null) try { conn.close(); } catch (Exception ignored) {}
    }
%>
        <div class="table-wrap">
            <table>
                <thead><tr><th>Service</th><th>Status</th><th>Details</th></tr></thead>
                <tbody>
                    <tr><td>MySQL (BrarnerScience)</td><td><%= dbStatus %></td><td><%= dbVersion %></td></tr>
                    <tr><td>Servlet Container</td><td>Online</td><td><%= application.getServerInfo() %></td></tr>
                    <tr><td>JVM</td><td>Online</td><td><%= System.getProperty("java.version") %></td></tr>
                </tbody>
            </table>
        </div>
    </div>
</section>

<footer class="footer"><div class="footer-bottom" style="border:none;padding:0;">
    <span>&#169; 2026 MEARVK LLC. All rights reserved.</span>
</div></footer>
</body>
</html>
