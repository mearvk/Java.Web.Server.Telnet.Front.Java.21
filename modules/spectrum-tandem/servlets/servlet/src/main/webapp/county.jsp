<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.net.*, java.io.*" %>
<%
    // Query county data
    String countyData = "";
    String queryCounty = request.getParameter("county");
    if (queryCounty != null && !queryCounty.isEmpty()) {
        try (Socket s = new Socket()) {
            s.connect(new InetSocketAddress("127.0.0.1", 49222), 5000);
            s.setSoTimeout(5000);
            PrintWriter pw = new PrintWriter(s.getOutputStream(), true);
            BufferedReader br = new BufferedReader(new InputStreamReader(s.getInputStream()));
            br.readLine(); // banner
            pw.println("COUNTY|" + queryCounty);
            countyData = br.readLine();
            pw.println("QUIT");
        } catch (Exception e) { countyData = "ERROR|Backend offline: " + e.getMessage(); }
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/>
    <link rel="preconnect" href="https://fonts.googleapis.com"/><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin/><link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:ital,wght@0,300;0,400;0,500;0,600;0,700;1,400;1,600&display=swap" rel="stylesheet"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>County Precedent — SpectrumTandem™</title>
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
        <li><a href="county.jsp" class="active">County Precedent</a></li>
        <li><a href="status.jsp">Status</a></li>
    </ul>
<div class="nav-actions"><%@ include file="auth-buttons.jsp" %></div></div></nav>

<section class="hero">
    <div class="hero-inner">
        <span class="hero-tag">COUNTY — Full Capitalized Term of Precedent</span>
        <h1>County Precedent</h1>
        <p>Query COUNTY (full capitalized term of precedent) with pointers, indirections, revisions, and caliber. County records track jurisdictional authority over term definitions.</p>
    </div>
</section>

<!-- CD1 Connector Button + Floating Dialog -->
<div style="display:flex;justify-content:center;align-items:center;width:100%;padding:2rem 0;">
    <button id="cd1-btn" type="button" aria-pressed="false" style="all:unset;display:block;margin:0 auto;cursor:pointer;padding:0;border:none;background:transparent;transition:transform 0.3s cubic-bezier(0.42,-1.84,0.42,1.84),filter 0.3s ease;">
        <img src="images/black.button.png" alt="Connector" style="display:block;width:80px;height:80px;border-radius:50%;background:transparent;"/>
    </button>
</div>
<div id="cd1-overlay" style="display:none;position:fixed;inset:0;z-index:299;background:transparent;"></div>
<div id="cd1-dialog" style="display:none;position:fixed;top:50%;left:50%;transform:translate(-50%,-50%);z-index:300;background:#1a1a1a;border:1px solid #333;border-radius:12px;padding:1.25rem;width:520px;max-width:90vw;box-shadow:0 8px 32px rgba(0,0,0,0.6);">
    <div style="font-size:0.9rem;font-weight:600;color:#e8e0d6;margin-bottom:0.75rem;">CD1 Connector &#8212; Port 49222</div>
    <div style="display:flex;gap:0.5rem;margin-bottom:0.75rem;flex-wrap:wrap;align-items:center;">
        <select id="cd1-action" style="background:#222;color:#e8e0d6;border:1px solid #444;border-radius:8px;padding:0.45rem 2rem 0.45rem 0.75rem;font-size:0.8rem;cursor:pointer;appearance:none;">
            <option value="connect">Connect</option>
            <option value="disconnect">Disconnect</option>
            <option value="status">Status</option>
            <option value="hardreset">Hard Reset Connection</option>
        </select>
        <button onclick="cd1Send()" style="background:#666;color:#fff;border:none;border-radius:8px;padding:0.45rem 1rem;font-size:0.8rem;font-weight:600;cursor:pointer;">Send</button>
        <button onclick="cd1Ok()" style="background:#666;color:#fff;border:none;border-radius:8px;padding:0.45rem 1rem;font-size:0.8rem;font-weight:600;cursor:pointer;">OK</button>
    </div>
    <div style="display:flex;align-items:center;gap:0.5rem;margin-bottom:0.75rem;">
        <label style="display:flex;align-items:center;gap:0.4rem;color:#999;font-size:0.75rem;cursor:pointer;">
            <input type="checkbox" id="cd1-direct-port" style="accent-color:#888;width:14px;height:14px;cursor:pointer;"/>
            Direct Port (bypass Strernary&#8482; 20000)
        </label>
        <span id="cd1-mode-badge" style="font-size:0.65rem;background:#222;color:#aaa;padding:0.2rem 0.5rem;border-radius:4px;">STRERNARY</span>
    </div>
    <textarea id="cd1-textarea" placeholder="Connection idle..." spellcheck="false" style="width:100%;min-height:140px;background:#ffffff;color:#111;border:1px solid #333;border-radius:8px;padding:0.75rem;font-family:monospace;font-size:0.8rem;resize:vertical;"></textarea>
</div>
<script>window.CD1_MODULE_PORT = "49222";</script>
<script src="js/cd1-connector.js"></script>


<section class="section">
    <div class="section-inner">
        <h2>Query County</h2>
        <form method="GET" action="county.jsp" style="display:flex;gap:1rem;align-items:flex-end;flex-wrap:wrap;">
            <div class="form-group" style="flex:1;min-width:200px;">
                <label>County (Full Capitalized)</label>
                <input type="text" name="county" value="<%= queryCounty != null ? queryCounty : "" %>" placeholder="e.g. DURHAM, WAKE, ORANGE" required style="text-transform:uppercase;"/>
            </div>
            <button type="submit" class="btn btn-primary">Query</button>
        </form>
    </div>
</section>

<% if (queryCounty != null && !queryCounty.isEmpty()) { %>
<section class="section">
    <div class="section-inner">
        <h2>Results: "<%= queryCounty.toUpperCase() %>"</h2>
<%
    if (countyData != null && countyData.startsWith("COUNTY|") && !countyData.contains("NONE") && !countyData.contains("ERROR")) {
        String[] entries = countyData.split("\\|");
%>
        <div class="table-wrap">
        <table>
            <thead><tr><th>County</th><th>Revision</th><th>Pointer</th><th>Indirection</th></tr></thead>
            <tbody>
<%
        for (int i = 1; i < entries.length; i++) {
            String entry = entries[i].trim();
            if (entry.isEmpty()) continue;
            // Format: COUNTY[rN]=pointer→indirection
            String county2 = entry.contains("[") ? entry.substring(0, entry.indexOf("[")) : entry;
            String rev = entry.contains("[r") ? entry.substring(entry.indexOf("[r") + 2, entry.indexOf("]")) : "?";
            String rest = entry.contains("]=") ? entry.substring(entry.indexOf("]=") + 2) : "";
            String pointer = rest.contains("→") ? rest.substring(0, rest.indexOf("→")) : rest;
            String indirection = rest.contains("→") ? rest.substring(rest.indexOf("→") + 1) : "";
%>
                <tr><td><%= county2 %></td><td>r<%= rev %></td><td><code><%= pointer %></code></td><td><code><%= indirection %></code></td></tr>
<%      } %>
            </tbody>
        </table>
        </div>
<%  } else { %>
        <p style="padding:1rem;background:#f0f0f0;border-radius:8px;"><code><%= countyData != null ? countyData : "No data" %></code></p>
<%  } %>
    </div>
</section>
<% } %>

<section class="section">
    <div class="section-inner">
        <h2>Registered Counties</h2>
        <div class="table-wrap">
        <table>
            <thead><tr><th>County</th><th>Pointer</th><th>Caliber</th></tr></thead>
            <tbody>
                <tr><td>DURHAM</td><td>dolyene→spectrum</td><td>STANDARD</td></tr>
                <tr><td>WAKE</td><td>radix→spelling_variant</td><td>STANDARD</td></tr>
                <tr><td>ORANGE</td><td>int discipline→discipline_index</td><td>HIGH</td></tr>
            </tbody>
        </table>
        </div>
    </div>
</section>

<footer class="footer">
    <span>SpectrumTandem™ — County Precedent — MEARVK LLC — NitroWebExpress™ 2026</span>
</footer>
</body>
</html>
