<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
    String __user = (String) session.getAttribute("chat_username");
    Boolean __admin = (Boolean) session.getAttribute("chat_admin");
    if (__admin == null) __admin = false;
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/>
    <link rel="preconnect" href="https://fonts.googleapis.com"/><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin/><link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:ital,wght@0,300;0,400;0,500;0,600;0,700;1,400;1,600&display=swap" rel="stylesheet"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>Federation — Communicator™</title>
    <link rel="stylesheet" href="css/style.css"/>
    <script src="js/scroll-preserve.js"></script>
    <script src="js/nwe-readme-viewer.js"></script>
</head>
<body>
<nav class="nav"><div class="nav-inner">
    <span class="nav-brand"><img src="images/MearvK.Ltd/communicator/trillian.jpeg" alt="Communicator" style="height:24px;width:auto;vertical-align:middle;margin-right:6px;background:transparent;border-radius:4px;"/>Communicator™</span>
    <ul class="nav-links">
        <li><a href="index.jsp">Chat</a></li>
        <li><a href="account.jsp">Account</a></li>
        <li><a href="federation.jsp" class="active">Federation</a></li>
        <li><a href="settings.jsp">Settings</a></li>
        <li><a href="admin.jsp">Admin</a></li>
        <li><a href="status.jsp">Status</a></li>
    </ul>
<div class="nav-actions">
        <% if (__admin) { %>
            <span style="font-size:0.75rem;color:#f59e0b;margin-right:4px;">&#9733; Admin</span>
            <a href="admin.jsp?action=logout" class="nav-cta" style="border-color:#dc2626;color:#dc2626;">Logout</a>
        <% } else if (__user != null) { %>
            <span style="font-size:0.8rem;color:var(--accent);margin-right:6px;"><%= __user %></span>
            <a href="account.jsp?action=logout" class="nav-cta" style="border-color:#dc2626;color:#dc2626;">Logout</a>
        <% } else { %>
            <a href="account.jsp" class="nav-cta">Login</a>
            <a href="admin.jsp" class="nav-cta" style="border-color:#f59e0b;color:#f59e0b;">Admin</a>
        <% } %>
    </div>
</div></nav>

<section class="hero">
    <div class="hero-inner">
        <span class="hero-tag">Multi-Server Federation</span>
        <h1>Federation</h1>
        <p>Connect to up to 5 external Communicator™ servers (of Max Rupplin's design) by IP or domain name. Earn ranks through successful connections.</p>
    </div>
</section>

<!-- CD1 Connector Button + Floating Dialog -->
<div style="display:flex;justify-content:center;align-items:center;width:100%;padding:2rem 0;">
    <button id="cd1-btn" type="button" aria-pressed="false" style="all:unset;display:block;margin:0 auto;cursor:pointer;padding:0;border:none;background:transparent;transition:transform 0.3s cubic-bezier(0.42,-1.84,0.42,1.84),filter 0.3s ease;">
        <img src="images/black.button.png" alt="Connector" style="display:block;width:80px;height:80px;border-radius:50%;background:transparent;"/>
    </button>
</div>
<div id="cd1-overlay" style="display:none;position:fixed;inset:0;z-index:299;background:transparent;"></div>
<div id="cd1-dialog" style="display:none;position:fixed;top:50%;left:50%;transform:translate(-50%,-50%);z-index:300;background:#1a1a1a;border:1px solid #333;border-radius:12px;padding:1.25rem;width:520px;max-width:90vw;box-shadow:0 8px 32px rgba(0,0,0,0.6);">
    <div style="font-size:0.9rem;font-weight:600;color:#e8e0d6;margin-bottom:0.75rem;">CD1 Connector &#8212; Port 49230</div>
    <div style="display:flex;gap:0.5rem;margin-bottom:0.75rem;flex-wrap:wrap;align-items:center;">
        <select id="cd1-action" style="background:#222;color:#e8e0d6;border:1px solid #444;border-radius:8px;padding:0.45rem 2rem 0.45rem 0.75rem;font-size:0.8rem;cursor:pointer;appearance:none;">
            <option value="connect">Connect</option>
            <option value="disconnect">Disconnect</option>
            <option value="status">Status</option>
            <option value="hardreset">Hard Reset Connection</option>
        </select>
        <button onclick="cd1Send()" style="background:#666;color:#fff;border:none;border-radius:8px;padding:0.45rem 1rem;font-size:0.8rem;font-weight:600;cursor:pointer;">Send</button>
        <button onclick="cd1Ok()" style="background:#666;color:#fff;border:none;border-radius:8px;padding:0.45rem 1rem;font-size:0.8rem;font-weight:600;cursor:pointer;">OK</button>
    </div>
    <div style="display:flex;align-items:center;gap:0.5rem;margin-bottom:0.75rem;">
        <label style="display:flex;align-items:center;gap:0.4rem;color:#999;font-size:0.75rem;cursor:pointer;">
            <input type="checkbox" id="cd1-direct-port" style="accent-color:#888;width:14px;height:14px;cursor:pointer;"/>
            Direct Port (bypass Strernary&#8482; 20000)
        </label>
        <span id="cd1-mode-badge" style="font-size:0.65rem;background:#222;color:#aaa;padding:0.2rem 0.5rem;border-radius:4px;">STRERNARY</span>
    </div>
    <textarea id="cd1-textarea" placeholder="Connection idle..." spellcheck="false" style="width:100%;min-height:140px;background:#ffffff;color:#111;border:1px solid #333;border-radius:8px;padding:0.75rem;font-family:monospace;font-size:0.8rem;resize:vertical;"></textarea>
</div>
<script>window.CD1_MODULE_PORT = "49230";</script>
<script src="js/cd1-connector.js"></script>


<section class="section">
    <div class="section-inner">
        <h2>Connect to Remote Server</h2>
        <form method="POST" action="federation.jsp" style="max-width:600px;">
            <div style="display:grid;grid-template-columns:3fr 1fr;gap:1rem;">
                <div class="form-group"><label>Server Address (IP or Domain)</label><input type="text" name="server" required placeholder="e.g. 192.168.1.100 or chat.example.com"/></div>
                <div class="form-group"><label>Port (optional)</label><input type="number" name="port" placeholder="49230" value="49230"/></div>
            </div>
            <button type="submit" class="btn btn-primary">Federate</button>
        </form>
    </div>
</section>

<section class="section">
    <div class="section-inner">
        <h2>Rank Progression</h2>
        <div class="table-wrap">
        <table>
            <thead><tr><th>Connects</th><th>Rank</th><th>Reward</th></tr></thead>
            <tbody>
                <tr><td>50+</td><td><span class="badge badge-online">CONNECTOR</span></td><td>Federation Connector badge</td></tr>
                <tr><td>100+</td><td><span class="badge badge-encrypted">FEDERATION VETERAN</span></td><td>Veteran status + priority routing</td></tr>
                <tr><td>200+</td><td><span class="badge badge-rank">CONCEALMENT 3</span></td><td>★ Concealment 3 Rank — elevated encryption tier</td></tr>
                <tr><td>300+</td><td><span class="badge badge-gold">GOLD HARVARD CERTIFICATE</span></td><td>★★ Gold Letter of Certificate from Harvard. Kids.</td></tr>
            </tbody>
        </table>
        </div>
        <p style="margin-top:1rem;font-size:0.85rem;color:var(--text-muted);">Federated connections must be to verified Communicator™ servers of Max Rupplin's design. The server will probe the remote endpoint to verify compatibility before counting the connection.</p>
    </div>
</section>

<section class="section">
    <div class="section-inner">
        <h2>Your Federation Status</h2>
        <div class="table-wrap">
        <table>
            <thead><tr><th>Property</th><th>Value</th></tr></thead>
            <tbody>
                <tr><td>Max Servers</td><td>5</td></tr>
                <tr><td>Connected Servers</td><td><em>(login required)</em></td></tr>
                <tr><td>Total Successful Connects</td><td><em>(login required)</em></td></tr>
                <tr><td>Current Rank</td><td><em>(login required)</em></td></tr>
            </tbody>
        </table>
        </div>
    </div>
</section>

<footer class="footer">
    <span>Communicator™ — Federation — MEARVK LLC — NitroWebExpress™ 2026</span>
</footer>
</body>
</html>
