<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.net.*, java.io.*" %>
<%
    // Connect to backend and fetch word bank
    String wordBankData = "";
    try (Socket s = new Socket()) {
        s.connect(new InetSocketAddress("127.0.0.1", 49222), 5000);
        s.setSoTimeout(5000);
        PrintWriter pw = new PrintWriter(s.getOutputStream(), true);
        BufferedReader br = new BufferedReader(new InputStreamReader(s.getInputStream()));
        br.readLine(); // banner
        pw.println("WORDBANK");
        wordBankData = br.readLine();
        pw.println("QUIT");
    } catch (Exception e) { wordBankData = "ERROR|Backend offline: " + e.getMessage(); }

    // Handle add term form
    String addResult = "";
    String termParam = request.getParameter("term");
    if (termParam != null && !termParam.isEmpty()) {
        String defParam = request.getParameter("definition");
        String specParam = request.getParameter("specialness");
        String authParam = request.getParameter("authorId");
        if (defParam != null && specParam != null && authParam != null) {
            try (Socket s = new Socket()) {
                s.connect(new InetSocketAddress("127.0.0.1", 49222), 5000);
                s.setSoTimeout(5000);
                PrintWriter pw = new PrintWriter(s.getOutputStream(), true);
                BufferedReader br = new BufferedReader(new InputStreamReader(s.getInputStream()));
                br.readLine();
                pw.println("ADD|" + termParam + "|" + defParam + "|" + specParam + "|" + authParam);
                addResult = br.readLine();
                pw.println("QUIT");
            } catch (Exception e) { addResult = "ERROR|" + e.getMessage(); }
        }
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>Word Bank — SpectrumTandem™</title>
    <link rel="stylesheet" href="css/style.css"/>
    <script src="js/scroll-preserve.js"></script>
</head>
<body>
<nav class="nav"><div class="nav-inner">
    <span class="nav-brand">SpectrumTandem™</span>
    <ul class="nav-links">
        <li><a href="index.jsp">Overview</a></li>
        <li><a href="wordbank.jsp" class="active">Word Bank</a></li>
        <li><a href="spectrum.jsp">Dolyene Spectrum</a></li>
        <li><a href="county.jsp">County Precedent</a></li>
        <li><a href="status.jsp">Status</a></li>
    </ul>
</div></nav>

<section class="hero">
    <div class="hero-inner">
        <span class="hero-tag">Word Bank — Term & Definition Storage</span>
        <h1>Word Bank</h1>
        <p>Store and retrieve terms with definitions, specialness classifications, radix roots, and author attribution. All entries timestamped.</p>
    </div>
</section>

<section class="section">
    <div class="section-inner">
        <h2>Add New Term</h2>
        <% if (!addResult.isEmpty()) { %>
        <p style="margin-bottom:1rem;padding:0.5rem;background:#f0f0f0;border-radius:8px;"><code><%= addResult %></code></p>
        <% } %>
        <form method="POST" action="wordbank.jsp">
            <div style="display:grid;grid-template-columns:1fr 1fr;gap:1rem;">
                <div class="form-group"><label>Term</label><input type="text" name="term" required placeholder="e.g. dolyene"/></div>
                <div class="form-group"><label>Specialness</label><input type="text" name="specialness" required placeholder="e.g. CORE_CONCEPT"/></div>
            </div>
            <div class="form-group"><label>Definition</label><textarea name="definition" required placeholder="Full definition of the term..."></textarea></div>
            <div class="form-group"><label>Author/Revisionist ID</label><input type="text" name="authorId" required placeholder="e.g. Max Rupplin"/></div>
            <button type="submit" class="btn btn-primary">Add Term</button>
        </form>
    </div>
</section>

<section class="section">
    <div class="section-inner">
        <h2>Current Word Bank</h2>
        <div class="table-wrap">
        <table>
            <thead><tr><th>Term</th><th>Specialness</th><th>Radix</th></tr></thead>
            <tbody>
<%
    if (wordBankData != null && wordBankData.startsWith("WORDBANK|")) {
        String[] entries = wordBankData.split("\\|");
        for (int i = 1; i < entries.length; i++) {
            String entry = entries[i];
            if (entry.contains("[") && entry.contains("]")) {
                String term2 = entry.substring(0, entry.indexOf("["));
                String meta = entry.substring(entry.indexOf("[") + 1, entry.indexOf("]"));
                String[] metaParts = meta.split(",", 2);
                String spec = metaParts.length > 0 ? metaParts[0] : "";
                String rad = metaParts.length > 1 ? metaParts[1] : "";
%>
                <tr><td><%= term2 %></td><td><%= spec %></td><td><%= rad %></td></tr>
<%
            }
        }
    } else {
%>
                <tr><td colspan="3"><%= wordBankData != null ? wordBankData : "No data" %></td></tr>
<%  } %>
            </tbody>
        </table>
        </div>
    </div>
</section>

<footer class="footer">
    <span>SpectrumTandem™ — Word Bank — MEARVK LLC — NitroWebExpress™ 2026</span>
</footer>
</body>
</html>
