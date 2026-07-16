<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.Properties, java.io.*" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>Status — AE6E66™</title>
    <link rel="stylesheet" href="css/style.css"/>
<script src="js/scroll-preserve.js"></script>
</head>
<body>
<nav class="nav"><div class="nav-inner">
    <span class="nav-brand">AE6E66™</span>
    <ul class="nav-links">
        <li><a href="index.jsp">Overview</a></li>
        <li><a href="contacts.jsp">Contacts</a></li>
        <li><a href="sent.jsp">Sent</a></li>
        <li><a href="status.jsp" class="active">Status</a></li>
    </ul>
    <div class="nav-actions"><a href="crawl.jsp" class="nav-cta">Crawl</a></div>
</div></nav>

<section class="hero" style="padding:4rem 2rem;">
    <div class="hero-inner">
        <span class="hero-tag">Health Check</span>
        <h1>Status</h1>
    </div>
</section>

<section class="section">
    <div class="section-inner">
<%
    Properties dbProps = new Properties();
    boolean propsLoaded = false;
    String dbStatus = "Offline";
    String dbVersion = "";
    String contactCount = "?";
    String sentCount = "?";
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
        DatabaseMetaData md = conn.getMetaData();
        dbStatus = "Online";
        dbVersion = md.getDatabaseProductName() + " " + md.getDatabaseProductVersion();
        ResultSet rs = conn.createStatement().executeQuery("SELECT COUNT(*) FROM contacts");
        if (rs.next()) contactCount = String.valueOf(rs.getInt(1)); rs.close();
        try { rs = conn.createStatement().executeQuery("SELECT COUNT(*) FROM sent_log");
            if (rs.next()) sentCount = String.valueOf(rs.getInt(1)); rs.close(); } catch (Exception ignored) { sentCount = "table missing"; }
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
                    <tr><td>MySQL (nwe_ae6e66)</td><td><%= dbStatus %></td><td><%= dbVersion %></td></tr>
                    <tr><td>Contacts</td><td><%= contactCount %> records</td><td>HOL + HOC</td></tr>
                    <tr><td>Sent Log</td><td><%= sentCount %></td><td>DKIM-signed messages</td></tr>
                    <tr><td>Servlet Container</td><td>Online</td><td><%= application.getServerInfo() %></td></tr>
                    <tr><td>JVM</td><td>Online</td><td><%= System.getProperty("java.version") %></td></tr>
                </tbody>
            </table>
        </div>
    </div>
</section>

<footer class="footer"><div><span>&#169; 2026 MEARVK LLC. All rights reserved.</span></div></footer>
</body>
</html>
