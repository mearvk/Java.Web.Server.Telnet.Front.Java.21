<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.net.*, java.io.*" %>
<%
    String statusData = "";
    try (Socket s = new Socket()) {
        s.connect(new InetSocketAddress("127.0.0.1", 49230), 5000);
        s.setSoTimeout(5000);
        PrintWriter pw = new PrintWriter(s.getOutputStream(), true);
        BufferedReader br = new BufferedReader(new InputStreamReader(s.getInputStream()));
        // Read banner
        String line; while ((line = br.readLine()) != null) { if (line.startsWith("Commands:")) break; }
        pw.println("STATUS");
        statusData = br.readLine();
        pw.println("QUIT");
    } catch (Exception e) { statusData = "ERROR|Backend offline: " + e.getMessage(); }
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
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>Status — Communicator™</title>
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
        <li><a href="admin.jsp">Admin</a></li>
        <li><a href="status.jsp" class="active">Status</a></li>
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
        <span class="hero-tag">System Status</span>
        <h1>Status</h1>
        <p>Backend connectivity, encryption status, and protocol reference.</p>
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
        <h2>Backend Status</h2>
        <div class="table-wrap">
        <table>
            <thead><tr><th>Field</th><th>Value</th></tr></thead>
            <tbody>
<%
    if (statusData != null && !statusData.startsWith("ERROR")) {
        String[] parts = statusData.split("\\|");
        for (String p : parts) {
            if (p.contains("=")) {
                String[] kv = p.split("=", 2);
%>
                <tr><td><%= kv[0] %></td><td><code><%= kv[1] %></code></td></tr>
<%          } else if (!p.isEmpty()) { %>
                <tr><td>Status</td><td><code><%= p %></code></td></tr>
<%          }
        }
    } else { %>
                <tr><td>Error</td><td><code><%= statusData %></code></td></tr>
<%  } %>
            </tbody>
        </table>
        </div>
    </div>
</section>

<section class="section">
    <div class="section-inner">
        <h2>Protocol Reference (Port 49230)</h2>
        <div class="table-wrap">
        <table>
            <thead><tr><th>Command</th><th>Description</th></tr></thead>
            <tbody>
                <tr><td><code>REGISTER|user|pass|email</code></td><td>Create a new account</td></tr>
                <tr><td><code>LOGIN|user|pass</code></td><td>Authenticate</td></tr>
                <tr><td><code>ADMIN|password</code></td><td>Enable admin mode</td></tr>
                <tr><td><code>MSG|user|text</code></td><td>Send direct message (encrypted user↔user)</td></tr>
                <tr><td><code>BROADCAST|text</code></td><td>Send to all connected users</td></tr>
                <tr><td><code>LIST</code></td><td>List online users with geo info</td></tr>
                <tr><td><code>HISTORY</code></td><td>Show last 30 messages</td></tr>
                <tr><td><code>ENCRYPT|DH</code></td><td>Initiate DH-2048 key exchange</td></tr>
                <tr><td><code>ENCRYPT|RSA</code></td><td>Initiate RSA-2048 key exchange</td></tr>
                <tr><td><code>ENCRYPT_ACCEPT|pubkey</code></td><td>Complete encryption handshake</td></tr>
                <tr><td><code>ENCRYPT_OFF</code></td><td>Disable encryption</td></tr>
                <tr><td><code>FILE|user|name|size|b64</code></td><td>Send file to user (base64-encoded)</td></tr>
                <tr><td><code>VOICE|user|ms|b64</code></td><td>Send voice note (base64 audio)</td></tr>
                <tr><td><code>FEDERATE|host[:port]</code></td><td>Connect to remote Chat server</td></tr>
                <tr><td><code>FEDERATION_STATUS</code></td><td>View federation stats and rank</td></tr>
                <tr><td><code>CHANGE_USERNAME|new</code></td><td>Change your username</td></tr>
                <tr><td><code>DELETE_ACCOUNT</code></td><td>Mark account for deletion</td></tr>
                <tr><td><code>QUIT</code></td><td>Disconnect</td></tr>
            </tbody>
        </table>
        </div>
    </div>
</section>

<footer class="footer">
    <span>Communicator™ — Status — MEARVK LLC — NitroWebExpress™ 2026</span>
</footer>
</body>
</html>
