<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.net.*, java.io.*" %>
<%
    String statusData = "";
    try (Socket s = new Socket()) {
        s.connect(new InetSocketAddress("127.0.0.1", 49200), 3000);
        s.setSoTimeout(3000);
        BufferedReader br = new BufferedReader(new InputStreamReader(s.getInputStream()));
        PrintWriter pw = new PrintWriter(s.getOutputStream(), true);
        br.readLine();
        pw.println("STATUS");
        statusData = br.readLine();
        pw.println("QUIT");
    } catch (Exception e) { statusData = "Backend offline: " + e.getMessage(); }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>Schedule — CalendarD44™</title>
    <link rel="stylesheet" href="css/style.css"/>
    <script src="js/scroll-preserve.js"></script>
    <script src="js/nwe-readme-viewer.js"></script>
</head>
<body>
<nav class="nav"><div class="nav-inner">
    <span class="nav-brand">🍂 CalendarD44™</span>
    <ul class="nav-links">
        <li><a href="index.jsp">Today</a></li>
        <li><a href="schedule.jsp" class="active">Schedule</a></li>
        <li><a href="status.jsp">Status</a></li>
    </ul>
</div></nav>
<section class="hero"><div class="hero-inner">
    <span class="hero-tag">Scheduled Tasks &amp; Messages</span>
    <h1>Schedule</h1>
    <p>View and manage scheduled tasks, message deliveries, and recurring operations.</p>
</div></section>

<!-- CD1 Connector Button + Floating Dialog -->
<div style="display:flex;justify-content:center;align-items:center;width:100%;padding:2rem 0;">
    <button id="cd1-btn" type="button" aria-pressed="false" style="all:unset;display:block;margin:0 auto;cursor:pointer;padding:0;border:none;background:transparent;transition:transform 0.3s cubic-bezier(0.42,-1.84,0.42,1.84),filter 0.3s ease;">
        <img src="images/black.button.png" alt="Connector" style="display:block;width:80px;height:80px;border-radius:50%;background:transparent;"/>
    </button>
</div>
<div id="cd1-overlay" style="display:none;position:fixed;inset:0;z-index:299;background:transparent;"></div>
<div id="cd1-dialog" style="display:none;position:fixed;top:50%;left:50%;transform:translate(-50%,-50%);z-index:300;background:#241c14;border:1px solid #4a3828;border-radius:12px;padding:1.25rem;width:520px;max-width:90vw;box-shadow:0 8px 32px rgba(0,0,0,0.6);"><div style="font-size:0.9rem;font-weight:600;color:#d97706;margin-bottom:0.75rem;">CalendarD44 Connector &#8212; Port 49200</div><div style="display:flex;gap:0.5rem;margin-bottom:0.75rem;flex-wrap:wrap;align-items:center;"><select id="cd1-action" style="background:#2e2418;color:#f5ebe0;border:1px solid #4a3828;border-radius:8px;padding:0.45rem 2rem 0.45rem 0.75rem;font-size:0.8rem;cursor:pointer;appearance:none;"><option value="connect">Connect</option><option value="schedule">Schedule</option><option value="status">Status</option><option value="disconnect">Disconnect</option></select><button onclick="cd1Send()" style="background:#c2410c;color:#fff;border:none;border-radius:8px;padding:0.45rem 1rem;font-size:0.8rem;font-weight:600;cursor:pointer;">Send</button><button onclick="cd1Ok()" style="background:#c2410c;color:#fff;border:none;border-radius:8px;padding:0.45rem 1rem;font-size:0.8rem;font-weight:600;cursor:pointer;">OK</button></div><label style="font-size:0.7rem;color:#b8a090;"><input type="checkbox" id="cd1-direct-port" style="accent-color:#d97706;"/> Direct Port</label><textarea id="cd1-textarea" placeholder="Idle..." style="width:100%;min-height:120px;background:#fff;color:#111;border:1px solid #4a3828;border-radius:8px;padding:0.75rem;font-family:monospace;font-size:0.8rem;margin-top:0.5rem;resize:vertical;"></textarea></div>
<script>window.CD1_MODULE_PORT="49200";</script>
<script src="js/cd1-connector.js"></script>

<section class="section"><div class="section-inner">
    <h2>Protocol Commands</h2>
    <div class="table-wrap"><table>
        <thead><tr><th>Command</th><th>Description</th></tr></thead>
        <tbody>
            <tr><td><code>SCHEDULE|time|target|message</code></td><td>Schedule a message delivery at a specific time</td></tr>
            <tr><td><code>LIST</code></td><td>List all pending scheduled tasks</td></tr>
            <tr><td><code>CANCEL|taskId</code></td><td>Cancel a scheduled task</td></tr>
            <tr><td><code>HISTORY</code></td><td>View completed deliveries</td></tr>
            <tr><td><code>TODAY</code></td><td>Show today's schedule</td></tr>
            <tr><td><code>STATUS</code></td><td>Server status</td></tr>
        </tbody>
    </table></div>
</div></section>
<footer class="footer"><span>CalendarD44™ — Schedule — MEARVK LLC — NitroWebExpress™ 2026</span></footer>
</body></html>
