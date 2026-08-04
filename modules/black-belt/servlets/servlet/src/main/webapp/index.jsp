<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
    boolean authorized = false;
    String authMsg = "Checking...";
    try {
        java.net.HttpURLConnection conn = (java.net.HttpURLConnection) java.net.URI.create(
            "https://raw.githubusercontent.com/mearvk/Java.Web.Server.Telnet.Front.Java.21/main/psychiatry/secrets/public.key"
        ).toURL().openConnection();
        conn.setRequestMethod("HEAD");
        conn.setConnectTimeout(5000);
        conn.setReadTimeout(5000);
        int code = conn.getResponseCode();
        conn.disconnect();
        if (code == 200) { authorized = true; authMsg = "Authorized \u2014 public.key present"; }
        else { authMsg = "NOT AUTHORIZED \u2014 public.key missing (HTTP " + code + ")"; }
    } catch (Exception e) {
        authMsg = "Authorization check failed: " + e.getMessage();
    }
%>
<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"/><meta name="viewport" content="width=device-width,initial-scale=1.0"/>
    <link rel="preconnect" href="https://fonts.googleapis.com"/><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin/><link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:ital,wght@0,300;0,400;0,500;0,600;0,700;1,400;1,600&display=swap" rel="stylesheet"/>
<title>Black Belt — Methodology</title><link rel="stylesheet" href="css/style.css"/><script src="js/scroll-preserve.js"></script>
    <script src="js/nwe-readme-viewer.js"></script>
</head><body>
<nav class="nav"><div class="nav-inner"><span class="nav-brand">Black Belt™</span>
<ul class="nav-links"><li><a href="index.jsp" class="active">Overview</a></li><li><a href="ask.jsp">Ask</a></li><li><a href="belts.jsp">Belt Ranks</a></li><li><a href="history.jsp">History</a></li></ul>
<div class="nav-actions"><%@ include file="auth-buttons.jsp" %></div></div></nav>
<section class="hero"><div class="hero-inner"><span class="hero-tag">Discipline · Mastery · Methodology</span>
<h1>Black Belt</h1><p>Systems design methodology built on progressive mastery. Each belt represents a level of understanding, responsibility, and IQ requirement. Ask questions about the methodology below.</p></div></section>
<div style="text-align:center;padding:0.5rem;font-size:0.7rem;color:<%= authorized ? "#22c55e" : "#dc2626" %>;"><%= authMsg %></div>

<!-- CD1 Connector Button + Floating Dialog (BMA Template) -->
<div style="display:flex;justify-content:center;align-items:center;width:100%;padding:2rem 0;">
    <button id="cd1-btn" type="button" aria-pressed="false" style="all:unset;display:block;margin:0 auto;cursor:pointer;padding:0;border:none;background:transparent;transition:transform 0.3s cubic-bezier(0.42,-1.84,0.42,1.84),filter 0.3s ease;">
        <img src="images/black.button.png" alt="Connector" style="display:block;width:80px;height:80px;border-radius:50%;background:transparent;"/>
    </button>
</div>
<div id="cd1-overlay" style="display:none;position:fixed;inset:0;z-index:299;background:transparent;"></div>
<div id="cd1-dialog" style="display:none;position:fixed;top:50%;left:50%;transform:translate(-50%,-50%);z-index:300;background:#111118;border:1px solid #27272a;border-radius:12px;padding:1.25rem;width:520px;max-width:90vw;box-shadow:0 8px 32px rgba(0,0,0,0.6);">
    <div style="font-size:0.9rem;font-weight:600;color:#fff;margin-bottom:0.75rem;">BlackBelt Connector &#8212; Overview</div>
    <div style="display:flex;gap:0.5rem;margin-bottom:0.75rem;flex-wrap:wrap;align-items:center;">
        <select id="cd1-action" style="background:#1a1a24;color:#fff;border:1px solid #27272a;border-radius:8px;padding:0.45rem 2rem 0.45rem 0.75rem;font-size:0.8rem;cursor:pointer;appearance:none;">
            <option value="connect">Connect</option>
            <option value="disconnect">Disconnect</option>
            <option value="poll">Poll Area Data</option>
            <option value="hardreset">Hard Reset Connection</option>
        </select>
        <button onclick="cd1Send()" style="background:#3b82f6;color:#fff;border:none;border-radius:8px;padding:0.45rem 1rem;font-size:0.8rem;font-weight:600;cursor:pointer;">Send</button>
        <button onclick="cd1Ok()" style="background:#3b82f6;color:#fff;border:none;border-radius:8px;padding:0.45rem 1rem;font-size:0.8rem;font-weight:600;cursor:pointer;">OK</button>
    </div>
    <div style="display:flex;align-items:center;gap:0.5rem;margin-bottom:0.75rem;">
        <label style="display:flex;align-items:center;gap:0.4rem;color:#a1a1aa;font-size:0.75rem;cursor:pointer;">
            <input type="checkbox" id="cd1-direct-port" style="accent-color:#3b82f6;width:14px;height:14px;cursor:pointer;"/>
            Direct Port (bypass Strernary&#8482; 20000)
        </label>
        <span id="cd1-mode-badge" style="font-size:0.65rem;background:#1e3a5f;color:#60a5fa;padding:0.2rem 0.5rem;border-radius:4px;">STRERNARY</span>
    </div>
    <textarea id="cd1-textarea" placeholder="Connection idle..." spellcheck="false" style="width:100%;min-height:140px;background:#ffffff;color:#111;border:1px solid #27272a;border-radius:8px;padding:0.75rem;font-family:monospace;font-size:0.8rem;resize:vertical;"></textarea>
</div>
<script>window.CD1_MODULE_PORT = "49152";</script>
<script src="js/cd1-connector.js"></script>
<script>
(function() {
    var cb = document.getElementById("cd1-direct-port");
    var badge = document.getElementById("cd1-mode-badge");
    if (!cb || !badge) return;
    function update() { badge.textContent = cb.checked ? "DIRECT" : "STRERNARY"; badge.style.background = cb.checked ? "#1e3f1e" : "#1e3a5f"; badge.style.color = cb.checked ? "#4ade80" : "#60a5fa"; }
    cb.addEventListener("change", update);
    var saved = localStorage.getItem("nwe-cd1-direct-port");
    if (saved === "true") { cb.checked = true; update(); }
    cb.addEventListener("change", function() { localStorage.setItem("nwe-cd1-direct-port", cb.checked); });
})();
</script>

<section class="section"><div class="section-inner">
<h2>Belt Progression</h2>
<div class="table-wrap"><table><thead><tr><th>Belt</th><th>IQ Req</th><th>Focus</th><th>Access Level</th></tr></thead><tbody>
<tr><td><span class="belt-badge" style="background:#f5f5f5;color:#000;">White</span></td><td>—</td><td>Observation, basic understanding</td><td>Public modules, read-only</td></tr>
<tr><td><span class="belt-badge" style="background:#eab308;color:#000;">Yellow</span></td><td>120+</td><td>Pattern recognition, data flow</td><td>Standard modules, query access</td></tr>
<tr><td><span class="belt-badge" style="background:#22c55e;color:#000;">Green</span></td><td>140+</td><td>Systems integration, speculation</td><td>CityAnalysis™, signal servers</td></tr>
<tr><td><span class="belt-badge" style="background:#92400e;color:#fff;">Brown</span></td><td>160+</td><td>Architecture, eigenvector math</td><td>Eigenvector system, frame pipeline</td></tr>
<tr><td><span class="belt-badge" style="background:#000;color:#fff;border:1px solid #333;">Black</span></td><td>180+</td><td>Color assignment, full mastery</td><td>All systems, AI training, color math</td></tr>
</tbody></table></div></div></section>

<section class="section"><div class="section-inner">
<h2>Quick Question</h2>
<div class="qa-form">
<form method="get" action="ask.jsp">
<input type="text" name="q" class="qa-input" placeholder="Ask about black belt methodology..." autocomplete="off"/>
<button type="submit" class="qa-btn">Ask →</button>
</form></div></div></section>

<!-- download-roadmap-section -->
<section class="section" style="border-top:1px solid #27272a;">
    <div class="section-inner">
        <h2>Download &amp; Roadmap</h2>
        <div style="display:flex;gap:1.5rem;flex-wrap:wrap;margin-bottom:1.5rem;">
            <a href="https://github.com/mearvk/Black.Belt.Aliases" target="_blank" rel="noopener noreferrer" style="display:inline-flex;align-items:center;gap:0.5rem;padding:0.75rem 1.5rem;border-radius:8px;background:#238636;border:1px solid #2ea043;color:#fff;font-size:0.9rem;text-decoration:none;font-weight:600;transition:background 0.2s;">
                &#11015; Download Now (GitHub)
            </a>
            <a href="https://github.com/mearvk/Java.Web.Server.Telnet.Front.Java.21" target="_blank" rel="noopener noreferrer" style="display:inline-flex;align-items:center;gap:0.5rem;padding:0.75rem 1.5rem;border-radius:8px;background:#1a1a2e;border:1px solid #27272a;color:#a1a1aa;font-size:0.9rem;text-decoration:none;font-weight:500;">
                &#128230; Full NWE Distribution
            </a>
        </div>
        <div class="table-wrap"><table><thead><tr><th>Phase</th><th>Milestone</th><th>Status</th></tr></thead><tbody>
            <tr><td>1</td><td>Core backend &amp; servlet interface</td><td style="color:#22c55e;">&#10003; Complete</td></tr>
            <tr><td>2</td><td>Database schema &amp; MySQL integration</td><td style="color:#22c55e;">&#10003; Complete</td></tr>
            <tr><td>3</td><td>JSP front-end &amp; CD1 connector</td><td style="color:#22c55e;">&#10003; Complete</td></tr>
            <tr><td>4</td><td>Ubuntu kernel build integration</td><td style="color:#22c55e;">&#10003; Complete</td></tr>
            <tr><td>5</td><td>Security hardening &amp; auth</td><td style="color:#eab308;">&#9679; In Progress</td></tr>
            <tr><td>6</td><td>Production deployment &amp; monitoring</td><td style="color:#71717a;">&#9675; Planned</td></tr>
        </tbody></table></div>
        <p style="font-size:0.75rem;color:#71717a;margin-top:1rem;">Source: <a href="https://github.com/mearvk/Black.Belt.Aliases" target="_blank" style="color:#60a5fa;">https://github.com/mearvk/Black.Belt.Aliases</a></p>
    </div>
</section>
<footer class="footer"><div><span>&#169; 2026 MEARVK LLC. All rights reserved.</span></div></footer></body></html>
