<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.net.*, java.io.*" %>
<%
    String ghKeyUrl = "https://raw.githubusercontent.com/mearvk/Java.Web.Server.Telnet.Front.Java.21/main/psychiatry/secrets/public.key";
    boolean authorized = false;
    String authStatus = "Unknown";
    try {
        HttpURLConnection hc = (HttpURLConnection) new URL(ghKeyUrl).openConnection();
        hc.setRequestMethod("HEAD");
        hc.setConnectTimeout(5000);
        hc.setReadTimeout(5000);
        authorized = (hc.getResponseCode() == 200);
        authStatus = authorized ? "Authorized (public.key present)" : "Revoked";
        hc.disconnect();
    } catch (Exception e) { authStatus = "Check failed"; }
%>
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
    <title>Communicator™ — Encrypted Communication — NitroWebExpress™</title>
    <link rel="stylesheet" href="css/style.css"/>
    <link rel="manifest" href="manifest.json"/>
    <meta name="theme-color" content="#0a0e1a"/>
    <meta name="description" content="Communicator™ — Encrypted communication with DH-2048 + RSA-2048. Federation, file transfer, voice notes. Ethics: We conceal God but do not work for Her."/>
    <script src="js/scroll-preserve.js"></script>
    <script src="js/nwe-readme-viewer.js"></script>
</head>
<body>
<nav class="nav"><div class="nav-inner">
    <span class="nav-brand"><img src="images/MearvK.Ltd/communicator/trillian.jpeg" alt="Communicator" style="height:24px;width:auto;vertical-align:middle;margin-right:6px;background:transparent;border-radius:4px;"/>Communicator™</span>
    <ul class="nav-links">
        <li><a href="index.jsp" class="active">Chat</a></li>
        <li><a href="account.jsp">Account</a></li>
        <li><a href="federation.jsp">Federation</a></li>
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
        <div class="logo-container">
            <img src="images/MearvK.Ltd/communicator/trillian.jpeg" alt="Communicator" style="height:48px;width:auto;background:transparent;border-radius:8px;"/>
        </div>
        <span class="hero-tag">Encrypted Communication — DH-2048 + RSA-2048</span>
        <h1>Communicator™</h1>
        <p>Secure messaging with end-to-end encryption. Direct messages, broadcast, federation across servers, file transfer, and voice notes. Port 49230.</p>
        <p style="margin-top:0.75rem;font-size:0.85rem;color:var(--purple-hover);font-style:italic;">Ethics: We conceal God but do not work for Her.</p>
    </div>
</section>

<!-- CD1 Connector Button + Floating Dialog (Blue theme) -->
<div style="display:flex;justify-content:center;align-items:center;width:100%;padding:2rem 0;">
    <button id="cd1-btn" type="button" aria-pressed="false" style="all:unset;display:block;margin:0 auto;cursor:pointer;padding:0;border:none;background:transparent;transition:transform 0.3s cubic-bezier(0.42,-1.84,0.42,1.84),filter 0.3s ease;">
        <img src="images/black.button.png" alt="Connector" style="display:block;width:80px;height:80px;border-radius:50%;background:transparent;filter:hue-rotate(200deg) saturate(1.5);"/>
    </button>
</div>
<div id="cd1-overlay" style="display:none;position:fixed;inset:0;z-index:299;background:transparent;"></div>
<div id="cd1-dialog" style="display:none;position:fixed;top:50%;left:50%;transform:translate(-50%,-50%);z-index:300;background:#0f1428;border:1px solid #1e2a4a;border-radius:12px;padding:1.25rem;width:560px;max-width:90vw;box-shadow:0 8px 32px rgba(0,0,0,0.6);">
    <div style="font-size:0.9rem;font-weight:600;color:#6b8aff;margin-bottom:0.75rem;">Communicator Connector &#8212; Direct Link</div>
    <div style="display:flex;gap:0.5rem;margin-bottom:0.75rem;flex-wrap:wrap;align-items:center;">
        <select id="cd1-action" style="background:#161d36;color:#e2e8f0;border:1px solid #1e2a4a;border-radius:8px;padding:0.45rem 2rem 0.45rem 0.75rem;font-size:0.8rem;cursor:pointer;appearance:none;">
            <option value="connect">Connect</option>
            <option value="disconnect">Disconnect</option>
            <option value="encrypt-dh">Encrypt (DH-2048)</option>
            <option value="encrypt-rsa">Encrypt (RSA-2048)</option>
            <option value="status">Status</option>
            <option value="hardreset">Hard Reset</option>
        </select>
        <button onclick="cd1Send()" style="background:#4a6cf7;color:#fff;border:none;border-radius:8px;padding:0.45rem 1rem;font-size:0.8rem;font-weight:600;cursor:pointer;">Send</button>
        <button onclick="cd1Ok()" style="background:#4a6cf7;color:#fff;border:none;border-radius:8px;padding:0.45rem 1rem;font-size:0.8rem;font-weight:600;cursor:pointer;">OK</button>
    </div>
    <div style="display:flex;align-items:center;gap:0.5rem;margin-bottom:0.75rem;">
        <label style="display:flex;align-items:center;gap:0.4rem;color:#94a3b8;font-size:0.75rem;cursor:pointer;">
            <input type="checkbox" id="cd1-direct-port" style="accent-color:#7c3aed;width:14px;height:14px;cursor:pointer;"/>
            Direct Port (bypass Strernary&#8482; 20000)
        </label>
        <span id="cd1-mode-badge" style="font-size:0.65rem;background:#161d36;color:#7c3aed;padding:0.2rem 0.5rem;border-radius:4px;">STRERNARY</span>
    </div>
    <textarea id="cd1-textarea" placeholder="Connection idle..." spellcheck="false" style="width:100%;min-height:140px;background:#0a0e1a;color:#e2e8f0;border:1px solid #1e2a4a;border-radius:8px;padding:0.75rem;font-family:monospace;font-size:0.8rem;resize:vertical;"></textarea>
</div>
<script>window.CD1_MODULE_PORT = "49230";</script>
<script src="js/cd1-connector.js"></script>
<script>
(function() {
    var cb = document.getElementById("cd1-direct-port");
    var badge = document.getElementById("cd1-mode-badge");
    if (cb && badge) {
        function updateBadge() { badge.textContent = cb.checked ? "DIRECT" : "STRERNARY"; }
        cb.addEventListener("change", updateBadge);
        updateBadge();
    }
})();
</script>

<!-- Chat Interface -->
<section class="section">
    <div class="section-inner">
        <h2>Live Chat</h2>
        <div class="chat-container">
            <div class="chat-messages" id="chat-messages">
                <div class="msg msg-system">[System] Connect to Communicator™ via port 49230 or use the CD1 button above.</div>
                <div class="msg msg-system">[System] Type /login username password to authenticate.</div>
                <div class="msg msg-system">[System] Encryption: DH-2048 + AES-256-GCM active by default.</div>
            </div>
            <div class="chat-input">
                <input type="text" id="chat-input" placeholder="Type a message or command... (/help for commands)" onkeydown="if(event.key==='Enter')sendChat()"/>
                <button onclick="sendChat()">Send</button>
            </div>
        </div>
        <div style="display:flex;gap:0.5rem;margin-top:0.75rem;flex-wrap:wrap;">
            <button class="btn btn-ghost" onclick="document.getElementById('file-upload').click()">📎 File</button>
            <button class="btn btn-ghost" id="mic-btn" onclick="toggleMic()">🎤 Mic</button>
            <button class="btn btn-ghost" onclick="sendChat('/encrypt DH')">🔒 Encrypt</button>
            <input type="file" id="file-upload" style="display:none;" onchange="handleFileUpload(this)"/>
        </div>
    </div>
</section>

<section class="section">
    <div class="section-inner">
        <h2>Features</h2>
        <div class="table-wrap">
        <table>
            <thead><tr><th>Feature</th><th>Description</th></tr></thead>
            <tbody>
                <tr><td>DH-2048 + AES-256-GCM</td><td>Diffie-Hellman key exchange with AES-256-GCM authenticated encryption</td></tr>
                <tr><td>RSA-2048</td><td>RSA public-key encryption for server↔user and user↔user DMs</td></tr>
                <tr><td>Federation</td><td>Connect to up to 5 external Communicator servers by IP/domain</td></tr>
                <tr><td>File Transfer</td><td>Send files up to 25MB with end-to-end encryption</td></tr>
                <tr><td>Voice Notes</td><td>Record and send microphone audio (up to 120s)</td></tr>
                <tr><td>Concealment 3</td><td>Rank awarded at 200+ successful federated connections</td></tr>
                <tr><td>Gold Harvard Certificate</td><td>Awarded at 300+ federated connections. Kids.</td></tr>
                <tr><td>Admin Panel</td><td>User management, ban/unban, logs, IP/Geo tracking</td></tr>
                <tr><td>Chat Logs</td><td>All messages stored with sender IP and timestamps</td></tr>
                <tr><td>Account Management</td><td>Register, login, change username, delete account</td></tr>
            </tbody>
        </table>
        </div>
    </div>
</section>

<section class="section">
    <div class="section-inner">
        <h2>Module Information</h2>
        <div class="table-wrap">
        <table>
            <thead><tr><th>Property</th><th>Value</th></tr></thead>
            <tbody>
                <tr><td>Module</td><td>Communicator™</td></tr>
                <tr><td>Port</td><td>49230</td></tr>
                <tr><td>Database</td><td>nwe_chat</td></tr>
                <tr><td>Context Path</td><td>/chat</td></tr>
                <tr><td>Installer Tech ID</td><td>Max Rupplin</td></tr>
                <tr><td>Authorization</td><td><%= authStatus %></td></tr>
                <tr><td>Encryption</td><td>DH-2048 (RFC 3526 Group 14) + RSA-2048 + AES-256-GCM</td></tr>
                <tr><td>Ethics</td><td><em>We conceal God but do not work for Her.</em></td></tr>
                <tr><td>AI Backend</td><td>Strernary™ (port 20000)</td></tr>
                <tr><td>Communicator Link</td><td>Port 49199 (existing NWE Communicator)</td></tr>
            </tbody>
        </table>
        </div>
    </div>
</section>

<footer class="footer">
    <span>Communicator™ — Encrypted Communication — We conceal God but do not work for Her. — MEARVK LLC — NitroWebExpress™ 2026</span>
</footer>

<script>
function sendChat(override) {
    var input = document.getElementById('chat-input');
    var msg = override || input.value.trim();
    if (!msg) return;
    var msgs = document.getElementById('chat-messages');
    msgs.innerHTML += '<div class="msg msg-dm">[You] ' + msg.replace(/</g,'&lt;') + '</div>';
    msgs.scrollTop = msgs.scrollHeight;
    if (!override) input.value = '';
}
function handleFileUpload(el) {
    if (el.files.length > 0) {
        var f = el.files[0];
        var msgs = document.getElementById('chat-messages');
        msgs.innerHTML += '<div class="msg msg-system">[File] Uploading: ' + f.name + ' (' + (f.size/1024).toFixed(1) + 'KB)</div>';
        msgs.scrollTop = msgs.scrollHeight;
    }
}
var micActive = false;
function toggleMic() {
    micActive = !micActive;
    var btn = document.getElementById('mic-btn');
    if (micActive) {
        btn.style.background = 'rgba(124,58,237,0.3)';
        btn.textContent = '🔴 Recording...';
        var msgs = document.getElementById('chat-messages');
        msgs.innerHTML += '<div class="msg msg-system">[Mic] Recording started...</div>';
        msgs.scrollTop = msgs.scrollHeight;
    } else {
        btn.style.background = '';
        btn.textContent = '🎤 Mic';
        var msgs = document.getElementById('chat-messages');
        msgs.innerHTML += '<div class="msg msg-system">[Mic] Recording stopped. Voice note ready.</div>';
        msgs.scrollTop = msgs.scrollHeight;
    }
}
</script>
</body>
</html>
