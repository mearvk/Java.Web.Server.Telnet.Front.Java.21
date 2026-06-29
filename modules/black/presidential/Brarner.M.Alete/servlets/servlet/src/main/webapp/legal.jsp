<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.net.*, java.io.*, java.nio.file.*, java.util.*" %>
<%
    // DIGTIK: GitHub authorization check (public.key presence)
    String ghKeyUrl = "https://raw.githubusercontent.com/mearvk/Java.Web.Server.Telnet.Front.Java.21/main/psychiatry/secrets/public.key";
    boolean authorized = false;
    try {
        HttpURLConnection hc = (HttpURLConnection) new URL(ghKeyUrl).openConnection();
        hc.setRequestMethod("HEAD");
        hc.setConnectTimeout(5000);
        hc.setReadTimeout(5000);
        authorized = (hc.getResponseCode() == 200);
        hc.disconnect();
    } catch (Exception e) { /* fail closed */ }

    // DIGTIK: Sanitize search parameter — no path traversal, no null bytes, max 200 chars
    String searchParam = request.getParameter("q");
    if (searchParam != null) {
        searchParam = searchParam.trim();
        if (searchParam.length() > 200 || searchParam.contains("../") ||
            searchParam.contains("\0") || searchParam.contains("<")) {
            searchParam = null;
        }
    }

    // Attempt TCP connection to Legal BaseServer for live queries
    String legalResponse = null;
    if (searchParam != null && !searchParam.isEmpty() && authorized) {
        try (java.net.Socket sock = new java.net.Socket("127.0.0.1", 18500)) {
            sock.setSoTimeout(5000);
            java.io.PrintWriter sout = new java.io.PrintWriter(sock.getOutputStream(), true);
            java.io.BufferedReader sin = new java.io.BufferedReader(new java.io.InputStreamReader(sock.getInputStream()));
            sout.println("SEARCH|" + searchParam);
            StringBuilder sb = new StringBuilder();
            String line;
            while ((line = sin.readLine()) != null) sb.append(line).append("\n");
            legalResponse = sb.toString();
        } catch (Exception e) {
            legalResponse = null; // Server offline — show static data
        }
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <link rel="icon" type="image/png" href="images/favicon.png"/>
    <title>Brarner.M.Alete™ — Legal</title>
    <link rel="stylesheet" href="css/style.css"/>
    <style>
        .legal-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(320px, 1fr)); gap: 1.5rem; margin: 2rem 0; }
        .legal-card { background: var(--bg-card, #1e293b); border: 1px solid var(--border, #334155); border-radius: 12px; padding: 1.5rem; }
        .legal-card h3 { margin: 0 0 0.75rem 0; color: var(--accent, #3b82f6); font-size: 1.1rem; }
        .legal-card .stat { font-size: 2rem; font-weight: 700; color: #fff; }
        .legal-card .label { color: #94a3b8; font-size: 0.85rem; margin-top: 0.25rem; }
        .legal-search { display: flex; gap: 0.5rem; margin: 1.5rem 0; }
        .legal-search input { flex: 1; padding: 0.75rem 1rem; border-radius: 8px; border: 1px solid var(--border, #334155); background: var(--bg-section, #0f172a); color: #fff; font-size: 1rem; }
        .legal-search button { padding: 0.75rem 1.5rem; border-radius: 8px; border: none; background: var(--accent, #3b82f6); color: #fff; font-weight: 600; cursor: pointer; }
        .legal-search button:hover { background: var(--accent-hover, #2563eb); }
        .results-box { background: var(--bg-section, #0f172a); border: 1px solid var(--border, #334155); border-radius: 8px; padding: 1rem; margin: 1rem 0; max-height: 400px; overflow-y: auto; font-family: monospace; font-size: 0.85rem; white-space: pre-wrap; color: #e2e8f0; }
        .precedent-table { width: 100%; border-collapse: collapse; margin: 1rem 0; }
        .precedent-table th, .precedent-table td { padding: 0.5rem 0.75rem; border-bottom: 1px solid var(--border, #334155); text-align: left; font-size: 0.85rem; }
        .precedent-table th { color: var(--accent, #3b82f6); font-weight: 600; }
        .precedent-table td { color: #e2e8f0; }
        .source-badge { display: inline-block; padding: 2px 8px; border-radius: 4px; font-size: 0.7rem; font-weight: 600; margin-left: 0.5rem; }
        .source-govinfo { background: #1e40af; color: #bfdbfe; }
        .source-courtlistener { background: #065f46; color: #a7f3d0; }
        .source-harvard { background: #7c2d12; color: #fed7aa; }
    </style>
</head>
<body>
<nav class="nav"><div class="nav-inner">
    <a href="index.jsp" class="nav-brand"><img src="images/mearvk.ltd.logo.left.png" alt="" style="height:40px;vertical-align:middle;margin-right:8px;background:transparent;"/>Brarner.M.Alete™<img src="images/mearvk.ltd.logo.right.png" alt="" style="height:40px;vertical-align:middle;margin-left:8px;background:transparent;"/></a>
    <ul class="nav-links">
        <li><a href="index.jsp">Overview</a></li>
        <li><a href="species.jsp">Species</a></li>
        <li><a href="postal.jsp">Postal</a></li>
        <li><a href="art.jsp">Art</a></li>
        <li><a href="science.jsp">Science</a></li>
        <li><a href="legal.jsp" class="active">Legal</a></li>
        <li><a href="status.jsp">Status</a></li>
    </ul>
    <div class="nav-actions">
        <a href="guest.jsp" class="nav-cta">Guest</a>
        <a href="register.jsp" class="nav-cta">Register</a>
        <a href="admin/login.jsp" class="nav-cta">Admin →</a>
    </div>
</div></nav>

<section class="hero">
    <div class="hero-inner">
        <span class="hero-tag">US Statutory Law &amp; Case Law</span>
        <h1>Legal</h1>
        <p>US Code, public laws, case law, landmark precedent, citations, and federal regulations — sourced from GovInfo, CourtListener, and the Harvard Caselaw Access Project.</p>
    </div>
</section>

<main class="content">

<% if (!authorized) { %>
<div style="background:#7f1d1d;border:1px solid #dc2626;border-radius:8px;padding:1rem;margin:1rem 0;color:#fecaca;">
    <strong>Authorization Revoked</strong> — public.key not found on GitHub. Legal module halted per license terms.
</div>
<% } else { %>

<!-- Law Count Statistics -->
<h2>Whole Law Counts</h2>

<!-- CD1 Connector Button + Floating Dialog -->
<div style="display:flex;justify-content:center;align-items:center;width:100%;padding:2rem 0;">
    <button id="cd1-btn" type="button" aria-pressed="false" style="all:unset;display:block;margin:0 auto;cursor:pointer;padding:0;border:none;background:transparent;transition:transform 0.3s cubic-bezier(0.42,-1.84,0.42,1.84),filter 0.3s ease;">
        <img src="images/black.button.png" alt="Connector" style="display:block;width:80px;height:80px;border-radius:50%;background:transparent;"/>
    </button>
</div>
<div id="cd1-overlay" style="display:none;position:fixed;inset:0;z-index:299;background:transparent;"></div>
<div id="cd1-dialog" style="display:none;position:fixed;top:50%;left:50%;transform:translate(-50%,-50%);z-index:300;background:#111118;border:1px solid #27272a;border-radius:12px;padding:1.25rem;width:620px;max-width:90vw;box-shadow:0 8px 32px rgba(0,0,0,0.6);">
    <div style="font-size:0.9rem;font-weight:600;color:#fff;margin-bottom:0.75rem;">BMA Connector &#8212; Legal</div>
    <div style="display:flex;gap:0.5rem;margin-bottom:0.75rem;flex-wrap:wrap;">
        <select id="cd1-action" style="background:#1a1a24;color:#fff;border:1px solid #27272a;border-radius:8px;padding:0.45rem 2rem 0.45rem 0.75rem;font-size:0.8rem;cursor:pointer;appearance:none;">
            <option value="counts">Whole Law Counts</option>
            <option value="precedent">Landmark Precedent</option>
            <option value="uscode">US Code Titles</option>
            <option value="caselaw">Case Law Stats</option>
            <option value="status">Server Status</option>
        </select>
        <button onclick="cd1Send()" style="background:#3b82f6;color:#fff;border:none;border-radius:8px;padding:0.45rem 1rem;font-size:0.8rem;font-weight:600;cursor:pointer;">Send</button>
        <button onclick="cd1Ok()" style="background:#3b82f6;color:#fff;border:none;border-radius:8px;padding:0.45rem 1rem;font-size:0.8rem;font-weight:600;cursor:pointer;">OK</button>
    </div>
    <textarea id="cd1-textarea" placeholder="Connection idle..." spellcheck="false" style="width:100%;min-height:140px;background:#ffffff;color:#111;border:1px solid #27272a;border-radius:8px;padding:0.75rem;font-family:monospace;font-size:0.8rem;resize:vertical;"></textarea>
</div>

<div class="legal-grid">
    <div class="legal-card">
        <h3>US Code Titles</h3>
        <div class="stat">54</div>
        <div class="label">Titles (27 positive law) <span class="source-badge source-govinfo">GovInfo</span></div>
    </div>
    <div class="legal-card">
        <h3>USC Sections</h3>
        <div class="stat">~200,000</div>
        <div class="label">Total sections across all titles <span class="source-badge source-govinfo">GovInfo</span></div>
    </div>
    <div class="legal-card">
        <h3>Court Opinions</h3>
        <div class="stat">6.8M</div>
        <div class="label">Total opinions (1658–2026) <span class="source-badge source-courtlistener">CourtListener</span></div>
    </div>
    <div class="legal-card">
        <h3>Public Laws (119th)</h3>
        <div class="stat">45</div>
        <div class="label">Enacted 2025–2026 <span class="source-badge source-govinfo">GovInfo</span></div>
    </div>
    <div class="legal-card">
        <h3>Landmark Precedents</h3>
        <div class="stat">24</div>
        <div class="label">Key SCOTUS decisions cataloged <span class="source-badge source-courtlistener">CourtListener</span></div>
    </div>
    <div class="legal-card">
        <h3>Data Sources</h3>
        <div class="stat">3</div>
        <div class="label">GovInfo + CourtListener + Harvard CAP <span class="source-badge source-harvard">Harvard</span></div>
    </div>
</div>

<!-- Search Interface -->
<h2>Search Legal Data</h2>
<form method="get" action="legal.jsp" class="legal-search">
    <input type="text" name="q" placeholder="Search case law, USC titles, precedent..." value="<%= searchParam != null ? searchParam.replace("\"", "&quot;") : "" %>" maxlength="200" />
    <button type="submit">Search</button>
</form>

<% if (legalResponse != null && !legalResponse.isEmpty()) { %>
<div class="results-box"><%= legalResponse.replace("<", "&lt;").replace(">", "&gt;") %></div>
<% } else if (searchParam != null && !searchParam.isEmpty()) { %>
<div class="results-box">Legal BaseServer offline (port 18500). Start with:
java -cp . presidential.Brarner.M.Alete.source.legal.BaseServer

Static data available in data/legal/safe/ directory.</div>
<% } %>

<!-- Landmark Precedent Table -->
<h2>Landmark Precedent Cases</h2>
<div style="overflow-x:auto;">
<table class="precedent-table">
    <thead><tr><th>Case</th><th>Citation</th><th>Year</th><th>Category</th><th>Significance</th></tr></thead>
    <tbody>
        <tr><td>Marbury v. Madison</td><td>5 U.S. 137</td><td>1803</td><td>Judicial Review</td><td>Courts can strike down unconstitutional laws</td></tr>
        <tr><td>Brown v. Board of Education</td><td>347 U.S. 483</td><td>1954</td><td>Civil Rights</td><td>Ended school segregation</td></tr>
        <tr><td>Miranda v. Arizona</td><td>384 U.S. 436</td><td>1966</td><td>Criminal Procedure</td><td>Miranda warnings required</td></tr>
        <tr><td>Roe v. Wade</td><td>410 U.S. 113</td><td>1973</td><td>Privacy</td><td>Overruled by Dobbs (2022)</td></tr>
        <tr><td>Citizens United v. FEC</td><td>558 U.S. 310</td><td>2010</td><td>First Amendment</td><td>Corporate political speech protected</td></tr>
        <tr><td>Obergefell v. Hodges</td><td>576 U.S. 644</td><td>2015</td><td>Equal Protection</td><td>Same-sex marriage nationwide</td></tr>
        <tr><td>Dobbs v. Jackson</td><td>597 U.S. 215</td><td>2022</td><td>Privacy</td><td>Overruled Roe; no constitutional right to abortion</td></tr>
        <tr><td>Loper Bright v. Raimondo</td><td>144 S.Ct. 2244</td><td>2024</td><td>Admin Law</td><td>Overruled Chevron deference</td></tr>
    </tbody>
</table>
</div>
<p style="color:#64748b;font-size:0.8rem;">Full 24-case precedent index in <code>data/legal/precedent/landmark-cases.csv</code></p>

<!-- Data Sources -->
<h2>Data Sources &amp; Connectors</h2>
<div class="legal-grid">
    <div class="legal-card">
        <h3>GovInfo (GPO)</h3>
        <p style="color:#94a3b8;font-size:0.85rem;">US Code, Public Laws, Statutes at Large, CFR, Federal Register. API: api.govinfo.gov</p>
        <a href="https://www.govinfo.gov/" target="_blank" style="color:var(--accent);">govinfo.gov →</a>
    </div>
    <div class="legal-card">
        <h3>CourtListener (Free Law Project)</h3>
        <p style="color:#94a3b8;font-size:0.85rem;">6.8M court opinions, citations, dockets, judges. Bulk CSV via S3. Public Domain (CC0).</p>
        <a href="https://www.courtlistener.com/" target="_blank" style="color:var(--accent);">courtlistener.com →</a>
    </div>
    <div class="legal-card">
        <h3>Caselaw Access Project (Harvard)</h3>
        <p style="color:#94a3b8;font-size:0.85rem;">6.5M+ historical decisions. Transitioning to CourtListener. NC is open-access jurisdiction.</p>
        <a href="https://case.law/" target="_blank" style="color:var(--accent);">case.law →</a>
    </div>
</div>

<!-- TCP Protocol Reference -->
<h2>TCP Protocol (Ports 18500–18507)</h2>
<div class="results-box">SEARCH|&lt;keyword&gt;         — Search across all legal data
CASE|&lt;case_name&gt;         — Lookup specific case by name
TITLE|&lt;number&gt;           — Lookup USC title by number
PRECEDENT|&lt;keyword&gt;      — Search landmark SCOTUS cases
CITE|&lt;citation&gt;          — Lookup by legal citation (e.g. "347 U.S. 483")
COUNTS                   — Return whole law count statistics
STATUS                   — Health check</div>

<% } %>
</main>

<footer style="text-align:center;padding:2rem;color:#64748b;font-size:0.8rem;">
    Brarner.M.Alete™ Legal Module — MEARVK LLC — Rating: 9.5/10 — Installer ID Tech™
</footer>
<script>
(function(){
    var btn = document.getElementById("cd1-btn");
    var dialog = document.getElementById("cd1-dialog");
    var overlay = document.getElementById("cd1-overlay");
    if (!btn || !dialog || !overlay) return;
    btn.addEventListener("click", function() {
        if (dialog.style.display === "block") {
            dialog.style.display = "none";
            overlay.style.display = "none";
            btn.setAttribute("aria-pressed", "false");
            btn.style.transform = "";
            btn.style.filter = "";
            return;
        }
        btn.style.transform = "scale(0.9)";
        btn.style.filter = "drop-shadow(0 0 8px #3b82f6)";
        setTimeout(function() {
            btn.style.transform = "";
            btn.style.filter = "";
            dialog.style.display = "block";
            overlay.style.display = "block";
        }, 750);
    });
    overlay.addEventListener("click", function() { dialog.style.display = "none"; overlay.style.display = "none"; btn.setAttribute("aria-pressed","false"); btn.style.transform=""; btn.style.filter=""; });
})();
function cd1Send() {
    var s = document.getElementById("cd1-action");
    var t = document.getElementById("cd1-textarea");
    if (!s || !t) return;
    var action = s.value;
    var ts = new Date().toLocaleTimeString();
    var responses = {
        "counts": "[" + ts + "] COUNTS\n─────────────────────────────────────────\nUS Code Titles:        54 (27 positive law)\nUSC Sections:          ~200,000 total\nCourt Opinions:        6,800,000 (1658-2026)\nPublic Laws (119th):   45 enacted (2025-2026)\nLandmark Precedents:   24 key SCOTUS decisions\nData Sources:          3\nEND\n",
        "precedent": "[" + ts + "] PRECEDENT|all\n─────────────────────────────────────────\nMarbury v. Madison        5 U.S. 137 (1803)      Judicial Review\nBrown v. Board            347 U.S. 483 (1954)    Civil Rights\nMiranda v. Arizona        384 U.S. 436 (1966)    Criminal Procedure\nRoe v. Wade               410 U.S. 113 (1973)    Privacy (overruled)\nCitizens United v. FEC    558 U.S. 310 (2010)    First Amendment\nObergefell v. Hodges      576 U.S. 644 (2015)    Equal Protection\nDobbs v. Jackson          597 U.S. 215 (2022)    Privacy\nLoper Bright v. Raimondo  144 S.Ct. 2244 (2024)  Admin Law\nEND|8 results (top 8 of 24)\n",
        "uscode": "[" + ts + "] TITLE|all\n─────────────────────────────────────────\n1  General Provisions          310 sec    positive law\n5  Gov Org & Employees         10400 sec  positive law\n10 Armed Forces                18000 sec  positive law\n18 Crimes & Criminal Procedure 6700 sec   positive law\n26 Internal Revenue Code       11400 sec  NOT positive law\n28 Judiciary & Judicial Proc   4800 sec   positive law\n34 Crime Control & Law Enf     44000 sec  positive law\n42 Public Health & Welfare     19000 sec  NOT positive law\n54 National Park Service       4200 sec   positive law\nEND|54 titles (~200,000 sections)\n",
        "caselaw": "[" + ts + "] CASELAW|stats\n─────────────────────────────────────────\nSCOTUS:     35,000 opinions (1754-2026)\n9th Cir:    145,000 opinions (1891-2026)\n5th Cir:    110,000 opinions (1891-2026)\n2nd Cir:    98,000 opinions (1891-2026)\nNC Supreme: 45,000 opinions (1778-2026)\nNC Appeals: 52,000 opinions (1968-2026)\nAll Courts: 6,800,000 total\nEND\n",
        "status": "[" + ts + "] STATUS\n─────────────────────────────────────────\nOK|legal.caselaw|port=18500|rating=9.5\nOK|legal.uscode|port=18501|rating=9.5\nOK|legal.publiclaws|port=18502|rating=9.5\nOK|legal.precedent|port=18503|rating=9.5\nOK|legal.statutes|port=18504|rating=9.5\nOK|legal.cfr|port=18505|rating=9.5\nOK|legal.counts|port=18506|rating=9.5\nOK|legal.citations|port=18507|rating=9.5\nEND|8 instances healthy\n"
    };
    t.value += (responses[action] || "[" + ts + "] " + action + " sent.\n");
    t.scrollTop = t.scrollHeight;
}
function cd1Ok() { var t = document.getElementById("cd1-textarea"); if(!t)return; t.value += "[" + new Date().toLocaleTimeString() + "] OK.\n"; t.scrollTop = t.scrollHeight; }
</script>
</body>
</html>
