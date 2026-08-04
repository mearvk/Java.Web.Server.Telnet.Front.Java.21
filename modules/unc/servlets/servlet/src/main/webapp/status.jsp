<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.net.*, java.io.*" %>
<%
    String statusData = "";
    boolean backendUp = false;
    try (Socket s = new Socket()) {
        s.connect(new InetSocketAddress("127.0.0.1", 49218), 3000);
        s.setSoTimeout(3000);
        BufferedReader br = new BufferedReader(new InputStreamReader(s.getInputStream()));
        PrintWriter pw = new PrintWriter(s.getOutputStream(), true);
        String banner = br.readLine();
        pw.println("STATUS");
        statusData = br.readLine();
        pw.println("QUIT");
        backendUp = true;
    } catch (Exception e) { statusData = "Backend offline: " + e.getMessage(); }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/>
    <link rel="preconnect" href="https://fonts.googleapis.com"/><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin/><link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:ital,wght@0,300;0,400;0,500;0,600;0,700;1,400;1,600&display=swap" rel="stylesheet"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>Status — UNC Chapel Hill™</title>
    <link rel="stylesheet" href="css/style.css"/>
    <script src="js/scroll-preserve.js"></script>
    <script src="js/nwe-readme-viewer.js"></script>
</head>
<body>
<nav class="nav"><div class="nav-inner">
    <span class="nav-brand">🐏 UNC Chapel Hill™</span>
    <ul class="nav-links">
        <li><a href="index.jsp">Overview</a></li>
        <li><a href="schools.jsp">Schools</a></li>
        <li><a href="departments.jsp">Departments</a></li>
        <li><a href="messaging.jsp">Messages</a></li>
        <li><a href="profile.jsp">Profile</a></li>
        <li><a href="status.jsp" class="active">Status</a></li>
    </ul>
<div class="nav-actions"><%@ include file="auth-buttons.jsp" %></div></div></nav>

<section class="hero" style="padding:4rem 2rem;">
    <div class="hero-inner">
        <span class="hero-tag">System Status</span>
        <h1>Status</h1>
        <p>Backend connectivity, configuration, and system health.</p>
    </div>
</section>

<section class="section">
    <div class="section-inner">
        <h2>Backend (Port 49218)</h2>
        <div class="table-wrap"><table>
            <thead><tr><th>Property</th><th>Value</th></tr></thead>
            <tbody>
                <tr><td>Backend Status</td><td><%= backendUp ? "<span style='color:#4ade80;'>Connected</span>" : "<span style='color:#f87171;'>Offline</span>" %></td></tr>
                <tr><td>Port</td><td><code>49218</code></td></tr>
                <tr><td>Module</td><td><code>UNC Chapel Hill™</code></td></tr>
                <tr><td>Context Path</td><td><code>/california-unc</code></td></tr>
                <tr><td>Theme</td><td>Carolina Blue (#4B9CD3)</td></tr>
                <tr><td>Installer Tech ID</td><td>Max Rupplin</td></tr>
<% if (backendUp && statusData != null && !statusData.isEmpty()) {
    String[] parts = statusData.split("\\|");
    for (String p : parts) {
        if (p.contains("=")) { String[] kv = p.split("=", 2); %>
                <tr><td><%= kv[0] %></td><td><code><%= kv[1] %></code></td></tr>
<%      } } } %>
            </tbody>
        </table></div>
    </div>
</section>

<section class="section">
    <div class="section-inner">
        <h2>Configuration</h2>
        <div class="table-wrap"><table>
            <thead><tr><th>Setting</th><th>Value</th></tr></thead>
            <tbody>
                <tr><td>University</td><td>University of North Carolina at Chapel Hill</td></tr>
                <tr><td>Founded</td><td>1789</td></tr>
                <tr><td>Location</td><td>Chapel Hill, NC</td></tr>
                <tr><td>Mascot</td><td>🐏 Rameses</td></tr>
                <tr><td>Colors</td><td>Carolina Blue (#4B9CD3) + White</td></tr>
                <tr><td>Strernary Integration</td><td>Hardened (trust-aware)</td></tr>
                <tr><td>Encryption</td><td>DH-2048 / AES-256</td></tr>
            </tbody>
        </table></div>
    </div>
</section>

<footer class="footer"><span>UNC Chapel Hill™ — Status — MEARVK LLC — NitroWebExpress™ 2026</span></footer>
</body>
</html>
