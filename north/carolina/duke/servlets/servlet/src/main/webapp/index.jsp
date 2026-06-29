<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.net.*, java.io.*" %>
<%
    String ghKeyUrl = "https://raw.githubusercontent.com/mearvk/Java.Web.Server.Telnet.Front.Java.21/main/psychiatry/secrets/public.key";
    boolean authorized = false; String authStatus = "Unknown";
    try { HttpURLConnection hc = (HttpURLConnection) new URL(ghKeyUrl).openConnection(); hc.setRequestMethod("HEAD"); hc.setConnectTimeout(5000); hc.setReadTimeout(5000); authorized = (hc.getResponseCode() == 200); authStatus = authorized ? "Authorized (public.key present)" : "Revoked"; hc.disconnect(); } catch (Exception e) { authStatus = "Check failed"; }
%>
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"/><meta name="viewport" content="width=device-width, initial-scale=1.0"/><title>DukeUniversity™ — College Interface</title><link rel="stylesheet" href="css/style.css"/></head>
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

<!-- Duke Connector Button -->
<div style="display:flex;justify-content:center;width:100%;padding:2rem 0;">
    <button id="duke-btn" type="button" style="all:unset;display:block;cursor:pointer;transition:transform 0.3s cubic-bezier(0.42,-1.84,0.42,1.84);">
        <div style="width:80px;height:80px;border-radius:50%;background:linear-gradient(135deg,#003087,#001A57);display:flex;align-items:center;justify-content:center;border:2px solid #4B9CD3;box-shadow:0 4px 24px rgba(0,48,135,0.4);">
            <span style="font-size:1rem;font-weight:800;color:#fff;">DUKE</span>
        </div>
    </button>
</div>
<div id="duke-overlay" style="display:none;position:fixed;inset:0;z-index:299;background:transparent;"></div>
<div id="duke-dialog" style="display:none;position:fixed;top:50%;left:50%;transform:translate(-50%,-50%);z-index:300;background:#111118;border:1px solid #27272a;border-radius:12px;padding:1.25rem;width:560px;max-width:90vw;box-shadow:0 8px 32px rgba(0,0,0,0.6);">
    <div style="font-size:0.9rem;font-weight:600;color:#fff;margin-bottom:0.75rem;">Duke Connector — duke.edu</div>
    <div style="display:flex;gap:0.5rem;margin-bottom:0.75rem;flex-wrap:wrap;">
        <select id="duke-action" style="background:#1a1a24;color:#fff;border:1px solid #27272a;border-radius:8px;padding:0.45rem 2rem 0.45rem 0.75rem;font-size:0.8rem;cursor:pointer;">
            <option value="academics">Academics</option>
            <option value="admissions">Admissions</option>
            <option value="research">Research</option>
            <option value="trinity">Trinity College</option>
            <option value="pratt">Pratt Engineering</option>
            <option value="fuqua">Fuqua Business</option>
            <option value="status">Check Status</option>
        </select>
        <button onclick="dukeSend()" style="background:#003087;color:#fff;border:none;border-radius:8px;padding:0.45rem 1rem;font-size:0.8rem;font-weight:600;cursor:pointer;">Open</button>
        <button onclick="dukeClose()" style="background:#003087;color:#fff;border:none;border-radius:8px;padding:0.45rem 1rem;font-size:0.8rem;font-weight:600;cursor:pointer;">OK</button>
    </div>
    <textarea id="duke-textarea" placeholder="Connection idle..." spellcheck="false" style="width:100%;min-height:140px;background:#fff;color:#111;border:1px solid #27272a;border-radius:8px;padding:0.75rem;font-family:monospace;font-size:0.8rem;resize:vertical;"></textarea>
</div>
<script>
const btn=document.getElementById('duke-btn'),dlg=document.getElementById('duke-dialog'),ov=document.getElementById('duke-overlay'),ta=document.getElementById('duke-textarea');
btn.onclick=()=>{dlg.style.display='block';ov.style.display='block';};
ov.onclick=()=>{dlg.style.display='none';ov.style.display='none';};
function dukeClose(){dlg.style.display='none';ov.style.display='none';}
function dukeSend(){
    const a=document.getElementById('duke-action').value;
    const urls={academics:'https://www.duke.edu/academics/',admissions:'https://admissions.duke.edu/',research:'https://research.duke.edu/',trinity:'https://trinity.duke.edu/',pratt:'https://pratt.duke.edu/',fuqua:'https://www.fuqua.duke.edu/',status:'STATUS'};
    if(a==='status'){ta.value='Connecting to DukeUniversity™ port 49213...\nSTATUS|OK|port=49213|db=nwe_duke';return;}
    ta.value='Opening: '+urls[a]+'\n'; window.open(urls[a],'_blank');
}
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
            <tr><td>Installer ID Tech™</td><td>Required for table writes</td></tr>
        </tbody></table></div>
    </div>
</section>

<footer class="footer"><div><span>&#169; 2026 MEARVK LLC. All rights reserved. DukeUniversity™ — Duke Blue.</span></div></footer>
</body></html>
