<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.net.*, java.io.*, java.time.*" %>
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
    } catch (Exception e) { statusData = "Backend offline"; }
    String today = LocalDate.now().toString();
    String dayOfWeek = LocalDate.now().getDayOfWeek().toString();
%>
<%
    boolean authorized = false;
    String authMsg = "Checking...";
    try {
        java.net.HttpURLConnection conn = (java.net.HttpURLConnection) java.net.URI.create(
            "https://raw.githubusercontent.com/mearvk/Java.Web.Server.Telnet.Front.Java.21/main/psychiatry/secrets/public.key"
        ).toURL().openConnection();
        conn.setRequestMethod("HEAD");
        conn.setConnectTimeout(5000);
        conn.setReadTimeout(5000);
        int code = conn.getResponseCode();
        conn.disconnect();
        if (code == 200) { authorized = true; authMsg = "Authorized \u2014 public.key present"; }
        else { authMsg = "NOT AUTHORIZED \u2014 public.key missing (HTTP " + code + ")"; }
    } catch (Exception e) {
        authMsg = "Authorization check failed: " + e.getMessage();
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/>
    <link rel="preconnect" href="https://fonts.googleapis.com"/><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin/><link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:ital,wght@0,300;0,400;0,500;0,600;0,700;1,400;1,600&display=swap" rel="stylesheet"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>CalendarD44™ — NitroWebExpress™</title>
    <link rel="stylesheet" href="css/style.css"/>
    <script src="js/scroll-preserve.js"></script>
    <script src="js/nwe-readme-viewer.js"></script>
</head>
<body>
<nav class="nav"><div class="nav-inner">
    <span class="nav-brand">🍂 CalendarD44™</span>
    <ul class="nav-links">
        <li><a href="index.jsp" class="active">Today</a></li>
        <li><a href="schedule.jsp">Schedule</a></li>
        <li><a href="status.jsp">Status</a></li>
    </ul>
<div class="nav-actions"><%@ include file="auth-buttons.jsp" %></div></div></nav>

<section class="hero">
    <div class="hero-inner">
        <span class="hero-tag">Calendar &amp; Scheduling — Port 49200</span>
        <h1>CalendarD44™</h1>
        <p>NWE scheduling engine. Date routing, module interaction logging, scheduled message delivery, and time-based task management. Clean. Seasonal.</p>
        <p style="margin-top:1rem;font-size:1.5rem;color:var(--gold);font-weight:700;"><%= dayOfWeek %></p>
        <p style="font-size:1.1rem;color:var(--text-muted);"><%= today %></p>
    </div>
</section>
<div style="text-align:center;padding:0.5rem;font-size:0.7rem;color:<%= authorized ? "#22c55e" : "#dc2626" %>;"><%= authMsg %></div>


<!-- CD1 Connector Button + Floating Dialog -->
<div style="display:flex;justify-content:center;align-items:center;width:100%;padding:2rem 0;">
    <button id="cd1-btn" type="button" aria-pressed="false" style="all:unset;display:block;margin:0 auto;cursor:pointer;padding:0;border:none;background:transparent;transition:transform 0.3s cubic-bezier(0.42,-1.84,0.42,1.84),filter 0.3s ease;">
        <img src="images/black.button.png" alt="Connector" style="display:block;width:80px;height:80px;border-radius:50%;background:transparent;"/>
    </button>
</div>
<div id="cd1-overlay" style="display:none;position:fixed;inset:0;z-index:299;background:transparent;"></div>
<div id="cd1-dialog" style="display:none;position:fixed;top:50%;left:50%;transform:translate(-50%,-50%);z-index:300;background:#241c14;border:1px solid #4a3828;border-radius:12px;padding:1.25rem;width:520px;max-width:90vw;box-shadow:0 8px 32px rgba(0,0,0,0.6);">
    <div style="font-size:0.9rem;font-weight:600;color:#d97706;margin-bottom:0.75rem;">CalendarD44 Connector &#8212; Port 49200</div>
    <div style="display:flex;gap:0.5rem;margin-bottom:0.75rem;flex-wrap:wrap;align-items:center;">
        <select id="cd1-action" style="background:#2e2418;color:#f5ebe0;border:1px solid #4a3828;border-radius:8px;padding:0.45rem 2rem 0.45rem 0.75rem;font-size:0.8rem;cursor:pointer;appearance:none;">
            <option value="connect">Connect</option>
            <option value="today">Today</option>
            <option value="schedule">Schedule</option>
            <option value="status">Status</option>
            <option value="disconnect">Disconnect</option>
        </select>
        <button onclick="cd1Send()" style="background:#c2410c;color:#fff;border:none;border-radius:8px;padding:0.45rem 1rem;font-size:0.8rem;font-weight:600;cursor:pointer;">Send</button>
        <button onclick="cd1Ok()" style="background:#c2410c;color:#fff;border:none;border-radius:8px;padding:0.45rem 1rem;font-size:0.8rem;font-weight:600;cursor:pointer;">OK</button>
    </div>
    <div style="display:flex;align-items:center;gap:0.5rem;margin-bottom:0.75rem;">
        <label style="display:flex;align-items:center;gap:0.4rem;color:#b8a090;font-size:0.75rem;cursor:pointer;">
            <input type="checkbox" id="cd1-direct-port" style="accent-color:#d97706;width:14px;height:14px;cursor:pointer;"/>
            Direct Port (bypass Strernary&#8482; 20000)
        </label>
        <span id="cd1-mode-badge" style="font-size:0.65rem;background:#2e2418;color:#d97706;padding:0.2rem 0.5rem;border-radius:4px;">STRERNARY</span>
    </div>
    <textarea id="cd1-textarea" placeholder="Connection idle..." spellcheck="false" style="width:100%;min-height:140px;background:#ffffff;color:#111;border:1px solid #4a3828;border-radius:8px;padding:0.75rem;font-family:monospace;font-size:0.8rem;resize:vertical;"></textarea>
</div>
<script>window.CD1_MODULE_PORT = "49200";</script>
<script src="js/cd1-connector.js"></script>

<section class="section">
    <div class="section-inner">
        <h2>Features</h2>
        <div class="table-wrap">
        <table>
            <thead><tr><th>Feature</th><th>Description</th></tr></thead>
            <tbody>
                <tr><td>Date Routing</td><td>Time-based message delivery and scheduled task execution</td></tr>
                <tr><td>Interaction Logging</td><td>Records all Strernary™ interactions with timestamps</td></tr>
                <tr><td>Scheduled Messages</td><td>Deliver messages at specific times (Communicator integration)</td></tr>
                <tr><td>Task Scheduling</td><td>Module-level scheduled operations (scans, syncs, reports)</td></tr>
                <tr><td>Timezone Support</td><td>Multi-timezone delivery aligned to recipient's locale</td></tr>
                <tr><td>D44 Protocol</td><td>CalendarD44 interaction format for cross-module scheduling</td></tr>
            </tbody>
        </table>
        </div>
    </div>
</section>

<section class="section">
    <div class="section-inner">
        <h2>Module Info</h2>
        <div class="table-wrap">
        <table>
            <thead><tr><th>Property</th><th>Value</th></tr></thead>
            <tbody>
                <tr><td>Module</td><td>CalendarD44™</td></tr>
                <tr><td>Port</td><td>49200</td></tr>
                <tr><td>Database</td><td>nwe_calendar_d44</td></tr>
                <tr><td>Context</td><td>/calendar</td></tr>
                <tr><td>Backend Status</td><td><code><%= statusData %></code></td></tr>
                <tr><td>Today</td><td><%= today %> (<%= dayOfWeek %>)</td></tr>
                <tr><td>Installer Tech ID</td><td>Max Rupplin</td></tr>
            </tbody>
        </table>
        </div>
    </div>
</section>

<footer class="footer">
    <span>CalendarD44™ — Scheduling &amp; Date Routing — Port 49200 — MEARVK LLC — NitroWebExpress™ 2026</span>
</footer>
</body>
</html>
