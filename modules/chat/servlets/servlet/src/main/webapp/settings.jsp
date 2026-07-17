<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>Settings — Communicator™</title>
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
        <li><a href="settings.jsp" class="active">Settings</a></li>
        <li><a href="admin.jsp">Admin</a></li>
        <li><a href="status.jsp">Status</a></li>
    </ul>
</div></nav>

<section class="hero">
    <div class="hero-inner">
        <span class="hero-tag">Configuration — Review, Set, Revise</span>
        <h1>Settings</h1>
        <p>Review and revise chat server settings. All settings are stored in XML configuration and the database. Changes take effect immediately.</p>
    </div>
</section>

<section class="section">
    <div class="section-inner">
        <h2>Current Settings</h2>
        <div class="table-wrap">
        <table>
            <thead><tr><th>Setting</th><th>Value</th><th>Last Updated By</th></tr></thead>
            <tbody>
                <tr><td>session_timeout_hours</td><td>4</td><td>Max Rupplin</td></tr>
                <tr><td>max_federation_servers</td><td>5</td><td>Max Rupplin</td></tr>
                <tr><td>concealment_3_threshold</td><td>200</td><td>Max Rupplin</td></tr>
                <tr><td>gold_cert_threshold</td><td>300</td><td>Max Rupplin</td></tr>
                <tr><td>encryption_default</td><td>DH-2048</td><td>Max Rupplin</td></tr>
                <tr><td>max_file_size_mb</td><td>25</td><td>Max Rupplin</td></tr>
                <tr><td>max_voice_duration_sec</td><td>120</td><td>Max Rupplin</td></tr>
                <tr><td>ethics_statement</td><td><em>We conceal God but do not work for Her.</em></td><td>Max Rupplin</td></tr>
                <tr><td>brand</td><td>Communicator™</td><td>Max Rupplin</td></tr>
            </tbody>
        </table>
        </div>
    </div>
</section>

<section class="section">
    <div class="section-inner">
        <h2>Revise Setting (Admin Required)</h2>
        <form method="POST" action="settings.jsp" style="max-width:600px;">
            <div class="form-group">
                <label>Setting Key</label>
                <select name="setting_key">
                    <option value="session_timeout_hours">session_timeout_hours</option>
                    <option value="max_federation_servers">max_federation_servers</option>
                    <option value="concealment_3_threshold">concealment_3_threshold</option>
                    <option value="gold_cert_threshold">gold_cert_threshold</option>
                    <option value="encryption_default">encryption_default</option>
                    <option value="max_file_size_mb">max_file_size_mb</option>
                    <option value="max_voice_duration_sec">max_voice_duration_sec</option>
                    <option value="ethics_statement">ethics_statement</option>
                    <option value="brand">brand</option>
                </select>
            </div>
            <div class="form-group"><label>New Value</label><input type="text" name="setting_value" required/></div>
            <div class="form-group"><label>Admin Password</label><input type="password" name="admin_password" required/></div>
            <button type="submit" class="btn btn-primary">Update Setting</button>
        </form>
    </div>
</section>

<section class="section">
    <div class="section-inner">
        <h2>XML Configuration Location</h2>
        <p style="color:var(--text-muted);">Settings are also defined in the XML configuration file:</p>
        <code>modules/chat/configuration/chat-config.xml</code>
        <p style="margin-top:0.5rem;color:var(--text-muted);font-size:0.85rem;">Changes to the XML file require a module restart. Database settings override XML values at runtime.</p>
    </div>
</section>

<footer class="footer">
    <span>Communicator™ — Settings — MEARVK LLC — NitroWebExpress™ 2026</span>
</footer>
</body>
</html>
