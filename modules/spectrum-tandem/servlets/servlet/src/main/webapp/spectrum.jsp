<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.net.*, java.io.*" %>
<%
    // Get spectrum for a term
    String spectrumData = "";
    String queryTerm = request.getParameter("term");
    if (queryTerm != null && !queryTerm.isEmpty()) {
        try (Socket s = new Socket()) {
            s.connect(new InetSocketAddress("127.0.0.1", 49222), 5000);
            s.setSoTimeout(5000);
            PrintWriter pw = new PrintWriter(s.getOutputStream(), true);
            BufferedReader br = new BufferedReader(new InputStreamReader(s.getInputStream()));
            br.readLine(); // banner
            pw.println("SPECTRUM|" + queryTerm);
            spectrumData = br.readLine();
            pw.println("QUIT");
        } catch (Exception e) { spectrumData = "ERROR|Backend offline: " + e.getMessage(); }
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>Dolyene Spectrum — SpectrumTandem™</title>
    <link rel="stylesheet" href="css/style.css"/>
    <script src="js/scroll-preserve.js"></script>
</head>
<body>
<nav class="nav"><div class="nav-inner">
    <span class="nav-brand">SpectrumTandem™</span>
    <ul class="nav-links">
        <li><a href="index.jsp">Overview</a></li>
        <li><a href="wordbank.jsp">Word Bank</a></li>
        <li><a href="spectrum.jsp" class="active">Dolyene Spectrum</a></li>
        <li><a href="county.jsp">County Precedent</a></li>
        <li><a href="status.jsp">Status</a></li>
    </ul>
</div></nav>

<section class="hero">
    <div class="hero-inner">
        <span class="hero-tag">Graphing the Dolyene</span>
        <h1>Dolyene Spectrum</h1>
        <p>Graph the spectrum of int discipline for any term — visualize spelling conditions, radix weights, and discipline indices. The dolyene measures how a term's various spellings distribute across its integer discipline space.</p>
    </div>
</section>

<section class="section">
    <div class="section-inner">
        <h2>Query Dolyene Spectrum</h2>
        <form method="GET" action="spectrum.jsp" style="display:flex;gap:1rem;align-items:flex-end;flex-wrap:wrap;">
            <div class="form-group" style="flex:1;min-width:200px;">
                <label>Term</label>
                <input type="text" name="term" value="<%= queryTerm != null ? queryTerm : "" %>" placeholder="Enter term to graph spectrum..." required/>
            </div>
            <button type="submit" class="btn btn-primary">Graph Spectrum</button>
        </form>
    </div>
</section>

<% if (queryTerm != null && !queryTerm.isEmpty()) { %>
<section class="section">
    <div class="section-inner">
        <h2>Spectrum Results: "<%= queryTerm %>"</h2>
<%
    if (spectrumData != null && spectrumData.startsWith("SPECTRUM|") && !spectrumData.contains("NONE") && !spectrumData.contains("ERROR")) {
        String[] entries = spectrumData.split("\\|");
%>
        <div style="margin:1.5rem 0;">
<%
        for (int i = 1; i < entries.length; i++) {
            String entry = entries[i].trim();
            if (entry.isEmpty()) continue;
            // Parse: idx=N,int=N,spelling=X,weight=N
            String spelling = "";
            int intVal = 0;
            double weight = 0;
            int idx = 0;
            String[] fields = entry.split(",");
            for (String f : fields) {
                if (f.startsWith("idx=")) idx = Integer.parseInt(f.substring(4));
                else if (f.startsWith("int=")) intVal = Integer.parseInt(f.substring(4));
                else if (f.startsWith("spelling=")) spelling = f.substring(9);
                else if (f.startsWith("weight=")) weight = Double.parseDouble(f.substring(7));
            }
            int barWidth = (int)(weight * 100);
%>
            <div class="spectrum-bar">
                <span class="label">[<%= idx %>] <%= spelling %></span>
                <div class="bar" style="width:<%= barWidth %>%;max-width:400px;"></div>
                <span class="value"><%= intVal %> (<%= String.format("%.0f%%", weight * 100) %>)</span>
            </div>
<%      } %>
        </div>
        <div class="table-wrap" style="margin-top:1.5rem;">
        <table>
            <thead><tr><th>Index</th><th>Spelling Condition</th><th>Int Value</th><th>Weight</th></tr></thead>
            <tbody>
<%
        for (int i = 1; i < entries.length; i++) {
            String entry = entries[i].trim();
            if (entry.isEmpty()) continue;
            String spelling2 = "";
            int intVal2 = 0;
            double weight2 = 0;
            int idx2 = 0;
            String[] fields2 = entry.split(",");
            for (String f : fields2) {
                if (f.startsWith("idx=")) idx2 = Integer.parseInt(f.substring(4));
                else if (f.startsWith("int=")) intVal2 = Integer.parseInt(f.substring(4));
                else if (f.startsWith("spelling=")) spelling2 = f.substring(9);
                else if (f.startsWith("weight=")) weight2 = Double.parseDouble(f.substring(7));
            }
%>
                <tr><td><%= idx2 %></td><td><%= spelling2 %></td><td><%= intVal2 %></td><td><%= String.format("%.2f", weight2) %></td></tr>
<%      } %>
            </tbody>
        </table>
        </div>
<%  } else { %>
        <p style="padding:1rem;background:#f0f0f0;border-radius:8px;"><code><%= spectrumData != null ? spectrumData : "No data" %></code></p>
<%  } %>
    </div>
</section>
<% } %>

<footer class="footer">
    <span>SpectrumTandem™ — Dolyene Spectrum — MEARVK LLC — NitroWebExpress™ 2026</span>
</footer>
</body>
</html>
