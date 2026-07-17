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
