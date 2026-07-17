<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.net.*, java.io.*" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/>
    <link rel="preconnect" href="https://fonts.googleapis.com"/><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin/><link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:ital,wght@0,300;0,400;0,500;0,600;0,700;1,400;1,600&display=swap" rel="stylesheet"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>UNC Chapel Hill™ — NitroWebExpress™</title>
    <link rel="stylesheet" href="css/style.css"/>
    <script src="js/scroll-preserve.js"></script>
    <script src="js/nwe-readme-viewer.js"></script>
</head>
<body>
<nav class="nav"><div class="nav-inner">
    <span class="nav-brand">🐏 UNC Chapel Hill™</span>
    <ul class="nav-links">
        <li><a href="index.jsp" class="active">Overview</a></li>
        <li><a href="schools.jsp">Schools</a></li>
        <li><a href="departments.jsp">Departments</a></li>
        <li><a href="status.jsp">Status</a></li>
    </ul>
</div></nav>

<section class="hero">
    <div class="hero-inner">
        <span class="hero-tag">Carolina Blue — University of North Carolina at Chapel Hill</span>
        <h1>UNC Chapel Hill™</h1>
        <p>Lux Libertas. The Tar Heels. America's first public university (1789). 14 schools, 30,000+ students. AI-assisted academic queries via Strernary™. Chapel Hill, North Carolina.</p>
    </div>
</section>

<!-- CD1 Connector Button -->
<div style="display:flex;justify-content:center;align-items:center;width:100%;padding:2rem 0;">
    <button id="cd1-btn" type="button" aria-pressed="false" style="all:unset;display:block;margin:0 auto;cursor:pointer;padding:0;border:none;background:transparent;transition:transform 0.3s cubic-bezier(0.42,-1.84,0.42,1.84),filter 0.3s ease;">
        <div style="width:80px;height:80px;border-radius:50%;background:#132a47;border:3px solid #4B9CD3;display:flex;align-items:center;justify-content:center;font-size:1.5rem;color:#4B9CD3;">⬡</div>
    </button>
</div>
<div id="cd1-overlay" style="display:none;position:fixed;inset:0;z-index:299;background:transparent;"></div>
<div id="cd1-dialog" style="display:none;position:fixed;top:50%;left:50%;transform:translate(-50%,-50%);z-index:300;background:#0f1d30;border:1px solid #1e3a5f;border-radius:12px;padding:1.25rem;width:520px;max-width:90vw;box-shadow:0 8px 32px rgba(0,0,0,0.6);">
    <div style="font-size:0.9rem;font-weight:600;color:#e8f0f8;margin-bottom:0.75rem;">UNC Connector — Port 49218</div>
    <div style="display:flex;gap:0.5rem;margin-bottom:0.75rem;flex-wrap:wrap;align-items:center;">
        <select id="cd1-action" style="background:#132a47;color:#e8f0f8;border:1px solid #1e3a5f;border-radius:8px;padding:0.45rem 2rem 0.45rem 0.75rem;font-size:0.8rem;cursor:pointer;">
            <option value="COLLEGES">List Schools</option>
            <option value="DEPARTMENTS|College of Arts and Sciences">Arts & Sciences Depts</option>
            <option value="DEPARTMENTS|School of Medicine">Medicine Depts</option>
            <option value="SEARCH|biology">Search Courses</option>
            <option value="ADMIN">Administration</option>
            <option value="STATUS">Server Status</option>
        </select>
        <button onclick="cd1Send()" style="background:#4B9CD3;color:#fff;border:none;border-radius:8px;padding:0.45rem 1rem;font-size:0.8rem;font-weight:600;cursor:pointer;">Send</button>
        <button onclick="cd1Ok()" style="background:#4B9CD3;color:#fff;border:none;border-radius:8px;padding:0.45rem 1rem;font-size:0.8rem;font-weight:600;cursor:pointer;">OK</button>
    </div>
    <div style="display:flex;align-items:center;gap:0.5rem;margin-bottom:0.75rem;">
        <label style="display:flex;align-items:center;gap:0.4rem;color:#8fafc8;font-size:0.75rem;cursor:pointer;">
            <input type="checkbox" id="cd1-direct-port" style="accent-color:#4B9CD3;width:14px;height:14px;cursor:pointer;"/>
            Direct Port (bypass Strernary™ 20000)
        </label>
        <span id="cd1-mode-badge" style="font-size:0.65rem;background:#132a47;color:#4B9CD3;padding:0.2rem 0.5rem;border-radius:4px;">STRERNARY</span>
    </div>
    <textarea id="cd1-textarea" placeholder="Connection idle... Go Heels!" spellcheck="false" style="width:100%;min-height:140px;background:#fff;color:#111;border:1px solid #1e3a5f;border-radius:8px;padding:0.75rem;font-family:monospace;font-size:0.8rem;resize:vertical;"></textarea>
</div>
<script>window.CD1_MODULE_PORT = "49218";</script>
<script src="js/cd1-connector.js"></script>

<section class="section">
    <div class="section-inner">
        <h2>Schools & Colleges</h2>
        <div class="school-grid">
            <div class="school-card"><h4>College of Arts and Sciences</h4><p>Largest academic unit — humanities, natural sciences, social sciences, fine arts</p></div>
            <div class="school-card"><h4>Kenan-Flagler Business School</h4><p>Top-ranked MBA, accounting, finance, marketing, entrepreneurship</p></div>
            <div class="school-card"><h4>School of Dentistry</h4><p>DDS program, oral surgery, periodontics, pediatric dentistry</p></div>
            <div class="school-card"><h4>School of Education</h4><p>Teacher preparation, educational leadership, human development</p></div>
            <div class="school-card"><h4>Gillings School of Global Public Health</h4><p>Biostatistics, epidemiology, health policy, nutrition, environmental sciences</p></div>
            <div class="school-card"><h4>Graduate School</h4><p>Master's and doctoral programs across all disciplines</p></div>
            <div class="school-card"><h4>School of Information and Library Science</h4><p>MSIS, MSLS, bioinformatics, digital curation</p></div>
            <div class="school-card"><h4>School of Law</h4><p>JD program, constitutional law, corporate law, environmental law</p></div>
            <div class="school-card"><h4>School of Medicine</h4><p>MD program, 25+ departments, UNC Health system partnership</p></div>
            <div class="school-card"><h4>School of Nursing</h4><p>BSN, MSN, DNP — ranked among top nursing schools nationally</p></div>
            <div class="school-card"><h4>Eshelman School of Pharmacy</h4><p>PharmD, pharmaceutical sciences, drug development</p></div>
            <div class="school-card"><h4>School of Social Work</h4><p>MSW program, clinical practice, community development</p></div>
            <div class="school-card"><h4>Hussman School of Journalism and Media</h4><p>Journalism, advertising, PR, media analytics</p></div>
            <div class="school-card"><h4>School of Government</h4><p>Public administration, local government, policy analysis</p></div>
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
                    <tr><td>Chancellor</td><td>Lee H. Roberts</td><td>Office of the Chancellor</td></tr>
                    <tr><td>Provost & Chief Academic Officer</td><td>Christopher Clemens</td><td>Office of the Provost</td></tr>
                    <tr><td>Executive Vice Chancellor & Provost</td><td>Robert A. Blouin</td><td>Office of the Provost</td></tr>
                    <tr><td>VC Research</td><td>Penny Gordon-Larsen</td><td>Office of the Vice Chancellor for Research</td></tr>
                    <tr><td>VC Student Affairs</td><td>Amy Johnson</td><td>Division of Student Affairs</td></tr>
                    <tr><td>VC Finance and Operations</td><td>Nate Knuffman</td><td>Finance and Operations</td></tr>
                    <tr><td>VC University Development</td><td>David Routh</td><td>University Development</td></tr>
                    <tr><td>VC Information Technology & CIO</td><td>Chris Kielt</td><td>Information Technology Services</td></tr>
                    <tr><td>Dean of Arts and Sciences</td><td>Terry Rhodes</td><td>College of Arts and Sciences</td></tr>
                    <tr><td>Dean of Kenan-Flagler</td><td>Mary-Ann Fitzgerald</td><td>Kenan-Flagler Business School</td></tr>
                    <tr><td>Dean of School of Medicine</td><td>Wesley Burks</td><td>School of Medicine</td></tr>
                    <tr><td>Athletics Director</td><td>Bubba Cunningham</td><td>Athletics</td></tr>
                    <tr><td>Faculty Chair</td><td>Mimi Chapman</td><td>Faculty Council</td></tr>
                </tbody>
            </table>
        </div>
    </div>
</section>

<section class="section">
    <div class="section-inner">
        <h2>Arts & Sciences Departments</h2>
        <div class="school-grid">
            <div class="school-card"><h4>Computer Science</h4><p>AI, systems, HCI, computational biology</p></div>
            <div class="school-card"><h4>Biology</h4><p>Ecology, genetics, marine biology, neurobiology</p></div>
            <div class="school-card"><h4>Chemistry</h4><p>Organic, inorganic, physical, analytical</p></div>
            <div class="school-card"><h4>Economics</h4><p>Econometrics, labor, international trade, public finance</p></div>
            <div class="school-card"><h4>English and Comparative Literature</h4><p>Creative writing, literary theory, rhetoric</p></div>
            <div class="school-card"><h4>History</h4><p>American, European, Latin American, public history</p></div>
            <div class="school-card"><h4>Mathematics</h4><p>Pure math, applied math, analysis, topology</p></div>
            <div class="school-card"><h4>Physics and Astronomy</h4><p>Astrophysics, nuclear physics, condensed matter</p></div>
            <div class="school-card"><h4>Political Science</h4><p>American politics, comparative, international relations</p></div>
            <div class="school-card"><h4>Psychology and Neuroscience</h4><p>Clinical, cognitive, developmental, social</p></div>
            <div class="school-card"><h4>Statistics and Operations Research</h4><p>Biostatistics, machine learning, data science</p></div>
            <div class="school-card"><h4>Sociology</h4><p>Race and ethnicity, inequality, medical sociology</p></div>
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
                    <tr><td>Backend Port</td><td><code>49218</code></td></tr>
                    <tr><td>Protocol</td><td><code>NWE-UNC</code> (TCP socket)</td></tr>
                    <tr><td>Database</td><td><code>nwe_unc</code> (MySQL)</td></tr>
                    <tr><td>AI Inference</td><td><code>Strernary™ port 20000</code> (DJL/PyTorch)</td></tr>
                    <tr><td>Webapp Context</td><td><code>/california-unc</code></td></tr>
                    <tr><td>University URL</td><td><a href="https://www.unc.edu">unc.edu</a></td></tr>
                    <tr><td>Location</td><td>Chapel Hill, North Carolina</td></tr>
                    <tr><td>Founded</td><td>1789 (America's first public university)</td></tr>
                    <tr><td>Enrollment</td><td>30,000+ students</td></tr>
                    <tr><td>Installer Tech ID</td><td>Max Rupplin</td></tr>
                </tbody>
            </table>
        </div>
    </div>
</section>

<section class="section">
    <div class="section-inner">
        <h2>Commands (Telnet — port 49218)</h2>
        <div class="table-wrap">
            <table>
                <thead><tr><th>Command</th><th>Description</th></tr></thead>
                <tbody>
                    <tr><td><code>COLLEGES</code></td><td>List all UNC schools and colleges</td></tr>
                    <tr><td><code>DEPARTMENTS|&lt;school&gt;</code></td><td>List departments within a school</td></tr>
                    <tr><td><code>SEARCH|&lt;keyword&gt;</code></td><td>Search courses and departments</td></tr>
                    <tr><td><code>QUERY|&lt;school&gt;|&lt;text&gt;</code></td><td>Submit query (AI-assisted response)</td></tr>
                    <tr><td><code>ADMIN</code></td><td>List university administration</td></tr>
                    <tr><td><code>STATUS</code></td><td>Server health check</td></tr>
                    <tr><td><code>QUIT</code></td><td>Disconnect</td></tr>
                </tbody>
            </table>
        </div>
    </div>
</section>

<footer class="footer"><div><span>&#169; 2026 MEARVK LLC. UNC Chapel Hill™ — Carolina Blue. Go Heels!</span></div></footer>
</body>
</html>
