<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"/>
    <link rel="preconnect" href="https://fonts.googleapis.com"/><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin/><link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:ital,wght@0,300;0,400;0,500;0,600;0,700;1,400;1,600&display=swap" rel="stylesheet"/><meta name="viewport" content="width=device-width,initial-scale=1.0"/>
<title>Strernary™ — Best-Guess Inference Server</title><link rel="stylesheet" href="css/style.css"/><script src="js/scroll-preserve.js"></script>
</head><body>
<nav class="nav"><div class="nav-inner"><span class="nav-brand">Strernary™</span>
<ul class="nav-links"><li><a href="index.jsp" class="active">Overview</a></li><li><a href="ask.jsp">Ask</a></li><li><a href="directory.jsp">Directory</a></li><li><a href="queries.jsp">Queries</a></li><li><a href="status.jsp">Status</a></li></ul>
</div></nav>

<section class="hero"><div class="hero-inner"><span class="hero-tag">Cyan — Best-Guess Inference</span>
<h1>Strernary™</h1><p>Port 20000 inference server. Accepts standard information and returns best-guess responses. DJL (Deep Java Library) with PyTorch, OS port relay, and keyword heuristics.</p></div></section>

<!-- CD1 Connector Button + Floating Dialog -->
<div style="display:flex;justify-content:center;align-items:center;width:100%;padding:2rem 0;">
    <button id="cd1-btn" type="button" aria-pressed="false" style="all:unset;display:block;margin:0 auto;cursor:pointer;padding:0;border:none;background:transparent;transition:transform 0.3s cubic-bezier(0.42,-1.84,0.42,1.84),filter 0.3s ease;">
        <img src="images/black.button.png" alt="Connector" style="display:block;width:80px;height:80px;border-radius:50%;background:transparent;"/>
    </button>
</div>
<div id="cd1-overlay" style="display:none;position:fixed;inset:0;z-index:299;background:transparent;"></div>
<div id="cd1-dialog" style="display:none;position:fixed;top:50%;left:50%;transform:translate(-50%,-50%);z-index:300;background:#1a1a1a;border:1px solid #333;border-radius:12px;padding:1.25rem;width:520px;max-width:90vw;box-shadow:0 8px 32px rgba(0,0,0,0.6);">
    <div style="font-size:0.9rem;font-weight:600;color:#e8e0d6;margin-bottom:0.75rem;">CD1 Connector &#8212; Port 20000</div>
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
<script>window.CD1_MODULE_PORT = "20000";</script>
<script src="js/cd1-connector.js"></script>


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

</body></html>
