<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
    // Check DukeUniversityServer TCP connectivity
    String serverStatus = "OFFLINE";
    String serverResponse = "";
    try (java.net.Socket sock = new java.net.Socket("127.0.0.1", 49213)) {
        sock.setSoTimeout(3000);
        java.io.BufferedReader br = new java.io.BufferedReader(new java.io.InputStreamReader(sock.getInputStream()));
        java.io.PrintWriter pw = new java.io.PrintWriter(sock.getOutputStream(), true);
        br.readLine(); // banner
        br.readLine(); // commands
        br.readLine(); // blank
        pw.println("STATUS");
        serverResponse = br.readLine();
        pw.println("QUIT");
        serverStatus = "ONLINE";
    } catch (Exception e) {
        serverStatus = "OFFLINE";
        serverResponse = e.getMessage();
    }

    // Check MySQL connectivity
    String dbStatus = "OFFLINE";
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        try (java.sql.Connection conn = java.sql.DriverManager.getConnection("jdbc:mysql://127.0.0.1:3306/nwe_duke", "root", "$$Ironman1")) {
            dbStatus = "ONLINE";
        }
    } catch (Exception e) { dbStatus = "OFFLINE (" + e.getMessage() + ")"; }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>Status — DukeUniversity™</title>
    <link rel="stylesheet" href="css/style.css"/>
    <link rel="preconnect" href="https://fonts.googleapis.com"/>
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin/>
    <link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:ital,wght@0,300;0,400;0,500;0,600;0,700;1,400;1,600&display=swap" rel="stylesheet"/>
</head>
<body>
<nav class="nav"><div class="nav-inner">
    <span class="nav-brand">DukeUniversity™</span>
    <ul class="nav-links">
        <li><a href="index.jsp">Overview</a></li>
        <li><a href="colleges.jsp">Colleges</a></li>
        <li><a href="query.jsp">Query</a></li>
        <li><a href="messaging.jsp">Messages</a></li>
        <li><a href="status.jsp" class="active">Status</a></li>
    </ul>
</div></nav>

<section class="hero" style="padding:4rem 2rem;">
    <div class="hero-inner">
        <span class="hero-tag">System Health</span>
        <h1>DukeUniversity™ Status</h1>
        <p>Real-time status of the Duke University module backend services.</p>
    </div>
</section>

<section class="section">
    <div class="section-inner" style="max-width:800px;">
        <h2>Service Status</h2>
        <div class="table-wrap">
            <table>
                <thead><tr><th>Service</th><th>Status</th><th>Detail</th></tr></thead>
                <tbody>
                    <tr>
                        <td>DukeUniversityServer (TCP 49213)</td>
                        <td style="color:<%= "ONLINE".equals(serverStatus) ? "#22c55e" : "#ef4444" %>; font-weight:600;">● <%= serverStatus %></td>
                        <td><code><%= serverResponse != null ? serverResponse : "—" %></code></td>
                    </tr>
                    <tr>
                        <td>MySQL Database (nwe_duke)</td>
                        <td style="color:<%= dbStatus.startsWith("ONLINE") ? "#22c55e" : "#ef4444" %>; font-weight:600;">● <%= dbStatus.startsWith("ONLINE") ? "ONLINE" : "OFFLINE" %></td>
                        <td><code><%= dbStatus %></code></td>
                    </tr>
                    <tr>
                        <td>Strernary™ AI (port 20000)</td>
                        <td style="color:var(--text-muted);">● CHECK MANUALLY</td>
                        <td>AI inference backend for query responses</td>
                    </tr>
                    <tr>
                        <td>Tomcat Servlet Container</td>
                        <td style="color:#22c55e; font-weight:600;">● ONLINE</td>
                        <td>This page is served by Tomcat — confirmed operational</td>
                    </tr>
                </tbody>
            </table>
        </div>

        <h2 style="margin-top:2.5rem;">Module Information</h2>
        <div class="table-wrap">
            <table>
                <thead><tr><th>Property</th><th>Value</th></tr></thead>
                <tbody>
                    <tr><td>Module Name</td><td>DukeUniversity™</td></tr>
                    <tr><td>NWE Port</td><td>49213 (TCP, NIO masquerade)</td></tr>
                    <tr><td>Database</td><td>nwe_duke (MySQL)</td></tr>
                    <tr><td>AI Backend</td><td>Strernary™ port 20000</td></tr>
                    <tr><td>Protocol</td><td>COLLEGES | SEARCH|kw | QUERY|college|text | STATUS | QUIT</td></tr>
                    <tr><td>Colleges</td><td>10 schools with individual pages</td></tr>
                    <tr><td>Installer</td><td>Max Rupplin — MEARVK LLC</td></tr>
                    <tr><td>Checked At</td><td><%= new java.text.SimpleDateFormat("yyyy-MM-dd HH:mm:ss z").format(new java.util.Date()) %></td></tr>
                </tbody>
            </table>
        </div>
    </div>
</section>

<footer class="footer"><div><span>© 2026 MEARVK LLC. All rights reserved. DukeUniversity™ — Duke Blue.</span></div></footer>
</body>
</html>
