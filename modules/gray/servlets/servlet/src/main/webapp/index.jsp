<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.net.*, java.io.*" %>
<%
    boolean authorized = false; String authStatus = "Unknown";
    try { HttpURLConnection hc = (HttpURLConnection) new URL("https://raw.githubusercontent.com/mearvk/Java.Web.Server.Telnet.Front.Java.21/main/psychiatry/secrets/public.key").openConnection();
        hc.setRequestMethod("HEAD"); hc.setConnectTimeout(5000); hc.setReadTimeout(5000);
        authorized = (hc.getResponseCode() == 200); authStatus = authorized ? "Authorized" : "Revoked"; hc.disconnect();
    } catch (Exception e) { authStatus = "Check failed"; }
%>
<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"/><meta name="viewport" content="width=device-width,initial-scale=1.0"/>
<title>GrayPortRegistry™ — Installer ID Tech™</title><link rel="stylesheet" href="css/style.css"/><script src="js/scroll-preserve.js"></script>
</head><body>
<nav class="nav"><div class="nav-inner"><span class="nav-brand">GrayPortRegistry™</span>
<ul class="nav-links"><li><a href="index.jsp" class="active">Overview</a></li><li><a href="leases.jsp">Leases</a></li><li><a href="bindings.jsp">Bindings</a></li><li><a href="status.jsp">Status</a></li></ul>
</div></nav>
<section class="hero"><div class="hero-inner"><span class="hero-tag">Installer ID Tech™</span>
<h1>GrayPortRegistry™</h1><p>30,000,000 port block leasing via Bitcoin or Dashcoin. $10 USD minimum donation. 1000 blocks available. Port 9999.</p></div></section>
<section class="section"><div class="section-inner">
<div style="margin-bottom:2rem;padding:1rem;border:1px solid <%= authorized ? "#22c55e" : "#ef4444" %>;border-radius:8px;">
<span style="font-size:0.85rem;color:<%= authorized ? "#22c55e" : "#ef4444" %>;font-weight:600;">&#9679; <%= authStatus %></span></div>
<h2>Protocol Commands (TCP port 9999)</h2>
<div class="table-wrap"><table><thead><tr><th>Command</th><th>Format</th><th>Description</th></tr></thead><tbody>
<tr><td><code>LEASE</code></td><td><code>LEASE|block_id|term|btc_txid</code></td><td>Lease a 30M port block</td></tr>
<tr><td><code>STATUS</code></td><td><code>STATUS|block_id</code></td><td>Check block availability</td></tr>
<tr><td><code>BIND</code></td><td><code>BIND|block_id|port</code></td><td>Bind port within leased block (AI-gated)</td></tr>
<tr><td><code>LIST</code></td><td><code>LIST</code></td><td>List all active leases</td></tr>
<tr><td><code>QUIT</code></td><td><code>QUIT</code></td><td>Disconnect</td></tr>
</tbody></table></div>
<h2 style="margin-top:2rem;">Configuration</h2>
<div class="table-wrap"><table><thead><tr><th>Property</th><th>Value</th></tr></thead><tbody>
<tr><td>Port</td><td><code>9999</code></td></tr>
<tr><td>Block Size</td><td>30,000,000 ports</td></tr>
<tr><td>Available Blocks</td><td>1000</td></tr>
<tr><td>Total Capacity</td><td>30 billion ports</td></tr>
<tr><td>Minimum Donation</td><td>$10 USD (Bitcoin/Dashcoin)</td></tr>
<tr><td>Terms</td><td>month (30d), year (1y), multi-year (3y)</td></tr>
<tr><td>AI Gate</td><td>Binary authorization per BIND</td></tr>
<tr><td>Database</td><td><code>nwe_gray_registry</code></td></tr>
</tbody></table></div></div></section>
<footer class="footer"><div><span>&#169; 2026 MEARVK LLC. All rights reserved.</span></div></footer></body></html>
