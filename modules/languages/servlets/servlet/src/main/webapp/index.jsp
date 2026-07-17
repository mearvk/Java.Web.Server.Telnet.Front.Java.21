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
<title>Languages™ — Translation &amp; AI Module</title><link rel="stylesheet" href="css/style.css"/><script src="js/scroll-preserve.js"></script>
    <script src="js/nwe-readme-viewer.js"></script>
</head><body>
<nav class="nav"><div class="nav-inner"><span class="nav-brand">Languages™</span>
<ul class="nav-links"><li><a href="index.jsp" class="active">Overview</a></li><li><a href="translate.jsp">Translate</a></li><li><a href="history.jsp">History</a></li></ul>
</div></nav>
<section class="hero"><div class="hero-inner"><span class="hero-tag">Violet — Polite Diplomacy</span>
<h1>Languages™</h1><p>Multi-language translation module with AI inference. Supports American, English, French, Spanish, Thai, Italian, German, Japanese, Chinese, Arabic, Russian, Ukrainian, and Turkish.</p></div></section>
<div style="text-align:center;padding:0.5rem;font-size:0.7rem;color:<%= authorized ? \"#22c55e\" : \"#dc2626\" %>;"><%= authMsg %></div>

<!-- CD1 Connector Button + Floating Dialog (BMA Template) -->
<div style="display:flex;justify-content:center;align-items:center;width:100%;padding:2rem 0;">
    <button id="cd1-btn" type="button" aria-pressed="false" style="all:unset;display:block;margin:0 auto;cursor:pointer;padding:0;border:none;background:transparent;transition:transform 0.3s cubic-bezier(0.42,-1.84,0.42,1.84),filter 0.3s ease;">
        <img src="images/black.button.png" alt="Connector" style="display:block;width:80px;height:80px;border-radius:50%;background:transparent;"/>
    </button>
</div>
<div id="cd1-overlay" style="display:none;position:fixed;inset:0;z-index:299;background:transparent;"></div>
<div id="cd1-dialog" style="display:none;position:fixed;top:50%;left:50%;transform:translate(-50%,-50%);z-index:300;background:#111118;border:1px solid #27272a;border-radius:12px;padding:1.25rem;width:520px;max-width:90vw;box-shadow:0 8px 32px rgba(0,0,0,0.6);">
    <div style="font-size:0.9rem;font-weight:600;color:#fff;margin-bottom:0.75rem;">Languages Connector &#8212; Overview</div>
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
<div style="padding:1.25rem;border:1px solid var(--accent);border-radius:8px;background:rgba(139,92,246,0.05);margin-bottom:2rem;">
<p style="font-size:0.9rem;color:var(--text-secondary);line-height:1.7;">The US Supreme Court is in Custody and Control of the US with assistance of the Original Barrister Class at ATX10 Grade. All translations produced by this module are provided under the authority and diplomatic courtesy of the established legal framework.</p>
</div>

<h2>Supported Languages</h2>
<div class="table-wrap"><table><thead><tr><th>Language</th><th>Code</th><th>Region</th><th>Status</th></tr></thead><tbody>
<tr><td>American English</td><td><code>en-US</code></td><td>United States</td><td style="color:#22c55e;">Active</td></tr>
<tr><td>English</td><td><code>en-GB</code></td><td>United Kingdom</td><td style="color:#22c55e;">Active</td></tr>
<tr><td>French</td><td><code>fr</code></td><td>France / Canada</td><td style="color:#22c55e;">Active</td></tr>
<tr><td>Spanish</td><td><code>es</code></td><td>Spain / Americas</td><td style="color:#22c55e;">Active</td></tr>
<tr><td>Thai</td><td><code>th</code></td><td>Thailand</td><td style="color:#22c55e;">Active</td></tr>
<tr><td>Italian</td><td><code>it</code></td><td>Italy</td><td style="color:#22c55e;">Active</td></tr>
<tr><td>German</td><td><code>de</code></td><td>Germany / Switzerland</td><td style="color:#22c55e;">Active</td></tr>
<tr><td>Japanese</td><td><code>ja</code></td><td>Japan</td><td style="color:#22c55e;">Active</td></tr>
<tr><td>Chinese</td><td><code>zh</code></td><td>China / Taiwan</td><td style="color:#22c55e;">Active</td></tr>
<tr><td>Arabic</td><td><code>ar</code></td><td>Middle East / N. Africa</td><td style="color:#22c55e;">Active</td></tr>
<tr><td>Russian</td><td><code>ru</code></td><td>Russia</td><td style="color:#22c55e;">Active</td></tr>
<tr><td>Ukrainian</td><td><code>uk</code></td><td>Ukraine</td><td style="color:#22c55e;">Active</td></tr>
<tr><td>Turkish</td><td><code>tr</code></td><td>Turkey</td><td style="color:#22c55e;">Active</td></tr>
</tbody></table></div>
</div></section>

<section class="section"><div class="section-inner">
<h2>Architecture</h2>
<div class="table-wrap"><table><thead><tr><th>Component</th><th>Description</th></tr></thead><tbody>
<tr><td>Translation Engine</td><td>DJL (Deep Java Library) with multilingual transformer model</td></tr>
<tr><td>Fallback</td><td>Keyword heuristics + dictionary lookup when model unavailable</td></tr>
<tr><td>Database</td><td><code>nwe_languages</code> — translation history, phrase cache</td></tr>
<tr><td>Authority</td><td>US Supreme Court — Custody &amp; Control — Original Barrister Class ATX10</td></tr>
</tbody></table></div>
</div></section>

<footer class="footer"><div><span>&#169; 2026 MEARVK LLC. All rights reserved. Violet — Polite Diplomacy.</span></div></footer></body></html>
