<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/><meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>UK Government Departments — AE6E66™</title>
    <link rel="stylesheet" href="css/style.css"/>
    <link rel="preconnect" href="https://fonts.googleapis.com"/><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin/>
    <link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:wght@300;400;500;600;700&display=swap" rel="stylesheet"/>
    <style>
        .dept-grid { display:grid; grid-template-columns:repeat(auto-fill, minmax(320px, 1fr)); gap:1rem; margin-top:1.5rem; }
        .dept-card { background:var(--bg-card); border:1px solid var(--border); border-radius:8px; padding:1.25rem; transition:border-color 0.2s, transform 0.2s; }
        .dept-card:hover { border-color:var(--accent); transform:translateY(-2px); }
        .dept-card h3 { font-size:1rem; font-weight:700; color:#fff; margin-bottom:0.4rem; }
        .dept-card p { font-size:0.8rem; color:var(--text-secondary); line-height:1.4; margin-bottom:0.75rem; }
        .dept-card .card-link { font-size:0.8rem; color:var(--accent); font-weight:500; }
        .dept-card .card-link:hover { color:#fff; }
        .dept-card .host { font-size:0.7rem; color:var(--text-muted); font-family:monospace; }
    </style>
</head>
<body>
<nav class="nav"><div class="nav-inner">
    <span class="nav-brand">AE6E66™</span>
    <ul class="nav-links">
        <li><a href="index.jsp">Overview</a></li>
        <li><a href="contacts.jsp">Contacts</a></li>
        <li><a href="departments.jsp" class="active">Departments</a></li>
        <li><a href="sent.jsp">Sent</a></li>
        <li><a href="status.jsp">Status</a></li>
    </ul>
</div></nav>

<section class="hero" style="padding:4rem 2rem;"><div class="hero-inner">
    <span class="hero-tag">UK Government — 18 Departments</span>
    <h1>Public Departments</h1>
    <p>Contact forms for all major UK government departments, public services, and institutions. Messages are stored locally, forwarded to the official .gov.uk site, and the site's public TLS key and full HTML response are captured and stored in the database.</p>
</div></section>

<section class="section"><div class="section-inner">
    <h2>Health & Social Services</h2>
    <div class="dept-grid">
        <div class="dept-card">
            <h3>NHS — National Health Service</h3>
            <p>Health inquiries, patient feedback, GP services, prescriptions, mental health, and emergency information.</p>
            <span class="host">www.nhs.uk</span><br/>
            <a href="departments/nhs.jsp" class="card-link">Contact NHS →</a>
        </div>
        <div class="dept-card">
            <h3>Department of Health and Social Care</h3>
            <p>Health policy, social care reform, public health strategy, and workforce planning.</p>
            <span class="host">www.gov.uk</span><br/>
            <a href="departments/health.jsp" class="card-link">Contact DHSC →</a>
        </div>
        <div class="dept-card">
            <h3>Department for Work and Pensions</h3>
            <p>Benefits, pensions, employment support, disability services, and child maintenance.</p>
            <span class="host">www.gov.uk</span><br/>
            <a href="departments/dwp.jsp" class="card-link">Contact DWP →</a>
        </div>
    </div>

    <h2 style="margin-top:2.5rem;">Housing, Environment & Transport</h2>
    <div class="dept-grid">
        <div class="dept-card">
            <h3>Ministry of Housing, Communities & Local Government</h3>
            <p>Housing policy, planning, local government, building safety, and homelessness.</p>
            <span class="host">www.gov.uk</span><br/>
            <a href="departments/housing.jsp" class="card-link">Contact MHCLG →</a>
        </div>
        <div class="dept-card">
            <h3>Department for Environment, Food & Rural Affairs</h3>
            <p>Environment protection, food standards, farming, rural communities, and wildlife.</p>
            <span class="host">www.gov.uk</span><br/>
            <a href="departments/environment.jsp" class="card-link">Contact DEFRA →</a>
        </div>
        <div class="dept-card">
            <h3>Department for Transport</h3>
            <p>Roads, rail, aviation, maritime, driving licences, and road safety.</p>
            <span class="host">www.gov.uk</span><br/>
            <a href="departments/transport.jsp" class="card-link">Contact DfT →</a>
        </div>
        <div class="dept-card">
            <h3>Department for Energy Security & Net Zero</h3>
            <p>Energy policy, net zero strategy, renewable energy, nuclear, and fuel poverty.</p>
            <span class="host">www.gov.uk</span><br/>
            <a href="departments/energy.jsp" class="card-link">Contact DESNZ →</a>
        </div>
    </div>

    <h2 style="margin-top:2.5rem;">Finance & Economy</h2>
    <div class="dept-grid">
        <div class="dept-card">
            <h3>HM Treasury</h3>
            <p>Economic and fiscal policy, public spending, financial services regulation, and tax policy.</p>
            <span class="host">www.gov.uk</span><br/>
            <a href="departments/treasury.jsp" class="card-link">Contact Treasury →</a>
        </div>
        <div class="dept-card">
            <h3>HM Revenue & Customs</h3>
            <p>Tax collection, customs, National Insurance, tax credits, and VAT.</p>
            <span class="host">www.gov.uk</span><br/>
            <a href="departments/hmrc.jsp" class="card-link">Contact HMRC →</a>
        </div>
        <div class="dept-card">
            <h3>Department for Business and Trade</h3>
            <p>Business support, international trade, exports, investment, and enterprise.</p>
            <span class="host">www.gov.uk</span><br/>
            <a href="departments/trade.jsp" class="card-link">Contact DBT →</a>
        </div>
    </div>

    <h2 style="margin-top:2.5rem;">Security, Defence & Justice</h2>
    <div class="dept-grid">
        <div class="dept-card">
            <h3>Home Office</h3>
            <p>Immigration, passports, policing, counter-terrorism, and border control.</p>
            <span class="host">www.gov.uk</span><br/>
            <a href="departments/home-office.jsp" class="card-link">Contact Home Office →</a>
        </div>
        <div class="dept-card">
            <h3>Ministry of Defence</h3>
            <p>UK armed forces, defence policy, veterans support, and military operations.</p>
            <span class="host">www.gov.uk</span><br/>
            <a href="departments/defence.jsp" class="card-link">Contact MoD →</a>
        </div>
        <div class="dept-card">
            <h3>Ministry of Justice</h3>
            <p>Courts, prisons, probation, legal aid, and constitutional reform.</p>
            <span class="host">www.gov.uk</span><br/>
            <a href="departments/justice.jsp" class="card-link">Contact MoJ →</a>
        </div>
        <div class="dept-card">
            <h3>Foreign, Commonwealth & Development Office</h3>
            <p>Foreign affairs, diplomacy, international development, and consular services.</p>
            <span class="host">www.gov.uk</span><br/>
            <a href="departments/foreign-office.jsp" class="card-link">Contact FCDO →</a>
        </div>
    </div>

    <h2 style="margin-top:2.5rem;">Education, Culture & Libraries</h2>
    <div class="dept-grid">
        <div class="dept-card">
            <h3>Department for Education</h3>
            <p>Education policy, schools, higher education, apprenticeships, and children's services.</p>
            <span class="host">www.gov.uk</span><br/>
            <a href="departments/education.jsp" class="card-link">Contact DfE →</a>
        </div>
        <div class="dept-card">
            <h3>Department for Culture, Media & Sport</h3>
            <p>Arts, media, broadcasting, sport, tourism, and digital economy.</p>
            <span class="host">www.gov.uk</span><br/>
            <a href="departments/culture.jsp" class="card-link">Contact DCMS →</a>
        </div>
        <div class="dept-card">
            <h3>British Library</h3>
            <p>UK national library — reading rooms, research services, document supply, and digital resources.</p>
            <span class="host">www.bl.uk</span><br/>
            <a href="departments/libraries.jsp" class="card-link">Contact British Library →</a>
        </div>
    </div>

    <h2 style="margin-top:2.5rem;">Parliament</h2>
    <div class="dept-grid">
        <div class="dept-card">
            <h3>UK Parliament</h3>
            <p>House of Commons, House of Lords — legislative inquiries, select committees, public petitions.</p>
            <span class="host">www.parliament.uk</span><br/>
            <a href="departments/parliament.jsp" class="card-link">Contact Parliament →</a>
        </div>
    </div>
</div></section>

<section class="section"><div class="section-inner">
    <h2>Data Handling</h2>
    <div class="table-wrap"><table>
        <thead><tr><th>Step</th><th>Action</th><th>Storage</th></tr></thead>
        <tbody>
            <tr><td>1</td><td>Form submission (HTTP POST)</td><td><code>outbound_messages</code> — sender, subject, category, department, message body</td></tr>
            <tr><td>2</td><td>Forward to .gov.uk / .uk site</td><td>HTTP POST to target URL</td></tr>
            <tr><td>3</td><td>Capture response</td><td><code>outbound_messages.response_text</code> — full HTML/XHTML response (LONGTEXT)</td></tr>
            <tr><td>4</td><td>Capture response code</td><td><code>outbound_messages.response_code</code> — HTTP status</td></tr>
            <tr><td>5</td><td>Fetch TLS public key</td><td><code>site_public_keys</code> — subject, issuer, algorithm, key (Base64), validity</td></tr>
        </tbody>
    </table></div>
</div></section>

<footer class="footer"><div><span>© 2026 MEARVK LLC. AE6E66™ — Emerald Green. UK Government Contact Module.</span></div></footer>
</body></html>
