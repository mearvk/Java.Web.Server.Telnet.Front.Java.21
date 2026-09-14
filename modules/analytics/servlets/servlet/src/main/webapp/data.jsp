<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.*, java.security.MessageDigest" %>
<%
    // ═══════════════════════════════════════════════════════════════════════════════
    // NitroWebExpress™ — Analytics Data Page (data.jsp)
    // GitHub-style traffic graphs driven by MySQL, rendered by Chart.js
    // ═══════════════════════════════════════════════════════════════════════════════

    // --- Record this visit ---
    String visitorIP = request.getRemoteAddr();
    String userAgent = request.getHeader("User-Agent") != null ? request.getHeader("User-Agent") : "";
    String referrer = request.getHeader("Referer") != null ? request.getHeader("Referer") : "";
    String pagePath = request.getRequestURI();
    String moduleName = request.getParameter("module");
    if (moduleName == null || moduleName.isEmpty()) moduleName = "ALL";

    // Hash the visitor IP for privacy
    String visitorHash = "";
    try {
        MessageDigest md = MessageDigest.getInstance("SHA-256");
        byte[] hash = md.digest((visitorIP + userAgent.substring(0, Math.min(userAgent.length(), 32))).getBytes());
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < 8; i++) sb.append(String.format("%02x", hash[i]));
        visitorHash = sb.toString();
    } catch (Exception e) { visitorHash = visitorIP; }

    // --- DB connection ---
    String dbUrl = "jdbc:mysql://127.0.0.1:3306/nwe_analytics";
    String dbUser = "root";
    String dbPass = "$$Ironman1";

    // Try loading db.properties
    try {
        Properties dbProps = new Properties();
        java.io.InputStream is = application.getResourceAsStream("/WEB-INF/db.properties");
        if (is != null) {
            dbProps.load(is);
            is.close();
            dbUrl = dbProps.getProperty("db.url", dbUrl);
            dbUser = dbProps.getProperty("db.user", dbUser);
            dbPass = dbProps.getProperty("db.password", dbPass);
        }
    } catch (Exception e) { /* use defaults */ }

    Connection conn = null;
    boolean dbOk = false;
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        conn = DriverManager.getConnection(dbUrl, dbUser, dbPass);
        dbOk = true;

        // Record visitor
        PreparedStatement ps = conn.prepareStatement(
            "INSERT INTO visitor_log (module_name, visitor_hash, ip_address, user_agent, page_path, referrer) VALUES (?, ?, ?, ?, ?, ?)");
        ps.setString(1, moduleName);
        ps.setString(2, visitorHash);
        ps.setString(3, visitorIP);
        ps.setString(4, userAgent.length() > 512 ? userAgent.substring(0, 512) : userAgent);
        ps.setString(5, pagePath);
        ps.setString(6, referrer.length() > 512 ? referrer.substring(0, 512) : referrer);
        ps.executeUpdate();
        ps.close();

        // Increment daily page_views (upsert)
        ps = conn.prepareStatement(
            "INSERT INTO page_views (module_name, view_date, total_views, unique_visitors) " +
            "VALUES (?, CURDATE(), 1, 1) " +
            "ON DUPLICATE KEY UPDATE total_views = total_views + 1, " +
            "unique_visitors = (SELECT COUNT(DISTINCT visitor_hash) FROM visitor_log WHERE module_name = ? AND DATE(visited_at) = CURDATE())");
        ps.setString(1, moduleName);
        ps.setString(2, moduleName);
        ps.executeUpdate();
        ps.close();

        // Record referrer domain
        if (!referrer.isEmpty()) {
            String refDomain = "";
            try { refDomain = new java.net.URL(referrer).getHost(); } catch (Exception ex) { refDomain = referrer; }
            if (!refDomain.isEmpty()) {
                ps = conn.prepareStatement(
                    "INSERT INTO referring_sites (module_name, referrer_domain, ref_date, visit_count, unique_visitors) " +
                    "VALUES (?, ?, CURDATE(), 1, 1) " +
                    "ON DUPLICATE KEY UPDATE visit_count = visit_count + 1");
                ps.setString(1, moduleName);
                ps.setString(2, refDomain.length() > 256 ? refDomain.substring(0, 256) : refDomain);
                ps.executeUpdate();
                ps.close();
            }
        }
    } catch (Exception e) {
        dbOk = false;
    }

    // --- Fetch graph data (last 14 days, like GitHub) ---
    String viewsLabelsJson = "[]";
    String viewsTotalJson = "[]";
    String viewsUniqueJson = "[]";
    String usersLabelsJson = "[]";
    String usersCountJson = "[]";
    String uploadsLabelsJson = "[]";
    String uploadsCountJson = "[]";
    String clonesLabelsJson = "[]";
    String clonesTotalJson = "[]";
    String clonesUniqueJson = "[]";

    // Module list for dropdown
    List<String[]> moduleList = new ArrayList<>();

    if (dbOk && conn != null) {
        try {
            // Module list
            Statement st = conn.createStatement();
            ResultSet rs = st.executeQuery("SELECT module_name, context_path, theme_color FROM modules WHERE is_active = TRUE ORDER BY module_name");
            while (rs.next()) {
                moduleList.add(new String[]{ rs.getString(1), rs.getString(2), rs.getString(3) });
            }
            rs.close(); st.close();

            // Page views (14 days)
            StringBuilder lbls = new StringBuilder("[");
            StringBuilder totals = new StringBuilder("[");
            StringBuilder uniques = new StringBuilder("[");
            PreparedStatement ps2 = conn.prepareStatement(
                "SELECT view_date, total_views, unique_visitors FROM page_views " +
                "WHERE module_name = ? AND view_date >= DATE_SUB(CURDATE(), INTERVAL 14 DAY) " +
                "ORDER BY view_date ASC");
            ps2.setString(1, moduleName);
            ResultSet rs2 = ps2.executeQuery();
            boolean first = true;
            while (rs2.next()) {
                if (!first) { lbls.append(","); totals.append(","); uniques.append(","); }
                lbls.append("\"").append(rs2.getString(1)).append("\"");
                totals.append(rs2.getInt(2));
                uniques.append(rs2.getInt(3));
                first = false;
            }
            lbls.append("]"); totals.append("]"); uniques.append("]");
            viewsLabelsJson = lbls.toString();
            viewsTotalJson = totals.toString();
            viewsUniqueJson = uniques.toString();
            rs2.close(); ps2.close();

            // New users (14 days)
            lbls = new StringBuilder("[");
            StringBuilder counts = new StringBuilder("[");
            ps2 = conn.prepareStatement(
                "SELECT register_date, user_count FROM new_users " +
                "WHERE module_name = ? AND register_date >= DATE_SUB(CURDATE(), INTERVAL 14 DAY) " +
                "ORDER BY register_date ASC");
            ps2.setString(1, moduleName);
            rs2 = ps2.executeQuery();
            first = true;
            while (rs2.next()) {
                if (!first) { lbls.append(","); counts.append(","); }
                lbls.append("\"").append(rs2.getString(1)).append("\"");
                counts.append(rs2.getInt(2));
                first = false;
            }
            lbls.append("]"); counts.append("]");
            usersLabelsJson = lbls.toString();
            usersCountJson = counts.toString();
            rs2.close(); ps2.close();

            // Uploads (14 days)
            lbls = new StringBuilder("[");
            counts = new StringBuilder("[");
            ps2 = conn.prepareStatement(
                "SELECT upload_date, upload_count FROM uploads " +
                "WHERE module_name = ? AND upload_date >= DATE_SUB(CURDATE(), INTERVAL 14 DAY) " +
                "ORDER BY upload_date ASC");
            ps2.setString(1, moduleName);
            rs2 = ps2.executeQuery();
            first = true;
            while (rs2.next()) {
                if (!first) { lbls.append(","); counts.append(","); }
                lbls.append("\"").append(rs2.getString(1)).append("\"");
                counts.append(rs2.getInt(2));
                first = false;
            }
            lbls.append("]"); counts.append("]");
            uploadsLabelsJson = lbls.toString();
            uploadsCountJson = counts.toString();
            rs2.close(); ps2.close();

            // Clones (14 days)
            lbls = new StringBuilder("[");
            totals = new StringBuilder("[");
            uniques = new StringBuilder("[");
            ps2 = conn.prepareStatement(
                "SELECT clone_date, total_clones, unique_cloners FROM clones " +
                "WHERE module_name = ? AND clone_date >= DATE_SUB(CURDATE(), INTERVAL 14 DAY) " +
                "ORDER BY clone_date ASC");
            ps2.setString(1, moduleName);
            rs2 = ps2.executeQuery();
            first = true;
            while (rs2.next()) {
                if (!first) { lbls.append(","); totals.append(","); uniques.append(","); }
                lbls.append("\"").append(rs2.getString(1)).append("\"");
                totals.append(rs2.getInt(2));
                uniques.append(rs2.getInt(3));
                first = false;
            }
            lbls.append("]"); totals.append("]"); uniques.append("]");
            clonesLabelsJson = lbls.toString();
            clonesTotalJson = totals.toString();
            clonesUniqueJson = uniques.toString();
            rs2.close(); ps2.close();

        } catch (Exception e) { /* graphs render empty */ }
    }

    // --- Fetch summary stats ---
    int totalViewsSum = 0, uniqueVisitorsSum = 0, totalUsersSum = 0, totalUploadsSum = 0;
    String topReferrer = "—";
    String topContent = "—";

    if (dbOk && conn != null) {
        try {
            PreparedStatement ps3 = conn.prepareStatement(
                "SELECT COALESCE(SUM(total_views),0), COALESCE(SUM(unique_visitors),0) FROM page_views WHERE module_name = ? AND view_date >= DATE_SUB(CURDATE(), INTERVAL 14 DAY)");
            ps3.setString(1, moduleName);
            ResultSet rs3 = ps3.executeQuery();
            if (rs3.next()) { totalViewsSum = rs3.getInt(1); uniqueVisitorsSum = rs3.getInt(2); }
            rs3.close(); ps3.close();

            ps3 = conn.prepareStatement(
                "SELECT COALESCE(SUM(user_count),0) FROM new_users WHERE module_name = ? AND register_date >= DATE_SUB(CURDATE(), INTERVAL 14 DAY)");
            ps3.setString(1, moduleName);
            rs3 = ps3.executeQuery();
            if (rs3.next()) totalUsersSum = rs3.getInt(1);
            rs3.close(); ps3.close();

            ps3 = conn.prepareStatement(
                "SELECT COALESCE(SUM(upload_count),0) FROM uploads WHERE module_name = ? AND upload_date >= DATE_SUB(CURDATE(), INTERVAL 14 DAY)");
            ps3.setString(1, moduleName);
            rs3 = ps3.executeQuery();
            if (rs3.next()) totalUploadsSum = rs3.getInt(1);
            rs3.close(); ps3.close();

            ps3 = conn.prepareStatement(
                "SELECT referrer_domain FROM referring_sites WHERE module_name = ? AND ref_date >= DATE_SUB(CURDATE(), INTERVAL 14 DAY) ORDER BY visit_count DESC LIMIT 1");
            ps3.setString(1, moduleName);
            rs3 = ps3.executeQuery();
            if (rs3.next()) topReferrer = rs3.getString(1);
            rs3.close(); ps3.close();

            ps3 = conn.prepareStatement(
                "SELECT page_path FROM popular_content WHERE module_name = ? AND content_date >= DATE_SUB(CURDATE(), INTERVAL 14 DAY) ORDER BY view_count DESC LIMIT 1");
            ps3.setString(1, moduleName);
            rs3 = ps3.executeQuery();
            if (rs3.next()) topContent = rs3.getString(1);
            rs3.close(); ps3.close();

        } catch (Exception e) { /* summary stays zero */ }
    }

    if (conn != null) try { conn.close(); } catch (Exception e) {}
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <link rel="preconnect" href="https://fonts.googleapis.com"/><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin/><link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:ital,wght@0,300;0,400;0,500;0,600;0,700;1,400;1,600&display=swap" rel="stylesheet"/>
    <title>Traffic — NitroWebExpress™ Analytics</title>
    <style>
        :root {
            --bg-dark: #0d1117;
            --bg-section: #161b22;
            --bg-card: #1c2128;
            --border: #30363d;
            --accent: #58a6ff;
            --accent-hover: #79c0ff;
            --green: #3fb950;
            --orange: #d29922;
            --red: #f85149;
            --purple: #bc8cff;
            --text: #c9d1d9;
            --text-muted: #8b949e;
            --radius: 6px;
            --radius-lg: 12px;
            --max-width: 1200px;
            --font: 'IBM Plex Sans', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
            --font-mono: 'JetBrains Mono', 'Fira Code', monospace;
        }
        * { margin:0; padding:0; box-sizing:border-box; }
        body { font-family:var(--font); background:var(--bg-dark); color:var(--text); line-height:1.6; -webkit-font-smoothing:antialiased; }
        a { color:var(--accent); text-decoration:none; }
        a:hover { color:var(--accent-hover); text-decoration:underline; }

        .nav { background:var(--bg-section); border-bottom:1px solid var(--border); padding:0 2rem; position:sticky; top:0; z-index:100; }
        .nav-inner { max-width:var(--max-width); margin:0 auto; display:flex; align-items:center; height:56px; gap:1.5rem; }
        .nav-brand { font-size:1rem; font-weight:700; color:var(--accent); }
        .nav-links { list-style:none; display:flex; gap:1rem; margin-left:auto; }
        .nav-links a { font-size:0.8rem; color:var(--text-muted); padding:0.3rem 0.6rem; border-radius:var(--radius); }
        .nav-links a:hover, .nav-links a.active { background:var(--bg-card); color:var(--text); text-decoration:none; }

        .header { padding:2rem; border-bottom:1px solid var(--border); }
        .header-inner { max-width:var(--max-width); margin:0 auto; display:flex; align-items:center; gap:1.5rem; flex-wrap:wrap; }
        .header h1 { font-size:1.5rem; font-weight:600; }
        .header p { color:var(--text-muted); font-size:0.875rem; }

        .module-select { background:var(--bg-card); color:var(--text); border:1px solid var(--border); border-radius:var(--radius); padding:0.4rem 0.8rem; font-size:0.8rem; cursor:pointer; }
        .module-select:focus { outline:none; border-color:var(--accent); }

        .stats-grid { display:grid; grid-template-columns:repeat(auto-fit, minmax(180px, 1fr)); gap:1rem; padding:2rem; max-width:var(--max-width); margin:0 auto; }
        .stat-card { background:var(--bg-section); border:1px solid var(--border); border-radius:var(--radius-lg); padding:1.25rem; }
        .stat-card .stat-label { font-size:0.75rem; color:var(--text-muted); text-transform:uppercase; letter-spacing:0.05em; margin-bottom:0.25rem; }
        .stat-card .stat-value { font-size:1.75rem; font-weight:700; color:var(--text); }
        .stat-card .stat-sub { font-size:0.7rem; color:var(--text-muted); margin-top:0.25rem; }

        .graphs { max-width:var(--max-width); margin:0 auto; padding:0 2rem 2rem; display:grid; gap:1.5rem; }
        .graph-card { background:var(--bg-section); border:1px solid var(--border); border-radius:var(--radius-lg); padding:1.5rem; }
        .graph-card h3 { font-size:0.9rem; font-weight:600; margin-bottom:1rem; color:var(--text); }
        .graph-card canvas { width:100% !important; height:200px !important; }

        .tables-section { max-width:var(--max-width); margin:0 auto; padding:0 2rem 3rem; display:grid; grid-template-columns:1fr 1fr; gap:1.5rem; }
        .table-card { background:var(--bg-section); border:1px solid var(--border); border-radius:var(--radius-lg); padding:1.25rem; }
        .table-card h3 { font-size:0.85rem; font-weight:600; margin-bottom:0.75rem; color:var(--text-muted); }
        .table-card table { width:100%; border-collapse:collapse; font-size:0.8rem; }
        .table-card th { text-align:left; padding:0.4rem 0.6rem; color:var(--text-muted); font-weight:500; border-bottom:1px solid var(--border); }
        .table-card td { padding:0.4rem 0.6rem; border-bottom:1px solid rgba(48,54,61,0.5); color:var(--text); }

        .db-error { background:#2d1b1b; border:1px solid #f85149; border-radius:var(--radius-lg); padding:1.5rem; max-width:var(--max-width); margin:2rem auto; text-align:center; color:#f85149; }

        .footer { padding:2rem; text-align:center; border-top:1px solid var(--border); color:var(--text-muted); font-size:0.75rem; }

        @media (max-width:768px) {
            .stats-grid { grid-template-columns:repeat(2, 1fr); }
            .tables-section { grid-template-columns:1fr; }
            .header-inner { flex-direction:column; align-items:flex-start; }
        }
    </style>
</head>
<body>

<nav class="nav">
    <div class="nav-inner">
        <span class="nav-brand">&#9679; NitroWebExpress™ Traffic</span>
        <ul class="nav-links">
            <li><a href="data.jsp" class="active">Traffic</a></li>
            <li><a href="index.jsp">Home</a></li>
            <li><a href="status.jsp">Status</a></li>
        </ul>
    </div>
</nav>

<div class="header">
    <div class="header-inner">
        <div>
            <h1>Traffic &amp; Analytics</h1>
            <p>Page views, unique visitors, uploads, and new users — last 14 days. GitHub-style traffic graphs.</p>
        </div>
        <form method="get" action="data.jsp" style="margin-left:auto;">
            <select name="module" class="module-select" onchange="this.form.submit()">
                <option value="ALL" <%= "ALL".equals(moduleName) ? "selected" : "" %>>All Modules</option>
                <% for (String[] m : moduleList) { %>
                <option value="<%= m[0] %>" <%= m[0].equals(moduleName) ? "selected" : "" %>><%= m[0] %></option>
                <% } %>
            </select>
        </form>
    </div>
</div>

<% if (!dbOk) { %>
<div class="db-error">
    <strong>Database Offline</strong><br/>
    Could not connect to nwe_analytics. Run <code>bash modules/analytics/servlets/setup-db.sh</code> to initialize.
</div>
<% } else { %>

<!-- Summary Stats -->
<div class="stats-grid">
    <div class="stat-card">
        <div class="stat-label">Total Views</div>
        <div class="stat-value"><%= totalViewsSum %></div>
        <div class="stat-sub">Last 14 days</div>
    </div>
    <div class="stat-card">
        <div class="stat-label">Unique Visitors</div>
        <div class="stat-value"><%= uniqueVisitorsSum %></div>
        <div class="stat-sub">Last 14 days</div>
    </div>
    <div class="stat-card">
        <div class="stat-label">New Users</div>
        <div class="stat-value"><%= totalUsersSum %></div>
        <div class="stat-sub">Registrations</div>
    </div>
    <div class="stat-card">
        <div class="stat-label">Uploads</div>
        <div class="stat-value"><%= totalUploadsSum %></div>
        <div class="stat-sub">Files / voice / images</div>
    </div>
    <div class="stat-card">
        <div class="stat-label">Top Referrer</div>
        <div class="stat-value" style="font-size:1rem;word-break:break-all;"><%= topReferrer %></div>
        <div class="stat-sub">Most traffic from</div>
    </div>
    <div class="stat-card">
        <div class="stat-label">Top Content</div>
        <div class="stat-value" style="font-size:1rem;word-break:break-all;"><%= topContent %></div>
        <div class="stat-sub">Most visited page</div>
    </div>
</div>

<!-- Graphs -->
<div class="graphs">
    <div class="graph-card">
        <h3>&#128200; Page Views — Total vs Unique Visitors</h3>
        <canvas id="chartViews"></canvas>
    </div>
    <div class="graph-card">
        <h3>&#128100; New User Registrations</h3>
        <canvas id="chartUsers"></canvas>
    </div>
    <div class="graph-card">
        <h3>&#128228; Uploads (Files, Voice, Images)</h3>
        <canvas id="chartUploads"></canvas>
    </div>
    <div class="graph-card">
        <h3>&#128230; Clones / Downloads</h3>
        <canvas id="chartClones"></canvas>
    </div>
</div>

<!-- Tables: Referring Sites + Popular Content -->
<div class="tables-section">
    <div class="table-card">
        <h3>Referring Sites (14 days)</h3>
        <table>
            <thead><tr><th>Domain</th><th>Views</th><th>Unique</th></tr></thead>
            <tbody id="refTable">
                <tr><td colspan="3" style="color:var(--text-muted);">Loading...</td></tr>
            </tbody>
        </table>
    </div>
    <div class="table-card">
        <h3>Popular Content (14 days)</h3>
        <table>
            <thead><tr><th>Page</th><th>Views</th><th>Unique</th></tr></thead>
            <tbody id="contentTable">
                <tr><td colspan="3" style="color:var(--text-muted);">Loading...</td></tr>
            </tbody>
        </table>
    </div>
</div>

<% } %>

<footer class="footer">
    <span>NitroWebExpress™ Analytics — Traffic Data — MEARVK LLC — 2026</span>
</footer>

<!-- Chart.js from CDN -->
<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.3/dist/chart.umd.min.js"></script>
<script>
(function() {
    'use strict';

    // Data injected from MySQL via JSP
    var viewsLabels = <%= viewsLabelsJson %>;
    var viewsTotal = <%= viewsTotalJson %>;
    var viewsUnique = <%= viewsUniqueJson %>;
    var usersLabels = <%= usersLabelsJson %>;
    var usersCount = <%= usersCountJson %>;
    var uploadsLabels = <%= uploadsLabelsJson %>;
    var uploadsCount = <%= uploadsCountJson %>;
    var clonesLabels = <%= clonesLabelsJson %>;
    var clonesTotal = <%= clonesTotalJson %>;
    var clonesUnique = <%= clonesUniqueJson %>;

    // Common chart config (GitHub style)
    var gridColor = 'rgba(48,54,61,0.6)';
    var tickColor = '#8b949e';

    function commonScales() {
        return {
            x: { grid: { color: gridColor, drawBorder: false }, ticks: { color: tickColor, font: { size: 10 } } },
            y: { grid: { color: gridColor, drawBorder: false }, ticks: { color: tickColor, font: { size: 10 }, beginAtZero: true },
                 suggestedMin: 0 }
        };
    }

    function commonPlugins(title) {
        return {
            legend: { labels: { color: '#c9d1d9', font: { size: 11 } } },
            tooltip: { backgroundColor: '#1c2128', borderColor: '#30363d', borderWidth: 1,
                       titleColor: '#c9d1d9', bodyColor: '#8b949e' }
        };
    }

    // 1. Page Views Chart (area + line)
    if (document.getElementById('chartViews')) {
        new Chart(document.getElementById('chartViews').getContext('2d'), {
            type: 'line',
            data: {
                labels: viewsLabels,
                datasets: [
                    {
                        label: 'Total Views',
                        data: viewsTotal,
                        borderColor: '#58a6ff',
                        backgroundColor: 'rgba(88,166,255,0.1)',
                        fill: true,
                        tension: 0.3,
                        pointRadius: 3,
                        pointHoverRadius: 5
                    },
                    {
                        label: 'Unique Visitors',
                        data: viewsUnique,
                        borderColor: '#3fb950',
                        backgroundColor: 'rgba(63,185,80,0.08)',
                        fill: true,
                        tension: 0.3,
                        pointRadius: 3,
                        pointHoverRadius: 5
                    }
                ]
            },
            options: { responsive: true, scales: commonScales(), plugins: commonPlugins() }
        });
    }

    // 2. New Users Chart (bar)
    if (document.getElementById('chartUsers')) {
        new Chart(document.getElementById('chartUsers').getContext('2d'), {
            type: 'bar',
            data: {
                labels: usersLabels,
                datasets: [{
                    label: 'New Users',
                    data: usersCount,
                    backgroundColor: 'rgba(188,140,255,0.7)',
                    borderColor: '#bc8cff',
                    borderWidth: 1,
                    borderRadius: 4
                }]
            },
            options: { responsive: true, scales: commonScales(), plugins: commonPlugins() }
        });
    }

    // 3. Uploads Chart (bar)
    if (document.getElementById('chartUploads')) {
        new Chart(document.getElementById('chartUploads').getContext('2d'), {
            type: 'bar',
            data: {
                labels: uploadsLabels,
                datasets: [{
                    label: 'Uploads',
                    data: uploadsCount,
                    backgroundColor: 'rgba(210,153,34,0.7)',
                    borderColor: '#d29922',
                    borderWidth: 1,
                    borderRadius: 4
                }]
            },
            options: { responsive: true, scales: commonScales(), plugins: commonPlugins() }
        });
    }

    // 4. Clones Chart (line)
    if (document.getElementById('chartClones')) {
        new Chart(document.getElementById('chartClones').getContext('2d'), {
            type: 'line',
            data: {
                labels: clonesLabels,
                datasets: [
                    {
                        label: 'Total Clones',
                        data: clonesTotal,
                        borderColor: '#f85149',
                        backgroundColor: 'rgba(248,81,73,0.08)',
                        fill: true,
                        tension: 0.3,
                        pointRadius: 3
                    },
                    {
                        label: 'Unique Cloners',
                        data: clonesUnique,
                        borderColor: '#d29922',
                        backgroundColor: 'rgba(210,153,34,0.08)',
                        fill: true,
                        tension: 0.3,
                        pointRadius: 3
                    }
                ]
            },
            options: { responsive: true, scales: commonScales(), plugins: commonPlugins() }
        });
    }

    // Fetch referring sites table via inline JSP data (already rendered server-side)
    // For the tables, we use AJAX-style fetch to a JSON endpoint (or inline)
    // Since this is JSP, we render the table data server-side below
})();
</script>

<%-- Referring Sites + Popular Content tables rendered server-side --%>
<%
    if (dbOk) {
        Connection conn2 = null;
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            conn2 = DriverManager.getConnection(dbUrl, dbUser, dbPass);

            // Referring sites
            StringBuilder refHtml = new StringBuilder();
            PreparedStatement ps4 = conn2.prepareStatement(
                "SELECT referrer_domain, SUM(visit_count) as vc, SUM(unique_visitors) as uv " +
                "FROM referring_sites WHERE module_name = ? AND ref_date >= DATE_SUB(CURDATE(), INTERVAL 14 DAY) " +
                "GROUP BY referrer_domain ORDER BY vc DESC LIMIT 10");
            ps4.setString(1, moduleName);
            ResultSet rs4 = ps4.executeQuery();
            boolean hasRef = false;
            while (rs4.next()) {
                hasRef = true;
                refHtml.append("<tr><td>").append(rs4.getString(1))
                       .append("</td><td>").append(rs4.getInt(2))
                       .append("</td><td>").append(rs4.getInt(3))
                       .append("</td></tr>");
            }
            if (!hasRef) refHtml.append("<tr><td colspan='3' style='color:var(--text-muted)'>No referrer data yet</td></tr>");
            rs4.close(); ps4.close();

            // Popular content
            StringBuilder contentHtml = new StringBuilder();
            ps4 = conn2.prepareStatement(
                "SELECT page_path, SUM(view_count) as vc, SUM(unique_visitors) as uv " +
                "FROM popular_content WHERE module_name = ? AND content_date >= DATE_SUB(CURDATE(), INTERVAL 14 DAY) " +
                "GROUP BY page_path ORDER BY vc DESC LIMIT 10");
            ps4.setString(1, moduleName);
            rs4 = ps4.executeQuery();
            boolean hasCont = false;
            while (rs4.next()) {
                hasCont = true;
                contentHtml.append("<tr><td>").append(rs4.getString(1))
                           .append("</td><td>").append(rs4.getInt(2))
                           .append("</td><td>").append(rs4.getInt(3))
                           .append("</td></tr>");
            }
            if (!hasCont) contentHtml.append("<tr><td colspan='3' style='color:var(--text-muted)'>No content data yet</td></tr>");
            rs4.close(); ps4.close();
            conn2.close();
%>
<script>
document.getElementById('refTable').innerHTML = '<%= refHtml.toString().replace("'", "\\'") %>';
document.getElementById('contentTable').innerHTML = '<%= contentHtml.toString().replace("'", "\\'") %>';
</script>
<%
        } catch (Exception e) {
            if (conn2 != null) try { conn2.close(); } catch (Exception ex) {}
        }
    }
%>

</body>
</html>
