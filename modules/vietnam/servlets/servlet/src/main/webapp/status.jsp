<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.Properties, java.io.*, java.net.*" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>Status — Vietnam™</title>
    <link rel="stylesheet" href="css/style.css"/>
    <script src="js/scroll-preserve.js"></script>
    <script src="js/nwe-readme-viewer.js"></script>
</head>
<body>
<nav class="nav"><div class="nav-inner">
    <span class="nav-brand">Vietnam™</span>
    <ul class="nav-links">
        <li><a href="index.jsp">Overview</a></li>
        <li><a href="styles.jsp">Fighting Styles</a></li>
        <li><a href="languages.jsp">Languages</a></li>
        <li><a href="status.jsp" class="active">Status</a></li>
    </ul>
</div></nav>

<section class="hero" style="padding:4rem 2rem;">
    <div class="hero-inner">
        <span class="hero-tag">Health Check</span>
        <h1>Status</h1>
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
    <div style="font-size:0.9rem;font-weight:600;color:#e8e0d6;margin-bottom:0.75rem;">CD1 Connector &#8212; Port 49215</div>
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
<script>window.CD1_MODULE_PORT = "49215";</script>
<script src="js/cd1-connector.js"></script>


<section class="section">
    <div class="section-inner">
<%
    String dbStatus = "Offline", dbVersion = "", stylesCount = "?", langCount = "?";
    boolean tcpAlive = false;

    // DB check
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        try (Connection conn = DriverManager.getConnection(
                "jdbc:mysql://127.0.0.1:3306/nwe_vietnam", "root", "")) {
            dbStatus = "Online";
            dbVersion = conn.getMetaData().getDatabaseProductName() + " " + conn.getMetaData().getDatabaseProductVersion();
            try (ResultSet rs = conn.createStatement().executeQuery("SELECT COUNT(*) FROM fighting_styles")) {
                if (rs.next()) stylesCount = String.valueOf(rs.getInt(1));
            }
            try (ResultSet rs = conn.createStatement().executeQuery("SELECT COUNT(*) FROM languages")) {
                if (rs.next()) langCount = String.valueOf(rs.getInt(1));
            }
        }
    } catch (Exception e) { dbStatus = "Error"; }

    // TCP port 49215 check
    try (Socket s = new Socket()) {
        s.connect(new InetSocketAddress("localhost", 49215), 2000);
        tcpAlive = true;
    } catch (Exception ignored) {}
%>
        <div class="table-wrap">
            <table>
                <thead><tr><th>Service</th><th>Status</th><th>Details</th></tr></thead>
                <tbody>
                    <tr><td>MySQL (nwe_vietnam)</td><td style="color:<%= "Online".equals(dbStatus) ? "#22c55e" : "#ef4444" %>;"><%= dbStatus %></td><td><%= dbVersion %></td></tr>
                    <tr><td>Fighting Styles</td><td><%= stylesCount %> records</td><td>Vovinam, Viet Vo Dao, Binh Dinh, Cuong Nhu, Nhat Nam</td></tr>
                    <tr><td>Languages</td><td><%= langCount %> records</td><td>Vietnamese, Tay, Muong, Khmer Krom, Cham, Hmong</td></tr>
                    <tr><td>TCP Server (49215)</td><td style="color:<%= tcpAlive ? "#22c55e" : "#ef4444" %>;"><%= tcpAlive ? "Online" : "Offline" %></td><td>NIO masquerade routed</td></tr>
                    <tr><td>AI Inference (port 20000)</td><td>Strernary™</td><td>DJL/DistilBERT search &amp; training</td></tr>
                    <tr><td>Servlet Container</td><td style="color:#22c55e;">Online</td><td><%= application.getServerInfo() %></td></tr>
                    <tr><td>JVM</td><td style="color:#22c55e;">Online</td><td><%= System.getProperty("java.version") %></td></tr>
                </tbody>
            </table>
        </div>
    </div>
</section>

<footer class="footer"><div><span>&#169; 2026 MEARVK LLC. All rights reserved. Vietnam™ — Light Brown.</span></div></footer>
</body>
</html>
