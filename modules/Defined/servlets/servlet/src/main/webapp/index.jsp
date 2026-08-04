<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.net.*, java.io.*" %>
<%
    String ghKeyUrl = "https://raw.githubusercontent.com/mearvk/Java.Web.Server.Telnet.Front.Java.21/main/psychiatry/secrets/public.key";
    boolean authorized = false;
    String authStatus = "Unknown";
    try {
        HttpURLConnection hc = (HttpURLConnection) new URL(ghKeyUrl).openConnection();
        hc.setRequestMethod("HEAD");
        hc.setConnectTimeout(5000);
        hc.setReadTimeout(5000);
        authorized = (hc.getResponseCode() == 200);
        authStatus = authorized ? "Authorized (public.key present)" : "Revoked";
        hc.disconnect();
    } catch (Exception e) { authStatus = "Check failed"; }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/>
    <link rel="preconnect" href="https://fonts.googleapis.com"/><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin/><link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:ital,wght@0,300;0,400;0,500;0,600;0,700;1,400;1,600&display=swap" rel="stylesheet"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>Defined™ — NitroWebExpress™</title>
    <link rel="stylesheet" href="css/style.css"/>
    <script src="js/scroll-preserve.js"></script>
    <script src="js/nwe-readme-viewer.js"></script>
</head>
<body>
<nav class="nav"><div class="nav-inner">
    <span class="nav-brand">Defined™</span>
    <ul class="nav-links">
        <li><a href="index.jsp" class="active">Overview</a></li>
        <li><a href="categories.jsp">Categories</a></li>
        <li><a href="protocols.jsp">Protocols</a></li>
        <li><a href="status.jsp">Status</a></li>
    </ul>
<div class="nav-actions"><%@ include file="auth-buttons.jsp" %></div></div></nav>

<section class="hero">
    <div class="hero-inner">
        <span class="hero-tag">Dark Gray — Moral Surveillance</span>
        <h1>Defined™</h1>
        <p>Definition to narrow cause: defined. AI surveillance and moral assessment across 29 categories. 12 protocol handlers with UFW-managed port cycling. Strernary™ international feedback.</p>
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
    <div style="font-size:0.9rem;font-weight:600;color:#e8e0d6;margin-bottom:0.75rem;">CD1 Connector &#8212; Port 49220</div>
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
<script>window.CD1_MODULE_PORT = "49220";</script>
<script src="js/cd1-connector.js"></script>


<div class="notice">
    <strong>NOTICE:</strong> Known trespass against final medical review may result in being discharged from Earth forever. Kinded and Secondary (implied as good).
</div>

<!-- download-roadmap-section -->
<section class="section" style="border-top:1px solid #27272a;">
    <div class="section-inner">
        <h2>Download &amp; Roadmap</h2>
        <div style="display:flex;gap:1.5rem;flex-wrap:wrap;margin-bottom:1.5rem;">
            <a href="https://github.com/mearvk/Java.Web.Server.Telnet.Front.Java.21/tree/main/modules/Defined" target="_blank" rel="noopener noreferrer" style="display:inline-flex;align-items:center;gap:0.5rem;padding:0.75rem 1.5rem;border-radius:8px;background:#238636;border:1px solid #2ea043;color:#fff;font-size:0.9rem;text-decoration:none;font-weight:600;transition:background 0.2s;">
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
        <p style="font-size:0.75rem;color:#71717a;margin-top:1rem;">Source: <a href="https://github.com/mearvk/Java.Web.Server.Telnet.Front.Java.21/tree/main/modules/Defined" target="_blank" style="color:#60a5fa;">github.com/mearvk/Java.Web.Server.Telnet.Front.Java.21/tree/main/modules/Defined</a></p>
    </div>
</section>

</body>
</html>
