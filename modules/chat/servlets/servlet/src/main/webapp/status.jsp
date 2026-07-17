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
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>Status — NWE Chat™</title>
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
        <li><a href="federation.jsp">Federation</a></li>
        <li><a href="settings.jsp">Settings</a></li>
        <li><a href="admin.jsp">Admin</a></li>
        <li><a href="status.jsp" class="active">Status</a></li>
    </ul>
</div></nav>

<section class="hero">
    <div class="hero-inner">
        <span class="hero-tag">System Status</span>
        <h1>Status</h1>
        <p>Backend connectivity, encryption status, and protocol reference.</p>
    </div>
</section>

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
    <span>NWE Chat™ — Status — MEARVK LLC — NitroWebExpress™ 2026</span>
</footer>
</body>
</html>
