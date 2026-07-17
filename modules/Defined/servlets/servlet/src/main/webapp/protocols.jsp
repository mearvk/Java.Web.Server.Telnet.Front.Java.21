<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"/>
    <link rel="preconnect" href="https://fonts.googleapis.com"/><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin/><link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:ital,wght@0,300;0,400;0,500;0,600;0,700;1,400;1,600&display=swap" rel="stylesheet"/><meta name="viewport" content="width=device-width, initial-scale=1.0"/><title>Protocols — Defined™</title><link rel="stylesheet" href="css/style.css"/>    <script src="js/nwe-readme-viewer.js"></script>
</head>
<body>
<nav class="nav"><div class="nav-inner"><span class="nav-brand">Defined™</span><ul class="nav-links"><li><a href="index.jsp">Overview</a></li><li><a href="categories.jsp">Categories</a></li><li><a href="protocols.jsp" class="active">Protocols</a></li><li><a href="status.jsp">Status</a></li></ul></div></nav>

<section class="hero"><div class="hero-inner"><span class="hero-tag">12 Port Handlers</span><h1>Protocol Awareness</h1><p>UFW-managed ports open before use and close after execution of search, data query, or retrieval.</p></div></section>

<!-- CD1 Connector Button + Floating Dialog -->
<div style="display:flex;justify-content:center;align-items:center;width:100%;padding:2rem 0;">
    <button id="cd1-btn" type="button" aria-pressed="false" style="all:unset;display:block;margin:0 auto;cursor:pointer;padding:0;border:none;background:transparent;transition:transform 0.3s cubic-bezier(0.42,-1.84,0.42,1.84),filter 0.3s ease;">
        <img src="images/black.button.png" alt="Connector" style="display:block;width:80px;height:80px;border-radius:50%;background:transparent;"/>
    </button>
</div>
<div id="cd1-overlay" style="display:none;position:fixed;inset:0;z-index:299;background:transparent;"></div>
<div id="cd1-dialog" style="display:none;position:fixed;top:50%;left:50%;transform:translate(-50%,-50%);z-index:300;background:#1a1a1a;border:1px solid #333;border-radius:12px;padding:1.25rem;width:520px;max-width:90vw;box-shadow:0 8px 32px rgba(0,0,0,0.6);">
    <div style="font-size:0.9rem;font-weight:600;color:#e8e0d6;margin-bottom:0.75rem;">CD1 Connector &#8212; Port 49220</div>
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
<script>window.CD1_MODULE_PORT = "49220";</script>
<script src="js/cd1-connector.js"></script>

<section class="section"><div class="section-inner"><h2>Protocol Handlers</h2><div class="table-wrap"><table>
<thead><tr><th>Port</th><th>Protocol</th><th>Direction</th><th>UFW</th><th>Auth Type</th></tr></thead>
<tbody>
<tr><td><code>20</code></td><td>FTP-DATA</td><td>outbound</td><td>persistent</td><td>Password</td></tr>
<tr><td><code>21</code></td><td>FTP</td><td>bidirectional</td><td>persistent</td><td>Password</td></tr>
<tr><td><code>22</code></td><td>SSH</td><td>outbound</td><td>managed (open/close)</td><td>Key + Password</td></tr>
<tr><td><code>25</code></td><td>SMTP</td><td>outbound</td><td>persistent</td><td>LOGIN</td></tr>
<tr><td><code>80</code></td><td>HTTP</td><td>outbound</td><td>persistent</td><td>Basic / Bearer</td></tr>
<tr><td><code>443</code></td><td>HTTPS (TLSv1.3)</td><td>outbound</td><td>managed (open/close)</td><td>Basic / Bearer</td></tr>
<tr><td><code>465</code></td><td>SMTPS (implicit TLS)</td><td>outbound</td><td>managed (open/close)</td><td>LOGIN</td></tr>
<tr><td><code>587</code></td><td>SMTP Submission</td><td>outbound</td><td>managed (open/close)</td><td>STARTTLS + LOGIN</td></tr>
<tr><td><code>990</code></td><td>FTPS (implicit TLS)</td><td>outbound</td><td>managed (open/close)</td><td>Password</td></tr>
<tr><td><code>993</code></td><td>IMAPS (SSL IMAP)</td><td>outbound</td><td>managed (open/close)</td><td>LOGIN</td></tr>
<tr><td><code>3306</code></td><td>MySQL</td><td>local</td><td>persistent</td><td>MySQL Auth</td></tr>
<tr><td><code>8080</code></td><td>HTTP-ALT (Tomcat)</td><td>bidirectional</td><td>persistent</td><td>Form</td></tr>
</tbody></table></div>
<h2 style="margin-top:2rem;">UFW Firewall Behavior</h2>
<div class="table-wrap"><table>
<thead><tr><th>Action</th><th>When</th></tr></thead>
<tbody>
<tr><td><code>sudo ufw allow out &lt;port&gt;/tcp</code></td><td>Before search, data query, or retrieval</td></tr>
<tr><td><code>sudo ufw delete allow out &lt;port&gt;/tcp</code></td><td>After execution completes</td></tr>
</tbody></table></div>
</div></section>
<footer class="footer"><div><span>&#169; 2026 MEARVK LLC. Defined™ — Dark Gray.</span></div></footer>
</body></html>
