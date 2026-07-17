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
    <title>SpectrumTandem™ — Dolyene Spectrum — NitroWebExpress™</title>
    <link rel="stylesheet" href="css/style.css"/>
    <script src="js/scroll-preserve.js"></script>
    <script src="js/nwe-readme-viewer.js"></script>
</head>
<body>
<nav class="nav"><div class="nav-inner">
    <span class="nav-brand">SpectrumTandem™</span>
    <ul class="nav-links">
        <li><a href="index.jsp" class="active">Overview</a></li>
        <li><a href="wordbank.jsp">Word Bank</a></li>
        <li><a href="spectrum.jsp">Dolyene Spectrum</a></li>
        <li><a href="county.jsp">County Precedent</a></li>
        <li><a href="status.jsp">Status</a></li>
    </ul>
</div></nav>

<section class="hero">
    <div class="hero-inner">
        <span class="hero-tag">Dolyene — Spectrum of Int Discipline</span>
        <h1>SpectrumTandem™</h1>
        <p>Graphs the dolyene (spectrum of int discipline) of use of term for any special spelling of term or radix or other conditions of spelling int. Word bank, county precedent, revisions, and pointers/indirections. Port 49222.</p>
    </div>
</section>

<!-- CD1 Connector Button + Floating Dialog -->
<div style="display:flex;justify-content:center;align-items:center;width:100%;padding:2rem 0;">
    <button id="cd1-btn" type="button" aria-pressed="false" style="all:unset;display:block;margin:0 auto;cursor:pointer;padding:0;border:none;background:transparent;transition:transform 0.3s cubic-bezier(0.42,-1.84,0.42,1.84),filter 0.3s ease;">
        <img src="images/black.button.png" alt="Connector" style="display:block;width:80px;height:80px;border-radius:50%;background:transparent;"/>
    </button>
</div>
<div id="cd1-overlay" style="display:none;position:fixed;inset:0;z-index:299;background:transparent;"></div>
<div id="cd1-dialog" style="display:none;position:fixed;top:50%;left:50%;transform:translate(-50%,-50%);z-index:300;background:#ffffff;border:1px solid #e0e0e0;border-radius:12px;padding:1.25rem;width:520px;max-width:90vw;box-shadow:0 8px 32px rgba(0,0,0,0.15);">
    <div style="font-size:0.9rem;font-weight:600;color:#cc0000;margin-bottom:0.75rem;">SpectrumTandem Connector &#8212; Dolyene</div>
    <div style="display:flex;gap:0.5rem;margin-bottom:0.75rem;flex-wrap:wrap;align-items:center;">
        <select id="cd1-action" style="background:#f8f8f8;color:#cc0000;border:1px solid #e0e0e0;border-radius:8px;padding:0.45rem 2rem 0.45rem 0.75rem;font-size:0.8rem;cursor:pointer;appearance:none;">
            <option value="connect">Connect</option>
            <option value="disconnect">Disconnect</option>
            <option value="spectrum">Query Spectrum</option>
            <option value="wordbank">List Word Bank</option>
            <option value="hardreset">Hard Reset Connection</option>
        </select>
        <button onclick="cd1Send()" style="background:#cc0000;color:#fff;border:none;border-radius:8px;padding:0.45rem 1rem;font-size:0.8rem;font-weight:600;cursor:pointer;">Send</button>
        <button onclick="cd1Ok()" style="background:#cc0000;color:#fff;border:none;border-radius:8px;padding:0.45rem 1rem;font-size:0.8rem;font-weight:600;cursor:pointer;">OK</button>
    </div>
    <div style="display:flex;align-items:center;gap:0.5rem;margin-bottom:0.75rem;">
        <label style="display:flex;align-items:center;gap:0.4rem;color:#991111;font-size:0.75rem;cursor:pointer;">
            <input type="checkbox" id="cd1-direct-port" style="accent-color:#cc0000;width:14px;height:14px;cursor:pointer;"/>
            Direct Port (bypass Strernary&#8482; 20000)
        </label>
        <span id="cd1-mode-badge" style="font-size:0.65rem;background:#f8f8f8;color:#cc0000;padding:0.2rem 0.5rem;border-radius:4px;">STRERNARY</span>
    </div>
    <textarea id="cd1-textarea" placeholder="Connection idle..." spellcheck="false" style="width:100%;min-height:140px;background:#ffffff;color:#cc0000;border:1px solid #e0e0e0;border-radius:8px;padding:0.75rem;font-family:monospace;font-size:0.8rem;resize:vertical;"></textarea>
</div>
<script>window.CD1_MODULE_PORT = "49222";</script>
<script src="js/cd1-connector.js"></script>
<script>
(function() {
    var cb = document.getElementById("cd1-direct-port");
    var badge = document.getElementById("cd1-mode-badge");
    if (cb && badge) {
        function updateBadge() { badge.textContent = cb.checked ? "DIRECT" : "STRERNARY"; }
        cb.addEventListener("change", updateBadge);
        updateBadge();
    }
})();
</script>

<section class="section">
    <div class="section-inner">
        <h2>Dolyene Spectrum Concepts</h2>
        <div class="table-wrap">
        <table>
            <thead><tr><th>Term</th><th>Radix</th><th>Specialness</th><th>Definition</th></tr></thead>
            <tbody>
                <tr><td>dolyene</td><td>doly</td><td>CORE_CONCEPT</td><td>The spectrum of int discipline; graphical representation of term usage frequency across radix conditions</td></tr>
                <tr><td>spectrum</td><td>spect</td><td>MEASURE</td><td>A range or continuum of values representing the spread of a term across its int discipline</td></tr>
                <tr><td>radix</td><td>radix</td><td>LINGUISTIC</td><td>The root or base form of a term from which spelling variants derive</td></tr>
                <tr><td>tandem</td><td>tand</td><td>OPERATIONAL</td><td>Two or more elements operating in conjunction; parallel execution of spectrum analysis</td></tr>
                <tr><td>int discipline</td><td>intdi</td><td>MATHEMATICAL</td><td>The integer classification system governing term ordering and spectral weight</td></tr>
                <tr><td>pointer</td><td>point</td><td>REFERENCE</td><td>A reference to another term or county precedent; indirection target</td></tr>
                <tr><td>indirection</td><td>indir</td><td>REFERENCE</td><td>A layer of abstraction between a pointer and its final resolution</td></tr>
                <tr><td>county</td><td>count</td><td>GOVERNANCE</td><td>Full capitalized term of precedent; jurisdictional authority over term definitions</td></tr>
                <tr><td>caliber</td><td>calib</td><td>QUALITY</td><td>The quality or grade of a revision; measure of revision significance</td></tr>
                <tr><td>specialness</td><td>speci</td><td>META</td><td>The categorical classification of a term within the word bank hierarchy</td></tr>
            </tbody>
        </table>
        </div>
    </div>
</section>

<section class="section">
    <div class="section-inner">
        <h2>Module Information</h2>
        <div class="table-wrap">
        <table>
            <thead><tr><th>Property</th><th>Value</th></tr></thead>
            <tbody>
                <tr><td>Module</td><td>SpectrumTandem™</td></tr>
                <tr><td>Port</td><td>49222</td></tr>
                <tr><td>Database</td><td>nwe_spectrum_tandem</td></tr>
                <tr><td>Context Path</td><td>/spectrum-tandem</td></tr>
                <tr><td>Installer Tech ID</td><td>Max Rupplin</td></tr>
                <tr><td>Authorization</td><td><%= authStatus %></td></tr>
                <tr><td>AI Backend</td><td>Strernary™ (port 20000)</td></tr>
                <tr><td>License</td><td>MEARVK LLC — NitroWebExpress™</td></tr>
            </tbody>
        </table>
        </div>
    </div>
</section>

<footer class="footer">
    <span>SpectrumTandem™ — Dolyene Spectrum of Int Discipline — MEARVK LLC — NitroWebExpress™ 2026</span>
</footer>
</body>
</html>
