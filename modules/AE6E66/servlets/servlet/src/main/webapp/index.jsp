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
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>AE6E66™ — UK Parliament Contact Module</title>
    <link rel="stylesheet" href="css/style.css"/>
</head>
<body>
<nav class="nav"><div class="nav-inner">
    <span class="nav-brand">AE6E66™</span>
    <ul class="nav-links">
        <li><a href="index.jsp" class="active">Overview</a></li>
        <li><a href="contacts.jsp">Contacts</a></li>
        <li><a href="sent.jsp">Sent</a></li>
        <li><a href="status.jsp">Status</a></li>
    </ul>
    <div class="nav-actions">
        <a href="crawl.jsp" class="nav-cta">Crawl</a>
    </div>
</div></nav>

<section class="hero">
    <div class="hero-inner">
        <span class="hero-tag">Emerald Green — Royals</span>
        <h1>AE6E66™</h1>
        <p>House of Lords + House of Commons Contact Module. Crawls UK Parliament members 0–999, gathers contact data, downloads portraits, and distributes DKIM-signed email via mail.lauradei.us.</p>
    </div>
</section>

<section class="section">
    <div class="section-inner">
        <div style="margin-bottom:2rem;padding:1rem;border:1px solid <%= authorized ? "#22c55e" : "#ef4444" %>;border-radius:8px;background:rgba(0,0,0,0.2);">
            <span style="font-size:0.85rem;color:<%= authorized ? "#22c55e" : "#ef4444" %>;font-weight:600;">&#9679; <%= authStatus %></span>
            <span style="font-size:0.75rem;color:#5f7a5f;margin-left:1rem;"><%= new java.text.SimpleDateFormat("yyyy-MM-dd HH:mm:ss z").format(new java.util.Date()) %></span>
        </div>
        <h2>Module Components</h2>
        <div class="table-wrap">
            <table>
                <thead><tr><th>Component</th><th>Description</th><th>Link</th></tr></thead>
                <tbody>
                    <tr><td>Contacts</td><td>House of Lords + House of Commons — crawled member data</td><td><a href="contacts.jsp">Browse →</a></td></tr>
                    <tr><td>Sent Archive</td><td>DKIM-signed messages with SHA-256 receipts</td><td><a href="sent.jsp">View →</a></td></tr>
                    <tr><td>Crawl</td><td>Trigger or view crawl status (members.parliament.uk)</td><td><a href="crawl.jsp">Run →</a></td></tr>
                    <tr><td>Status</td><td>Database, SMTP, DKIM health checks</td><td><a href="status.jsp">Check →</a></td></tr>
                </tbody>
            </table>
        </div>
    </div>
</section>

<section class="section">
    <div class="section-inner">
        <h2>Infrastructure</h2>
        <div class="table-wrap">
            <table>
                <thead><tr><th>Property</th><th>Value</th></tr></thead>
                <tbody>
                    <tr><td>Mail Server</td><td><code>mail.lauradei.us</code></td></tr>
                    <tr><td>Static IP</td><td><code>45.32.31.139</code></td></tr>
                    <tr><td>From Address</td><td><code>contact@lauradei.us</code></td></tr>
                    <tr><td>DKIM Selector</td><td><code>ae6e66</code> (2048-bit)</td></tr>
                    <tr><td>SPF</td><td><code>v=spf1 ip4:45.32.31.139 -all</code></td></tr>
                    <tr><td>DMARC</td><td><code>p=quarantine; pct=100</code></td></tr>
                    <tr><td>Database</td><td><code>nwe_ae6e66</code> (MySQL)</td></tr>
                    <tr><td>Crawl Range</td><td>Member IDs 0–999</td></tr>
                </tbody>
            </table>
        </div>
    </div>
</section>

<section class="section">
    <div class="section-inner">
        <h2>NIO Protocol Access</h2>
        <p style="margin-bottom:1rem;color:var(--text-muted);font-size:0.9rem;">Full module access via NIO masquerade layer — all ports routed.</p>
        <div class="table-wrap">
            <table>
                <thead><tr><th>Port</th><th>Protocol</th><th>Module</th></tr></thead>
                <tbody>
                    <tr><td>2000</td><td><code>NWE-DIRECTORY</code></td><td>Strernary™ Directory Server</td></tr>
                    <tr><td>5000</td><td><code>NWE-FUTURES</code></td><td>Democratic ProFront National (Futures™)</td></tr>
                    <tr><td>5512</td><td><code>AES</code></td><td>AesCompliant™</td></tr>
                    <tr><td>6682</td><td><code>BITCOIN</code></td><td>BitcoinCompliant™</td></tr>
                    <tr><td>7743</td><td><code>RSA</code></td><td>RsaCompliant™</td></tr>
                    <tr><td>7744</td><td><code>DSA</code></td><td>DsaCompliant™</td></tr>
                    <tr><td>9999</td><td><code>NWE-GRAY</code></td><td>GrayPortRegistry™</td></tr>
                    <tr><td>10085</td><td><code>NWE-GRAY85</code></td><td>Gray85 Crème™</td></tr>
                    <tr><td>20000</td><td><code>NWE-STRERNARY</code></td><td>Strernary™</td></tr>
                    <tr><td>49152</td><td><code>NWE-FINANCE</code></td><td>NationalFinanceID</td></tr>
                    <tr><td>49199</td><td><code>TCP</code></td><td>Communicator™</td></tr>
                    <tr><td>49201-4</td><td><code>SIGNAL</code></td><td>International Signal Servers</td></tr>
                </tbody>
            </table>
        </div>
    </div>
</section>

<section class="section">
    <div class="section-inner">
        <h2>Security</h2>
        <div class="table-wrap">
            <table>
                <thead><tr><th>Feature</th><th>Status</th><th>Details</th></tr></thead>
                <tbody>
                    <tr><td>Rate Limiting</td><td style="color:#22c55e;">Active</td><td>30 conn/min per IP, 5-min block on exceed</td></tr>
                    <tr><td>Input Sanitization</td><td style="color:#22c55e;">Active</td><td>Path traversal, null byte, shell injection prevention</td></tr>
                    <tr><td>TLS (opt-in)</td><td style="color:#22c55e;">Available</td><td>TLSv1.3 via psychiatry/secrets/server.p12</td></tr>
                    <tr><td>Heuristic Classifier</td><td style="color:#22c55e;">Active</td><td>Score ≥40 auto-drop, geo/port-scan/payload analysis</td></tr>
                    <tr><td>Antivirus (ClamAV)</td><td style="color:#22c55e;">Active</td><td>Daily scan + file integrity baseline</td></tr>
                    <tr><td>DKIM Email Signing</td><td style="color:#22c55e;">Active</td><td>2048-bit RSA, ae6e66 selector</td></tr>
                    <tr><td>XXE Prevention</td><td style="color:#22c55e;">Active</td><td>DOCTYPE/ENTITY stripping on XML payloads</td></tr>
                </tbody>
            </table>
        </div>
    </div>
</section>

<footer class="footer"><div>
    <span>&#169; 2026 MEARVK LLC. All rights reserved. AE6E66™ — Emerald Green.</span>
</div></footer>
</body>
</html>
