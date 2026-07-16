<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.net.*, java.io.*" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>NC State University™ — NitroWebExpress™</title>
    <link rel="stylesheet" href="css/style.css"/>
    <script src="js/scroll-preserve.js"></script>
</head>
<body>
<nav class="nav"><div class="nav-inner">
    <span class="nav-brand">🐺 NC State™</span>
    <ul class="nav-links">
        <li><a href="index.jsp" class="active">Overview</a></li>
        <li><a href="colleges.jsp">Colleges</a></li>
        <li><a href="departments.jsp">Departments</a></li>
        <li><a href="status.jsp">Status</a></li>
    </ul>
    <div class="nav-actions">
        <a href="colleges.jsp" class="nav-cta">View Colleges →</a>
    </div>
</div></nav>

<section class="hero">
    <div class="hero-inner">
        <span class="hero-tag">Wolfpack Red — North Carolina State University</span>
        <h1>NC State University™</h1>
        <p>Think and Do. The Wolfpack. 12 colleges, 37,000+ students. AI-assisted academic queries via Strernary™. Raleigh, North Carolina.</p>
    </div>
</section>

<!-- CD1 Connector Button -->
<div style="display:flex;justify-content:center;align-items:center;width:100%;padding:2rem 0;">
    <button id="cd1-btn" type="button" aria-pressed="false" style="all:unset;display:block;margin:0 auto;cursor:pointer;padding:0;border:none;background:transparent;transition:transform 0.3s cubic-bezier(0.42,-1.84,0.42,1.84),filter 0.3s ease;">
        <div style="width:80px;height:80px;border-radius:50%;background:#2d0a0a;border:3px solid #CC0000;display:flex;align-items:center;justify-content:center;font-size:1.5rem;color:#CC0000;">⬡</div>
    </button>
</div>
<div id="cd1-overlay" style="display:none;position:fixed;inset:0;z-index:299;background:transparent;"></div>
<div id="cd1-dialog" style="display:none;position:fixed;top:50%;left:50%;transform:translate(-50%,-50%);z-index:300;background:#220000;border:1px solid #4d1a1a;border-radius:12px;padding:1.25rem;width:520px;max-width:90vw;box-shadow:0 8px 32px rgba(0,0,0,0.6);">
    <div style="font-size:0.9rem;font-weight:600;color:#f0e8e8;margin-bottom:0.75rem;">NCSU Connector — Port 49217</div>
    <div style="display:flex;gap:0.5rem;margin-bottom:0.75rem;flex-wrap:wrap;align-items:center;">
        <select id="cd1-action" style="background:#2d0a0a;color:#f0e8e8;border:1px solid #4d1a1a;border-radius:8px;padding:0.45rem 2rem 0.45rem 0.75rem;font-size:0.8rem;cursor:pointer;">
            <option value="COLLEGES">List Colleges</option>
            <option value="DEPARTMENTS|College of Engineering">Engineering Departments</option>
            <option value="SEARCH|computer science">Search Courses</option>
            <option value="ADMIN">Administration</option>
            <option value="STATUS">Server Status</option>
        </select>
        <button onclick="cd1Send()" style="background:#CC0000;color:#fff;border:none;border-radius:8px;padding:0.45rem 1rem;font-size:0.8rem;font-weight:600;cursor:pointer;">Send</button>
        <button onclick="cd1Ok()" style="background:#CC0000;color:#fff;border:none;border-radius:8px;padding:0.45rem 1rem;font-size:0.8rem;font-weight:600;cursor:pointer;">OK</button>
    </div>
    <div style="display:flex;align-items:center;gap:0.5rem;margin-bottom:0.75rem;">
        <label style="display:flex;align-items:center;gap:0.4rem;color:#bb9999;font-size:0.75rem;cursor:pointer;">
            <input type="checkbox" id="cd1-direct-port" style="accent-color:#CC0000;width:14px;height:14px;cursor:pointer;"/>
            Direct Port (bypass Strernary™ 20000)
        </label>
        <span id="cd1-mode-badge" style="font-size:0.65rem;background:#2d0a0a;color:#CC0000;padding:0.2rem 0.5rem;border-radius:4px;">STRERNARY</span>
    </div>
    <textarea id="cd1-textarea" placeholder="Connection idle... Go Pack!" spellcheck="false" style="width:100%;min-height:140px;background:#fff;color:#111;border:1px solid #4d1a1a;border-radius:8px;padding:0.75rem;font-family:monospace;font-size:0.8rem;resize:vertical;"></textarea>
</div>
<script>window.CD1_MODULE_PORT = "49217";</script>
<script src="js/cd1-connector.js"></script>

<section class="section">
    <div class="section-inner">
        <h2>Colleges & Schools</h2>
        <div class="college-grid">
            <div class="college-card"><h4>College of Agriculture and Life Sciences</h4><p>Animal science, crop science, food science, biological engineering</p></div>
            <div class="college-card"><h4>College of Design</h4><p>Architecture, art + design, graphic design, industrial design, landscape architecture</p></div>
            <div class="college-card"><h4>College of Education</h4><p>Teacher education, STEM education, educational leadership</p></div>
            <div class="college-card"><h4>College of Engineering</h4><p>Computer science, electrical, mechanical, aerospace, biomedical, nuclear</p></div>
            <div class="college-card"><h4>College of Humanities and Social Sciences</h4><p>English, history, psychology, political science, communication</p></div>
            <div class="college-card"><h4>College of Natural Resources</h4><p>Forestry, environmental resources, parks and recreation management</p></div>
            <div class="college-card"><h4>College of Sciences</h4><p>Biology, chemistry, mathematics, physics, statistics, marine sciences</p></div>
            <div class="college-card"><h4>Poole College of Management</h4><p>Accounting, economics, finance, marketing, business management</p></div>
            <div class="college-card"><h4>Wilson College of Textiles</h4><p>Textile engineering, apparel technology, forest biomaterials</p></div>
            <div class="college-card"><h4>College of Veterinary Medicine</h4><p>Clinical sciences, molecular biomedical sciences, population health</p></div>
            <div class="college-card"><h4>Graduate School</h4><p>Master's and doctoral programs across all disciplines</p></div>
        </div>
    </div>
</section>

<section class="section">
    <div class="section-inner">
        <h2>University Administration</h2>
        <div class="table-wrap">
            <table>
                <thead><tr><th>Title</th><th>Name</th><th>Department</th></tr></thead>
                <tbody>
                    <tr><td>Chancellor</td><td>Kevin M. Guskiewicz</td><td>Office of the Chancellor</td></tr>
                    <tr><td>Provost & Executive Vice Chancellor</td><td>Warwick Arden</td><td>Office of the Provost</td></tr>
                    <tr><td>VC Research and Innovation</td><td>Mladen Vouk</td><td>Office of Research and Innovation</td></tr>
                    <tr><td>VC Student Affairs</td><td>Doneka Scott</td><td>Division of Academic and Student Affairs</td></tr>
                    <tr><td>VC Finance and Administration</td><td>Charles Leffler</td><td>Finance and Administration</td></tr>
                    <tr><td>VC University Advancement</td><td>Brian Sischo</td><td>University Advancement</td></tr>
                    <tr><td>VC Information Technology</td><td>Marc Hoit</td><td>Office of Information Technology</td></tr>
                    <tr><td>Dean of Engineering</td><td>Louis Martin-Vega</td><td>College of Engineering</td></tr>
                    <tr><td>Dean of Sciences</td><td>Christopher McGahan</td><td>College of Sciences</td></tr>
                    <tr><td>Dean of Agriculture</td><td>Richard Linton</td><td>College of Agriculture and Life Sciences</td></tr>
                    <tr><td>Athletics Director</td><td>Boo Corrigan</td><td>Athletics</td></tr>
                    <tr><td>Faculty Senate Chair</td><td>RaJade M. Berry-James</td><td>Faculty Senate</td></tr>
                </tbody>
            </table>
        </div>
    </div>
</section>

<section class="section">
    <div class="section-inner">
        <h2>Engineering Departments</h2>
        <div class="college-grid">
            <div class="college-card"><h4>Computer Science</h4><p>AI, systems, networking, software engineering</p></div>
            <div class="college-card"><h4>Electrical and Computer Engineering</h4><p>Power systems, signal processing, VLSI</p></div>
            <div class="college-card"><h4>Mechanical and Aerospace Engineering</h4><p>Robotics, thermodynamics, aerodynamics</p></div>
            <div class="college-card"><h4>Civil, Construction, and Environmental</h4><p>Structural, transportation, water resources</p></div>
            <div class="college-card"><h4>Biomedical Engineering</h4><p>Medical devices, tissue engineering, imaging</p></div>
            <div class="college-card"><h4>Chemical and Biomolecular Engineering</h4><p>Process design, nanotechnology, polymers</p></div>
            <div class="college-card"><h4>Nuclear Engineering</h4><p>Reactor design, radiation protection, fusion</p></div>
            <div class="college-card"><h4>Industrial and Systems Engineering</h4><p>Operations research, human factors, analytics</p></div>
            <div class="college-card"><h4>Materials Science and Engineering</h4><p>Composites, ceramics, electronic materials</p></div>
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
                    <tr><td>Backend Port</td><td><code>49217</code></td></tr>
                    <tr><td>Protocol</td><td><code>NWE-NCSU</code> (TCP socket)</td></tr>
                    <tr><td>Database</td><td><code>nwe_ncsu</code> (MySQL)</td></tr>
                    <tr><td>AI Inference</td><td><code>Strernary™ port 20000</code> (DJL/PyTorch)</td></tr>
                    <tr><td>Webapp Context</td><td><code>/california-ncsu</code></td></tr>
                    <tr><td>University URL</td><td><a href="https://www.ncsu.edu">ncsu.edu</a></td></tr>
                    <tr><td>Location</td><td>Raleigh, North Carolina</td></tr>
                    <tr><td>Founded</td><td>1887</td></tr>
                    <tr><td>Enrollment</td><td>37,000+ students</td></tr>
                    <tr><td>Installer Tech ID</td><td>Max Rupplin</td></tr>
                </tbody>
            </table>
        </div>
    </div>
</section>

<section class="section">
    <div class="section-inner">
        <h2>Commands (Telnet — port 49217)</h2>
        <div class="table-wrap">
            <table>
                <thead><tr><th>Command</th><th>Description</th></tr></thead>
                <tbody>
                    <tr><td><code>COLLEGES</code></td><td>List all NC State colleges and schools</td></tr>
                    <tr><td><code>DEPARTMENTS|&lt;college&gt;</code></td><td>List departments within a college</td></tr>
                    <tr><td><code>SEARCH|&lt;keyword&gt;</code></td><td>Search courses and departments</td></tr>
                    <tr><td><code>QUERY|&lt;college&gt;|&lt;text&gt;</code></td><td>Submit query (AI-assisted response)</td></tr>
                    <tr><td><code>ADMIN</code></td><td>List university administration</td></tr>
                    <tr><td><code>STATUS</code></td><td>Server health check</td></tr>
                    <tr><td><code>QUIT</code></td><td>Disconnect</td></tr>
                </tbody>
            </table>
        </div>
    </div>
</section>

<footer class="footer"><div><span>&#169; 2026 MEARVK LLC. NC State University™ — Wolfpack Red. Go Pack!</span></div></footer>
</body>
</html>
