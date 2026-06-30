<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"/><meta name="viewport" content="width=device-width,initial-scale=1.0"/>
<title>Strernary™ — Best-Guess Inference Server</title><link rel="stylesheet" href="css/style.css"/><script src="js/scroll-preserve.js"></script>
</head><body>
<nav class="nav"><div class="nav-inner"><span class="nav-brand">Strernary™</span>
<ul class="nav-links"><li><a href="index.jsp" class="active">Overview</a></li><li><a href="ask.jsp">Ask</a></li><li><a href="directory.jsp">Directory</a></li><li><a href="queries.jsp">Queries</a></li><li><a href="status.jsp">Status</a></li></ul>
</div></nav>
<section class="hero"><div class="hero-inner"><span class="hero-tag">Cyan — Best-Guess Inference</span>
<h1>Strernary™</h1><p>Port 20000 inference server. Accepts standard information and returns best-guess responses. DJL (Deep Java Library) with PyTorch, OS port relay, and keyword heuristics.</p></div></section>

<section class="section"><div class="section-inner">
<h2>Inference Stack (Priority Order)</h2>
<div class="table-wrap"><table><thead><tr><th>#</th><th>Layer</th><th>Description</th></tr></thead><tbody>
<tr><td>1</td><td>DJL / PyTorch</td><td>Local DistilBERT inference via Amazon's Deep Java Library (~250 MB model)</td></tr>
<tr><td>2</td><td>OS Port Relay</td><td>Forwards to OS-level listener on 20000 if alive (opportunistic)</td></tr>
<tr><td>3</td><td>Keyword Heuristics</td><td>Routes queries to known NWE services based on content keywords</td></tr>
</tbody></table></div></div></section>

<section class="section"><div class="section-inner">
<h2>Architecture</h2>
<div class="table-wrap"><table><thead><tr><th>Component</th><th>Port</th><th>Role</th></tr></thead><tbody>
<tr><td>Strernary Server</td><td><code>20000</code></td><td>Primary inference — ASK|text, RELAY|text, STATUS</td></tr>
<tr><td>Directory Server</td><td><code>2000</code></td><td>Telnet menu + XML packet forwarding + Rank 4 registration</td></tr>
<tr><td>NIO Masquerade</td><td><code>127.0.0.1–17</code></td><td>NIO front bridging non-blocking to blocking architecture</td></tr>
<tr><td>OS Port Module</td><td><code>20000 (OS)</code></td><td>Dual-port: Java + OS listener coexist opportunistically</td></tr>
</tbody></table></div></div></section>

<section class="section"><div class="section-inner">
<h2>Protocol</h2>
<div class="table-wrap"><table><thead><tr><th>Command</th><th>Format</th><th>Response</th></tr></thead><tbody>
<tr><td><code>ASK</code></td><td><code>ASK|What is life?</code></td><td>Best-guess text response</td></tr>
<tr><td><code>RELAY</code></td><td><code>RELAY|text</code></td><td>Forwarded to OS port if alive</td></tr>
<tr><td><code>STATUS</code></td><td><code>STATUS</code></td><td>Server uptime, model loaded, queries served</td></tr>
</tbody></table></div></div></section>

<section class="section"><div class="section-inner">
<h2>Source Files</h2>
<div class="table-wrap"><table><thead><tr><th>File</th><th>Purpose</th></tr></thead><tbody>
<tr><td><code>StrernaryServer.java</code></td><td>Port 20000 TCP inference server</td></tr>
<tr><td><code>StrernaryDirectoryServer.java</code></td><td>Port 2000 telnet menu + XML forwarding</td></tr>
<tr><td><code>DjlInferenceEngine.java</code></td><td>DJL/PyTorch model loading and query</td></tr>
<tr><td><code>NioMasqueradeEngine.java</code></td><td>NIO selector with 18 local IP bindings</td></tr>
<tr><td><code>NioModuleScanner.java</code></td><td>Startup module discovery and registration</td></tr>
<tr><td><code>StrernaryKnowledgeFetcher.java</code></td><td>Knowledge base retrieval</td></tr>
<tr><td><code>StrernaryTranslationLayer.java</code></td><td>Query translation and routing</td></tr>
</tbody></table></div></div></section>

<footer class="footer"><div><span>&#169; 2026 MEARVK LLC. All rights reserved. Strernary™ — Cyan.</span></div></footer></body></html>
