<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"/>
    <link rel="preconnect" href="https://fonts.googleapis.com"/><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin/><link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:ital,wght@0,300;0,400;0,500;0,600;0,700;1,400;1,600&display=swap" rel="stylesheet"/><meta name="viewport" content="width=device-width, initial-scale=1.0"/><title>Categories — Defined™</title><link rel="stylesheet" href="css/style.css"/>    <script src="js/nwe-readme-viewer.js"></script>
</head>
<body>
<nav class="nav"><div class="nav-inner"><span class="nav-brand">Defined™</span><ul class="nav-links"><li><a href="index.jsp">Overview</a></li><li><a href="categories.jsp" class="active">Categories</a></li><li><a href="protocols.jsp">Protocols</a></li><li><a href="status.jsp">Status</a></li></ul></div></nav>

<section class="hero"><div class="hero-inner"><span class="hero-tag">29 Assessment Domains</span><h1>Categories</h1><p>Each category has a data folder accepting .txt, .csv, .doc, .docx for further informing these issues.</p></div></section>

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

<section class="section"><div class="section-inner"><div class="table-wrap"><table>
<thead><tr><th>#</th><th>Category</th><th>Data Folder</th></tr></thead>
<tbody>
<tr><td>1</td><td>Banking</td><td><code>data/categories/banking/</code></td></tr>
<tr><td>2</td><td>Middle Schools</td><td><code>data/categories/middle-schools/</code></td></tr>
<tr><td>3</td><td>Strong Middle Schools</td><td><code>data/categories/strong-middle-schools/</code></td></tr>
<tr><td>4</td><td>Improbable Activity in Today's Youth</td><td><code>data/categories/improbable-activity-youth/</code></td></tr>
<tr><td>5</td><td>Firefights (20+ Casualties)</td><td><code>data/categories/firefights-20-plus-casualties/</code></td></tr>
<tr><td>6</td><td>Fire Department Errors (3+ Employees)</td><td><code>data/categories/fire-department-errors-3-plus/</code></td></tr>
<tr><td>7</td><td>Schools That Have Burned Down</td><td><code>data/categories/schools-burned-down/</code></td></tr>
<tr><td>8</td><td>Misuse of Scientology</td><td><code>data/categories/misuse-of-scientology/</code></td></tr>
<tr><td>9</td><td>Known Misuse of Public Officials</td><td><code>data/categories/known-misuse-public-officials/</code></td></tr>
<tr><td>10</td><td>Unkind Language About Books/Reading</td><td><code>data/categories/unkind-language-books-reading/</code></td></tr>
<tr><td>11</td><td>Unkind Misuse of Heads of State</td><td><code>data/categories/unkind-misuse-heads-of-state/</code></td></tr>
<tr><td>12</td><td>Absence of FBI Presence</td><td><code>data/categories/absence-fbi-presence/</code></td></tr>
<tr><td>13</td><td>Absence of Border Protection</td><td><code>data/categories/absence-border-protection/</code></td></tr>
<tr><td>14</td><td>Unequal Treatment of US Treasury</td><td><code>data/categories/unequal-treatment-us-treasury/</code></td></tr>
<tr><td>15</td><td>Unequal Footing — US State Department</td><td><code>data/categories/unequal-footing-us-state-department/</code></td></tr>
<tr><td>16</td><td>Private Ownership of LSAT</td><td><code>data/categories/private-ownership-lsat/</code></td></tr>
<tr><td>17</td><td>Torturers</td><td><code>data/categories/torturers/</code></td></tr>
<tr><td>18</td><td>Rapists</td><td><code>data/categories/rapists/</code></td></tr>
<tr><td>19</td><td>Convicted Murderers</td><td><code>data/categories/convicted-murderers/</code></td></tr>
<tr><td>20</td><td>Gods Going Crazy or Similar</td><td><code>data/categories/gods-going-crazy/</code></td></tr>
<tr><td>21</td><td>Anti-God(s) or Such Rhetoric</td><td><code>data/categories/anti-god-rhetoric/</code></td></tr>
<tr><td>22</td><td>Against Space or NASA</td><td><code>data/categories/against-space-nasa/</code></td></tr>
<tr><td>23</td><td>Anti-Political Whisper</td><td><code>data/categories/anti-political-whisper/</code></td></tr>
<tr><td>24</td><td>Sovietism vs Socialism</td><td><code>data/categories/sovietism-vs-socialism/</code></td></tr>
<tr><td>25</td><td>Failing Schools</td><td><code>data/categories/failing-schools/</code></td></tr>
<tr><td>26</td><td>Failing Final Tests</td><td><code>data/categories/failing-final-tests/</code></td></tr>
<tr><td>27</td><td>Non-Social Graces</td><td><code>data/categories/non-social-graces/</code></td></tr>
<tr><td>28</td><td>Prayer Against Even Temper</td><td><code>data/categories/prayer-against-even-temper/</code></td></tr>
<tr><td>29</td><td>NTSB</td><td><code>data/categories/ntsb/</code></td></tr>
</tbody></table></div></div></section>
<footer class="footer"><div><span>&#169; 2026 MEARVK LLC. Defined™ — Dark Gray.</span></div></footer>
</body></html>
