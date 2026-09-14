<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.Properties" %>
<%
    // DB connection
    Connection conn = null;
    boolean dbOk = false;
    int perceptionCount = 0, cognitionCount = 0, modulationCount = 0, expressionCount = 0, curveCount = 0, logCount = 0;
    int saimptomCount = 0, stereoRecovered = 0, domainCount = 16;
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        conn = DriverManager.getConnection("jdbc:mysql://127.0.0.1:3306/nwe_tandem_equals", "root", "$$Ironman1");
        dbOk = true;
        Statement st = conn.createStatement();
        ResultSet rs = st.executeQuery("SELECT (SELECT COUNT(*) FROM perception) as p, (SELECT COUNT(*) FROM cognition) as c, (SELECT COUNT(*) FROM modulation) as m, (SELECT COUNT(*) FROM expression) as e, (SELECT COUNT(*) FROM control_curve) as cc, (SELECT COUNT(*) FROM intellect_log) as il");
        if (rs.next()) { perceptionCount = rs.getInt(1); cognitionCount = rs.getInt(2); modulationCount = rs.getInt(3); expressionCount = rs.getInt(4); curveCount = rs.getInt(5); logCount = rs.getInt(6); }
        rs.close(); st.close();
        // Saimptom sessions count
        try { st = conn.createStatement(); rs = st.executeQuery("SELECT COUNT(*) FROM saimptom_sessions"); if (rs.next()) saimptomCount = rs.getInt(1); rs.close(); st.close(); } catch (Exception ignored) {}
        try { st = conn.createStatement(); rs = st.executeQuery("SELECT COUNT(*) FROM saimptom_sessions WHERE stereo_recovered = TRUE"); if (rs.next()) stereoRecovered = rs.getInt(1); rs.close(); st.close(); } catch (Exception ignored) {}
    } catch (Exception e) { dbOk = false; }
    if (conn != null) try { conn.close(); } catch (Exception e) {}
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <link rel="preconnect" href="https://fonts.googleapis.com"/><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin/><link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:wght@300;400;500;600;700;800&display=swap" rel="stylesheet"/>
    <title>TandemEquals™ — Human Intellect Modulator</title>
    <link rel="stylesheet" href="css/style.css"/>
</head>
<body>
<nav class="nav"><div class="nav-inner">
    <span class="nav-brand">TandemEquals™</span>
    <ul class="nav-links">
        <li><a href="index.jsp" class="active">Overview</a></li>
        <li><a href="layers.jsp">Layers</a></li>
        <li><a href="curves.jsp">Control Curves</a></li>
        <li><a href="messaging.jsp">Messages</a></li>
        <li><a href="status.jsp">Status</a></li>
    </ul>
<div class="nav-actions"><%@ include file="auth-buttons.jsp" %></div></div></nav>

<section class="hero">
    <div class="hero-inner">
        <span class="hero-tag">Outward Dilemma Resolution via Saimptom</span>
        <h1>Tandem<span>Equals</span>™</h1>
        <p>42×42 choice matrix. Stereo mind recovery in ~12 answers. Resolves the saimptom into CHOICE and EQUAL NOISE. Reveals province wisdom hidden by overconfidence. White and Red.</p>
    </div>
</section>

<!-- Core Concepts -->
<section class="section">
    <div class="section-inner">
        <div class="layer-grid">
            <div class="layer-card">
                <span class="layer-num" style="color:var(--layer1);">42²</span>
                <h3 style="color:var(--layer1);">Saimptom Matrix</h3>
                <p>1764-cell choice matrix. Rows = consideration. Columns = consequence. Tandem lockstep.</p>
                <div class="layer-bar" style="background:var(--layer1);"></div>
            </div>
            <div class="layer-card">
                <span class="layer-num" style="color:var(--layer2);">12</span>
                <h3 style="color:var(--layer2);">Stereo Recovery</h3>
                <p>~12 answers flatten overconfidence and restore the stereo mind from mono collapse.</p>
                <div class="layer-bar" style="background:var(--layer2);"></div>
            </div>
            <div class="layer-card">
                <span class="layer-num" style="color:var(--layer3);">±</span>
                <h3 style="color:var(--layer3);">Choice + Noise</h3>
                <p>CHOICE = resolved direction. EQUAL NOISE = honest residual ambiguity made visible.</p>
                <div class="layer-bar" style="background:var(--layer3);"></div>
            </div>
            <div class="layer-card">
                <span class="layer-num" style="color:var(--layer4);">⊕</span>
                <h3 style="color:var(--layer4);">Province Wisdom</h3>
                <p>Your contextual truth — local, personal, situational — hidden by the unkind mono mind.</p>
                <div class="layer-bar" style="background:var(--layer4);"></div>
            </div>
        </div>
    </div>
</section>

<!-- How It Works -->
<section class="section">
    <div class="section-inner">
        <h2>Stereo Mind Recovery</h2>
        <div class="curve-path">
            <div class="curve-node" style="border-color:var(--layer1);color:var(--layer1);">
                <strong>Domain</strong><span style="font-size:0.55rem;">select area</span>
            </div>
            <span class="curve-arrow">→</span>
            <div class="curve-node" style="border-color:var(--layer2);color:var(--layer2);">
                <strong>12 Answers</strong><span style="font-size:0.55rem;">-1000 to +1000</span>
            </div>
            <span class="curve-arrow">→</span>
            <div class="curve-node" style="border-color:var(--layer3);color:var(--layer3);">
                <strong>Resolve</strong><span style="font-size:0.55rem;">flatten mono</span>
            </div>
            <span class="curve-arrow">→</span>
            <div class="curve-node" style="border-color:var(--layer4);color:var(--layer4);">
                <strong>Stereo</strong><span style="font-size:0.55rem;">both ends visible</span>
            </div>
        </div>
        <p style="text-align:center;font-size:0.8rem;color:var(--text-muted);max-width:600px;margin:1rem auto 0;">A saimptom is merely a choice but not both ends obvious. Overconfidence collapses stereo to mono — you see only ONE path. TandemEquals makes the noise visible and equal, revealing province wisdom.</p>
    </div>
</section>

<!-- Stats -->
<section class="section">
    <div class="section-inner">
        <h2>System State</h2>
        <% if (!dbOk) { %>
        <p style="color:var(--accent);">Database offline. Run <code>bash modules/tandem-equals/servlets/setup-db.sh</code></p>
        <% } else { %>
        <div class="stat-row">
            <div class="stat-box"><div class="num"><%= saimptomCount %></div><div class="lbl">Saimptoms Resolved</div></div>
            <div class="stat-box"><div class="num"><%= stereoRecovered %></div><div class="lbl">Stereo Recovered</div></div>
            <div class="stat-box"><div class="num"><%= domainCount %></div><div class="lbl">Choice Domains</div></div>
            <div class="stat-box"><div class="num">42×42</div><div class="lbl">Matrix Cells</div></div>
            <div class="stat-box"><div class="num"><%= curveCount %></div><div class="lbl">Control Curves</div></div>
            <div class="stat-box"><div class="num"><%= logCount %></div><div class="lbl">Evaluations</div></div>
        </div>
        <% } %>
    </div>
</section>

<!-- Choice Domains -->
<section class="section">
    <div class="section-inner">
        <h2>Choice Domains</h2>
        <p style="font-size:0.85rem;color:var(--text-muted);margin-bottom:1rem;">Select a domain to begin saimptom resolution. 16 predefined domains spanning the breadth of human dilemma.</p>
        <div style="display:grid;grid-template-columns:repeat(auto-fill, minmax(130px, 1fr));gap:0.5rem;">
            <% String[] domains = {"career", "relationship", "financial", "health", "creative", "technical", "ethical", "geographic", "temporal", "priority", "risk", "commitment", "freedom", "legacy", "community", "education"};
               for (String d : domains) { %>
            <div style="background:var(--bg-section);border:1px solid var(--border);border-radius:var(--radius);padding:0.5rem 0.75rem;font-size:0.75rem;text-align:center;color:var(--accent);font-weight:500;"><%= d %></div>
            <% } %>
        </div>
    </div>
</section>

<!-- Protocol -->
<section class="section">
    <div class="section-inner">
        <h2>TCP Protocol (Port 49223)</h2>
        <div class="table-wrap">
        <table>
            <thead><tr><th>Command</th><th>Description</th><th>Output</th></tr></thead>
            <tbody>
                <tr><td><code>DOMAIN|name</code></td><td>Begin resolution with a choice domain</td><td>Matrix seeded (1764 cells)</td></tr>
                <tr><td><code>ANSWER|value</code></td><td>Provide answer (-1000 to +1000). Repeat ~12 times.</td><td>Overconfidence measurement</td></tr>
                <tr><td><code>RESOLVE</code></td><td>Force resolution with current answers</td><td>CHOICE + NOISE + WISDOM</td></tr>
                <tr><td><code>RESULT</code></td><td>Show current resolution result</td><td>Choice/noise vectors, province wisdom</td></tr>
                <tr><td><code>DOMAINS</code></td><td>List all 16 available choice domains</td><td>Domain list</td></tr>
                <tr><td><code>STEREO</code></td><td>Show stereo recovery state</td><td>Answers given, overconfidence, recovered?</td></tr>
                <tr><td><code>PERCEPTION</code></td><td>List perception signals (modulator layer)</td><td>Signal data</td></tr>
                <tr><td><code>COGNITION</code></td><td>List cognition patterns (modulator layer)</td><td>Pattern data</td></tr>
                <tr><td><code>MODULATION</code></td><td>List modulation controls</td><td>Modulator data</td></tr>
                <tr><td><code>EXPRESSION</code></td><td>List expression outputs</td><td>Expression data</td></tr>
                <tr><td><code>CURVE</code></td><td>List control curves (simplex paths)</td><td>Curve data</td></tr>
                <tr><td><code>EVALUATE|id</code></td><td>Evaluate full simplex path for curve</td><td>Full 4-layer evaluation</td></tr>
                <tr><td><code>STATUS</code></td><td>System state and table counts</td><td>Table counts, session state</td></tr>
                <tr><td><code>QUIT</code></td><td>Disconnect</td><td>—</td></tr>
            </tbody>
        </table>
        </div>
        <p style="font-size:0.75rem;color:var(--text-muted);margin-top:1rem;">Kernel interface: <code>/proc/tandem_equals/{status, resolve, result, domains}</code></p>
    </div>
</section>

<!-- download-roadmap-section -->
<section class="section" style="border-top:1px solid #27272a;">
    <div class="section-inner">
        <h2>Download &amp; Roadmap</h2>
        <div style="display:flex;gap:1.5rem;flex-wrap:wrap;margin-bottom:1.5rem;">
            <a href="https://github.com/mearvk/Java.Web.Server.Telnet.Front.Java.21/tree/main/modules/tandem-equals" target="_blank" rel="noopener noreferrer" style="display:inline-flex;align-items:center;gap:0.5rem;padding:0.75rem 1.5rem;border-radius:8px;background:#238636;border:1px solid #2ea043;color:#fff;font-size:0.9rem;text-decoration:none;font-weight:600;transition:background 0.2s;">
                &#11015; Download Now (GitHub)
            </a>
            <a href="https://github.com/mearvk/Java.Web.Server.Telnet.Front.Java.21" target="_blank" rel="noopener noreferrer" style="display:inline-flex;align-items:center;gap:0.5rem;padding:0.75rem 1.5rem;border-radius:8px;background:#1a1a2e;border:1px solid #27272a;color:#a1a1aa;font-size:0.9rem;text-decoration:none;font-weight:500;">
                &#128230; Full NWE Distribution
            </a>
        </div>
        <div class="table-wrap"><table><thead><tr><th>Phase</th><th>Milestone</th><th>Status</th></tr></thead><tbody>
            <tr><td>1</td><td>Core backend &amp; servlet interface</td><td style="color:#22c55e;">&#10003; Complete</td></tr>
            <tr><td>2</td><td>Database schema &amp; MySQL integration</td><td style="color:#22c55e;">&#10003; Complete</td></tr>
            <tr><td>3</td><td>JSP front-end &amp; CD1 connector</td><td style="color:#22c55e;">&#10003; Complete</td></tr>
            <tr><td>4</td><td>Ubuntu kernel build integration</td><td style="color:#22c55e;">&#10003; Complete</td></tr>
            <tr><td>5</td><td>Security hardening &amp; auth</td><td style="color:#eab308;">&#9679; In Progress</td></tr>
            <tr><td>6</td><td>Production deployment &amp; monitoring</td><td style="color:#71717a;">&#9675; Planned</td></tr>
        </tbody></table></div>
        <p style="font-size:0.75rem;color:#71717a;margin-top:1rem;">Source: <a href="https://github.com/mearvk/Java.Web.Server.Telnet.Front.Java.21/tree/main/modules/tandem-equals" target="_blank" style="color:#60a5fa;">https://github.com/mearvk/Java.Web.Server.Telnet.Front.Java.21/tree/main/modules/tandem-equals</a></p>
    </div>
</section>
<footer class="footer">
    <span>TandemEquals™ — Human Intellect Modulator Simplex — MEARVK LLC — NitroWebExpress™ 2026</span>
</footer>
</body>
</html>
