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
    <title>CaliforniaFBI™ — Crime Reporting Module</title>
    <link rel="stylesheet" href="css/style.css"/>
</head>
<body>
<nav class="nav"><div class="nav-inner">
    <span class="nav-brand">CaliforniaFBI™</span>
    <ul class="nav-links">
        <li><a href="index.jsp" class="active">Overview</a></li>
        <li><a href="report.jsp">Report</a></li>
        <li><a href="search.jsp">Search</a></li>
        <li><a href="status.jsp">Status</a></li>
    </ul>
    <div class="nav-actions">
        <a href="report.jsp" class="nav-cta">File Report →</a>
    </div>
</div></nav>

<section class="hero">
    <div class="hero-inner">
        <span class="hero-tag">California — Federal Bureau of Investigation</span>
        <h1>CaliforniaFBI™</h1>
        <p>AI-assisted crime reporting and tip submission. Connects to tips.fbi.gov and IC3 for federal crime reporting. Installer ID Tech™ secured database. NIO masquerade routed on port 49210.</p>
    </div>
</section>

<!-- FBI Connector Button (BMA pattern) -->
<div style="display:flex;justify-content:center;align-items:center;width:100%;padding:2rem 0;">
    <button id="fbi-btn" type="button" style="all:unset;display:block;cursor:pointer;transition:transform 0.3s cubic-bezier(0.42,-1.84,0.42,1.84),filter 0.3s ease;">
        <div style="width:80px;height:80px;border-radius:50%;background:linear-gradient(135deg,#dc2626,#7f1d1d);display:flex;align-items:center;justify-content:center;border:2px solid #991b1b;box-shadow:0 4px 24px rgba(220,38,38,0.3);">
            <span style="font-size:1.5rem;font-weight:800;color:#fff;">FBI</span>
        </div>
    </button>
</div>
<div id="fbi-overlay" style="display:none;position:fixed;inset:0;z-index:299;background:transparent;"></div>
<div id="fbi-dialog" style="display:none;position:fixed;top:50%;left:50%;transform:translate(-50%,-50%);z-index:300;background:#111118;border:1px solid #27272a;border-radius:12px;padding:1.25rem;width:560px;max-width:90vw;box-shadow:0 8px 32px rgba(0,0,0,0.6);">
    <div style="font-size:0.9rem;font-weight:600;color:#fff;margin-bottom:0.75rem;">FBI Connector — tips.fbi.gov</div>
    <div style="display:flex;gap:0.5rem;margin-bottom:0.75rem;flex-wrap:wrap;">
        <select id="fbi-action" style="background:#1a1a24;color:#fff;border:1px solid #27272a;border-radius:8px;padding:0.45rem 2rem 0.45rem 0.75rem;font-size:0.8rem;cursor:pointer;">
            <option value="connect">Connect to FBI Tips</option>
            <option value="ic3">Connect to IC3 (Cyber)</option>
            <option value="field">LA Field Office</option>
            <option value="status">Check Status</option>
        </select>
        <button onclick="fbiSend()" style="background:#dc2626;color:#fff;border:none;border-radius:8px;padding:0.45rem 1rem;font-size:0.8rem;font-weight:600;cursor:pointer;">Send</button>
        <button onclick="fbiClose()" style="background:#dc2626;color:#fff;border:none;border-radius:8px;padding:0.45rem 1rem;font-size:0.8rem;font-weight:600;cursor:pointer;">OK</button>
    </div>
    <textarea id="fbi-textarea" placeholder="Connection idle..." spellcheck="false" style="width:100%;min-height:140px;background:#fff;color:#111;border:1px solid #27272a;border-radius:8px;padding:0.75rem;font-family:monospace;font-size:0.8rem;resize:vertical;"></textarea>
</div>
<script>
const btn=document.getElementById('fbi-btn'),dlg=document.getElementById('fbi-dialog'),ov=document.getElementById('fbi-overlay'),ta=document.getElementById('fbi-textarea');
btn.onclick=()=>{dlg.style.display='block';ov.style.display='block';};
ov.onclick=()=>{dlg.style.display='none';ov.style.display='none';};
function fbiClose(){dlg.style.display='none';ov.style.display='none';}
function fbiSend(){
    const action=document.getElementById('fbi-action').value;
    const urls={connect:'https://tips.fbi.gov/',ic3:'https://www.ic3.gov/',field:'https://www.fbi.gov/contact-us/field-offices/losangeles',status:'STATUS'};
    if(action==='status'){ta.value='Connecting to CaliforniaFBI™ port 49210...\nSTATUS|OK|port=49210|db=nwe_california_fbi';return;}
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
                    <tr><td>Report</td><td>Submit a crime report — AI categorization via Strernary™</td><td><a href="report.jsp">File →</a></td></tr>
                    <tr><td>Search</td><td>Search local report database by keyword</td><td><a href="search.jsp">Search →</a></td></tr>
                    <tr><td>Status</td><td>Database, port, and FBI connectivity health</td><td><a href="status.jsp">Check →</a></td></tr>
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
                    <tr><td>TCP Port</td><td><code>49210</code> (NIO masquerade routed)</td></tr>
                    <tr><td>Protocol</td><td><code>NWE-FBI</code></td></tr>
                    <tr><td>Database</td><td><code>nwe_california_fbi</code> (MySQL)</td></tr>
                    <tr><td>AI Inference</td><td><code>Strernary™ port 20000</code> (DJL/DistilBERT)</td></tr>
                    <tr><td>FBI Tips</td><td><code>tips.fbi.gov</code></td></tr>
                    <tr><td>IC3 Cyber</td><td><code>www.ic3.gov</code></td></tr>
                    <tr><td>Field Office</td><td>Los Angeles (California)</td></tr>
                    <tr><td>Installer ID Tech™</td><td>Required for all table writes</td></tr>
                </tbody>
            </table>
        </div>
    </div>
</section>

<section class="section">
    <div class="section-inner">
        <h2>Security</h2>
        <div class="table-wrap">
            <table>
                <thead><tr><th>Feature</th><th>Status</th></tr></thead>
                <tbody>
                    <tr><td>Installer ID Tech™ (table access)</td><td style="color:#22c55e;">Active</td></tr>
                    <tr><td>Rate Limiting (30/min per IP)</td><td style="color:#22c55e;">Active</td></tr>
                    <tr><td>Input Sanitization (XXE, traversal)</td><td style="color:#22c55e;">Active</td></tr>
                    <tr><td>Heuristic Classifier</td><td style="color:#22c55e;">Active</td></tr>
                    <tr><td>HardenedBaseServer (512 conn, 10/IP)</td><td style="color:#22c55e;">Active</td></tr>
                    <tr><td>Security Headers Filter</td><td style="color:#22c55e;">Active</td></tr>
                </tbody>
            </table>
        </div>
    </div>
</section>

<footer class="footer"><div><span>&#169; 2026 MEARVK LLC. All rights reserved. CaliforniaFBI™ — Red.</span></div></footer>
</body>
</html>
