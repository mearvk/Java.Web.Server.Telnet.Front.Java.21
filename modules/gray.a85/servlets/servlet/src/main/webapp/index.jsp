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
<title>Gray85 Crème Registry™</title><link rel="stylesheet" href="css/style.css"/></head><body>
<nav class="nav"><div class="nav-inner"><span class="nav-brand">Gray85 Crème™</span>
<ul class="nav-links"><li><a href="index.jsp" class="active">Overview</a></li><li><a href="leases.jsp">Leases</a></li><li><a href="bindings.jsp">Bindings</a></li><li><a href="creme.jsp">Crème</a></li><li><a href="status.jsp">Status</a></li></ul>
</div></nav>
<section class="hero"><div class="hero-inner"><span class="hero-tag">Planetary Auditor Control</span>
<h1>Gray85 Crème Registry™</h1><p>85% open ports ($10 lease) + 15% Crème-locked ($1000/unlock/hour). Planetary auditor control layer. Port 10085.</p></div></section>
<section class="section"><div class="section-inner">
<div style="margin-bottom:2rem;padding:1rem;border:1px solid <%= authorized ? "#22c55e" : "#ef4444" %>;border-radius:8px;">
<span style="font-size:0.85rem;color:<%= authorized ? "#22c55e" : "#ef4444" %>;font-weight:600;">&#9679; <%= authStatus %></span></div>
<h2>Protocol Commands (TCP port 10085)</h2>
<div class="table-wrap"><table><thead><tr><th>Command</th><th>Format</th><th>Description</th></tr></thead><tbody>
<tr><td><code>LEASE</code></td><td><code>LEASE|block_id|term|btc_txid</code></td><td>Lease a 30M port block ($10)</td></tr>
<tr><td><code>BIND</code></td><td><code>BIND|block_id|port</code></td><td>Bind open port (85%)</td></tr>
<tr><td><code>UNLOCK</code></td><td><code>UNLOCK|block_id|port_offset|hours|btc_txid</code></td><td>Unlock Crème port ($1000/hr)</td></tr>
<tr><td><code>CREME</code></td><td><code>CREME|block_id</code></td><td>List Crème-locked ports in block</td></tr>
<tr><td><code>STATUS</code></td><td><code>STATUS|block_id</code></td><td>Check block availability</td></tr>
<tr><td><code>LIST</code></td><td><code>LIST</code></td><td>List active leases</td></tr>
<tr><td><code>QUIT</code></td><td><code>QUIT</code></td><td>Disconnect</td></tr>
</tbody></table></div>
<h2 style="margin-top:2rem;">Pricing</h2>
<div class="table-wrap"><table><thead><tr><th>Tier</th><th>Ports</th><th>Cost</th><th>Notes</th></tr></thead><tbody>
<tr><td>Open (85%)</td><td>25,500,000 per block</td><td>$10 USD lease</td><td>Standard AI-gated binding</td></tr>
<tr><td>Crème (15%)</td><td>4,500,000 per block</td><td>$1000 USD/unlock/hour</td><td>Planetary auditor controlled</td></tr>
</tbody></table></div></div></section>
<footer class="footer"><div><span>&#169; 2026 MEARVK LLC. All rights reserved.</span></div></footer></body></html>
