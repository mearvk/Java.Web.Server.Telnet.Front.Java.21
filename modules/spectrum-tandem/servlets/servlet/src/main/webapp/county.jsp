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
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>County Precedent — SpectrumTandem™</title>
    <link rel="stylesheet" href="css/style.css"/>
    <script src="js/scroll-preserve.js"></script>
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
</div></nav>

<section class="hero">
    <div class="hero-inner">
        <span class="hero-tag">COUNTY — Full Capitalized Term of Precedent</span>
        <h1>County Precedent</h1>
        <p>Query COUNTY (full capitalized term of precedent) with pointers, indirections, revisions, and caliber. County records track jurisdictional authority over term definitions.</p>
    </div>
</section>

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
