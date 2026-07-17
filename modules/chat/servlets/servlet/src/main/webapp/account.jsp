<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>Account — Communicator™</title>
    <link rel="stylesheet" href="css/style.css"/>
    <script src="js/scroll-preserve.js"></script>
    <script src="js/nwe-readme-viewer.js"></script>
</head>
<body>
<nav class="nav"><div class="nav-inner">
    <span class="nav-brand"><img src="images/MearvK.Ltd/communicator/trillian.jpeg" alt="Communicator" style="height:24px;width:auto;vertical-align:middle;margin-right:6px;background:transparent;border-radius:4px;"/>Communicator™</span>
    <ul class="nav-links">
        <li><a href="index.jsp">Chat</a></li>
        <li><a href="account.jsp" class="active">Account</a></li>
        <li><a href="federation.jsp">Federation</a></li>
        <li><a href="settings.jsp">Settings</a></li>
        <li><a href="admin.jsp">Admin</a></li>
        <li><a href="status.jsp">Status</a></li>
    </ul>
</div></nav>

<section class="hero">
    <div class="hero-inner">
        <span class="hero-tag">Account Management</span>
        <h1>Your Account</h1>
        <p>Register, login, change username, or delete your account. All actions encrypted.</p>
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
        <h2>Register</h2>
        <form method="POST" action="account.jsp" style="max-width:500px;">
            <input type="hidden" name="action" value="register"/>
            <div class="form-group"><label>Username (3-32 chars)</label><input type="text" name="username" required minlength="3" maxlength="32"/></div>
            <div class="form-group"><label>Password (6+ chars)</label><input type="password" name="password" required minlength="6"/></div>
            <div class="form-group"><label>Email</label><input type="email" name="email" required/></div>
            <button type="submit" class="btn btn-primary">Create Account</button>
        </form>
    </div>
</section>

<section class="section">
    <div class="section-inner">
        <h2>Login</h2>
        <form method="POST" action="account.jsp" style="max-width:500px;">
            <input type="hidden" name="action" value="login"/>
            <div class="form-group"><label>Username</label><input type="text" name="username" required/></div>
            <div class="form-group"><label>Password</label><input type="password" name="password" required/></div>
            <button type="submit" class="btn btn-primary">Login</button>
        </form>
    </div>
</section>

<section class="section">
    <div class="section-inner">
        <h2>Change Username</h2>
        <form method="POST" action="account.jsp" style="max-width:500px;">
            <input type="hidden" name="action" value="change_username"/>
            <div class="form-group"><label>New Username</label><input type="text" name="new_username" required minlength="3" maxlength="32"/></div>
            <button type="submit" class="btn btn-ghost">Change Username</button>
        </form>
    </div>
</section>

<section class="section">
    <div class="section-inner">
        <h2>Delete Account</h2>
        <p style="color:var(--text-muted);margin-bottom:1rem;">This marks your account for deletion. Existing chat logs remain for audit purposes.</p>
        <form method="POST" action="account.jsp" onsubmit="return confirm('Are you sure? This cannot be undone.');">
            <input type="hidden" name="action" value="delete"/>
            <button type="submit" class="btn btn-danger">Delete My Account</button>
        </form>
    </div>
</section>

<footer class="footer">
    <span>Communicator™ — Account — MEARVK LLC — NitroWebExpress™ 2026</span>
</footer>
</body>
</html>
