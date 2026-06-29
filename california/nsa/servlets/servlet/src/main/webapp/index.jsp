<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.net.*, java.io.*" %>
<%
    String ghKeyUrl = "https://raw.githubusercontent.com/mearvk/Java.Web.Server.Telnet.Front.Java.21/main/psychiatry/secrets/public.key";
    boolean authorized = false;
    String authStatus = "Unknown";
    try {
        HttpURLConnection hc = (HttpURLConnection) new URL(ghKeyUrl).openConnection();
        hc.setRequestMethod("HEAD"); hc.setConnectTimeout(5000); hc.setReadTimeout(5000);
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
    <title>CaliforniaNSA™ — Cybersecurity Module</title>
    <link rel="stylesheet" href="css/style.css"/>
</head>
<body>
<nav class="nav"><div class="nav-inner">
    <span class="nav-brand">CaliforniaNSA™</span>
    <ul class="nav-links">
        <li><a href="index.jsp" class="active">Overview</a></li>
        <li><a href="report.jsp">Report</a></li>
        <li><a href="advisories.jsp">Advisories</a></li>
        <li><a href="search.jsp">Search</a></li>
        <li><a href="status.jsp">Status</a></li>
    </ul>
    <div class="nav-actions"><a href="report.jsp" class="nav-cta">Report Incident →</a></div>
</div></nav>

<section class="hero">
    <div class="hero-inner">
        <span class="hero-tag">California — National Security Agency</span>
        <h1>CaliforniaNSA™</h1>
        <p>AI-assisted cybersecurity incident reporting and advisory tracking. Connects to nsa.gov and CISA for vulnerability disclosure and threat intelligence. Installer ID Tech™ secured. NIO masquerade routed on port 49212.</p>
    </div>
</section>

<!-- NSA Connector Button (BMA pattern) -->
<div style="display:flex;justify-content:center;align-items:center;width:100%;padding:2rem 0;">
    <button id="nsa-btn" type="button" style="all:unset;display:block;cursor:pointer;transition:transform 0.3s cubic-bezier(0.42,-1.84,0.42,1.84);">
        <div style="width:80px;height:80px;border-radius:50%;background:linear-gradient(135deg,#0284c7,#0c4a6e);display:flex;align-items:center;justify-content:center;border:2px solid #0369a1;box-shadow:0 4px 24px rgba(56,189,248,0.3);">
            <span style="font-size:1.3rem;font-weight:800;color:#fff;">NSA</span>
        </div>
    </button>
</div>
<div id="nsa-overlay" style="display:none;position:fixed;inset:0;z-index:299;background:transparent;"></div>
<div id="nsa-dialog" style="display:none;position:fixed;top:50%;left:50%;transform:translate(-50%,-50%);z-index:300;background:#111118;border:1px solid #27272a;border-radius:12px;padding:1.25rem;width:560px;max-width:90vw;box-shadow:0 8px 32px rgba(0,0,0,0.6);">
    <div style="font-size:0.9rem;font-weight:600;color:#fff;margin-bottom:0.75rem;">NSA Connector — nsa.gov</div>
    <div style="display:flex;gap:0.5rem;margin-bottom:0.75rem;flex-wrap:wrap;">
        <select id="nsa-action" style="background:#1a1a24;color:#fff;border:1px solid #27272a;border-radius:8px;padding:0.45rem 2rem 0.45rem 0.75rem;font-size:0.8rem;cursor:pointer;">
            <option value="cybersecurity">Cybersecurity Advisories</option>
            <option value="vulnerability">Report Vulnerability</option>
            <option value="cisa">CISA Reporting</option>
            <option value="status">Check Status</option>
        </select>
        <button onclick="nsaSend()" style="background:#0284c7;color:#fff;border:none;border-radius:8px;padding:0.45rem 1rem;font-size:0.8rem;font-weight:600;cursor:pointer;">Send</button>
        <button onclick="nsaClose()" style="background:#0284c7;color:#fff;border:none;border-radius:8px;padding:0.45rem 1rem;font-size:0.8rem;font-weight:600;cursor:pointer;">OK</button>
    </div>
    <textarea id="nsa-textarea" placeholder="Connection idle..." spellcheck="false" style="width:100%;min-height:140px;background:#fff;color:#111;border:1px solid #27272a;border-radius:8px;padding:0.75rem;font-family:monospace;font-size:0.8rem;resize:vertical;"></textarea>
</div>
<script>
const btn=document.getElementById('nsa-btn'),dlg=document.getElementById('nsa-dialog'),ov=document.getElementById('nsa-overlay'),ta=document.getElementById('nsa-textarea');
btn.onclick=()=>{dlg.style.display='block';ov.style.display='block';};
ov.onclick=()=>{dlg.style.display='none';ov.style.display='none';};
function nsaClose(){dlg.style.display='none';ov.style.display='none';}
function nsaSend(){
    const action=document.getElementById('nsa-action').value;
    const urls={cybersecurity:'https://www.nsa.gov/Cybersecurity/',vulnerability:'https://www.nsa.gov/About/Cryptologic-Heritage/Historical-Figures-Posters/Report-a-Vulnerability/',cisa:'https://www.cisa.gov/report',status:'STATUS'};
    if(action==='status'){ta.value='Connecting to CaliforniaNSA™ port 49212...\nSTATUS|OK|port=49212|db=nwe_california_nsa';return;}
    ta.value='Opening: '+urls[action]+'\n';
    window.open(urls[action],'_blank');
}
</script>

<section class="section">
    <div class="section-inner">
        <div style="margin-bottom:2rem;padding:1rem;border:1px solid <%= authorized ? "#22c55e" : "#ef4444" %>;border-radius:8px;background:rgba(0,0,0,0.2);">
            <span style="font-size:0.85rem;color:<%= authorized ? "#22c55e" : "#ef4444" %>;font-weight:600;">&#9679; <%= authStatus %></span>
            <span style="font-size:0.75rem;color:#71717a;margin-left:1rem;"><%= new java.text.SimpleDateFormat("yyyy-MM-dd HH:mm:ss z").format(new java.util.Date()) %></span>
        </div>
        <h2>Module Components</h2>
        <div class="table-wrap">
            <table>
                <thead><tr><th>Component</th><th>Description</th><th>Link</th></tr></thead>
                <tbody>
                    <tr><td>Report</td><td>Submit cybersecurity incident — AI categorization</td><td><a href="report.jsp">Report →</a></td></tr>
                    <tr><td>Advisories</td><td>Track NSA/CISA cybersecurity advisories</td><td><a href="advisories.jsp">View →</a></td></tr>
                    <tr><td>Search</td><td>Search local cyber report database</td><td><a href="search.jsp">Search →</a></td></tr>
                    <tr><td>Status</td><td>Database, port, and NSA connectivity health</td><td><a href="status.jsp">Check →</a></td></tr>
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
                    <tr><td>TCP Port</td><td><code>49212</code> (NIO masquerade routed)</td></tr>
                    <tr><td>Protocol</td><td><code>NWE-NSA</code></td></tr>
                    <tr><td>Database</td><td><code>nwe_california_nsa</code> (MySQL)</td></tr>
                    <tr><td>AI Inference</td><td><code>Strernary™ port 20000</code></td></tr>
                    <tr><td>NSA Cybersecurity</td><td><code>nsa.gov/Cybersecurity</code></td></tr>
                    <tr><td>CISA Reporting</td><td><code>cisa.gov/report</code></td></tr>
                    <tr><td>Installer ID Tech™</td><td>Required for all table writes</td></tr>
                </tbody>
            </table>
        </div>
    </div>
</section>

<footer class="footer"><div><span>&#169; 2026 MEARVK LLC. All rights reserved. CaliforniaNSA™ — Sky Blue.</span></div></footer>
</body>
</html>
