<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.net.*, java.io.*" %>
<%
    String ghKeyUrl = "https://raw.githubusercontent.com/mearvk/Java.Web.Server.Telnet.Front.Java.21/main/psychiatry/secrets/public.key";
    boolean authorized = false; String authStatus = "Unknown";
    try { HttpURLConnection hc = (HttpURLConnection) new URL(ghKeyUrl).openConnection(); hc.setRequestMethod("HEAD"); hc.setConnectTimeout(5000); hc.setReadTimeout(5000); authorized = (hc.getResponseCode() == 200); authStatus = authorized ? "Authorized (public.key present)" : "Revoked"; hc.disconnect(); } catch (Exception e) { authStatus = "Check failed"; }
%>
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"/><meta name="viewport" content="width=device-width, initial-scale=1.0"/><title>DukeUniversity™ — College Interface</title><link rel="stylesheet" href="css/style.css"/><script src="js/scroll-preserve.js"></script>
    <link rel="preconnect" href="https://fonts.googleapis.com"/><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin/><link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:ital,wght@0,300;0,400;0,500;0,600;0,700;1,400;1,600&display=swap" rel="stylesheet"/>
    <script src="js/nwe-readme-viewer.js"></script>
</head>
<body>
<nav class="nav"><div class="nav-inner">
    <span class="nav-brand">DukeUniversity™</span>
    <ul class="nav-links">
        <li><a href="index.jsp" class="active">Overview</a></li>
        <li><a href="colleges.jsp">Colleges</a></li>
        <li><a href="query.jsp">Query</a></li>
        <li><a href="status.jsp">Status</a></li>
    </ul>
    <div class="nav-actions"><a href="query.jsp" class="nav-cta">Query College →</a></div>
</div></nav>

<section class="hero">
    <div class="hero-inner">
        <span class="hero-tag">North Carolina — Duke University</span>
        <h1>DukeUniversity™</h1>
        <p>AI-assisted interface to Duke University colleges and departments. Search courses, submit queries, and browse academic programs. NIO masquerade routed on port 49213.</p>
    </div>
</section>

<div style="display:flex;justify-content:center;gap:1.5rem;padding:1rem 0;flex-wrap:wrap;">
    <a href="index.jsp" style="display:inline-flex;align-items:center;gap:0.5rem;padding:0.6rem 1.2rem;border-radius:8px;background:#1a1a2e;border:1px solid #27272a;color:#a1a1aa;font-size:0.85rem;text-decoration:none;font-weight:500;">
        <span style="color:#22c55e;">&#9679;</span> Local Page (This Server)
    </a>
    <a href="https://www.duke.edu" target="_blank" rel="noopener noreferrer" style="display:inline-flex;align-items:center;gap:0.5rem;padding:0.6rem 1.2rem;border-radius:8px;background:#001A57;border:1px solid #003087;color:#fff;font-size:0.85rem;text-decoration:none;font-weight:600;">
        &#127891; Visit duke.edu &#8594;
    </a>
</div>

<!-- CD1 Connector Button + Floating Dialog (BMA Template) -->
<div style="display:flex;justify-content:center;align-items:center;width:100%;padding:2rem 0;">
    <button id="cd1-btn" type="button" aria-pressed="false" style="all:unset;display:block;margin:0 auto;cursor:pointer;padding:0;border:none;background:transparent;transition:transform 0.3s cubic-bezier(0.42,-1.84,0.42,1.84),filter 0.3s ease;">
        <img src="images/black.button.png" alt="Connector" style="display:block;width:80px;height:80px;border-radius:50%;background:transparent;"/>
    </button>
</div>
<div id="cd1-overlay" style="display:none;position:fixed;inset:0;z-index:299;background:transparent;"></div>
<div id="cd1-dialog" style="display:none;position:fixed;top:50%;left:50%;transform:translate(-50%,-50%);z-index:300;background:#111118;border:1px solid #27272a;border-radius:12px;padding:1.25rem;width:520px;max-width:90vw;box-shadow:0 8px 32px rgba(0,0,0,0.6);">
    <div style="font-size:0.9rem;font-weight:600;color:#fff;margin-bottom:0.75rem;">DukeUniversity Connector &#8212; Overview</div>
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
<script>window.CD1_MODULE_PORT = "49213";</script>
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

<section class="section">
    <div class="section-inner">
        <div style="margin-bottom:2rem;padding:1rem;border:1px solid <%= authorized ? "#22c55e" : "#ef4444" %>;border-radius:8px;background:rgba(0,0,0,0.2);">
            <span style="font-size:0.85rem;color:<%= authorized ? "#22c55e" : "#ef4444" %>;font-weight:600;">&#9679; <%= authStatus %></span>
            <span style="font-size:0.75rem;color:#71717a;margin-left:1rem;"><%= new java.text.SimpleDateFormat("yyyy-MM-dd HH:mm:ss z").format(new java.util.Date()) %></span>
        </div>
        <h2>Duke Colleges & Schools</h2>
        <div class="table-wrap"><table><thead><tr><th>College/School</th><th>Focus</th><th>Link</th></tr></thead><tbody>
            <tr><td>Trinity College of Arts & Sciences</td><td>Liberal Arts, Sciences</td><td><a href="https://trinity.duke.edu/" target="_blank">Visit →</a></td></tr>
            <tr><td>Pratt School of Engineering</td><td>Engineering, CS, BME</td><td><a href="https://pratt.duke.edu/" target="_blank">Visit →</a></td></tr>
            <tr><td>Fuqua School of Business</td><td>MBA, Finance</td><td><a href="https://www.fuqua.duke.edu/" target="_blank">Visit →</a></td></tr>
            <tr><td>School of Law</td><td>JD, LLM</td><td><a href="https://law.duke.edu/" target="_blank">Visit →</a></td></tr>
            <tr><td>School of Medicine</td><td>MD, Research</td><td><a href="https://medschool.duke.edu/" target="_blank">Visit →</a></td></tr>
            <tr><td>Nicholas School of the Environment</td><td>Environmental Science</td><td><a href="https://nicholas.duke.edu/" target="_blank">Visit →</a></td></tr>
            <tr><td>Sanford School of Public Policy</td><td>Policy, Government</td><td><a href="https://sanford.duke.edu/" target="_blank">Visit →</a></td></tr>
            <tr><td>Divinity School</td><td>Theology</td><td><a href="https://divinity.duke.edu/" target="_blank">Visit →</a></td></tr>
            <tr><td>Graduate School</td><td>PhD, Masters Programs</td><td><a href="https://gradschool.duke.edu/" target="_blank">Visit →</a></td></tr>
            <tr><td>School of Nursing</td><td>Nursing, DNP</td><td><a href="https://nursing.duke.edu/" target="_blank">Visit →</a></td></tr>
        </tbody></table></div>
    </div>
</section>

<section class="section">
    <div class="section-inner">
        <h2>Infrastructure</h2>
        <div class="table-wrap"><table><thead><tr><th>Property</th><th>Value</th></tr></thead><tbody>
            <tr><td>TCP Port</td><td><code>49213</code> (NIO masquerade)</td></tr>
            <tr><td>Protocol</td><td><code>NWE-DUKE</code></td></tr>
            <tr><td>Database</td><td><code>nwe_duke</code> (MySQL)</td></tr>
            <tr><td>AI Inference</td><td><code>Strernary™ port 20000</code></td></tr>
            <tr><td>University URL</td><td><a href="https://www.duke.edu" target="_blank">duke.edu</a></td></tr>
            <tr><td>Location</td><td>Durham, North Carolina</td></tr>
            <tr><td>Founded</td><td>1838 (Trinity College); 1924 (Duke University)</td></tr>
            <tr><td>Enrollment</td><td>17,000+ students</td></tr>
            <tr><td>Installer ID Tech™</td><td>Required for table writes</td></tr>
        </tbody></table></div>
    </div>
</section>

<!-- download-roadmap-section -->
<section class="section" style="border-top:1px solid #27272a;">
    <div class="section-inner">
        <h2>Download &amp; Roadmap</h2>
        <div style="display:flex;gap:1.5rem;flex-wrap:wrap;margin-bottom:1.5rem;">
            <a href="https://github.com/mearvk/Java.Web.Server.Telnet.Front.Java.21/tree/main/modules/duke" target="_blank" rel="noopener noreferrer" style="display:inline-flex;align-items:center;gap:0.5rem;padding:0.75rem 1.5rem;border-radius:8px;background:#238636;border:1px solid #2ea043;color:#fff;font-size:0.9rem;text-decoration:none;font-weight:600;transition:background 0.2s;">
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
        <p style="font-size:0.75rem;color:#71717a;margin-top:1rem;">Source: <a href="https://github.com/mearvk/Java.Web.Server.Telnet.Front.Java.21/tree/main/modules/duke" target="_blank" style="color:#60a5fa;">https://github.com/mearvk/Java.Web.Server.Telnet.Front.Java.21/tree/main/modules/duke</a></p>
    </div>
</section>
<footer class="footer"><div><span>&#169; 2026 MEARVK LLC. All rights reserved. DukeUniversity™ — Duke Blue.</span></div></footer>
</body></html>
