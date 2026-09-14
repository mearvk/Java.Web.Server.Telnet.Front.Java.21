<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>Colleges & Schools — DukeUniversity™</title>
    <link rel="stylesheet" href="css/style.css"/>
    <link rel="preconnect" href="https://fonts.googleapis.com"/>
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin/>
    <link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:ital,wght@0,300;0,400;0,500;0,600;0,700;1,400;1,600&display=swap" rel="stylesheet"/>
    <script src="js/scroll-preserve.js"></script>
    <style>
        .college-grid { display:grid; grid-template-columns:repeat(auto-fill, minmax(340px, 1fr)); gap:1.25rem; margin-top:1.5rem; }
        .college-card { background:var(--bg-card); border:1px solid var(--border); border-radius:var(--radius-lg); padding:1.5rem; transition:border-color 0.2s, transform 0.2s; }
        .college-card:hover { border-color:var(--accent-light); transform:translateY(-2px); }
        .college-card h3 { font-size:1.1rem; font-weight:700; margin-bottom:0.5rem; color:var(--text-primary); }
        .college-card p { font-size:0.85rem; color:var(--text-secondary); line-height:1.5; margin-bottom:1rem; }
        .college-card .meta { font-size:0.75rem; color:var(--text-muted); margin-bottom:0.75rem; }
        .college-card .meta span { display:inline-block; margin-right:1rem; }
        .college-card .card-links { display:flex; gap:0.75rem; flex-wrap:wrap; }
        .college-card .card-links a { font-size:0.8rem; color:var(--accent-light); font-weight:500; }
        .college-card .card-links a:hover { color:#fff; }
        .college-card .card-links .ext { color:var(--text-muted); }
        .college-card .card-links .ext:hover { color:var(--accent-light); }
    </style>
</head>
<body>
<nav class="nav"><div class="nav-inner">
    <span class="nav-brand">DukeUniversity™</span>
    <ul class="nav-links">
        <li><a href="index.jsp">Overview</a></li>
        <li><a href="colleges.jsp" class="active">Colleges</a></li>
        <li><a href="query.jsp">Query</a></li>
        <li><a href="messaging.jsp">Messages</a></li>
        <li><a href="status.jsp">Status</a></li>
    </ul>
    <div class="nav-actions"><a href="query.jsp" class="nav-cta">Query College →</a></div>
</div></nav>

<section class="hero">
    <div class="hero-inner">
        <span class="hero-tag">10 Schools & Colleges</span>
        <h1>Duke Colleges & Schools</h1>
        <p>Duke University is home to 10 schools — each with its own character, programs, and significant opportunity for cross-disciplinary collaboration. Select a school below to view details and communicate directly.</p>
    </div>
</section>

<section class="section">
    <div class="section-inner">
        <h2>Undergraduate & Graduate Schools</h2>
        <div class="college-grid">

            <div class="college-card">
                <h3>Trinity College of Arts & Sciences</h3>
                <p>The intellectual heart of Duke — a rigorous liberal arts education with 35 departments across humanities, natural sciences, and social sciences.</p>
                <div class="meta"><span>~6,500 undergrads</span><span>35 departments</span></div>
                <div class="card-links">
                    <a href="colleges/trinity.jsp">View & Contact →</a>
                    <a href="https://trinity.duke.edu" target="_blank" class="ext">Official Site ↗</a>
                </div>
            </div>

            <div class="college-card">
                <h3>Pratt School of Engineering</h3>
                <p>Engineering excellence in AI, quantum computing, robotics, and biomedical engineering. Departments: BME, CEE, ECE, MEMS, and Computer Science.</p>
                <div class="meta"><span>~1,400 undergrads</span><span>~1,200 grad students</span></div>
                <div class="card-links">
                    <a href="colleges/pratt.jsp">View & Contact →</a>
                    <a href="https://pratt.duke.edu" target="_blank" class="ext">Official Site ↗</a>
                </div>
            </div>

            <div class="college-card">
                <h3>Fuqua School of Business</h3>
                <p>Top-ranked MBA and executive education programs. Global network of leaders committed to bringing out the strength in others.</p>
                <div class="meta"><span>~1,800 students</span><span>5 programs</span></div>
                <div class="card-links">
                    <a href="colleges/fuqua.jsp">View & Contact →</a>
                    <a href="https://www.fuqua.duke.edu" target="_blank" class="ext">Official Site ↗</a>
                </div>
            </div>

            <div class="college-card">
                <h3>School of Law</h3>
                <p>Top 10 law school with strength in international, corporate, intellectual property, and environmental law. JD, LLM, SJD, and joint degrees.</p>
                <div class="meta"><span>~640 JD students</span><span>~150 LLM/SJD</span></div>
                <div class="card-links">
                    <a href="colleges/law.jsp">View & Contact →</a>
                    <a href="https://law.duke.edu" target="_blank" class="ext">Official Site ↗</a>
                </div>
            </div>

            <div class="college-card">
                <h3>School of Medicine</h3>
                <p>World-class medical research and education. Major areas: genomics, neuroscience, cancer biology, immunology. MD, PhD, and MD-PhD programs.</p>
                <div class="meta"><span>~500 MD students</span><span>1,000+ researchers</span></div>
                <div class="card-links">
                    <a href="colleges/medicine.jsp">View & Contact →</a>
                    <a href="https://medschool.duke.edu" target="_blank" class="ext">Official Site ↗</a>
                </div>
            </div>

            <div class="college-card">
                <h3>Nicholas School of the Environment</h3>
                <p>Environmental science, policy, and management. Includes the Duke Marine Lab in Beaufort, NC. Preparing leaders for an interconnected world.</p>
                <div class="meta"><span>~350 students</span><span>Marine Lab</span></div>
                <div class="card-links">
                    <a href="colleges/nicholas.jsp">View & Contact →</a>
                    <a href="https://nicholas.duke.edu" target="_blank" class="ext">Official Site ↗</a>
                </div>
            </div>

            <div class="college-card">
                <h3>Sanford School of Public Policy</h3>
                <p>Top 10 public policy school. Prepares students for leadership, civic engagement, and public service through rigorous analysis and real-world engagement.</p>
                <div class="meta"><span>~250 grad</span><span>~200 undergrad majors</span></div>
                <div class="card-links">
                    <a href="colleges/sanford.jsp">View & Contact →</a>
                    <a href="https://sanford.duke.edu" target="_blank" class="ext">Official Site ↗</a>
                </div>
            </div>

            <div class="college-card">
                <h3>Divinity School</h3>
                <p>The spiritual center of Duke — grounded in Christian Scripture and theology, cultivating innovative approaches to ministry in its many forms. Wesleyan tradition.</p>
                <div class="meta"><span>~400 students</span><span>6 degree programs</span></div>
                <div class="card-links">
                    <a href="colleges/divinity.jsp">View & Contact →</a>
                    <a href="https://divinity.duke.edu" target="_blank" class="ext">Official Site ↗</a>
                </div>
            </div>

            <div class="college-card">
                <h3>School of Nursing</h3>
                <p>Consistently ranked top 5 nationally. Prepares nurse leaders and innovators through transformative excellence in education, clinical practice, and nursing science.</p>
                <div class="meta"><span>~1,000 students</span><span>Duke Health partner</span></div>
                <div class="card-links">
                    <a href="colleges/nursing.jsp">View & Contact →</a>
                    <a href="https://nursing.duke.edu" target="_blank" class="ext">Official Site ↗</a>
                </div>
            </div>

            <div class="college-card">
                <h3>Graduate School</h3>
                <p>Oversees 80+ doctoral and master's programs across the entire university. Strong research focus with interdisciplinary collaboration at its core.</p>
                <div class="meta"><span>~4,000 grad students</span><span>80+ programs</span></div>
                <div class="card-links">
                    <a href="colleges/graduate.jsp">View & Contact →</a>
                    <a href="https://gradschool.duke.edu" target="_blank" class="ext">Official Site ↗</a>
                </div>
            </div>

        </div>
    </div>
</section>

<section class="section">
    <div class="section-inner">
        <h2>Communication Process</h2>
        <p style="color:var(--text-secondary); font-size:0.9rem; max-width:700px;">
            Each college page includes a direct communication form. When you submit an inquiry:
        </p>
        <div class="table-wrap" style="margin-top:1rem;">
            <table>
                <thead><tr><th>Step</th><th>Process</th><th>Detail</th></tr></thead>
                <tbody>
                    <tr><td>1</td><td>Form Submission</td><td>Your name, email, subject, inquiry type, and message are collected via HTTP POST</td></tr>
                    <tr><td>2</td><td>Backend Routing</td><td>The JSP connects to the DukeUniversity™ server (TCP port 49213) and sends: <code>QUERY|&lt;college&gt;|&lt;message&gt;</code></td></tr>
                    <tr><td>3</td><td>AI Processing</td><td>The server routes your query through Strernary™ AI (port 20000) for intelligent response generation</td></tr>
                    <tr><td>4</td><td>Database Storage</td><td>Your query is stored in <code>nwe_duke.college_queries</code> for institutional record and follow-up</td></tr>
                    <tr><td>5</td><td>Response</td><td>An AI-assisted response is returned immediately; human follow-up may occur via the email you provide</td></tr>
                </tbody>
            </table>
        </div>
    </div>
</section>

<section class="section">
    <div class="section-inner">
        <h2>Duke University — At a Glance</h2>
        <div class="table-wrap">
            <table>
                <thead><tr><th>Property</th><th>Value</th></tr></thead>
                <tbody>
                    <tr><td>Founded</td><td>1838 (as Brown's Schoolhouse), 1924 (as Duke University)</td></tr>
                    <tr><td>Location</td><td>Durham, North Carolina, USA</td></tr>
                    <tr><td>Total Enrollment</td><td>~17,000 (6,700 undergrad, 10,300 grad/professional)</td></tr>
                    <tr><td>Endowment</td><td>~$12.7 billion</td></tr>
                    <tr><td>Majors Available</td><td>53 majors, 52 minors, 23 certificates</td></tr>
                    <tr><td>Campus</td><td>8,709 acres (Duke Forest included)</td></tr>
                    <tr><td>Motto</td><td><em>Eruditio et Religio</em> (Knowledge and Faith)</td></tr>
                    <tr><td>Athletics</td><td>NCAA Division I — ACC (Blue Devils)</td></tr>
                    <tr><td>NWE Interface Port</td><td><code>49213</code> (TCP, NIO masquerade)</td></tr>
                </tbody>
            </table>
        </div>
    </div>
</section>

<footer class="footer"><div><span>© 2026 MEARVK LLC. All rights reserved. DukeUniversity™ — Duke Blue.</span></div></footer>
</body>
</html>
