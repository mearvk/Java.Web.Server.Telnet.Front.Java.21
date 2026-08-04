<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.*, java.security.MessageDigest" %>
<%
    // ═══════════════════════════════════════════════════════════════════════════════
    // Brarner.M.Alete™ — Science Input Graphs (data.jsp)
    // Tracks inputs, communications, posts, downloads across BMA categories:
    //   SSA, Species, Post Office, Science, Art, Legal, Analysis
    // MySQL-driven, Chart.js rendered.
    // ═══════════════════════════════════════════════════════════════════════════════

    // --- DB Connection ---
    String dbUrl = "jdbc:mysql://127.0.0.1:3306/nwe_analytics";
    String dbUser = "root";
    String dbPass = "$$Ironman1";

    try {
        Properties dbProps = new Properties();
        java.io.InputStream is = application.getResourceAsStream("/WEB-INF/db.properties");
        if (is != null) { dbProps.load(is); is.close();
            dbUrl = dbProps.getProperty("db.url", dbUrl);
            dbUser = dbProps.getProperty("db.user", dbUser);
            dbPass = dbProps.getProperty("db.password", dbPass);
        }
    } catch (Exception e) {}

    // Record this visit
    String visitorIP = request.getRemoteAddr();
    String userAgent = request.getHeader("User-Agent") != null ? request.getHeader("User-Agent") : "";
    String visitorHash = visitorIP;
    try {
        MessageDigest md = MessageDigest.getInstance("SHA-256");
        byte[] hash = md.digest((visitorIP + userAgent.substring(0, Math.min(userAgent.length(), 32))).getBytes());
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < 8; i++) sb.append(String.format("%02x", hash[i]));
        visitorHash = sb.toString();
    } catch (Exception e) {}

    Connection conn = null;
    boolean dbOk = false;

    // BMA categories
    String[] categories = {"SSA", "Species", "PostOffice", "Science", "Art", "Legal", "Analysis"};
    String[] categoryLabels = {"SSA", "Species", "Post Office", "Science", "Art", "Legal", "Analysis"};
    String[] categoryColors = {"#f59e0b", "#22c55e", "#ef4444", "#3b82f6", "#a855f7", "#06b6d4", "#ec4899"};

    // Selected time range
    String range = request.getParameter("range");
    int days = 14;
    if ("7".equals(range)) days = 7;
    else if ("30".equals(range)) days = 30;
    else if ("90".equals(range)) days = 90;

    // JSON data holders for each chart
    String inputsLabelsJson = "[]";
    String[] inputsDataJson = new String[categories.length];
    for (int i = 0; i < categories.length; i++) inputsDataJson[i] = "[]";

    String commsLabelsJson = "[]";
    String[] commsDataJson = new String[categories.length];
    for (int i = 0; i < categories.length; i++) commsDataJson[i] = "[]";

    String postsLabelsJson = "[]";
    String[] postsDataJson = new String[categories.length];
    for (int i = 0; i < categories.length; i++) postsDataJson[i] = "[]";

    String downloadsLabelsJson = "[]";
    String[] downloadsDataJson = new String[categories.length];
    for (int i = 0; i < categories.length; i++) downloadsDataJson[i] = "[]";

    // Summary totals
    int[] totalInputs = new int[categories.length];
    int[] totalComms = new int[categories.length];
    int[] totalPosts = new int[categories.length];
    int[] totalDownloads = new int[categories.length];
    int totalVisitors = 0;

    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        conn = DriverManager.getConnection(dbUrl, dbUser, dbPass);
        dbOk = true;

        // --- Inputs per category per day ---
        StringBuilder lbls = new StringBuilder("[");
        StringBuilder[] datasets = new StringBuilder[categories.length];
        for (int i = 0; i < categories.length; i++) datasets[i] = new StringBuilder("[");

        PreparedStatement ps = conn.prepareStatement(
            "SELECT activity_date, category, SUM(input_count) as cnt " +
            "FROM bma_science_inputs " +
            "WHERE activity_date >= DATE_SUB(CURDATE(), INTERVAL ? DAY) " +
            "GROUP BY activity_date, category ORDER BY activity_date ASC");
        ps.setInt(1, days);
        ResultSet rs = ps.executeQuery();

        // Collect into a map: date -> category -> count
        LinkedHashMap<String, int[]> inputMap = new LinkedHashMap<>();
        while (rs.next()) {
            String dt = rs.getString(1);
            String cat = rs.getString(2);
            int cnt = rs.getInt(3);
            if (!inputMap.containsKey(dt)) inputMap.put(dt, new int[categories.length]);
            for (int i = 0; i < categories.length; i++) {
                if (categories[i].equals(cat)) { inputMap.get(dt)[i] = cnt; totalInputs[i] += cnt; break; }
            }
        }
        rs.close(); ps.close();

        boolean first = true;
        for (Map.Entry<String, int[]> entry : inputMap.entrySet()) {
            if (!first) { lbls.append(","); for (int i = 0; i < categories.length; i++) datasets[i].append(","); }
            lbls.append("\"").append(entry.getKey()).append("\"");
            for (int i = 0; i < categories.length; i++) datasets[i].append(entry.getValue()[i]);
            first = false;
        }
        lbls.append("]");
        inputsLabelsJson = lbls.toString();
        for (int i = 0; i < categories.length; i++) { datasets[i].append("]"); inputsDataJson[i] = datasets[i].toString(); }

        // --- Communications per category ---
        for (int i = 0; i < categories.length; i++) datasets[i] = new StringBuilder("[");
        lbls = new StringBuilder("[");

        ps = conn.prepareStatement(
            "SELECT activity_date, category, SUM(comm_count) as cnt " +
            "FROM bma_science_inputs " +
            "WHERE activity_date >= DATE_SUB(CURDATE(), INTERVAL ? DAY) " +
            "GROUP BY activity_date, category ORDER BY activity_date ASC");
        ps.setInt(1, days);
        rs = ps.executeQuery();

        LinkedHashMap<String, int[]> commMap = new LinkedHashMap<>();
        while (rs.next()) {
            String dt = rs.getString(1);
            String cat = rs.getString(2);
            int cnt = rs.getInt(3);
            if (!commMap.containsKey(dt)) commMap.put(dt, new int[categories.length]);
            for (int i = 0; i < categories.length; i++) {
                if (categories[i].equals(cat)) { commMap.get(dt)[i] = cnt; totalComms[i] += cnt; break; }
            }
        }
        rs.close(); ps.close();

        first = true;
        for (Map.Entry<String, int[]> entry : commMap.entrySet()) {
            if (!first) { lbls.append(","); for (int i = 0; i < categories.length; i++) datasets[i].append(","); }
            lbls.append("\"").append(entry.getKey()).append("\"");
            for (int i = 0; i < categories.length; i++) datasets[i].append(entry.getValue()[i]);
            first = false;
        }
        lbls.append("]");
        commsLabelsJson = lbls.toString();
        for (int i = 0; i < categories.length; i++) { datasets[i].append("]"); commsDataJson[i] = datasets[i].toString(); }

        // --- Posts per category ---
        for (int i = 0; i < categories.length; i++) datasets[i] = new StringBuilder("[");
        lbls = new StringBuilder("[");

        ps = conn.prepareStatement(
            "SELECT activity_date, category, SUM(post_count) as cnt " +
            "FROM bma_science_inputs " +
            "WHERE activity_date >= DATE_SUB(CURDATE(), INTERVAL ? DAY) " +
            "GROUP BY activity_date, category ORDER BY activity_date ASC");
        ps.setInt(1, days);
        rs = ps.executeQuery();

        LinkedHashMap<String, int[]> postMap = new LinkedHashMap<>();
        while (rs.next()) {
            String dt = rs.getString(1);
            String cat = rs.getString(2);
            int cnt = rs.getInt(3);
            if (!postMap.containsKey(dt)) postMap.put(dt, new int[categories.length]);
            for (int i = 0; i < categories.length; i++) {
                if (categories[i].equals(cat)) { postMap.get(dt)[i] = cnt; totalPosts[i] += cnt; break; }
            }
        }
        rs.close(); ps.close();

        first = true;
        for (Map.Entry<String, int[]> entry : postMap.entrySet()) {
            if (!first) { lbls.append(","); for (int i = 0; i < categories.length; i++) datasets[i].append(","); }
            lbls.append("\"").append(entry.getKey()).append("\"");
            for (int i = 0; i < categories.length; i++) datasets[i].append(entry.getValue()[i]);
            first = false;
        }
        lbls.append("]");
        postsLabelsJson = lbls.toString();
        for (int i = 0; i < categories.length; i++) { datasets[i].append("]"); postsDataJson[i] = datasets[i].toString(); }

        // --- Downloads per category ---
        for (int i = 0; i < categories.length; i++) datasets[i] = new StringBuilder("[");
        lbls = new StringBuilder("[");

        ps = conn.prepareStatement(
            "SELECT activity_date, category, SUM(download_count) as cnt " +
            "FROM bma_science_inputs " +
            "WHERE activity_date >= DATE_SUB(CURDATE(), INTERVAL ? DAY) " +
            "GROUP BY activity_date, category ORDER BY activity_date ASC");
        ps.setInt(1, days);
        rs = ps.executeQuery();

        LinkedHashMap<String, int[]> dlMap = new LinkedHashMap<>();
        while (rs.next()) {
            String dt = rs.getString(1);
            String cat = rs.getString(2);
            int cnt = rs.getInt(3);
            if (!dlMap.containsKey(dt)) dlMap.put(dt, new int[categories.length]);
            for (int i = 0; i < categories.length; i++) {
                if (categories[i].equals(cat)) { dlMap.get(dt)[i] = cnt; totalDownloads[i] += cnt; break; }
            }
        }
        rs.close(); ps.close();

        first = true;
        for (Map.Entry<String, int[]> entry : dlMap.entrySet()) {
            if (!first) { lbls.append(","); for (int i = 0; i < categories.length; i++) datasets[i].append(","); }
            lbls.append("\"").append(entry.getKey()).append("\"");
            for (int i = 0; i < categories.length; i++) datasets[i].append(entry.getValue()[i]);
            first = false;
        }
        lbls.append("]");
        downloadsLabelsJson = lbls.toString();
        for (int i = 0; i < categories.length; i++) { datasets[i].append("]"); downloadsDataJson[i] = datasets[i].toString(); }

        // Total unique visitors
        ps = conn.prepareStatement(
            "SELECT COUNT(DISTINCT visitor_hash) FROM visitor_log WHERE module_name = 'Brarner.M.Alete' AND DATE(visited_at) >= DATE_SUB(CURDATE(), INTERVAL ? DAY)");
        ps.setInt(1, days);
        rs = ps.executeQuery();
        if (rs.next()) totalVisitors = rs.getInt(1);
        rs.close(); ps.close();

    } catch (Exception e) {
        dbOk = false;
    } finally {
        if (conn != null) try { conn.close(); } catch (Exception e) {}
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <link rel="preconnect" href="https://fonts.googleapis.com"/><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin/><link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:ital,wght@0,300;0,400;0,500;0,600;0,700;1,400;1,600&display=swap" rel="stylesheet"/>
    <link rel="icon" type="image/png" href="images/favicon.png"/>
    <title>Science Data — Brarner.M.Alete™</title>
    <link rel="stylesheet" href="css/style.css"/>
    <style>
        .data-header { padding:3rem 2rem 2rem; border-bottom:1px solid var(--border); }
        .data-header-inner { max-width:var(--max-width); margin:0 auto; display:flex; align-items:center; gap:1.5rem; flex-wrap:wrap; }
        .data-header h1 { font-size:1.6rem; font-weight:700; }
        .data-header p { color:var(--text-secondary); font-size:0.875rem; }

        .range-pills { display:flex; gap:0.5rem; margin-left:auto; }
        .range-pill { font-size:0.75rem; padding:0.35rem 0.75rem; border-radius:20px; border:1px solid var(--border); color:var(--text-secondary); text-decoration:none; transition:all 0.2s; }
        .range-pill:hover { border-color:var(--accent); color:var(--accent); text-decoration:none; }
        .range-pill.active { background:var(--accent); border-color:var(--accent); color:#fff; }

        .stats-row { display:grid; grid-template-columns:repeat(auto-fit, minmax(140px, 1fr)); gap:0.75rem; padding:1.5rem 2rem; max-width:var(--max-width); margin:0 auto; }
        .stat-box { background:var(--bg-section); border:1px solid var(--border); border-radius:var(--radius); padding:1rem; text-align:center; }
        .stat-box .stat-num { font-size:1.5rem; font-weight:700; }
        .stat-box .stat-lbl { font-size:0.65rem; color:var(--text-muted); text-transform:uppercase; letter-spacing:0.06em; margin-top:0.2rem; }

        .graphs-grid { max-width:var(--max-width); margin:0 auto; padding:1rem 2rem 2rem; display:grid; grid-template-columns:1fr 1fr; gap:1.25rem; }
        .graph-panel { background:var(--bg-section); border:1px solid var(--border); border-radius:var(--radius-lg); padding:1.25rem; }
        .graph-panel h3 { font-size:0.85rem; font-weight:600; margin-bottom:0.75rem; color:var(--text-primary); }
        .graph-panel canvas { width:100% !important; height:220px !important; }

        .cat-legend { display:flex; flex-wrap:wrap; gap:0.75rem; padding:0 2rem 1.5rem; max-width:var(--max-width); margin:0 auto; }
        .cat-badge { display:flex; align-items:center; gap:0.35rem; font-size:0.7rem; color:var(--text-secondary); }
        .cat-dot { width:10px; height:10px; border-radius:50%; }

        .breakdown-section { max-width:var(--max-width); margin:0 auto; padding:0 2rem 3rem; }
        .breakdown-section h2 { font-size:1.1rem; font-weight:600; margin-bottom:1rem; color:var(--accent-light); }
        .breakdown-table { width:100%; border-collapse:collapse; font-size:0.8rem; }
        .breakdown-table thead { background:var(--bg-card); }
        .breakdown-table th { padding:0.6rem 0.8rem; text-align:left; font-size:0.7rem; text-transform:uppercase; letter-spacing:0.04em; color:var(--text-muted); font-weight:600; }
        .breakdown-table td { padding:0.5rem 0.8rem; border-top:1px solid var(--border); color:var(--text-secondary); }
        .breakdown-table tr:hover { background:rgba(59,130,246,0.05); }
        .bar-cell { position:relative; }
        .bar-fill { position:absolute; left:0; top:0; bottom:0; opacity:0.15; border-radius:2px; }

        .db-error { background:rgba(239,68,68,0.1); border:1px solid #ef4444; border-radius:var(--radius-lg); padding:1.5rem; max-width:var(--max-width); margin:2rem auto; text-align:center; color:#ef4444; }

        @media (max-width:768px) {
            .graphs-grid { grid-template-columns:1fr; }
            .stats-row { grid-template-columns:repeat(3, 1fr); }
            .data-header-inner { flex-direction:column; align-items:flex-start; }
            .range-pills { margin-left:0; }
        }
    </style>
    <script src="js/scroll-preserve.js"></script>
    <script src="js/nwe-readme-viewer.js"></script>
</head>
<body>
<nav class="nav"><div class="nav-inner">
    <a href="index.jsp" class="nav-brand"><img src="images/mearvk.ltd.logo.left.png" alt="" style="height:40px;vertical-align:middle;margin-right:8px;background:transparent;"/>Brarner.M.Alete™<img src="images/mearvk.ltd.logo.right.png" alt="" style="height:40px;vertical-align:middle;margin-left:8px;background:transparent;"/></a>
    <ul class="nav-links">
        <li><a href="index.jsp">Overview</a></li>
        <li><a href="species.jsp">Species</a></li>
        <li><a href="postal.jsp">Postal</a></li>
        <li><a href="art.jsp">Art</a></li>
        <li><a href="science.jsp">Science</a></li>
        <li><a href="analysis.jsp">Analysis</a></li>
        <li><a href="legal.jsp">Legal</a></li>
        <li><a href="data.jsp" class="active">Data</a></li>
        <li><a href="status.jsp">Status</a></li>
    </ul>
    <div class="nav-actions">
        <a href="guest.jsp" class="nav-cta">Guest</a>
        <a href="register.jsp" class="nav-cta">Register</a>
    </div>
</div></nav>

<div class="data-header">
    <div class="data-header-inner">
        <div>
            <h1>Science Inputs &amp; Traffic</h1>
            <p>Inputs, communications, posts, and downloads across BMA interest categories.</p>
        </div>
        <div class="range-pills">
            <a href="data.jsp?range=7" class="range-pill <%= "7".equals(range) ? "active" : "" %>">7 days</a>
            <a href="data.jsp?range=14" class="range-pill <%= (range == null || "14".equals(range)) ? "active" : "" %>">14 days</a>
            <a href="data.jsp?range=30" class="range-pill <%= "30".equals(range) ? "active" : "" %>">30 days</a>
            <a href="data.jsp?range=90" class="range-pill <%= "90".equals(range) ? "active" : "" %>">90 days</a>
        </div>
    </div>
</div>

<% if (!dbOk) { %>
<div class="db-error">
    <strong>Analytics Database Offline</strong><br/>
    Run <code>bash modules/analytics/servlets/setup-bma-data.sh</code> to create the BMA science input tables.
</div>
<% } else { %>

<!-- Category Legend -->
<div class="cat-legend" style="padding-top:1.5rem;">
    <% for (int i = 0; i < categories.length; i++) { %>
    <span class="cat-badge"><span class="cat-dot" style="background:<%= categoryColors[i] %>;"></span><%= categoryLabels[i] %></span>
    <% } %>
</div>

<!-- Summary Stats Row -->
<div class="stats-row">
    <div class="stat-box">
        <div class="stat-num"><%= totalVisitors %></div>
        <div class="stat-lbl">Unique Visitors</div>
    </div>
    <% for (int i = 0; i < categories.length; i++) { %>
    <div class="stat-box">
        <div class="stat-num" style="color:<%= categoryColors[i] %>;"><%= totalInputs[i] %></div>
        <div class="stat-lbl"><%= categoryLabels[i] %> Inputs</div>
    </div>
    <% } %>
</div>

<!-- 4 Graph Panels: Inputs, Communications, Posts, Downloads -->
<div class="graphs-grid">
    <div class="graph-panel">
        <h3>&#128202; Science Inputs (by Category)</h3>
        <canvas id="chartInputs"></canvas>
    </div>
    <div class="graph-panel">
        <h3>&#128172; Communications (by Category)</h3>
        <canvas id="chartComms"></canvas>
    </div>
    <div class="graph-panel">
        <h3>&#128221; Posts (by Category)</h3>
        <canvas id="chartPosts"></canvas>
    </div>
    <div class="graph-panel">
        <h3>&#128229; Downloads (by Category)</h3>
        <canvas id="chartDownloads"></canvas>
    </div>
</div>

<!-- Breakdown Table -->
<div class="breakdown-section">
    <h2>Category Breakdown (Last <%= days %> Days)</h2>
    <div style="overflow-x:auto;border:1px solid var(--border);border-radius:var(--radius-lg);">
    <table class="breakdown-table">
        <thead>
            <tr>
                <th>Category</th>
                <th>Inputs</th>
                <th>Communications</th>
                <th>Posts</th>
                <th>Downloads</th>
                <th>Total Activity</th>
            </tr>
        </thead>
        <tbody>
            <% 
                int grandTotal = 0;
                for (int i = 0; i < categories.length; i++) {
                    int rowTotal = totalInputs[i] + totalComms[i] + totalPosts[i] + totalDownloads[i];
                    grandTotal += rowTotal;
                }
                for (int i = 0; i < categories.length; i++) {
                    int rowTotal = totalInputs[i] + totalComms[i] + totalPosts[i] + totalDownloads[i];
                    int barPct = grandTotal > 0 ? (rowTotal * 100 / grandTotal) : 0;
            %>
            <tr>
                <td><span class="cat-badge"><span class="cat-dot" style="background:<%= categoryColors[i] %>;"></span><strong><%= categoryLabels[i] %></strong></span></td>
                <td><%= totalInputs[i] %></td>
                <td><%= totalComms[i] %></td>
                <td><%= totalPosts[i] %></td>
                <td><%= totalDownloads[i] %></td>
                <td class="bar-cell">
                    <span class="bar-fill" style="width:<%= barPct %>%;background:<%= categoryColors[i] %>;"></span>
                    <strong><%= rowTotal %></strong>
                </td>
            </tr>
            <% } %>
            <tr style="border-top:2px solid var(--border);">
                <td><strong>Total</strong></td>
                <td><strong><%= Arrays.stream(totalInputs).sum() %></strong></td>
                <td><strong><%= Arrays.stream(totalComms).sum() %></strong></td>
                <td><strong><%= Arrays.stream(totalPosts).sum() %></strong></td>
                <td><strong><%= Arrays.stream(totalDownloads).sum() %></strong></td>
                <td><strong><%= grandTotal %></strong></td>
            </tr>
        </tbody>
    </table>
    </div>
</div>

<% } %>

<footer class="footer"><div class="footer-bottom" style="border:none;padding:0;">
    <span>&#169; 2026 MEARVK LLC — Brarner.M.Alete™ — Science Data</span>
</div></footer>

<!-- Chart.js -->
<script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.3/dist/chart.umd.min.js"></script>
<script>
(function() {
    'use strict';

    // Category labels and colors (from MySQL bma_categories)
    var catLabels = [<% for (int i = 0; i < categoryLabels.length; i++) { %>"<%= categoryLabels[i] %>"<%= i < categoryLabels.length-1 ? "," : "" %><% } %>];
    var catColors = [<% for (int i = 0; i < categoryColors.length; i++) { %>"<%= categoryColors[i] %>"<%= i < categoryColors.length-1 ? "," : "" %><% } %>];

    // Data from MySQL
    var inputsLabels = <%= inputsLabelsJson %>;
    var inputsData = [<% for (int i = 0; i < categories.length; i++) { %><%= inputsDataJson[i] %><%= i < categories.length-1 ? "," : "" %><% } %>];

    var commsLabels = <%= commsLabelsJson %>;
    var commsData = [<% for (int i = 0; i < categories.length; i++) { %><%= commsDataJson[i] %><%= i < categories.length-1 ? "," : "" %><% } %>];

    var postsLabels = <%= postsLabelsJson %>;
    var postsData = [<% for (int i = 0; i < categories.length; i++) { %><%= postsDataJson[i] %><%= i < categories.length-1 ? "," : "" %><% } %>];

    var downloadsLabels = <%= downloadsLabelsJson %>;
    var downloadsData = [<% for (int i = 0; i < categories.length; i++) { %><%= downloadsDataJson[i] %><%= i < categories.length-1 ? "," : "" %><% } %>];

    // Chart defaults
    var gridColor = 'rgba(39,39,42,0.8)';
    var tickColor = '#71717a';

    function makeScales() {
        return {
            x: { stacked: true, grid: { color: gridColor, drawBorder: false }, ticks: { color: tickColor, font: { size: 9 }, maxRotation: 45 } },
            y: { stacked: true, grid: { color: gridColor, drawBorder: false }, ticks: { color: tickColor, font: { size: 9 }, beginAtZero: true }, suggestedMin: 0 }
        };
    }

    function makeDatasets(data) {
        var ds = [];
        for (var i = 0; i < catLabels.length; i++) {
            ds.push({
                label: catLabels[i],
                data: data[i],
                backgroundColor: catColors[i] + 'cc',
                borderColor: catColors[i],
                borderWidth: 1,
                borderRadius: 3
            });
        }
        return ds;
    }

    function makeLineDatasets(data) {
        var ds = [];
        for (var i = 0; i < catLabels.length; i++) {
            ds.push({
                label: catLabels[i],
                data: data[i],
                borderColor: catColors[i],
                backgroundColor: catColors[i] + '18',
                fill: true,
                tension: 0.35,
                pointRadius: 2,
                pointHoverRadius: 4,
                borderWidth: 2
            });
        }
        return ds;
    }

    var pluginOpts = {
        legend: { display: false },
        tooltip: { backgroundColor: '#1a1a24', borderColor: '#27272a', borderWidth: 1,
                   titleColor: '#fff', bodyColor: '#a1a1aa', bodyFont: { size: 11 } }
    };

    // 1. Inputs (stacked bar)
    if (document.getElementById('chartInputs') && inputsLabels.length > 0) {
        new Chart(document.getElementById('chartInputs').getContext('2d'), {
            type: 'bar',
            data: { labels: inputsLabels, datasets: makeDatasets(inputsData) },
            options: { responsive: true, scales: makeScales(), plugins: pluginOpts }
        });
    }

    // 2. Communications (line, stacked area)
    if (document.getElementById('chartComms') && commsLabels.length > 0) {
        var commsScales = makeScales();
        commsScales.y.stacked = true;
        new Chart(document.getElementById('chartComms').getContext('2d'), {
            type: 'line',
            data: { labels: commsLabels, datasets: makeLineDatasets(commsData) },
            options: { responsive: true, scales: commsScales, plugins: pluginOpts }
        });
    }

    // 3. Posts (stacked bar)
    if (document.getElementById('chartPosts') && postsLabels.length > 0) {
        new Chart(document.getElementById('chartPosts').getContext('2d'), {
            type: 'bar',
            data: { labels: postsLabels, datasets: makeDatasets(postsData) },
            options: { responsive: true, scales: makeScales(), plugins: pluginOpts }
        });
    }

    // 4. Downloads (line)
    if (document.getElementById('chartDownloads') && downloadsLabels.length > 0) {
        var dlScales = makeScales();
        dlScales.y.stacked = false;
        dlScales.x.stacked = false;
        new Chart(document.getElementById('chartDownloads').getContext('2d'), {
            type: 'line',
            data: { labels: downloadsLabels, datasets: makeLineDatasets(downloadsData) },
            options: { responsive: true, scales: dlScales, plugins: pluginOpts }
        });
    }
})();
</script>

<!-- CD1 Connector -->
<div style="position:fixed;bottom:2rem;right:2rem;z-index:200;">
    <button id="cd1-btn" type="button" style="all:unset;cursor:pointer;">
        <img src="images/black.button.png" alt="Connector" style="display:block;width:60px;height:60px;border-radius:50%;box-shadow:0 4px 16px rgba(0,0,0,0.5);"/>
    </button>
</div>
<script>window.CD1_MODULE_PORT = "49152";</script>
<script src="js/cd1-connector.js"></script>
</body>
</html>
