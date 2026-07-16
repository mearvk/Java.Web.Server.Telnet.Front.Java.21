<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"/><meta name="viewport" content="width=device-width, initial-scale=1.0"/><title>Protocols — Defined™</title><link rel="stylesheet" href="css/style.css"/></head>
<body>
<nav class="nav"><div class="nav-inner"><span class="nav-brand">Defined™</span><ul class="nav-links"><li><a href="index.jsp">Overview</a></li><li><a href="categories.jsp">Categories</a></li><li><a href="protocols.jsp" class="active">Protocols</a></li><li><a href="status.jsp">Status</a></li></ul></div></nav>
<section class="hero"><div class="hero-inner"><span class="hero-tag">12 Port Handlers</span><h1>Protocol Awareness</h1><p>UFW-managed ports open before use and close after execution of search, data query, or retrieval.</p></div></section>
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
