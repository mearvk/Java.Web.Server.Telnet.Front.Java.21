<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=5.0, user-scalable=yes"/>
    <meta name="theme-color" content="#0a0a0f"/>
    <link rel="icon" type="image/png" href="../servlets/servlet/src/main/webapp/images/favicon.png"/>
    <title>BMA™ — Settings</title>
    <link rel="stylesheet" href="css/mobile.css"/>
<script src="js/scroll-preserve.js"></script>
</head>
<body>

<nav class="m-nav">
    <a href="index.jsp" class="m-nav-brand"><img src="../servlets/servlet/src/main/webapp/images/mearvk.ltd.logo.left.png" alt=""/>BMA™</a>
    <button id="m-hamburger" class="m-hamburger" aria-label="Menu"><span></span><span></span><span></span></button>
</nav>
<div id="m-menu" class="m-menu">
    <a href="index.jsp">Overview</a>
    <a href="species.jsp">Species</a>
    <a href="postal.jsp">Postal</a>
    <a href="art.jsp">Art</a>
    <a href="science.jsp">Science</a>
    <a href="legal.jsp">Legal Database</a>
    <a href="status.jsp">Status</a>
    <a href="settings.jsp" class="active">Settings</a>
</div>

<div class="m-hero">
    <span class="m-hero-tag">Configuration</span>
    <h1>Settings</h1>
    <p>Port preferences and role — saved locally and to session.</p>
</div>

<div class="m-section">
    <h2>Connection</h2>
    <div class="m-setting-row">
        <span class="m-setting-label">Active Port</span>
        <select id="settings-port" style="background:var(--bg-card);color:#fff;border:1px solid var(--border);border-radius:8px;padding:0.5rem;font-size:1rem;min-height:44px;">
            <option value="18500">18500 — Case Law</option>
            <option value="18501">18501 — US Code</option>
            <option value="18502">18502 — Public Laws</option>
            <option value="18503">18503 — Precedent</option>
            <option value="18504">18504 — Statutes</option>
            <option value="18505">18505 — CFR</option>
            <option value="18506">18506 — Counts</option>
            <option value="18507">18507 — Citations</option>
            <option value="18400">18400 — Art (NC Museum)</option>
            <option value="49152">49152 — NationalFinanceID</option>
        </select>
    </div>
    <div class="m-setting-row">
        <span class="m-setting-label">Role</span>
        <select id="settings-role" style="background:var(--bg-card);color:#fff;border:1px solid var(--border);border-radius:8px;padding:0.5rem;font-size:1rem;min-height:44px;">
            <option value="guest">Guest (read-only)</option>
            <option value="user">User (search + connect)</option>
            <option value="admin">Admin (full control)</option>
        </select>
    </div>
</div>

<div class="m-section">
    <h2>Role Permissions</h2>
    <div class="m-card"><div class="m-card-title">Guest</div><div class="m-card-note">Read-only. View counts, precedent tables. No port connections.</div></div>
    <div class="m-card"><div class="m-card-title">User</div><div class="m-card-note">Search legal data. Connect/disconnect ports. Cannot save server config.</div></div>
    <div class="m-card"><div class="m-card-title">Admin</div><div class="m-card-note">Full control. Set/unset ports, save configuration, access all endpoints.</div></div>
</div>

<div class="m-section">
    <button id="settings-save" style="width:100%;padding:1rem;background:var(--accent);color:#fff;border:none;border-radius:8px;font-size:1rem;font-weight:600;min-height:44px;cursor:pointer;">Save Settings</button>
    <p id="settings-status" style="text-align:center;margin-top:0.75rem;font-size:0.85rem;color:var(--text-muted);"></p>
</div>

<div class="m-section">
    <h2>Session Info</h2>
    <div class="m-setting-row"><span class="m-setting-label">Saved Port</span><span id="info-port" class="m-setting-value">—</span></div>
    <div class="m-setting-row"><span class="m-setting-label">Saved Role</span><span id="info-role" class="m-setting-value">—</span></div>
    <div class="m-setting-row"><span class="m-setting-label">Last Saved</span><span id="info-time" class="m-setting-value">—</span></div>
</div>

<nav class="m-bottom-nav">
    <a href="index.jsp"><span class="nav-icon">🏠</span>Home</a>
    <a href="legal.jsp"><span class="nav-icon">⚖️</span>Legal</a>
    <a href="status.jsp"><span class="nav-icon">📊</span>Status</a>
    <a href="settings.jsp"><span class="nav-icon">⚙️</span>Settings</a>
</nav>

<script src="js/mobile.js"></script>
<script>
(function(){
    var portEl = document.getElementById("settings-port");
    var roleEl = document.getElementById("settings-role");
    var saveBtn = document.getElementById("settings-save");
    var statusEl = document.getElementById("settings-status");

    // Load saved values
    var sp = localStorage.getItem("bma-port");
    var sr = localStorage.getItem("bma-role");
    var st = localStorage.getItem("bma-save-time");
    if (sp && portEl) portEl.value = sp;
    if (sr && roleEl) roleEl.value = sr;
    document.getElementById("info-port").textContent = sp || "not set";
    document.getElementById("info-role").textContent = sr || "not set";
    document.getElementById("info-time").textContent = st || "never";

    saveBtn.addEventListener("click", function() {
        var port = portEl.value;
        var role = roleEl.value;
        var now = new Date().toLocaleString();
        localStorage.setItem("bma-port", port);
        localStorage.setItem("bma-role", role);
        localStorage.setItem("bma-save-time", now);
        document.getElementById("info-port").textContent = port;
        document.getElementById("info-role").textContent = role;
        document.getElementById("info-time").textContent = now;
        statusEl.textContent = "Saved ✓ (port=" + port + ", role=" + role + ")";
        statusEl.style.color = "#22c55e";
        setTimeout(function(){ statusEl.style.color = "var(--text-muted)"; }, 3000);
    });
})();
</script>
</body>
</html>
