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
    <div class="nav-actions">
        <a href="categories.jsp" class="nav-cta">View Categories →</a>
    </div>
</div></nav>

<section class="hero">
    <div class="hero-inner">
        <span class="hero-tag">Dark Gray — Moral Surveillance</span>
        <h1>Defined™</h1>
        <p>Definition to narrow cause: defined. AI surveillance and moral assessment across 29 categories. 12 protocol handlers with UFW-managed port cycling. Strernary™ international feedback.</p>
    </div>
</section>

<div class="notice">
    <strong>NOTICE:</strong> Known trespass against final medical review may result in being discharged from Earth forever. Kinded and Secondary (implied as good).
</div>

<!-- CD1 Connector -->
<div style="display:flex;justify-content:center;align-items:center;width:100%;padding:2rem 0;">
    <button id="cd1-btn" type="button" aria-pressed="false" style="all:unset;display:block;margin:0 auto;cursor:pointer;padding:0;border:none;background:transparent;transition:transform 0.3s cubic-bezier(0.42,-1.84,0.42,1.84),filter 0.3s ease;">
        <div style="width:80px;height:80px;border-radius:50%;background:#2d2d2d;border:3px solid #808080;display:flex;align-items:center;justify-content:center;font-size:1.5rem;color:#a0a0a0;">⬡</div>
    </button>
</div>
<div id="cd1-overlay" style="display:none;position:fixed;inset:0;z-index:299;background:transparent;"></div>
<div id="cd1-dialog" style="display:none;position:fixed;top:50%;left:50%;transform:translate(-50%,-50%);z-index:300;background:#222;border:1px solid #3d3d3d;border-radius:12px;padding:1.25rem;width:520px;max-width:90vw;box-shadow:0 8px 32px rgba(0,0,0,0.6);">
    <div style="font-size:0.9rem;font-weight:600;color:#e8e8e8;margin-bottom:0.75rem;">Defined Connector — Port 49220</div>
    <div style="display:flex;gap:0.5rem;margin-bottom:0.75rem;flex-wrap:wrap;align-items:center;">
        <select id="cd1-action" style="background:#2d2d2d;color:#e8e8e8;border:1px solid #3d3d3d;border-radius:8px;padding:0.45rem 2rem 0.45rem 0.75rem;font-size:0.8rem;cursor:pointer;">
            <option value="connect">Connect</option>
            <option value="disconnect">Disconnect</option>
            <option value="scan">Trigger Scan</option>
            <option value="assess">Get Assessment</option>
            <option value="ntsb">NTSB Query</option>
        </select>
        <button onclick="cd1Send()" style="background:#808080;color:#fff;border:none;border-radius:8px;padding:0.45rem 1rem;font-size:0.8rem;font-weight:600;cursor:pointer;">Send</button>
        <button onclick="cd1Ok()" style="background:#808080;color:#fff;border:none;border-radius:8px;padding:0.45rem 1rem;font-size:0.8rem;font-weight:600;cursor:pointer;">OK</button>
    </div>
    <div style="display:flex;align-items:center;gap:0.5rem;margin-bottom:0.75rem;">
        <label style="display:flex;align-items:center;gap:0.4rem;color:#999;font-size:0.75rem;cursor:pointer;">
            <input type="checkbox" id="cd1-direct-port" style="accent-color:#808080;width:14px;height:14px;cursor:pointer;"/>
            Direct Port (bypass Strernary™ 20000)
        </label>
        <span id="cd1-mode-badge" style="font-size:0.65rem;background:#2d2d2d;color:#808080;padding:0.2rem 0.5rem;border-radius:4px;">STRERNARY</span>
    </div>
    <textarea id="cd1-textarea" placeholder="Connection idle..." spellcheck="false" style="width:100%;min-height:140px;background:#fff;color:#111;border:1px solid #3d3d3d;border-radius:8px;padding:0.75rem;font-family:monospace;font-size:0.8rem;resize:vertical;"></textarea>
</div>
<script>window.CD1_MODULE_PORT = "49220";</script>
<script src="js/cd1-connector.js"></script>

<section class="section">
    <div class="section-inner">
        <div style="margin-bottom:2rem;padding:1rem;border:1px solid <%= authorized ? "#22c55e" : "#ef4444" %>;border-radius:8px;background:rgba(0,0,0,0.2);">
            <span style="font-size:0.85rem;color:<%= authorized ? "#22c55e" : "#ef4444" %>;font-weight:600;">&#9679; <%= authStatus %></span>
            <span style="font-size:0.75rem;color:#999;margin-left:1rem;"><%= new java.text.SimpleDateFormat("yyyy-MM-dd HH:mm:ss z").format(new java.util.Date()) %></span>
        </div>
        <h2>Module Components</h2>
        <div class="table-wrap">
            <table>
                <thead><tr><th>Component</th><th>Description</th><th>Link</th></tr></thead>
                <tbody>
                    <tr><td>Categories</td><td>29 assessment domains — banking, schools, public officials, NTSB, and more</td><td><a href="categories.jsp">Browse →</a></td></tr>
                    <tr><td>Protocols</td><td>12 port handlers — SSH, HTTPS, SMTP, FTP, MySQL with UFW management</td><td><a href="protocols.jsp">Browse →</a></td></tr>
                    <tr><td>Reports</td><td>Periodic moral assessment — weekly, monthly, quarterly, annual</td><td><a href="status.jsp">View →</a></td></tr>
                    <tr><td>NTSB</td><td>Direct communication with www.ntsb.gov via port 80</td><td><a href="status.jsp">Check →</a></td></tr>
                </tbody>
            </table>
        </div>
    </div>
</section>

<section class="section">
    <div class="section-inner">
        <h2>Infrastructure</h2>
        <div class="table-wrap">
            <table>
                <thead><tr><th>Property</th><th>Value</th></tr></thead>
                <tbody>
                    <tr><td>AI Server Port</td><td><code>49220</code></td></tr>
                    <tr><td>Backend Port</td><td><code>49221</code> (protocol management, hours-restricted)</td></tr>
                    <tr><td>Protocol</td><td><code>NWE-DEFINED</code></td></tr>
                    <tr><td>Database</td><td><code>defined_dark_gray</code> (MySQL)</td></tr>
                    <tr><td>AI Inference</td><td><code>Strernary™ port 20000</code> (DJL/PyTorch)</td></tr>
                    <tr><td>Webapp Context</td><td><code>/defined</code></td></tr>
                    <tr><td>Strernary Feedback</td><td><code>data/strernary-feedback/</code></td></tr>
                    <tr><td>Connection Hours</td><td>Weekdays 06:00–23:00, Weekends 08:00–20:00 EST</td></tr>
                    <tr><td>UFW Managed Ports</td><td>22, 443, 465, 587, 990, 993</td></tr>
                    <tr><td>Installer Tech ID</td><td>Max Rupplin</td></tr>
                </tbody>
            </table>
        </div>
    </div>
</section>

<section class="section">
    <div class="section-inner">
        <h2>Commands (Telnet — port 49220)</h2>
        <div class="table-wrap">
            <table>
                <thead><tr><th>Command</th><th>Description</th></tr></thead>
                <tbody>
                    <tr><td><code>scan</code></td><td>View next scheduled internet scan time</td></tr>
                    <tr><td><code>assess</code></td><td>View today's assessments (1,2,3,4,final)</td></tr>
                    <tr><td><code>report &lt;period&gt;</code></td><td>View report schedule and priorities</td></tr>
                    <tr><td><code>ntsb</code></td><td>Enter NTSB direct communication mode</td></tr>
                    <tr><td><code>categories</code></td><td>List all 29 assessment categories</td></tr>
                    <tr><td><code>status</code></td><td>Module health and uptime</td></tr>
                    <tr><td><code>quit</code></td><td>Close session</td></tr>
                </tbody>
            </table>
        </div>
    </div>
</section>

<footer class="footer"><div><span>&#169; 2026 MEARVK LLC. All rights reserved. Defined™ — Dark Gray.</span></div></footer>
</body>
</html>
