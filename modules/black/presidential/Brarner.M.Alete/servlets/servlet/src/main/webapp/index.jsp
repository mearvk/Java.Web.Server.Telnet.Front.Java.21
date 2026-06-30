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
    <link rel="icon" type="image/png" href="images/favicon.png"/>
    <title>Brarner.M.Alete™ — Presidential Species/Postal/SSA/Art/Science Module</title>
    <link rel="stylesheet" href="css/style.css"/>
<script src="js/scroll-preserve.js"></script>
</head>
<body>
<nav class="nav"><div class="nav-inner">
    <a href="index.jsp" class="nav-brand"><img src="images/mearvk.ltd.logo.left.png" alt="" style="height:40px;vertical-align:middle;margin-right:8px;background:transparent;"/>Brarner.M.Alete™<img src="images/mearvk.ltd.logo.right.png" alt="" style="height:40px;vertical-align:middle;margin-left:8px;background:transparent;"/></a>
    <ul class="nav-links">
        <li><a href="index.jsp" class="active">Overview</a></li>
        <li><a href="species.jsp">Species</a></li>
        <li><a href="postal.jsp">Postal</a></li>
        <li><a href="art.jsp">Art</a></li>
        <li><a href="science.jsp">Science</a></li>
        <li><a href="legal.jsp">Legal</a></li>
        <li><a href="status.jsp">Status</a></li>
    </ul>
    <div class="nav-actions">
        <a href="guest.jsp" class="nav-cta">Guest</a>
        <a href="register.jsp" class="nav-cta">Register</a>
        <a href="admin/login.jsp" class="nav-cta">Admin →</a>
    </div>
</div></nav>

<section class="hero">
    <div class="hero-inner">
        <span class="hero-tag">NC Socialist-College Block</span>
        <h1>Brarner.M.Alete™</h1>
        <p>Presidential species, postal, SSA, art and science module. Maven multi-module architecture with servlets, EJB, and EAR packaging — maintained by MEARVK LLC.</p>
        <div class="hero-actions">
            <a href="https://github.com/mearvk/Java.Web.Server.Telnet.Front.Java.21/releases/latest" class="btn btn-primary">Download Now</a>
            <a href="#roadmap" class="btn btn-ghost">View Roadmap →</a>
        </div>
    </div>
</section>

<!-- CD1 Connector Button + Floating Dialog -->
<div style="display:flex;justify-content:center;align-items:center;width:100%;padding:2rem 0;">
    <button id="cd1-btn" type="button" aria-pressed="false" style="all:unset;display:block;margin:0 auto;cursor:pointer;padding:0;border:none;background:transparent;transition:transform 0.3s cubic-bezier(0.42,-1.84,0.42,1.84),filter 0.3s ease;">
        <img src="images/black.button.png" alt="Connector" style="display:block;width:80px;height:80px;border-radius:50%;background:transparent;"/>
    </button>
</div>
<div id="cd1-overlay" style="display:none;position:fixed;inset:0;z-index:299;background:transparent;"></div>
<div id="cd1-dialog" style="display:none;position:fixed;top:50%;left:50%;transform:translate(-50%,-50%);z-index:300;background:#111118;border:1px solid #27272a;border-radius:12px;padding:1.25rem;width:520px;max-width:90vw;box-shadow:0 8px 32px rgba(0,0,0,0.6);">
    <div style="font-size:0.9rem;font-weight:600;color:#fff;margin-bottom:0.75rem;">BMA Connector &#8212; Overview</div>
    <div style="display:flex;gap:0.5rem;margin-bottom:0.75rem;flex-wrap:wrap;">
        <select id="cd1-action" style="background:#1a1a24;color:#fff;border:1px solid #27272a;border-radius:8px;padding:0.45rem 2rem 0.45rem 0.75rem;font-size:0.8rem;cursor:pointer;appearance:none;">
            <option value="connect">Connect</option>
            <option value="disconnect">Disconnect</option>
            <option value="poll">Poll Area Data</option>
            <option value="hardreset">Hard Reset Connection</option>
        </select>
        <button onclick="cd1Send()" style="background:#3b82f6;color:#fff;border:none;border-radius:8px;padding:0.45rem 1rem;font-size:0.8rem;font-weight:600;cursor:pointer;">Send</button>
        <button onclick="cd1Ok()" style="background:#3b82f6;color:#fff;border:none;border-radius:8px;padding:0.45rem 1rem;font-size:0.8rem;font-weight:600;cursor:pointer;">OK</button>
    </div>
    <textarea id="cd1-textarea" placeholder="Connection idle..." spellcheck="false" style="width:100%;min-height:140px;background:#ffffff;color:#111;border:1px solid #27272a;border-radius:8px;padding:0.75rem;font-family:monospace;font-size:0.8rem;resize:vertical;"></textarea>
</div>

<section class="section" id="roadmap">
    <div class="section-inner">
        <div style="margin-bottom:2rem;padding:1rem;border:1px solid <%= authorized ? "#22c55e" : "#ef4444" %>;border-radius:8px;background:<%= authorized ? "rgba(34,197,94,0.05)" : "rgba(239,68,68,0.05)" %>;">
            <span style="font-size:0.85rem;color:<%= authorized ? "#22c55e" : "#ef4444" %>;font-weight:600;">&#9679; <%= authStatus %></span>
            <span style="font-size:0.75rem;color:#71717a;margin-left:1rem;">Checked: <%= new java.text.SimpleDateFormat("yyyy-MM-dd HH:mm:ss z").format(new java.util.Date()) %></span>
        </div>
        <h2>Editions <span id="editions-status" style="font-size:0.7rem;color:#71717a;font-weight:400;margin-left:0.5rem;"></span></h2>
        <p>Module release schedule and versioning. All releases LTS. <span style="font-size:0.75rem;color:#71717a;">(Auto-refreshes every 5 minutes from GitHub Releases)</span></p>
        <div class="table-wrap">
            <table>
                <thead><tr><th>Release</th><th>GA Date</th><th>Tag</th><th>Min JDK</th><th>LTS</th></tr></thead>
                <tbody id="editions-tbody">
                    <tr><td colspan="5" style="text-align:center;color:#71717a;">Loading editions...</td></tr>
                </tbody>
            </table>
        </div>
    </div>
</section>
<script>
(function(){
    var REPO='mearvk/Java.Web.Server.Telnet.Front.Java.21';
    var API='https://api.github.com/repos/'+REPO+'/releases?per_page=20';
    var TAGS_API='https://api.github.com/repos/'+REPO+'/tags?per_page=30';
    var tbody=document.getElementById('editions-tbody');
    var status=document.getElementById('editions-status');
    var POLL_MS=300000; // 5 minutes

    function formatDate(d){if(!d)return'—';var dt=new Date(d);return dt.toLocaleDateString('en-US',{month:'short',year:'numeric'});}
    function esc(s){if(!s)return'';var d=document.createElement('div');d.textContent=s;return d.innerHTML;}

    function renderRows(releases,tags){
        if(!releases.length&&!tags.length){tbody.innerHTML='<tr><td colspan="5" style="text-align:center;color:#71717a;">No releases found</td></tr>';return;}
        var html='';
        // Releases first
        releases.forEach(function(r){
            html+='<tr><td><code>'+esc(r.name||r.tag_name)+'</code></td>';
            html+='<td>'+formatDate(r.published_at)+'</td>';
            html+='<td><a href="'+esc(r.html_url)+'" target="_blank">'+esc(r.tag_name)+'</a></td>';
            html+='<td><code>21</code></td><td>yes</td></tr>';
        });
        // Tags that aren't in releases
        var relTags=releases.map(function(r){return r.tag_name;});
        tags.forEach(function(t){
            if(relTags.indexOf(t.name)===-1){
                html+='<tr><td><code>'+esc(t.name)+'</code></td><td>—</td>';
                html+='<td><a href="https://github.com/'+REPO+'/releases/tag/'+encodeURIComponent(t.name)+'" target="_blank">'+esc(t.name)+'</a></td>';
                html+='<td><code>21</code></td><td>yes</td></tr>';
            }
        });
        tbody.innerHTML=html;
    }

    function poll(){
        status.textContent='polling...';
        Promise.all([
            fetch(API).then(function(r){return r.ok?r.json():[]}).catch(function(){return[];}),
            fetch(TAGS_API).then(function(r){return r.ok?r.json():[]}).catch(function(){return[];})
        ]).then(function(results){
            renderRows(results[0],results[1]);
            status.textContent='updated '+new Date().toLocaleTimeString();
        }).catch(function(){
            status.textContent='fetch failed';
        });
    }

    poll();
    setInterval(poll,POLL_MS);
})();
</script>

<section class="section">
    <div class="section-inner">
        <h2>Module Components</h2>
        <div class="table-wrap">
            <table>
                <thead><tr><th>Component</th><th>Description</th><th>Link</th></tr></thead>
                <tbody>
                    <tr><td>Species</td><td>Biological classification — animalia, plantae, fungi, protista</td><td><a href="species.jsp">Browse →</a></td></tr>
                    <tr><td>Postal</td><td>US Postal code lookup and validation for all 50 states</td><td><a href="postal.jsp">Browse →</a></td></tr>
                    <tr><td>Art</td><td>Art museum collections indexer — 22 institutions</td><td><a href="art.jsp">Browse →</a></td></tr>
                    <tr><td>Science</td><td>Scientific publication indexer with DOI resolution</td><td><a href="science.jsp">Browse →</a></td></tr>
                    <tr><td>Status</td><td>Real-time module health monitoring</td><td><a href="status.jsp">View →</a></td></tr>
                </tbody>
            </table>
        </div>
    </div>
</section>

<footer class="footer"><div class="footer-bottom">
    <span>&#169; 2026 MEARVK LLC. All rights reserved.</span>
</div></footer>

<script>
(function() {
    var btn = document.getElementById("cd1-btn");
    var dialog = document.getElementById("cd1-dialog");
    var overlay = document.getElementById("cd1-overlay");
    var textarea = document.getElementById("cd1-textarea");
    if (!btn || !dialog || !overlay || !textarea) return;
    btn.addEventListener("click", function() {
        if (dialog.style.display !== "none") {
            dialog.style.display = "none";
            overlay.style.display = "none";
            btn.style.transform = "";
            btn.style.filter = "";
            return;
        }
        btn.style.transform = "scale(0.9)";
        btn.style.filter = "drop-shadow(0 0 8px #3b82f6)";
        setTimeout(function() {
            btn.style.transform = "";
            btn.style.filter = "";
            dialog.style.display = "block";
            overlay.style.display = "block";
        }, 750);
    });
    overlay.addEventListener("click", function() { dialog.style.display = "none"; overlay.style.display = "none"; });
})();
function cd1Send() { var s = document.getElementById("cd1-action"); var t = document.getElementById("cd1-textarea"); if(!s||!t)return; t.value += "[" + new Date().toLocaleTimeString() + "] " + s.value + " sent.\n"; }
function cd1Ok() { var t = document.getElementById("cd1-textarea"); if(!t)return; t.value += "[" + new Date().toLocaleTimeString() + "] OK.\n"; }
</script>
</body>
</html>
