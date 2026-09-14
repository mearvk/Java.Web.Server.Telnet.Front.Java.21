<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.net.*, java.io.*" %>
<%
    String statusData = "";
    try (Socket s = new Socket()) {
        s.connect(new InetSocketAddress("127.0.0.1", 49223), 5000);
        s.setSoTimeout(5000);
        BufferedReader br = new BufferedReader(new InputStreamReader(s.getInputStream()));
        PrintWriter pw = new PrintWriter(s.getOutputStream(), true);
        br.readLine(); br.readLine(); // banners
        pw.println("STATUS");
        statusData = br.readLine();
        pw.println("QUIT");
    } catch (Exception e) { statusData = "ERROR|Backend offline: " + e.getMessage(); }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/><meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <link rel="preconnect" href="https://fonts.googleapis.com"/><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin/><link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:wght@300;400;500;600;700;800&display=swap" rel="stylesheet"/>
    <title>Status — TandemEquals™</title>
    <link rel="stylesheet" href="css/style.css"/>
</head>
<body>
<nav class="nav"><div class="nav-inner">
    <span class="nav-brand">TandemEquals™</span>
    <ul class="nav-links">
        <li><a href="index.jsp">Overview</a></li>
        <li><a href="layers.jsp">Layers</a></li>
        <li><a href="curves.jsp">Control Curves</a></li>
        <li><a href="messaging.jsp">Messages</a></li>
        <li><a href="status.jsp" class="active">Status</a></li>
    </ul>
<div class="nav-actions"><%@ include file="auth-buttons.jsp" %></div></div></nav>

<section class="hero" style="padding:3rem 2rem;">
    <div class="hero-inner">
        <span class="hero-tag">System Status</span>
        <h1><span>Status</span></h1>
        <p>Backend connectivity and table counts.</p>
    </div>
</section>

<section class="section">
    <div class="section-inner">
        <h2>Backend (Port 49223)</h2>
        <div class="table-wrap"><table>
            <thead><tr><th>Field</th><th>Value</th></tr></thead>
            <tbody>
<%  if (statusData != null && !statusData.startsWith("ERROR")) {
        String[] parts = statusData.split("\\|");
        for (String p : parts) {
            if (p.contains("=")) { String[] kv = p.split("=", 2); %>
            <tr><td><%= kv[0] %></td><td><code><%= kv[1] %></code></td></tr>
<%          } else if (!p.isEmpty() && !"STATUS".equals(p)) { %>
            <tr><td>Status</td><td><code><%= p %></code></td></tr>
<%          }
        }
    } else { %>
            <tr><td>Error</td><td style="color:var(--accent);"><code><%= statusData %></code></td></tr>
<%  } %>
            </tbody>
        </table></div>
    </div>
</section>

<section class="section">
    <div class="section-inner">
        <h2>Configuration</h2>
        <div class="table-wrap"><table>
            <thead><tr><th>Property</th><th>Value</th></tr></thead>
            <tbody>
                <tr><td>Module</td><td><code>TandemEquals™</code></td></tr>
                <tr><td>Port</td><td><code>49223</code></td></tr>
                <tr><td>Database</td><td><code>nwe_tandem_equals</code></td></tr>
                <tr><td>Context</td><td><code>/tandem-equals</code></td></tr>
                <tr><td>Theme</td><td><code>White / Red</code></td></tr>
                <tr><td>Layers</td><td><code>4 (Perception → Cognition → Modulation → Expression)</code></td></tr>
                <tr><td>Installer</td><td><code>Max Rupplin</code></td></tr>
            </tbody>
        </table></div>
    </div>
</section>

<footer class="footer"><span>TandemEquals™ — Status — MEARVK LLC 2026</span></footer>
</body>
</html>
