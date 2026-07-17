<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.net.*, java.io.*" %>
<%
    boolean authorized = false; String authStatus = "Unknown";
    try { HttpURLConnection hc = (HttpURLConnection) new URL("https://raw.githubusercontent.com/mearvk/Java.Web.Server.Telnet.Front.Java.21/main/psychiatry/secrets/public.key").openConnection();
        hc.setRequestMethod("HEAD"); hc.setConnectTimeout(5000); hc.setReadTimeout(5000);
        authorized = (hc.getResponseCode() == 200); authStatus = authorized ? "Authorized" : "Revoked"; hc.disconnect();
    } catch (Exception e) { authStatus = "Check failed"; }
%>
<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"/><meta name="viewport" content="width=device-width,initial-scale=1.0"/>
    <link rel="preconnect" href="https://fonts.googleapis.com"/><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin/><link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:ital,wght@0,300;0,400;0,500;0,600;0,700;1,400;1,600&display=swap" rel="stylesheet"/>
<title>Gray85 Crème Registry™</title><link rel="stylesheet" href="css/style.css"/><script src="js/scroll-preserve.js"></script>
    <script src="js/nwe-readme-viewer.js"></script>
</head><body>
<nav class="nav"><div class="nav-inner"><span class="nav-brand">Gray85 Crème™</span>
<ul class="nav-links"><li><a href="index.jsp" class="active">Overview</a></li><li><a href="leases.jsp">Leases</a></li><li><a href="bindings.jsp">Bindings</a></li><li><a href="creme.jsp">Crème</a></li><li><a href="status.jsp">Status</a></li></ul>
</div></nav>
<section class="hero"><div class="hero-inner"><span class="hero-tag">Planetary Auditor Control</span>
<h1>Gray85 Crème Registry™</h1><p>85% open ports ($10 lease) + 15% Crème-locked ($1000/unlock/hour). Planetary auditor control layer. Port 10085.</p></div></section>
<!-- CD1 Connector Button + Floating Dialog (BMA Template) -->
<div style="display:flex;justify-content:center;align-items:center;width:100%;padding:2rem 0;">
    <button id="cd1-btn" type="button" aria-pressed="false" style="all:unset;display:block;margin:0 auto;cursor:pointer;padding:0;border:none;background:transparent;transition:transform 0.3s cubic-bezier(0.42,-1.84,0.42,1.84),filter 0.3s ease;">
        <img src="images/black.button.png" alt="Connector" style="display:block;width:80px;height:80px;border-radius:50%;background:transparent;"/>
    </button>
</div>
<div id="cd1-overlay" style="display:none;position:fixed;inset:0;z-index:299;background:transparent;"></div>
<div id="cd1-dialog" style="display:none;position:fixed;top:50%;left:50%;transform:translate(-50%,-50%);z-index:300;background:#111118;border:1px solid #27272a;border-radius:12px;padding:1.25rem;width:520px;max-width:90vw;box-shadow:0 8px 32px rgba(0,0,0,0.6);">
    <div style="font-size:0.9rem;font-weight:600;color:#fff;margin-bottom:0.75rem;">Gray85Crème Connector &#8212; Overview</div>
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
<script>window.CD1_MODULE_PORT = "10085";</script>
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
<div style="margin-bottom:2rem;padding:1rem;border:1px solid <%= authorized ? "#22c55e" : "#ef4444" %>;border-radius:8px;">
<span style="font-size:0.85rem;color:<%= authorized ? "#22c55e" : "#ef4444" %>;font-weight:600;">&#9679; <%= authStatus %></span></div>
<h2>Protocol Commands (TCP port 10085)</h2>
<div class="table-wrap"><table><thead><tr><th>Command</th><th>Format</th><th>Description</th></tr></thead><tbody>
<tr><td><code>LEASE</code></td><td><code>LEASE|block_id|term|btc_txid</code></td><td>Lease a 30M port block ($10)</td></tr>
<tr><td><code>BIND</code></td><td><code>BIND|block_id|port</code></td><td>Bind open port (85%)</td></tr>
<tr><td><code>UNLOCK</code></td><td><code>UNLOCK|block_id|port_offset|hours|btc_txid</code></td><td>Unlock Crème port ($1000/hr)</td></tr>
<tr><td><code>CREME</code></td><td><code>CREME|block_id</code></td><td>List Crème-locked ports in block</td></tr>
<tr><td><code>STATUS</code></td><td><code>STATUS|block_id</code></td><td>Check block availability</td></tr>
<tr><td><code>LIST</code></td><td><code>LIST</code></td><td>List active leases</td></tr>
<tr><td><code>QUIT</code></td><td><code>QUIT</code></td><td>Disconnect</td></tr>
</tbody></table></div>
<h2 style="margin-top:2rem;">Pricing</h2>
<div class="table-wrap"><table><thead><tr><th>Tier</th><th>Ports</th><th>Cost</th><th>Notes</th></tr></thead><tbody>
<tr><td>Open (85%)</td><td>25,500,000 per block</td><td>$10 USD lease</td><td>Standard AI-gated binding</td></tr>
<tr><td>Crème (15%)</td><td>4,500,000 per block</td><td>$1000 USD/unlock/hour</td><td>Planetary auditor controlled</td></tr>
</tbody></table></div></div></section>
<footer class="footer"><div><span>&#169; 2026 MEARVK LLC. All rights reserved.</span></div></footer></body></html>
