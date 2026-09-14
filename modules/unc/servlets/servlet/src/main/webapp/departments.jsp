<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/>
    <link rel="preconnect" href="https://fonts.googleapis.com"/><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin/><link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:ital,wght@0,300;0,400;0,500;0,600;0,700;1,400;1,600&display=swap" rel="stylesheet"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>Departments — UNC Chapel Hill™</title>
    <link rel="stylesheet" href="css/style.css"/>
    <script src="js/scroll-preserve.js"></script>
    <script src="js/nwe-readme-viewer.js"></script>
</head>
<body>
<nav class="nav"><div class="nav-inner">
    <span class="nav-brand">🐏 UNC Chapel Hill™</span>
    <ul class="nav-links">
        <li><a href="index.jsp">Overview</a></li>
        <li><a href="schools.jsp">Schools</a></li>
        <li><a href="departments.jsp" class="active">Departments</a></li>
        <li><a href="messaging.jsp">Messages</a></li>
        <li><a href="profile.jsp">Profile</a></li>
        <li><a href="status.jsp">Status</a></li>
    </ul>
<div class="nav-actions"><%@ include file="auth-buttons.jsp" %></div></div></nav>

<section class="hero" style="padding:4rem 2rem;">
    <div class="hero-inner">
        <span class="hero-tag">Academic Departments</span>
        <h1>Departments</h1>
        <p>Key departments within the College of Arts & Sciences and professional schools.</p>
    </div>
</section>

<section class="section">
    <div class="section-inner">
        <h2>College of Arts &amp; Sciences</h2>
        <div class="table-wrap"><table>
            <thead><tr><th>Department</th><th>Division</th><th>Focus</th></tr></thead>
            <tbody>
                <tr><td>Computer Science</td><td>Natural Sciences</td><td>Systems, AI, HCI, algorithms, graphics</td></tr>
                <tr><td>Mathematics</td><td>Natural Sciences</td><td>Pure, applied, statistics</td></tr>
                <tr><td>Physics & Astronomy</td><td>Natural Sciences</td><td>Particle physics, astrophysics, condensed matter</td></tr>
                <tr><td>Chemistry</td><td>Natural Sciences</td><td>Organic, inorganic, analytical, biochemistry</td></tr>
                <tr><td>Biology</td><td>Natural Sciences</td><td>Ecology, genetics, molecular, marine biology</td></tr>
                <tr><td>Statistics & Operations Research</td><td>Natural Sciences</td><td>Data science, optimization, probability</td></tr>
                <tr><td>English & Comparative Literature</td><td>Humanities</td><td>Literature, creative writing, rhetoric</td></tr>
                <tr><td>History</td><td>Humanities</td><td>American, European, global, public history</td></tr>
                <tr><td>Philosophy</td><td>Humanities</td><td>Ethics, logic, metaphysics, political philosophy</td></tr>
                <tr><td>Political Science</td><td>Social Sciences</td><td>American politics, comparative, IR, theory</td></tr>
                <tr><td>Economics</td><td>Social Sciences</td><td>Micro, macro, econometrics, development</td></tr>
                <tr><td>Psychology & Neuroscience</td><td>Social Sciences</td><td>Cognitive, clinical, developmental, behavioral neuro</td></tr>
                <tr><td>Sociology</td><td>Social Sciences</td><td>Inequality, culture, organizations, demography</td></tr>
                <tr><td>Music</td><td>Fine Arts</td><td>Performance, composition, musicology</td></tr>
                <tr><td>Art & Art History</td><td>Fine Arts</td><td>Studio art, visual studies, museum studies</td></tr>
                <tr><td>Dramatic Art</td><td>Fine Arts</td><td>Acting, directing, design, playwriting</td></tr>
            </tbody>
        </table></div>
    </div>
</section>

<section class="section">
    <div class="section-inner">
        <h2>Professional School Departments</h2>
        <div class="table-wrap"><table>
            <thead><tr><th>Department</th><th>School</th><th>Focus</th></tr></thead>
            <tbody>
                <tr><td>Biomedical Engineering</td><td>Engineering (joint)</td><td>Medical devices, imaging, tissue engineering</td></tr>
                <tr><td>Epidemiology</td><td>Public Health</td><td>Infectious disease, chronic disease, methods</td></tr>
                <tr><td>Biostatistics</td><td>Public Health</td><td>Clinical trials, genomics, causal inference</td></tr>
                <tr><td>Health Policy & Management</td><td>Public Health</td><td>Healthcare systems, economics, quality</td></tr>
                <tr><td>Pathology & Lab Medicine</td><td>Medicine</td><td>Diagnostic, molecular, forensic pathology</td></tr>
                <tr><td>Pharmacology</td><td>Medicine</td><td>Drug discovery, neuropharmacology</td></tr>
                <tr><td>Genetics</td><td>Medicine</td><td>Human genetics, genomics, gene therapy</td></tr>
            </tbody>
        </table></div>
    </div>
</section>

<footer class="footer"><span>UNC Chapel Hill™ — Departments — MEARVK LLC — NitroWebExpress™ 2026</span></footer>
</body>
</html>
