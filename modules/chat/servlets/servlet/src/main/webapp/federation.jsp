<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>Federation — NWE Chat™</title>
    <link rel="stylesheet" href="css/style.css"/>
    <script src="js/scroll-preserve.js"></script>
    <script src="js/nwe-readme-viewer.js"></script>
</head>
<body>
<nav class="nav"><div class="nav-inner">
    <span class="nav-brand">NWE Chat™</span>
    <ul class="nav-links">
        <li><a href="index.jsp">Chat</a></li>
        <li><a href="account.jsp">Account</a></li>
        <li><a href="federation.jsp" class="active">Federation</a></li>
        <li><a href="settings.jsp">Settings</a></li>
        <li><a href="admin.jsp">Admin</a></li>
        <li><a href="status.jsp">Status</a></li>
    </ul>
</div></nav>

<section class="hero">
    <div class="hero-inner">
        <span class="hero-tag">Multi-Server Federation</span>
        <h1>Federation</h1>
        <p>Connect to up to 5 external NWE Chat™ servers (of Max Rupplin's design) by IP or domain name. Earn ranks through successful connections.</p>
    </div>
</section>

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
        <p style="margin-top:1rem;font-size:0.85rem;color:var(--text-muted);">Federated connections must be to verified NWE Chat™ servers of Max Rupplin's design. The server will probe the remote endpoint to verify compatibility before counting the connection.</p>
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
    <span>NWE Chat™ — Federation — MEARVK LLC — NitroWebExpress™ 2026</span>
</footer>
</body>
</html>
