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
    <script src="js/nwe-readme-viewer.js"></script>
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
