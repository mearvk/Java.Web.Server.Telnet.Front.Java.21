<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.net.*, java.io.*" %>
<%
    String statusData = "";
    try (Socket s = new Socket()) {
        s.connect(new InetSocketAddress("127.0.0.1", 49222), 5000);
        s.setSoTimeout(5000);
        PrintWriter pw = new PrintWriter(s.getOutputStream(), true);
        BufferedReader br = new BufferedReader(new InputStreamReader(s.getInputStream()));
        String banner = br.readLine();
        pw.println("STATUS");
        statusData = br.readLine();
        pw.println("QUIT");
    } catch (Exception e) { statusData = "ERROR|Backend offline: " + e.getMessage(); }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>Status — SpectrumTandem™</title>
    <link rel="stylesheet" href="css/style.css"/>
    <script src="js/scroll-preserve.js"></script>
    <script src="js/nwe-readme-viewer.js"></script>
</head>
<body>
<nav class="nav"><div class="nav-inner">
    <span class="nav-brand">SpectrumTandem™</span>
    <ul class="nav-links">
        <li><a href="index.jsp">Overview</a></li>
        <li><a href="wordbank.jsp">Word Bank</a></li>
        <li><a href="spectrum.jsp">Dolyene Spectrum</a></li>
        <li><a href="county.jsp">County Precedent</a></li>
        <li><a href="status.jsp" class="active">Status</a></li>
    </ul>
</div></nav>

<section class="hero">
    <div class="hero-inner">
        <span class="hero-tag">System Status</span>
        <h1>Status</h1>
        <p>Backend connectivity, database health, and module diagnostics.</p>
    </div>
</section>

<section class="section">
    <div class="section-inner">
        <h2>Backend Status</h2>
        <div class="table-wrap">
        <table>
            <thead><tr><th>Field</th><th>Value</th></tr></thead>
            <tbody>
<%
    if (statusData != null && !statusData.startsWith("ERROR")) {
        String[] parts = statusData.split("\\|");
        for (String p : parts) {
            if (p.contains("=")) {
                String[] kv = p.split("=", 2);
%>
                <tr><td><%= kv[0] %></td><td><code><%= kv[1] %></code></td></tr>
<%
            } else if (!p.isEmpty()) {
%>
                <tr><td>Status</td><td><code><%= p %></code></td></tr>
<%          }
        }
    } else {
%>
                <tr><td>Error</td><td><code><%= statusData %></code></td></tr>
<%  } %>
            </tbody>
        </table>
        </div>
    </div>
</section>

<section class="section">
    <div class="section-inner">
        <h2>Protocol Reference</h2>
        <div class="table-wrap">
        <table>
            <thead><tr><th>Command</th><th>Description</th></tr></thead>
            <tbody>
                <tr><td><code>DEFINE|&lt;term&gt;</code></td><td>Get full definition of a term from word bank</td></tr>
                <tr><td><code>LOOKUP|&lt;term&gt;</code></td><td>Search by spelling, radix, or variant</td></tr>
                <tr><td><code>RADIX|&lt;radix&gt;</code></td><td>Search by radix root</td></tr>
                <tr><td><code>SPECTRUM|&lt;term&gt;</code></td><td>Get dolyene spectrum (int discipline graph)</td></tr>
                <tr><td><code>COUNTY|&lt;county&gt;</code></td><td>Query county precedent (full capitalized)</td></tr>
                <tr><td><code>REVISE|&lt;term&gt;|&lt;def&gt;|&lt;authorId&gt;</code></td><td>Revise a term's definition</td></tr>
                <tr><td><code>ADD|&lt;term&gt;|&lt;def&gt;|&lt;specialness&gt;|&lt;authorId&gt;</code></td><td>Add new term to word bank</td></tr>
                <tr><td><code>HISTORY|&lt;term&gt;</code></td><td>Get revision history</td></tr>
                <tr><td><code>WORDBANK</code></td><td>List all terms</td></tr>
                <tr><td><code>SEARCH|&lt;keyword&gt;</code></td><td>AI-assisted search via Strernary™</td></tr>
                <tr><td><code>STATUS</code></td><td>Module status check</td></tr>
                <tr><td><code>QUIT</code></td><td>Close session</td></tr>
            </tbody>
        </table>
        </div>
    </div>
</section>

<footer class="footer">
    <span>SpectrumTandem™ — Status — MEARVK LLC — NitroWebExpress™ 2026</span>
</footer>
</body>
</html>
