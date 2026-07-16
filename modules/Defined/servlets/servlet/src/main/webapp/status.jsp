<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"/><meta name="viewport" content="width=device-width, initial-scale=1.0"/><title>Status — Defined™</title><link rel="stylesheet" href="css/style.css"/></head>
<body>
<nav class="nav"><div class="nav-inner"><span class="nav-brand">Defined™</span><ul class="nav-links"><li><a href="index.jsp">Overview</a></li><li><a href="categories.jsp">Categories</a></li><li><a href="protocols.jsp">Protocols</a></li><li><a href="status.jsp" class="active">Status</a></li></ul></div></nav>
<section class="hero"><div class="hero-inner"><span class="hero-tag">System Health</span><h1>Status</h1><p>Backend, AI server, MySQL, UFW, and connection hours status.</p></div></section>
<section class="section"><div class="section-inner"><div class="table-wrap"><table>
<thead><tr><th>Service</th><th>Port</th><th>Expected</th></tr></thead>
<tbody>
<tr><td>AI Server (DefinedAIServer)</td><td><code>49220</code></td><td>Running 24/7, scans 4x daily</td></tr>
<tr><td>Protocol Backend (Telnet)</td><td><code>49221</code></td><td>Weekdays 06:00–23:00, Weekends 08:00–20:00 EST</td></tr>
<tr><td>MySQL (defined_dark_gray)</td><td><code>3306</code></td><td>Running</td></tr>
<tr><td>Tomcat (/defined)</td><td><code>8080</code></td><td>Always accessible</td></tr>
<tr><td>Strernary AI</td><td><code>20000</code></td><td>Running (feedback enabled)</td></tr>
<tr><td>UFW Firewall</td><td>—</td><td>Active, managing 6 ports</td></tr>
</tbody></table></div>
<h2 style="margin-top:2rem;">Daily Assessment Schedule</h2>
<div class="table-wrap"><table>
<thead><tr><th>Scan</th><th>Time (EST)</th><th>Assessment</th></tr></thead>
<tbody>
<tr><td>1</td><td>00:00</td><td>First daily assessment</td></tr>
<tr><td>2</td><td>06:00</td><td>Second daily assessment</td></tr>
<tr><td>3</td><td>12:00</td><td>Third daily assessment</td></tr>
<tr><td>4</td><td>18:00</td><td>Fourth daily assessment</td></tr>
<tr><td>Final</td><td>End of day</td><td>Concluding assessment (stored as #5)</td></tr>
</tbody></table></div>
<h2 style="margin-top:2rem;">Moral Disposition Weights (saved daily at noon EST)</h2>
<div class="table-wrap"><table>
<thead><tr><th>Position</th><th>Region</th><th>Consideration</th></tr></thead>
<tbody>
<tr><td>1</td><td>Asia</td><td>Best-first friend</td></tr>
<tr><td>2</td><td>Asia</td><td>Again</td></tr>
<tr><td>3</td><td>United States</td><td>Homeland</td></tr>
<tr><td>4</td><td>Soviet Russia</td><td>Historical</td></tr>
</tbody></table></div>
</div></section>
<footer class="footer"><div><span>&#169; 2026 MEARVK LLC. Defined™ — Dark Gray. Installer: Max Rupplin.</span></div></footer>
</body></html>
