<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.net.*, java.io.*" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>Status — Emeter™</title>
    <link rel="stylesheet" href="css/style.css"/>
    <script src="js/scroll-preserve.js"></script>
    <script src="js/nwe-readme-viewer.js"></script>
</head>
<body>
<nav class="nav"><div class="nav-inner">
    <span class="nav-brand">Emeter™</span>
    <ul class="nav-links">
        <li><a href="index.jsp">Overview</a></li>
        <li><a href="instructions.jsp">Instructions</a></li>
        <li><a href="calibration.jsp">Calibration</a></li>
        <li><a href="readings.jsp">Readings</a></li>
        <li><a href="status.jsp" class="active">Status</a></li>
    </ul>
    <div class="nav-actions"><a href="index.jsp" class="nav-cta">← Overview</a></div>
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
    String dbStatus = "Offline", dbVersion = "";
    String instructionCount = "?", readingCount = "?", calibrationCount = "?";
    boolean tcpAlive = false;

    // DB check
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        try (Connection conn = DriverManager.getConnection(
                "jdbc:mysql://127.0.0.1:3306/nwe_emeter", "root", "")) {
            dbStatus = "Online";
            dbVersion = conn.getMetaData().getDatabaseProductName() + " " + conn.getMetaData().getDatabaseProductVersion();
            try (ResultSet rs = conn.createStatement().executeQuery("SELECT COUNT(*) FROM instructions")) {
                if (rs.next()) instructionCount = String.valueOf(rs.getInt(1));
            } catch (Exception ignored) { instructionCount = "table missing"; }
            try (ResultSet rs = conn.createStatement().executeQuery("SELECT COUNT(*) FROM readings")) {
                if (rs.next()) readingCount = String.valueOf(rs.getInt(1));
            } catch (Exception ignored) { readingCount = "table missing"; }
            try (ResultSet rs = conn.createStatement().executeQuery("SELECT COUNT(*) FROM calibration")) {
                if (rs.next()) calibrationCount = String.valueOf(rs.getInt(1));
            } catch (Exception ignored) { calibrationCount = "table missing"; }
        }
    } catch (Exception e) { dbStatus = "Error: " + e.getMessage(); }

    // TCP port 49216 check
    try (Socket s = new Socket()) {
        s.connect(new InetSocketAddress("localhost", 49216), 2000);
        tcpAlive = true;
    } catch (Exception ignored) {}
%>
        <div class="table-wrap">
            <table>
                <thead><tr><th>Service</th><th>Status</th><th>Details</th></tr></thead>
                <tbody>
                    <tr>
                        <td>MySQL (nwe_emeter)</td>
                        <td style="color:<%= "Online".equals(dbStatus) ? "#22c55e" : "#ef4444" %>;"><%= dbStatus %></td>
                        <td><%= dbVersion %></td>
                    </tr>
                    <tr>
                        <td>Instructions Table</td>
                        <td><%= instructionCount %> records</td>
                        <td>Topic-indexed instruction content</td>
                    </tr>
                    <tr>
                        <td>Readings Table</td>
                        <td><%= readingCount %> records</td>
                        <td>Session reading submissions</td>
                    </tr>
                    <tr>
                        <td>Calibration Table</td>
                        <td><%= calibrationCount %> records</td>
                        <td>Calibration procedures</td>
                    </tr>
                    <tr>
                        <td>TCP Server (49216)</td>
                        <td style="color:<%= tcpAlive ? "#22c55e" : "#ef4444" %>;"><%= tcpAlive ? "Online" : "Offline" %></td>
                        <td>NIO masquerade routed</td>
                    </tr>
                    <tr>
                        <td>AI Inference (port 20000)</td>
                        <td>Strernary™</td>
                        <td>DJL/DistilBERT — training &amp; queries</td>
                    </tr>
                    <tr>
                        <td>Servlet Container</td>
                        <td style="color:#22c55e;">Online</td>
                        <td><%= application.getServerInfo() %></td>
                    </tr>
                    <tr>
                        <td>JVM</td>
                        <td style="color:#22c55e;">Online</td>
                        <td>Java <%= System.getProperty("java.version") %></td>
                    </tr>
                </tbody>
            </table>
        </div>
        <p style="margin-top:1.5rem;font-size:0.8rem;color:var(--text-muted);">Last checked: <%= new java.text.SimpleDateFormat("yyyy-MM-dd HH:mm:ss z").format(new java.util.Date()) %></p>
    </div>
</section>

<footer class="footer"><div><span>&#169; 2026 MEARVK LLC. All rights reserved. Emeter™ — NitroWebExpress™</span></div></footer>
</body>
</html>
