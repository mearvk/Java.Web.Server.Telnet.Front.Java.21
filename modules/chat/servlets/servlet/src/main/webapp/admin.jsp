<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>Admin — NWE Chat™</title>
    <link rel="stylesheet" href="css/style.css"/>
    <script src="js/scroll-preserve.js"></script>
</head>
<body>
<nav class="nav"><div class="nav-inner">
    <span class="nav-brand">NWE Chat™</span>
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
    <span>NWE Chat™ — Admin — MEARVK LLC — NitroWebExpress™ 2026</span>
</footer>
</body>
</html>
