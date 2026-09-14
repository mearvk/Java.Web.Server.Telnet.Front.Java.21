<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.net.HttpURLConnection, java.net.URI" %>
<%
    boolean authorized = false;
    String authMsg = "Checking...";
    try {
        HttpURLConnection conn = (HttpURLConnection) URI.create(
            "https://raw.githubusercontent.com/mearvk/Java.Web.Server.Telnet.Front.Java.21/main/psychiatry/secrets/public.key"
        ).toURL().openConnection();
        conn.setRequestMethod("HEAD");
        conn.setConnectTimeout(5000);
        conn.setReadTimeout(5000);
        int code = conn.getResponseCode();
        conn.disconnect();
        if (code == 200) { authorized = true; authMsg = "Authorized — public.key present"; }
        else { authMsg = "NOT AUTHORIZED — public.key missing (HTTP " + code + ")"; }
    } catch (Exception e) {
        authMsg = "Authorization check failed: " + e.getMessage();
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Futures&#8482; — D500 Democratic ProFront National 1.0</title>
    <link rel="stylesheet" href="css/style.css">
<script src="js/scroll-preserve.js"></script>
    <script src="js/nwe-readme-viewer.js"></script>
    <link rel="preconnect" href="https://fonts.googleapis.com"/><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin/><link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:ital,wght@0,300;0,400;0,500;0,600;0,700;1,400;1,600&display=swap" rel="stylesheet"/>
</head>
<body>

<nav>
    <span class="brand">Futures&#8482;</span>
    <a href="index.jsp" class="active">Overview</a>
    <a href="pipeline.jsp">Pipeline</a>
    <a href="training.jsp">Training</a>
    <a href="safety.jsp">Safety</a>
    <a href="status.jsp">Status</a>
<div class="nav-actions" style="margin-left:auto;display:flex;gap:0.5rem;align-items:center;"><%@ include file="auth-buttons.jsp" %></div>
</nav>

<div class="hero">
    <span class="tag">US Democratic Block</span>
    <h1>Futures&#8482;</h1>
    <p>D500 Democratic President — AI tax defense speculation engine. Protective procedural pipeline using Java CompletableFuture patterns with DJL/PyTorch inference on port 5000.</p>
    <div class="auth-status">
        <span class="dot <%= authorized ? "green" : "red" %>"></span>
        <span><%= authMsg %></span>
    </div>
</div>
<!-- CD1 Connector Button + Floating Dialog (BMA Template) -->
<div style="display:flex;justify-content:center;align-items:center;width:100%;padding:2rem 0;">
    <button id="cd1-btn" type="button" aria-pressed="false" style="all:unset;display:block;margin:0 auto;cursor:pointer;padding:0;border:none;background:transparent;transition:transform 0.3s cubic-bezier(0.42,-1.84,0.42,1.84),filter 0.3s ease;">
        <img src="images/black.button.png" alt="Connector" style="display:block;width:80px;height:80px;border-radius:50%;background:transparent;"/>
    </button>
</div>
<div id="cd1-overlay" style="display:none;position:fixed;inset:0;z-index:299;background:transparent;"></div>
<div id="cd1-dialog" style="display:none;position:fixed;top:50%;left:50%;transform:translate(-50%,-50%);z-index:300;background:#111118;border:1px solid #27272a;border-radius:12px;padding:1.25rem;width:520px;max-width:90vw;box-shadow:0 8px 32px rgba(0,0,0,0.6);">
    <div style="font-size:0.9rem;font-weight:600;color:#fff;margin-bottom:0.75rem;">Futures Connector &#8212; Overview</div>
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
<script>window.CD1_MODULE_PORT = "5000";</script>
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

<section>
    <h2>Pipeline Stages</h2>
    <table>
        <thead>
            <tr><th>Stage</th><th>Future Pattern</th><th>Protective Role</th></tr>
        </thead>
        <tbody>
            <tr><td>ConnectionGuard</td><td>supplyAsync</td><td>Initial connection validation and identity check</td></tr>
            <tr><td>DueProcessPipeline</td><td>thenCompose</td><td>Sequential due-process verification chain</td></tr>
            <tr><td>ParallelVetting</td><td>allOf</td><td>Concurrent multi-source background vetting</td></tr>
            <tr><td>ConsentGate</td><td>thenCombine</td><td>Merge consent signals before proceeding</td></tr>
            <tr><td>EjectionFuture</td><td>exceptionally</td><td>Graceful ejection on pipeline failure</td></tr>
            <tr><td>ResponseDispatcher</td><td>thenApply</td><td>Transform and dispatch authorized response</td></tr>
            <tr><td>GracefulTransfer</td><td>thenCompose</td><td>Handoff to downstream services</td></tr>
            <tr><td>LearningAccumulator</td><td>thenAccept</td><td>Accumulate outcomes for model training</td></tr>
        </tbody>
    </table>
</section>

<section>
    <h2>Infrastructure</h2>
    <table>
        <thead>
            <tr><th>Component</th><th>Value</th></tr>
        </thead>
        <tbody>
            <tr><td>Port</td><td>5000</td></tr>
            <tr><td>Inference</td><td>DJL / PyTorch</td></tr>
            <tr><td>Database</td><td>MySQL — nwe_futures</td></tr>
            <tr><td>Wait Strategy</td><td>Secure Random Wait</td></tr>
        </tbody>
    </table>
</section>

<footer>&copy; 2026 MEARVK LLC</footer>

</body>
</html>
