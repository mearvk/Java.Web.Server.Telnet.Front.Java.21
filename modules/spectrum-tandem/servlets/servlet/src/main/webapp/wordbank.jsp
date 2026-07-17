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
    <script src="js/nwe-readme-viewer.js"></script>
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
