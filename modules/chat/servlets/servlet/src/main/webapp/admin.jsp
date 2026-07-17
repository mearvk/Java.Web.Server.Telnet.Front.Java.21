<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>Admin — Communicator™</title>
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
        <li><a href="federation.jsp">Federation</a></li>
        <li><a href="settings.jsp">Settings</a></li>
        <li><a href="admin.jsp" class="active">Admin</a></li>
        <li><a href="status.jsp">Status</a></li>
    </ul>
</div></nav>

<section class="hero">
    <div class="hero-inner">
        <span class="hero-tag">Administration Panel</span>
        <h1>Admin</h1>
        <p>User management, chat logs, IP/Geo tracking, ban/unban. Requires admin authentication.</p>
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
        <h2>Admin Login</h2>
        <form method="POST" action="admin.jsp" style="max-width:400px;">
            <input type="hidden" name="action" value="admin_login"/>
            <div class="form-group"><label>Admin Password</label><input type="password" name="admin_password" required/></div>
            <button type="submit" class="btn btn-primary">Authenticate</button>
        </form>
    </div>
</section>

<section class="section">
    <div class="section-inner">
        <h2>User Management</h2>
        <div style="display:flex;gap:1rem;flex-wrap:wrap;margin-bottom:1rem;">
            <form method="POST" action="admin.jsp" style="display:flex;gap:0.5rem;align-items:flex-end;">
                <input type="hidden" name="action" value="ban"/>
                <div class="form-group" style="margin:0;"><label>Ban User</label><input type="text" name="username" required placeholder="username" style="width:150px;"/></div>
                <button type="submit" class="btn btn-danger">Ban</button>
            </form>
            <form method="POST" action="admin.jsp" style="display:flex;gap:0.5rem;align-items:flex-end;">
                <input type="hidden" name="action" value="unban"/>
                <div class="form-group" style="margin:0;"><label>Unban User</label><input type="text" name="username" required placeholder="username" style="width:150px;"/></div>
                <button type="submit" class="btn btn-ghost">Unban</button>
            </form>
        </div>
    </div>
</section>

<section class="section">
    <div class="section-inner">
        <h2>View User Geo/IP</h2>
        <form method="POST" action="admin.jsp" style="display:flex;gap:0.5rem;align-items:flex-end;max-width:400px;">
            <input type="hidden" name="action" value="geo"/>
            <div class="form-group" style="margin:0;flex:1;"><label>Username</label><input type="text" name="username" required placeholder="username"/></div>
            <button type="submit" class="btn btn-ghost">Lookup</button>
        </form>
    </div>
</section>

<section class="section">
    <div class="section-inner">
        <h2>Admin Commands (Telnet)</h2>
        <div class="table-wrap">
        <table>
            <thead><tr><th>Command</th><th>Description</th></tr></thead>
            <tbody>
                <tr><td><code>ADMIN_USERS</code></td><td>List all users with IPs, geo, federation stats, ban status</td></tr>
                <tr><td><code>ADMIN_BAN|username</code></td><td>Ban a user (disconnects immediately)</td></tr>
                <tr><td><code>ADMIN_UNBAN|username</code></td><td>Remove ban from a user</td></tr>
                <tr><td><code>ADMIN_LOGS</code></td><td>View last 50 events (logins, registrations, bans, etc.)</td></tr>
                <tr><td><code>ADMIN_GEO|username</code></td><td>View registration IP, last IP, city, country</td></tr>
                <tr><td><code>ADMIN_IPS</code></td><td>View all currently connected users and their IPs/Geos</td></tr>
            </tbody>
        </table>
        </div>
    </div>
</section>

<footer class="footer">
    <span>Communicator™ — Admin — MEARVK LLC — NitroWebExpress™ 2026</span>
</footer>
</body>
</html>
