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
    <title>Green.Durham.Grass.and.Herb™ — NitroWebExpress™</title>
    <link rel="stylesheet" href="css/style.css"/>
    <script src="js/scroll-preserve.js"></script>
</head>
<body>
<nav class="nav"><div class="nav-inner">
    <span class="nav-brand">Green.Durham™</span>
    <ul class="nav-links">
        <li><a href="index.jsp" class="active">Overview</a></li>
        <li><a href="labor.jsp">Labor Laws</a></li>
        <li><a href="ethics.jsp">Ethics</a></li>
        <li><a href="status.jsp">Status</a></li>
    </ul>
    <div class="nav-actions"><a href="labor.jsp" class="nav-cta">NC Labor Laws →</a></div>
</div></nav>

<section class="hero">
    <div class="hero-inner">
        <span class="hero-tag">Durham, NC — Labor &amp; Ethics</span>
        <h1>Green.Durham.Grass.and.Herb™</h1>
        <p>Labor, ethical, and moral concerns. NC labor laws, worker protections, compliance monitoring, and ethical governance via Strernary™ AI.</p>
    </div>
</section>

<!-- CD1 Connector -->
<div style="display:flex;justify-content:center;align-items:center;width:100%;padding:2rem 0;">
    <button id="cd1-btn" type="button" aria-pressed="false" style="all:unset;display:block;margin:0 auto;cursor:pointer;padding:0;border:none;background:transparent;transition:transform 0.3s cubic-bezier(0.42,-1.84,0.42,1.84),filter 0.3s ease;">
        <div style="width:80px;height:80px;border-radius:50%;background:#14301a;border:3px solid #22c55e;display:flex;align-items:center;justify-content:center;font-size:1.5rem;color:#4ade80;">❋</div>
    </button>
</div>
<div id="cd1-overlay" style="display:none;position:fixed;inset:0;z-index:299;background:transparent;"></div>
<div id="cd1-dialog" style="display:none;position:fixed;top:50%;left:50%;transform:translate(-50%,-50%);z-index:300;background:#0f2415;border:1px solid #1e4a26;border-radius:12px;padding:1.25rem;width:520px;max-width:90vw;box-shadow:0 8px 32px rgba(0,0,0,0.6);">
    <div style="font-size:0.9rem;font-weight:600;color:#e8f5e9;margin-bottom:0.75rem;">GDGH Connector — Port 20000</div>
    <div style="display:flex;gap:0.5rem;margin-bottom:0.75rem;flex-wrap:wrap;align-items:center;">
        <select id="cd1-action" style="background:#14301a;color:#e8f5e9;border:1px solid #1e4a26;border-radius:8px;padding:0.45rem 2rem 0.45rem 0.75rem;font-size:0.8rem;cursor:pointer;">
            <option value="connect">Connect</option>
            <option value="disconnect">Disconnect</option>
            <option value="labor-query">Labor Query</option>
            <option value="ethics-check">Ethics Check</option>
            <option value="compliance">Compliance</option>
        </select>
        <button onclick="cd1Send()" style="background:#22c55e;color:#fff;border:none;border-radius:8px;padding:0.45rem 1rem;font-size:0.8rem;font-weight:600;cursor:pointer;">Send</button>
        <button onclick="cd1Ok()" style="background:#22c55e;color:#fff;border:none;border-radius:8px;padding:0.45rem 1rem;font-size:0.8rem;font-weight:600;cursor:pointer;">OK</button>
    </div>
    <div style="display:flex;align-items:center;gap:0.5rem;margin-bottom:0.75rem;">
        <label style="display:flex;align-items:center;gap:0.4rem;color:#81c784;font-size:0.75rem;cursor:pointer;">
            <input type="checkbox" id="cd1-direct-port" style="accent-color:#22c55e;width:14px;height:14px;cursor:pointer;"/>
            Direct Port (bypass Strernary™ 20000)
        </label>
        <span id="cd1-mode-badge" style="font-size:0.65rem;background:#14301a;color:#22c55e;padding:0.2rem 0.5rem;border-radius:4px;">STRERNARY</span>
    </div>
    <textarea id="cd1-textarea" placeholder="Connection idle..." spellcheck="false" style="width:100%;min-height:140px;background:#fff;color:#111;border:1px solid #1e4a26;border-radius:8px;padding:0.75rem;font-family:monospace;font-size:0.8rem;resize:vertical;"></textarea>
</div>
<script>window.CD1_MODULE_PORT = "20000";</script>
<script src="js/cd1-connector.js"></script>

<section class="section">
    <div class="section-inner">
        <div style="margin-bottom:2rem;padding:1rem;border:1px solid <%= authorized ? "#22c55e" : "#ef4444" %>;border-radius:8px;background:rgba(0,0,0,0.2);">
            <span style="font-size:0.85rem;color:<%= authorized ? "#22c55e" : "#ef4444" %>;font-weight:600;">&#9679; <%= authStatus %></span>
            <span style="font-size:0.75rem;color:#81c784;margin-left:1rem;"><%= new java.text.SimpleDateFormat("yyyy-MM-dd HH:mm:ss z").format(new java.util.Date()) %></span>
        </div>
        <h2>Module Components</h2>
        <div class="table-wrap"><table>
            <thead><tr><th>Component</th><th>Description</th><th>Link</th></tr></thead>
            <tbody>
                <tr><td>Labor Laws</td><td>NC labor regulations and worker protections</td><td><a href="labor.jsp">Browse →</a></td></tr>
                <tr><td>Ethics</td><td>Ethical and moral concern database</td><td><a href="ethics.jsp">Browse →</a></td></tr>
                <tr><td>Compliance</td><td>Labor compliance monitoring and alerts</td><td><a href="status.jsp">View →</a></td></tr>
                <tr><td>AI Search</td><td>Strernary™-powered query for labor and ethics data</td><td><a href="status.jsp">Check →</a></td></tr>
            </tbody>
        </table></div>
    </div>
</section>

<section class="section">
    <div class="section-inner">
        <h2>Infrastructure</h2>
        <div class="table-wrap"><table>
            <thead><tr><th>Property</th><th>Value</th></tr></thead>
            <tbody>
                <tr><td>TCP Port</td><td><code>20000</code></td></tr>
                <tr><td>Protocol</td><td><code>NWE-GDGH</code></td></tr>
                <tr><td>Database</td><td><code>nwe_gdgh</code> (MySQL)</td></tr>
                <tr><td>AI Inference</td><td><code>Strernary™ port 20000</code></td></tr>
                <tr><td>Webapp Context</td><td><code>/gdgh</code></td></tr>
                <tr><td>Listener Class</td><td><code>listeners.BaseListener</code></td></tr>
            </tbody>
        </table></div>
    </div>
</section>

<section class="section">
    <div class="section-inner">
        <h2>Commands (Telnet — port 20000)</h2>
        <div class="table-wrap"><table>
            <thead><tr><th>Command</th><th>Description</th></tr></thead>
            <tbody>
                <tr><td><code>LABOR|&lt;topic&gt;</code></td><td>Query NC labor law by topic</td></tr>
                <tr><td><code>ETHICS|&lt;concern&gt;</code></td><td>Query ethical/moral concern</td></tr>
                <tr><td><code>SEARCH|&lt;keyword&gt;</code></td><td>AI-assisted search via Strernary™</td></tr>
                <tr><td><code>COMPLIANCE|&lt;check&gt;</code></td><td>Run compliance check</td></tr>
                <tr><td><code>STATUS</code></td><td>Module health check</td></tr>
                <tr><td><code>HELP</code></td><td>List available commands</td></tr>
                <tr><td><code>QUIT</code></td><td>Close session</td></tr>
            </tbody>
        </table></div>
    </div>
</section>

<footer class="footer"><div><span>&#169; 2026 MEARVK LLC. All rights reserved. Green.Durham.Grass.and.Herb™ — Green.</span></div></footer>
</body></html>
