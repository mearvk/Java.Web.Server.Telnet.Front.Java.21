<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.net.*, java.io.*" %>
<%
    // Check GitHub repo authorization (public.key presence)
    String ghKeyUrl = "https://raw.githubusercontent.com/mearvk/Java.Web.Server.Telnet.Front.Java.21/main/psychiatry/secrets/public.key";
    boolean authorized = false;
    String authStatus = "Unknown";
    try {
        HttpURLConnection hc = (HttpURLConnection) new URL(ghKeyUrl).openConnection();
        hc.setRequestMethod("HEAD");
        hc.setConnectTimeout(5000);
        hc.setReadTimeout(5000);
        int code = hc.getResponseCode();
        hc.disconnect();
        authorized = (code == 200);
        authStatus = authorized ? "Authorized (public.key present)" : "Revoked (HTTP " + code + ")";
    } catch (Exception e) {
        authStatus = "Check failed: " + (e.getMessage() != null ? e.getMessage() : "timeout");
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>Emeter™ — Precision Metering Instruction</title>
    <link rel="stylesheet" href="css/style.css"/>
    <script src="js/scroll-preserve.js"></script>
</head>
<body>
<nav class="nav"><div class="nav-inner">
    <span class="nav-brand">Emeter™</span>
    <ul class="nav-links">
        <li><a href="index.jsp" class="active">Overview</a></li>
        <li><a href="instructions.jsp">Instructions</a></li>
        <li><a href="calibration.jsp">Calibration</a></li>
        <li><a href="readings.jsp">Readings</a></li>
        <li><a href="status.jsp">Status</a></li>
    </ul>
    <div class="nav-actions">
        <a href="instructions.jsp" class="nav-cta">Begin Instruction →</a>
    </div>
</div></nav>

<section class="hero">
    <div class="hero-inner">
        <span class="hero-tag">Precision Metering Instruction</span>
        <h1>Emeter™</h1>
        <p>E-Meter instruction and calibration module. Session tracking, reading submission, tone level analysis, and AI-assisted training via Strernary™. TCP backend on port 49216.</p>
    </div>
</section>

<!-- CD1 Connector Button + Floating Dialog (BMA Template) -->
<div style="display:flex;justify-content:center;align-items:center;width:100%;padding:2rem 0;">
    <button id="cd1-btn" type="button" aria-pressed="false" style="all:unset;display:block;margin:0 auto;cursor:pointer;padding:0;border:none;background:transparent;transition:transform 0.3s cubic-bezier(0.42,-1.84,0.42,1.84),filter 0.3s ease;">
        <img src="images/black.button.png" alt="Connector" style="display:block;width:80px;height:80px;border-radius:50%;background:transparent;"/>
    </button>
</div>
<div id="cd1-overlay" style="display:none;position:fixed;inset:0;z-index:299;background:transparent;"></div>
<div id="cd1-dialog" style="display:none;position:fixed;top:50%;left:50%;transform:translate(-50%,-50%);z-index:300;background:#111118;border:1px solid #27272a;border-radius:12px;padding:1.25rem;width:520px;max-width:90vw;box-shadow:0 8px 32px rgba(0,0,0,0.6);">
    <div style="font-size:0.9rem;font-weight:600;color:#fff;margin-bottom:0.75rem;">Emeter Connector &#8212; Overview</div>
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
<script>window.CD1_MODULE_PORT = "49216";</script>
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
        <h2>Instruction Topics</h2>
        <p>Comprehensive E-Meter instruction curriculum — theory through advanced practice.</p>
        <div class="table-wrap">
            <table>
                <thead><tr><th>Topic</th><th>Description</th><th>Level</th></tr></thead>
                <tbody>
                    <tr><td>Introduction</td><td>Overview of the E-Meter, its components, and purpose</td><td>Beginner</td></tr>
                    <tr><td>Theory of Operation</td><td>Wheatstone bridge circuit, galvanic skin response measurement</td><td>Beginner</td></tr>
                    <tr><td>Calibration Procedure</td><td>Trim check, sensitivity setting, can squeeze test</td><td>Intermediate</td></tr>
                    <tr><td>Reading Interpretation</td><td>Tone arm position, needle behavior, fall/rise patterns</td><td>Intermediate</td></tr>
                    <tr><td>Session Protocols</td><td>Standard session setup, TA tracking, end-of-session indicators</td><td>Advanced</td></tr>
                    <tr><td>Advanced Techniques</td><td>Assessment reads, instant reads, prior reads, latent reads</td><td>Advanced</td></tr>
                </tbody>
            </table>
        </div>
    </div>
</section>

<section class="section">
    <div class="section-inner">
        <h2>Calibration Levels</h2>
        <p>Meter calibration parameters and positioning reference.</p>
        <div class="table-wrap">
            <table>
                <thead><tr><th>Level</th><th>Parameter</th><th>Description</th></tr></thead>
                <tbody>
                    <tr><td>Set</td><td>Tone Arm Zero</td><td>Adjust TA to 2.0 with cans in hands, relaxed grip</td></tr>
                    <tr><td>Sensitivity</td><td>Sensitivity Knob</td><td>Set for optimal needle response — typically 16–32</td></tr>
                    <tr><td>Range</td><td>Range Switch</td><td>Select appropriate resistance range for subject</td></tr>
                    <tr><td>Tone Arm</td><td>TA Positioning</td><td>TA counter reads 2.0–3.0 for normal range; track motion</td></tr>
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
                    <tr><td>TCP Port</td><td><code>49216</code> (NIO masquerade routed)</td></tr>
                    <tr><td>Protocol</td><td><code>NWE-EMETER</code></td></tr>
                    <tr><td>Database</td><td><code>nwe_emeter</code> (MySQL)</td></tr>
                    <tr><td>AI Inference</td><td><code>Strernary™ port 20000</code> (DJL/DistilBERT)</td></tr>
                    <tr><td>Tomcat Context</td><td><code>/emeter</code></td></tr>
                    <tr><td>Servlet Container</td><td>Apache Tomcat 11.0.2</td></tr>
                    <tr><td>JDK</td><td>Java 21 (virtual threads)</td></tr>
                </tbody>
            </table>
        </div>
    </div>
</section>

<footer class="footer"><div><span>&#169; 2026 MEARVK LLC. All rights reserved. Emeter™ — NitroWebExpress™</span></div></footer>
</body>
</html>
