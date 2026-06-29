<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"/><meta name="viewport" content="width=device-width,initial-scale=1.0"/>
<title>Directory — Strernary™</title><link rel="stylesheet" href="css/style.css"/></head><body>
<nav class="nav"><div class="nav-inner"><span class="nav-brand">Strernary™</span>
<ul class="nav-links"><li><a href="index.jsp">Overview</a></li><li><a href="ask.jsp">Ask</a></li><li><a href="directory.jsp" class="active">Directory</a></li><li><a href="queries.jsp">Queries</a></li><li><a href="status.jsp">Status</a></li></ul>
</div></nav>
<section class="hero" style="padding:4rem 2rem;"><div class="hero-inner"><span class="hero-tag">Port 2000</span><h1>Directory Server</h1><p>Telnet-accessible directory and routing. Interactive menu + XML packet forwarding for NIO masquerade routing.</p></div></section>
<section class="section"><div class="section-inner">
<h2>Interactive Menu (telnet port 2000)</h2>
<div class="table-wrap"><table><thead><tr><th>Option</th><th>Description</th><th>Auth</th></tr></thead><tbody>
<tr><td>1</td><td>List port 20000 server IPs (Strernary™)</td><td>NationalID (configurable)</td></tr>
<tr><td>2</td><td>List port 49152 server IPs (NationalFinanceID)</td><td>NationalID required</td></tr>
<tr><td>3</td><td>Register Rank 4 JWSTNJ21 server</td><td>public.key verification</td></tr>
<tr><td>4</td><td>Quit</td><td>—</td></tr>
</tbody></table></div>

<h2 style="margin-top:2rem;">XML Forwarding</h2>
<p style="margin-bottom:1rem;color:var(--text-secondary);">Send an <code>&lt;nwe-route&gt;</code> XML packet to port 2000 for direct NIO masquerade routing:</p>
<pre style="background:var(--bg-card);padding:1rem;border-radius:8px;font-size:0.85rem;color:var(--accent);overflow-x:auto;">&lt;nwe-route&gt;&lt;port&gt;20000&lt;/port&gt;&lt;payload&gt;ASK|What is life?&lt;/payload&gt;&lt;/nwe-route&gt;</pre>

<h2 style="margin-top:2rem;">Known Server Lists</h2>
<div class="table-wrap"><table><thead><tr><th>File</th><th>Contents</th></tr></thead><tbody>
<tr><td><code>known.port.20000.servers.xml</code></td><td>Strernary™ endpoints</td></tr>
<tr><td><code>known.port.49152.servers.xml</code></td><td>NationalFinanceID endpoints</td></tr>
</tbody></table></div>
</div></section>
<footer class="footer"><div><span>&#169; 2026 MEARVK LLC.</span></div></footer></body></html>
