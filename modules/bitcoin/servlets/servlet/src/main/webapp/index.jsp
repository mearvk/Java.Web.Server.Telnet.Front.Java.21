<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.net.*, java.io.*" %>
<%
    String statusData = "";
    try (Socket s = new Socket()) {
        s.connect(new InetSocketAddress("127.0.0.1", 6682), 3000);
        s.setSoTimeout(3000);
        BufferedReader br = new BufferedReader(new InputStreamReader(s.getInputStream()));
        PrintWriter pw = new PrintWriter(s.getOutputStream(), true);
        String banner = br.readLine();
        pw.println("STATUS");
        statusData = br.readLine();
        pw.println("QUIT");
    } catch (Exception e) { statusData = "Backend offline"; }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>Bitcoin™ — NitroWebExpress™</title>
    <link rel="stylesheet" href="css/style.css"/>
    <script src="js/scroll-preserve.js"></script>
    <script src="js/nwe-readme-viewer.js"></script>
</head>
<body>
<nav class="nav"><div class="nav-inner">
    <span class="nav-brand">₿ Bitcoin™</span>
    <ul class="nav-links">
        <li><a href="index.jsp" class="active">Overview</a></li>
        <li><a href="wallets.jsp">Wallets</a></li>
        <li><a href="transactions.jsp">Transactions</a></li>
        <li><a href="account.jsp">Account</a></li>
        <li><a href="profile.jsp">Profile</a></li>
        <li><a href="admin.jsp">Admin</a></li>
        <li><a href="status.jsp">Status</a></li>
    </ul>
    <div class="nav-actions">
        <a href="wallets.jsp" class="nav-cta">Wallets →</a>
    </div>
</div></nav>

<section class="hero">
    <div class="hero-inner">
        <span class="hero-tag">Cryptocurrency — Wallet & Transaction Server</span>
        <h1>₿ Bitcoin™</h1>
        <p>Bitcoin wallet management, transaction indexing, and trading interface. Local bitcoind integration, multi-timezone support, and Strernary™ AI-assisted market analysis. Port 6682.</p>
    </div>
</section>

<!-- CD1 Connector Button -->
<div style="display:flex;justify-content:center;align-items:center;width:100%;padding:2rem 0;">
    <button id="cd1-btn" type="button" aria-pressed="false" style="all:unset;display:block;margin:0 auto;cursor:pointer;padding:0;border:none;background:transparent;transition:transform 0.3s cubic-bezier(0.42,-1.84,0.42,1.84),filter 0.3s ease;">
        <img src="images/black.button.png" alt="Connector" style="display:block;width:80px;height:80px;border-radius:50%;background:transparent;"/>
    </button>
</div>
<div id="cd1-overlay" style="display:none;position:fixed;inset:0;z-index:299;background:transparent;"></div>
<div id="cd1-dialog" style="display:none;position:fixed;top:50%;left:50%;transform:translate(-50%,-50%);z-index:300;background:#211e16;border:1px solid #3d3528;border-radius:12px;padding:1.25rem;width:520px;max-width:90vw;box-shadow:0 8px 32px rgba(0,0,0,0.6);">
    <div style="font-size:0.9rem;font-weight:600;color:#f7931a;margin-bottom:0.75rem;">Bitcoin Connector &#8212; Port 6682</div>
    <div style="display:flex;gap:0.5rem;margin-bottom:0.75rem;flex-wrap:wrap;align-items:center;">
        <select id="cd1-action" style="background:#2a2518;color:#e8e0d6;border:1px solid #3d3528;border-radius:8px;padding:0.45rem 2rem 0.45rem 0.75rem;font-size:0.8rem;cursor:pointer;appearance:none;">
            <option value="connect">Connect</option>
            <option value="disconnect">Disconnect</option>
            <option value="balance">Check Balance</option>
            <option value="wallets">List Wallets</option>
            <option value="status">Status</option>
        </select>
        <button onclick="cd1Send()" style="background:#f7931a;color:#fff;border:none;border-radius:8px;padding:0.45rem 1rem;font-size:0.8rem;font-weight:600;cursor:pointer;">Send</button>
        <button onclick="cd1Ok()" style="background:#f7931a;color:#fff;border:none;border-radius:8px;padding:0.45rem 1rem;font-size:0.8rem;font-weight:600;cursor:pointer;">OK</button>
    </div>
    <div style="display:flex;align-items:center;gap:0.5rem;margin-bottom:0.75rem;">
        <label style="display:flex;align-items:center;gap:0.4rem;color:#9e9486;font-size:0.75rem;cursor:pointer;">
            <input type="checkbox" id="cd1-direct-port" style="accent-color:#f7931a;width:14px;height:14px;cursor:pointer;"/>
            Direct Port (bypass Strernary&#8482; 20000)
        </label>
        <span id="cd1-mode-badge" style="font-size:0.65rem;background:#2a2518;color:#f7931a;padding:0.2rem 0.5rem;border-radius:4px;">STRERNARY</span>
    </div>
    <textarea id="cd1-textarea" placeholder="Connection idle..." spellcheck="false" style="width:100%;min-height:140px;background:#1a1610;color:#e8e0d6;border:1px solid #3d3528;border-radius:8px;padding:0.75rem;font-family:monospace;font-size:0.8rem;resize:vertical;"></textarea>
</div>
<script>window.CD1_MODULE_PORT = "6682";</script>
<script src="js/cd1-connector.js"></script>

<section class="section">
    <div class="section-inner">
        <h2>Features</h2>
        <div class="table-wrap">
        <table>
            <thead><tr><th>Feature</th><th>Description</th></tr></thead>
            <tbody>
                <tr><td>Wallet Management</td><td>Browse, select, and manage wallets from /bitcoin/{24-30}/ directories</td></tr>
                <tr><td>Transaction Indexing</td><td>Scan and index wallet transactions with balance tracking</td></tr>
                <tr><td>Trading Interface</td><td>Buy/sell via bitcoind RPC. TraderModule integration.</td></tr>
                <tr><td>Multi-Timezone</td><td>NYC, LA, Tokyo, Dakar, Denver, Norfolk, Maldives, Reunion + more</td></tr>
                <tr><td>AI Market Analysis</td><td>Strernary™ inference for market signals on port 20000</td></tr>
                <tr><td>Message Ordering</td><td>MessageOrderer for sequenced blockchain communication</td></tr>
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
                <tr><td>Module</td><td>Bitcoin™ (BitcoinCompliant)</td></tr>
                <tr><td>Port</td><td>6682</td></tr>
                <tr><td>Backend Class</td><td>source.BitcoinCompliant</td></tr>
                <tr><td>Context Path</td><td>/bitcoin</td></tr>
                <tr><td>Installer Tech ID</td><td>Max Rupplin</td></tr>
                <tr><td>Backend Status</td><td><code><%= statusData %></code></td></tr>
                <tr><td>Wallet Directories</td><td>/bitcoin/24, /bitcoin/25, /bitcoin/26, /bitcoin/27, /bitcoin/28, /bitcoin/29, /bitcoin/30</td></tr>
                <tr><td>AI Backend</td><td>Strernary™ (port 20000)</td></tr>
            </tbody>
        </table>
        </div>
    </div>
</section>

<section class="section">
    <div class="section-inner">
        <h2>Timezone Coverage</h2>
        <div class="table-wrap">
        <table>
            <thead><tr><th>Region</th><th>Timezone</th><th>Class</th></tr></thead>
            <tbody>
                <tr><td>Americas — New York</td><td>America/New_York</td><td>BitcoinAmericaAndNewYorkDate</td></tr>
                <tr><td>Americas — Los Angeles</td><td>America/Los_Angeles</td><td>BitcoinAmericaAndLosAngelesDate</td></tr>
                <tr><td>Americas — Denver</td><td>America/Denver</td><td>BitcoinAmerica_DenverTimeDate</td></tr>
                <tr><td>Americas — St. Johns</td><td>America/St_Johns</td><td>BitcoinAmerica_St_JohnsTimeDate</td></tr>
                <tr><td>Asia — Tokyo</td><td>Asia/Tokyo</td><td>BitcoinAsiaAndTokyoDate</td></tr>
                <tr><td>Europe — Skopje</td><td>Europe/Skopje</td><td>BitcoinEurope_SkopjeTimeDate</td></tr>
                <tr><td>Africa — Dakar</td><td>Africa/Dakar</td><td>BitcoinAfrica_DakarTimeDate</td></tr>
                <tr><td>Indian — Maldives</td><td>Indian/Maldives</td><td>BitcoinIndian_MaldivesTimeDate</td></tr>
                <tr><td>Indian — Reunion</td><td>Indian/Reunion</td><td>BitcoinIndian_ReunionTimeDate</td></tr>
                <tr><td>Pacific — Norfolk</td><td>Pacific/Norfolk</td><td>BitcoinPacific_NorfolkTimeDate</td></tr>
            </tbody>
        </table>
        </div>
    </div>
</section>

<footer class="footer">
    <span>Bitcoin™ — Wallet &amp; Transaction Server — Port 6682 — MEARVK LLC — NitroWebExpress™ 2026</span>
</footer>
</body>
</html>
