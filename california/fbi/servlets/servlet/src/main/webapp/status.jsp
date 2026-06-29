<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.Properties, java.io.*, java.net.*" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>Status — CaliforniaFBI™</title>
    <link rel="stylesheet" href="css/style.css"/>
</head>
<body>
<nav class="nav"><div class="nav-inner">
    <span class="nav-brand">CaliforniaFBI™</span>
    <ul class="nav-links">
        <li><a href="index.jsp">Overview</a></li>
        <li><a href="report.jsp">Report</a></li>
        <li><a href="search.jsp">Search</a></li>
        <li><a href="status.jsp" class="active">Status</a></li>
    </ul>
    <div class="nav-actions"><a href="report.jsp" class="nav-cta">File Report →</a></div>
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
    String dbStatus = "Offline", dbVersion = "", reportCount = "?", forwardCount = "?";
    boolean fbiReachable = false, tcpAlive = false;

    // DB check
    try {
        Properties p = new Properties();
        InputStream is = application.getResourceAsStream("/WEB-INF/db.properties");
        if (is != null) { p.load(is); is.close(); }
        Class.forName(p.getProperty("db.driver", "com.mysql.cj.jdbc.Driver"));
        try (Connection conn = DriverManager.getConnection(
                p.getProperty("db.url", "jdbc:mysql://127.0.0.1:3306/nwe_california_fbi"),
                p.getProperty("db.user", "root"), p.getProperty("db.password", ""))) {
            dbStatus = "Online";
            dbVersion = conn.getMetaData().getDatabaseProductName() + " " + conn.getMetaData().getDatabaseProductVersion();
            try (ResultSet rs = conn.createStatement().executeQuery("SELECT COUNT(*) FROM crime_reports")) {
                if (rs.next()) reportCount = String.valueOf(rs.getInt(1));
            }
            try (ResultSet rs = conn.createStatement().executeQuery("SELECT COUNT(*) FROM fbi_forwarded_tips")) {
                if (rs.next()) forwardCount = String.valueOf(rs.getInt(1));
            } catch (Exception ignored) { forwardCount = "table missing"; }
        }
    } catch (Exception e) { dbStatus = "Error"; }

    // FBI reachability
    try {
        HttpURLConnection hc = (HttpURLConnection) new URL("https://tips.fbi.gov/").openConnection();
        hc.setRequestMethod("HEAD"); hc.setConnectTimeout(5000); hc.setReadTimeout(5000);
        fbiReachable = (hc.getResponseCode() == 200); hc.disconnect();
    } catch (Exception ignored) {}

    // TCP port 49210 check
    try (Socket s = new Socket()) {
        s.connect(new InetSocketAddress("localhost", 49210), 2000);
        tcpAlive = true;
    } catch (Exception ignored) {}
%>
        <div class="table-wrap">
            <table>
                <thead><tr><th>Service</th><th>Status</th><th>Details</th></tr></thead>
                <tbody>
                    <tr><td>MySQL (nwe_california_fbi)</td><td style="color:<%= "Online".equals(dbStatus) ? "#22c55e" : "#ef4444" %>;"><%= dbStatus %></td><td><%= dbVersion %></td></tr>
                    <tr><td>Crime Reports</td><td><%= reportCount %> records</td><td>Installer ID Tech™ secured</td></tr>
                    <tr><td>Forwarded Tips</td><td><%= forwardCount %></td><td>Sent to FBI</td></tr>
                    <tr><td>TCP Server (49210)</td><td style="color:<%= tcpAlive ? "#22c55e" : "#ef4444" %>;"><%= tcpAlive ? "Online" : "Offline" %></td><td>NIO masquerade routed</td></tr>
                    <tr><td>FBI tips.fbi.gov</td><td style="color:<%= fbiReachable ? "#22c55e" : "#ef4444" %>;"><%= fbiReachable ? "Reachable" : "Unreachable" %></td><td>Federal tip line</td></tr>
                    <tr><td>AI Inference (port 20000)</td><td>Strernary™</td><td>DJL/DistilBERT categorization</td></tr>
                    <tr><td>Servlet Container</td><td style="color:#22c55e;">Online</td><td><%= application.getServerInfo() %></td></tr>
                    <tr><td>JVM</td><td style="color:#22c55e;">Online</td><td><%= System.getProperty("java.version") %></td></tr>
                </tbody>
            </table>
        </div>
    </div>
</section>

<footer class="footer"><div><span>&#169; 2026 MEARVK LLC. All rights reserved.</span></div></footer>
</body>
</html>
