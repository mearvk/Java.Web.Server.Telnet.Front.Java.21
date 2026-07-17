<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.net.*, java.io.*" %>
<%
    String statusData = "";
    int chancellorsOnline = 0;
    try (Socket s = new Socket()) {
        s.connect(new InetSocketAddress("127.0.0.1", 49231), 3000);
        s.setSoTimeout(3000);
        PrintWriter pw = new PrintWriter(s.getOutputStream(), true);
        BufferedReader br = new BufferedReader(new InputStreamReader(s.getInputStream()));
        String line; while ((line = br.readLine()) != null) { if (line.startsWith("Commands:")) break; }
        pw.println("CHANCELLOR_STATUS");
        String chanStatus = br.readLine();
        if (chanStatus != null && chanStatus.contains("online_within_year=")) {
            String[] parts = chanStatus.split("\\|");
            for (String p : parts) {
                if (p.startsWith("online_now=")) chancellorsOnline = Integer.parseInt(p.split("=")[1]);
            }
        }
        pw.println("STATUS");
        statusData = br.readLine();
        pw.println("QUIT");
    } catch (Exception e) { statusData = "Backend offline"; }
    // Determine chancellor indicator squares (max 10 shown)
    int indicatorCount = Math.min(chancellorsOnline, 10);
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>UNCW™ — Wilmington at the Coast — NitroWebExpress™</title>
    <link rel="stylesheet" href="css/style.css"/>
    <script src="js/scroll-preserve.js"></script>
    <script src="js/audio-player.js"></script>
</head>
<body>
<nav class="nav"><div class="nav-inner">
    <span class="nav-brand">UNCW™ 🌊</span>
    <ul class="nav-links">
        <li><a href="index.jsp" class="active">Home</a></li>
        <li><a href="profile.jsp">Profile</a></li>
        <li><a href="messages.jsp">Messages</a></li>
        <li><a href="files.jsp">Files</a></li>
        <li><a href="community.jsp">Community</a></li>
        <li><a href="status.jsp">Status</a></li>
    </ul>
    <div class="nav-actions">
        <span style="font-size:0.7rem;color:var(--text-muted);margin-right:0.5rem;">Chancellors:</span>
        <% for (int i = 0; i < 10; i++) { %>
            <span class="chancellor-indicator <%= (i < indicatorCount) ? "active" : "inactive" %>"></span>
        <% } %>
        <a href="profile.jsp" class="nav-cta" style="margin-left:0.75rem;">Login →</a>
    </div>
</div></nav>

<section class="hero">
    <div class="hero-inner">
        <span class="hero-tag">Wilmington at the Coast of NC — Computer Science & Colleges</span>
        <h1>UNCW™</h1>
        <p>University of North Carolina Wilmington — Computer Science Club & College Community. Universal, fun. SeaCoast colors. File sharing, messaging, audio playback, chancellor notes. Go Seahawks! 🌊</p>
    </div>
</section>

<!-- CD1 Connector Button -->
<div style="display:flex;justify-content:center;align-items:center;width:100%;padding:2rem 0;">
    <button id="cd1-btn" type="button" aria-pressed="false" style="all:unset;display:block;margin:0 auto;cursor:pointer;padding:0;border:none;background:transparent;transition:transform 0.3s cubic-bezier(0.42,-1.84,0.42,1.84),filter 0.3s ease;">
        <img src="images/black.button.png" alt="Connector" style="display:block;width:80px;height:80px;border-radius:50%;background:transparent;filter:hue-rotate(160deg) saturate(1.3);"/>
    </button>
</div>
<div id="cd1-overlay" style="display:none;position:fixed;inset:0;z-index:299;background:transparent;"></div>
<div id="cd1-dialog" style="display:none;position:fixed;top:50%;left:50%;transform:translate(-50%,-50%);z-index:300;background:#0f2426;border:1px solid #1e4a4d;border-radius:12px;padding:1.25rem;width:540px;max-width:90vw;box-shadow:0 8px 32px rgba(0,0,0,0.6);">
    <div style="font-size:0.9rem;font-weight:600;color:#CDA028;margin-bottom:0.75rem;">UNCW Connector &#8212; SeaCoast</div>
    <div style="display:flex;gap:0.5rem;margin-bottom:0.75rem;flex-wrap:wrap;align-items:center;">
        <select id="cd1-action" style="background:#153234;color:#e2f0f0;border:1px solid #1e4a4d;border-radius:8px;padding:0.45rem 2rem 0.45rem 0.75rem;font-size:0.8rem;cursor:pointer;appearance:none;">
            <option value="connect">Connect</option><option value="disconnect">Disconnect</option>
            <option value="status">Status</option><option value="chancellor">Chancellor Status</option>
        </select>
        <button onclick="cd1Send()" style="background:linear-gradient(135deg,#00727A,#CDA028);color:#fff;border:none;border-radius:8px;padding:0.45rem 1rem;font-size:0.8rem;font-weight:600;cursor:pointer;">Send</button>
        <button onclick="cd1Ok()" style="background:linear-gradient(135deg,#00727A,#CDA028);color:#fff;border:none;border-radius:8px;padding:0.45rem 1rem;font-size:0.8rem;font-weight:600;cursor:pointer;">OK</button>
    </div>
    <div style="display:flex;align-items:center;gap:0.5rem;margin-bottom:0.75rem;">
        <label style="display:flex;align-items:center;gap:0.4rem;color:#8fb8ba;font-size:0.75rem;cursor:pointer;">
            <input type="checkbox" id="cd1-direct-port" style="accent-color:#00727A;width:14px;height:14px;cursor:pointer;"/>
            Direct Port (bypass Strernary&#8482; 20000)
        </label>
        <span id="cd1-mode-badge" style="font-size:0.65rem;background:#153234;color:#00727A;padding:0.2rem 0.5rem;border-radius:4px;">STRERNARY</span>
    </div>
    <textarea id="cd1-textarea" placeholder="Connection idle..." spellcheck="false" style="width:100%;min-height:120px;background:#0a1a1c;color:#e2f0f0;border:1px solid #1e4a4d;border-radius:8px;padding:0.75rem;font-family:monospace;font-size:0.8rem;resize:vertical;"></textarea>
</div>
<script>window.CD1_MODULE_PORT = "49231";</script>
<script src="js/cd1-connector.js"></script>

<section class="section">
    <div class="section-inner">
        <h2>Colleges & Clubs</h2>
        <div class="table-wrap">
        <table>
            <thead><tr><th>College</th><th>Focus</th><th>Vibe</th></tr></thead>
            <tbody>
                <tr><td>Computer Science</td><td>CS Club, coding, AI, systems</td><td>🖥️ Build things</td></tr>
                <tr><td>Marine Biology</td><td>Ocean research, ecology</td><td>🐠 Explore the deep</td></tr>
                <tr><td>Education</td><td>Teaching, curriculum</td><td>📚 Shape minds</td></tr>
                <tr><td>Business (Cameron)</td><td>Finance, marketing, entrepreneurship</td><td>💼 Make moves</td></tr>
                <tr><td>Arts & Sciences</td><td>Liberal arts, research</td><td>🎨 Create & discover</td></tr>
                <tr><td>Health & Human Services</td><td>Nursing, public health</td><td>❤️ Help people</td></tr>
                <tr><td>Engineering</td><td>Electrical, mechanical, software</td><td>⚙️ Engineer solutions</td></tr>
            </tbody>
        </table>
        </div>
    </div>
</section>

<section class="section">
    <div class="section-inner">
        <h2>Features</h2>
        <div class="table-wrap">
        <table>
            <thead><tr><th>Feature</th><th>Details</th></tr></thead>
            <tbody>
                <tr><td>Messaging</td><td>Chancellor unlimited; Users 10 free/month to other users</td></tr>
                <tr><td>File Sharing</td><td>Up to 80MB, stored in DB or user folder (your choice)</td></tr>
                <tr><td>Audio Playback</td><td>mp3, wav, ogg, flac, aac, m4a, opus — plays in browser</td></tr>
                <tr><td>Chancellor Login</td><td>Current + past Chancellors (up to 2000). Status indicators in nav.</td></tr>
                <tr><td>National ID</td><td>Set on profile, confirmed by NWE servers. Visible on profile page.</td></tr>
                <tr><td>Profiles</td><td>View other users' profiles. Student IDs, colleges, verification status.</td></tr>
                <tr><td>Chancellor Notes</td><td>Chancellors can post notes visible to all users.</td></tr>
            </tbody>
        </table>
        </div>
    </div>
</section>

<section class="section">
    <div class="section-inner">
        <h2>Chancellor Status</h2>
        <p style="color:var(--text-muted);margin-bottom:1rem;">Half white/teal squares indicate chancellors who have been online within a year. Gold squares for currently online.</p>
        <div style="display:flex;gap:4px;flex-wrap:wrap;margin-bottom:1rem;">
            <% for (int i = 0; i < indicatorCount; i++) { %><span class="chancellor-indicator gold"></span><% } %>
            <% for (int i = indicatorCount; i < 10; i++) { %><span class="chancellor-indicator active"></span><% } %>
        </div>
        <p style="font-size:0.8rem;color:var(--text-muted);">Gold = currently online | Teal/White = active within year | Gray = inactive</p>
    </div>
</section>

<footer class="footer">
    <span>UNCW™ — Wilmington at the Coast — Go Seahawks! 🌊 — MEARVK LLC — NitroWebExpress™ 2026</span>
</footer>
</body>
</html>
