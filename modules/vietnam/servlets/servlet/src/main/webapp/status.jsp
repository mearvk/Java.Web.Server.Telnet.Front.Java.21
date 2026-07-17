<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.Properties, java.io.*, java.net.*" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>Status — Vietnam™</title>
    <link rel="stylesheet" href="css/style.css"/>
    <script src="js/scroll-preserve.js"></script>
    <script src="js/nwe-readme-viewer.js"></script>
</head>
<body>
<nav class="nav"><div class="nav-inner">
    <span class="nav-brand">Vietnam™</span>
    <ul class="nav-links">
        <li><a href="index.jsp">Overview</a></li>
        <li><a href="styles.jsp">Fighting Styles</a></li>
        <li><a href="languages.jsp">Languages</a></li>
        <li><a href="status.jsp" class="active">Status</a></li>
    </ul>
    <div class="nav-actions"><a href="styles.jsp" class="nav-cta">Explore Styles →</a></div>
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
    String dbStatus = "Offline", dbVersion = "", stylesCount = "?", langCount = "?";
    boolean tcpAlive = false;

    // DB check
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        try (Connection conn = DriverManager.getConnection(
                "jdbc:mysql://127.0.0.1:3306/nwe_vietnam", "root", "")) {
            dbStatus = "Online";
            dbVersion = conn.getMetaData().getDatabaseProductName() + " " + conn.getMetaData().getDatabaseProductVersion();
            try (ResultSet rs = conn.createStatement().executeQuery("SELECT COUNT(*) FROM fighting_styles")) {
                if (rs.next()) stylesCount = String.valueOf(rs.getInt(1));
            }
            try (ResultSet rs = conn.createStatement().executeQuery("SELECT COUNT(*) FROM languages")) {
                if (rs.next()) langCount = String.valueOf(rs.getInt(1));
            }
        }
    } catch (Exception e) { dbStatus = "Error"; }

    // TCP port 49215 check
    try (Socket s = new Socket()) {
        s.connect(new InetSocketAddress("localhost", 49215), 2000);
        tcpAlive = true;
    } catch (Exception ignored) {}
%>
        <div class="table-wrap">
            <table>
                <thead><tr><th>Service</th><th>Status</th><th>Details</th></tr></thead>
                <tbody>
                    <tr><td>MySQL (nwe_vietnam)</td><td style="color:<%= "Online".equals(dbStatus) ? "#22c55e" : "#ef4444" %>;"><%= dbStatus %></td><td><%= dbVersion %></td></tr>
                    <tr><td>Fighting Styles</td><td><%= stylesCount %> records</td><td>Vovinam, Viet Vo Dao, Binh Dinh, Cuong Nhu, Nhat Nam</td></tr>
                    <tr><td>Languages</td><td><%= langCount %> records</td><td>Vietnamese, Tay, Muong, Khmer Krom, Cham, Hmong</td></tr>
                    <tr><td>TCP Server (49215)</td><td style="color:<%= tcpAlive ? "#22c55e" : "#ef4444" %>;"><%= tcpAlive ? "Online" : "Offline" %></td><td>NIO masquerade routed</td></tr>
                    <tr><td>AI Inference (port 20000)</td><td>Strernary™</td><td>DJL/DistilBERT search &amp; training</td></tr>
                    <tr><td>Servlet Container</td><td style="color:#22c55e;">Online</td><td><%= application.getServerInfo() %></td></tr>
                    <tr><td>JVM</td><td style="color:#22c55e;">Online</td><td><%= System.getProperty("java.version") %></td></tr>
                </tbody>
            </table>
        </div>
    </div>
</section>

<footer class="footer"><div><span>&#169; 2026 MEARVK LLC. All rights reserved. Vietnam™ — Light Brown.</span></div></footer>
</body>
</html>
