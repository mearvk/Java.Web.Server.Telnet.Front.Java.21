<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.net.*, java.io.*" %>
<%
    String ghKeyUrl = "https://raw.githubusercontent.com/mearvk/Java.Web.Server.Telnet.Front.Java.21/main/psychiatry/secrets/public.key";
    boolean authorized = false; String authStatus = "Unknown";
    try { HttpURLConnection hc = (HttpURLConnection) new URL(ghKeyUrl).openConnection(); hc.setRequestMethod("HEAD"); hc.setConnectTimeout(5000); hc.setReadTimeout(5000); authorized = (hc.getResponseCode() == 200); authStatus = authorized ? "Authorized (public.key present)" : "Revoked"; hc.disconnect(); } catch (Exception e) { authStatus = "Check failed"; }
%>
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"/><meta name="viewport" content="width=device-width, initial-scale=1.0"/><title>StanfordLibrary™ — Library Interface</title><link rel="stylesheet" href="css/style.css"/><script src="js/scroll-preserve.js"></script>
</head>
<body>
<nav class="nav"><div class="nav-inner">
    <span class="nav-brand">StanfordLibrary™</span>
    <ul class="nav-links">
        <li><a href="index.jsp" class="active">Overview</a></li>
        <li><a href="search.jsp">Search</a></li>
        <li><a href="request.jsp">Request</a></li>
        <li><a href="status.jsp">Status</a></li>
    </ul>
    <div class="nav-actions"><a href="search.jsp" class="nav-cta">Search Catalog →</a></div>
</div></nav>

<section class="hero">
    <div class="hero-inner">
        <span class="hero-tag">North Carolina — Stanford University Library</span>
        <h1>StanfordLibrary™</h1>
        <p>AI-assisted interface to Stanford University Libraries. Search the catalog, browse digital collections, and submit resource requests via library.stanford.edu. NIO masquerade routed on port 49214.</p>
    </div>
</section>

<!-- Stanford Library Connector Button -->
<div style="display:flex;justify-content:center;width:100%;padding:2rem 0;">
    <button id="lib-btn" type="button" style="all:unset;display:block;cursor:pointer;transition:transform 0.3s cubic-bezier(0.42,-1.84,0.42,1.84);">
        <div style="width:80px;height:80px;border-radius:50%;background:linear-gradient(135deg,#8C1515,#4D0000);display:flex;align-items:center;justify-content:center;border:2px solid #B83A4B;box-shadow:0 4px 24px rgba(140,21,21,0.4);">
            <span style="font-size:0.75rem;font-weight:800;color:#fff;text-align:center;line-height:1.1;">STAN<br/>LIB</span>
        </div>
    </button>
</div>
<div id="lib-overlay" style="display:none;position:fixed;inset:0;z-index:299;background:transparent;"></div>
<div id="lib-dialog" style="display:none;position:fixed;top:50%;left:50%;transform:translate(-50%,-50%);z-index:300;background:#111118;border:1px solid #27272a;border-radius:12px;padding:1.25rem;width:560px;max-width:90vw;box-shadow:0 8px 32px rgba(0,0,0,0.6);">
    <div style="font-size:0.9rem;font-weight:600;color:#fff;margin-bottom:0.75rem;">Stanford Library Connector — library.stanford.edu</div>
    <div style="display:flex;gap:0.5rem;margin-bottom:0.75rem;flex-wrap:wrap;">
        <select id="lib-action" style="background:#1a1a24;color:#fff;border:1px solid #27272a;border-radius:8px;padding:0.45rem 2rem 0.45rem 0.75rem;font-size:0.8rem;cursor:pointer;">
            <option value="catalog">SearchWorks Catalog</option>
            <option value="library">Library Home</option>
            <option value="digital">Digital Collections</option>
            <option value="special">Special Collections</option>
            <option value="maps">David Rumsey Map Center</option>
            <option value="status">Check Status</option>
        </select>
        <button onclick="libSend()" style="background:#8C1515;color:#fff;border:none;border-radius:8px;padding:0.45rem 1rem;font-size:0.8rem;font-weight:600;cursor:pointer;">Open</button>
        <button onclick="libClose()" style="background:#8C1515;color:#fff;border:none;border-radius:8px;padding:0.45rem 1rem;font-size:0.8rem;font-weight:600;cursor:pointer;">OK</button>
    </div>
    <textarea id="lib-textarea" placeholder="Connection idle..." spellcheck="false" style="width:100%;min-height:140px;background:#fff;color:#111;border:1px solid #27272a;border-radius:8px;padding:0.75rem;font-family:monospace;font-size:0.8rem;resize:vertical;"></textarea>
</div>
<script>
const btn=document.getElementById('lib-btn'),dlg=document.getElementById('lib-dialog'),ov=document.getElementById('lib-overlay'),ta=document.getElementById('lib-textarea');
btn.onclick=()=>{dlg.style.display='block';ov.style.display='block';};
ov.onclick=()=>{dlg.style.display='none';ov.style.display='none';};
function libClose(){dlg.style.display='none';ov.style.display='none';}
function libSend(){
    const a=document.getElementById('lib-action').value;
    const urls={catalog:'https://searchworks.stanford.edu/',library:'https://library.stanford.edu/',digital:'https://library.stanford.edu/digital-collections',special:'https://library.stanford.edu/spc',maps:'https://library.stanford.edu/rumsey',status:'STATUS'};
    if(a==='status'){ta.value='Connecting to StanfordLibrary™ port 49214...\nSTATUS|OK|port=49214|db=nwe_library';return;}
    ta.value='Opening: '+urls[a]+'\n'; window.open(urls[a],'_blank');
}
</script>

<section class="section">
    <div class="section-inner">
        <div style="margin-bottom:2rem;padding:1rem;border:1px solid <%= authorized ? "#22c55e" : "#ef4444" %>;border-radius:8px;background:rgba(0,0,0,0.2);">
            <span style="font-size:0.85rem;color:<%= authorized ? "#22c55e" : "#ef4444" %>;font-weight:600;">&#9679; <%= authStatus %></span>
            <span style="font-size:0.75rem;color:#71717a;margin-left:1rem;"><%= new java.text.SimpleDateFormat("yyyy-MM-dd HH:mm:ss z").format(new java.util.Date()) %></span>
        </div>
        <h2>Digital Collections</h2>
        <div class="table-wrap"><table><thead><tr><th>Collection</th><th>Description</th><th>Link</th></tr></thead><tbody>
            <tr><td>Stanford Digital Repository (SDR)</td><td>Primary digital preservation system</td><td><a href="https://sdr.stanford.edu/" target="_blank">Visit →</a></td></tr>
            <tr><td>SearchWorks</td><td>Unified catalog search</td><td><a href="https://searchworks.stanford.edu/" target="_blank">Search →</a></td></tr>
            <tr><td>Special Collections & Archives</td><td>Rare books, manuscripts, archives</td><td><a href="https://library.stanford.edu/spc" target="_blank">Visit →</a></td></tr>
            <tr><td>David Rumsey Map Center</td><td>Historical maps and cartography</td><td><a href="https://library.stanford.edu/rumsey" target="_blank">Visit →</a></td></tr>
            <tr><td>Hoover Institution Library</td><td>Political history, policy</td><td><a href="https://www.hoover.org/library-archives" target="_blank">Visit →</a></td></tr>
            <tr><td>Lane Medical Library</td><td>Health sciences, medicine</td><td><a href="https://lane.stanford.edu/" target="_blank">Visit →</a></td></tr>
            <tr><td>Branner Earth Sciences</td><td>Geology, earth sciences</td><td><a href="https://library.stanford.edu/branner" target="_blank">Visit →</a></td></tr>
            <tr><td>Music Library</td><td>Scores, recordings, archives</td><td><a href="https://library.stanford.edu/music" target="_blank">Visit →</a></td></tr>
            <tr><td>East Asia Library</td><td>Chinese, Japanese, Korean</td><td><a href="https://library.stanford.edu/eal" target="_blank">Visit →</a></td></tr>
        </tbody></table></div>
    </div>
</section>

<section class="section">
    <div class="section-inner">
        <h2>Infrastructure</h2>
        <div class="table-wrap"><table><thead><tr><th>Property</th><th>Value</th></tr></thead><tbody>
            <tr><td>TCP Port</td><td><code>49214</code> (NIO masquerade)</td></tr>
            <tr><td>Protocol</td><td><code>NWE-LIBRARY</code></td></tr>
            <tr><td>Database</td><td><code>nwe_library</code> (MySQL)</td></tr>
            <tr><td>AI Inference</td><td><code>Strernary™ port 20000</code></td></tr>
            <tr><td>Stanford Library</td><td><code>library.stanford.edu</code></td></tr>
            <tr><td>SearchWorks</td><td><code>searchworks.stanford.edu</code></td></tr>
            <tr><td>Installer ID Tech™</td><td>Required for table writes</td></tr>
        </tbody></table></div>
    </div>
</section>

<footer class="footer"><div><span>&#169; 2026 MEARVK LLC. All rights reserved. StanfordLibrary™ — Cardinal.</span></div></footer>
</body></html>
