<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*" %>
<%
    Connection conn = null; boolean dbOk = false;
    int termCount = 0, domainCount = 0, revisionCount = 0, refCount = 0;
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        conn = DriverManager.getConnection("jdbc:mysql://127.0.0.1:3306/nwe_dictionary", "root", "$$Ironman1");
        dbOk = true;
        Statement st = conn.createStatement();
        ResultSet rs = st.executeQuery("SELECT (SELECT COUNT(*) FROM terms) as t, (SELECT COUNT(*) FROM domains) as d, (SELECT COUNT(*) FROM term_revisions) as r, (SELECT COUNT(*) FROM cross_references) as c");
        if (rs.next()) { termCount = rs.getInt(1); domainCount = rs.getInt(2); revisionCount = rs.getInt(3); refCount = rs.getInt(4); }
        rs.close(); st.close();
    } catch (Exception e) {}
    if (conn != null) try { conn.close(); } catch (Exception e) {}
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/><meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <link rel="preconnect" href="https://fonts.googleapis.com"/><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin/><link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:wght@300;400;500;600;700;800&display=swap" rel="stylesheet"/>
    <title>Status — Dictionary™</title>
    <link rel="stylesheet" href="css/style.css"/>
</head>
<body>
<nav class="nav"><div class="nav-inner">
    <span class="nav-brand">Dictionary™</span>
    <ul class="nav-links">
        <li><a href="index.jsp">Browse</a></li>
        <li><a href="messaging.jsp">Messages</a></li>
        <li><a href="profile.jsp">Profile</a></li>
        <li><a href="status.jsp" class="active">Status</a></li>
    </ul>
<div class="nav-actions"><%@ include file="auth-buttons.jsp" %></div></div></nav>

<section class="hero" style="padding:2.5rem 2rem;">
    <div class="hero-inner">
        <span class="hero-tag">System</span>
        <h1><span>Status</span></h1>
    </div>
</section>

<section class="section">
    <div class="section-inner">
        <h2>Database</h2>
        <div style="overflow-x:auto;border:1px solid var(--border);border-radius:var(--radius-lg);">
        <table style="width:100%;border-collapse:collapse;font-size:0.8rem;">
            <thead style="background:var(--bg-card);"><tr><th style="padding:0.6rem 1rem;text-align:left;color:var(--accent);font-size:0.7rem;text-transform:uppercase;">Property</th><th style="padding:0.6rem 1rem;text-align:left;color:var(--accent);font-size:0.7rem;text-transform:uppercase;">Value</th></tr></thead>
            <tbody>
                <tr><td style="padding:0.5rem 1rem;border-top:1px solid var(--border);">Database</td><td style="padding:0.5rem 1rem;border-top:1px solid var(--border);"><code>nwe_dictionary</code></td></tr>
                <tr><td style="padding:0.5rem 1rem;border-top:1px solid var(--border);">Status</td><td style="padding:0.5rem 1rem;border-top:1px solid var(--border);"><%= dbOk ? "<span style='color:#4ade80;'>Connected</span>" : "<span style='color:#f87171;'>Offline</span>" %></td></tr>
                <tr><td style="padding:0.5rem 1rem;border-top:1px solid var(--border);">Terms</td><td style="padding:0.5rem 1rem;border-top:1px solid var(--border);"><%= termCount %></td></tr>
                <tr><td style="padding:0.5rem 1rem;border-top:1px solid var(--border);">Domains</td><td style="padding:0.5rem 1rem;border-top:1px solid var(--border);"><%= domainCount %></td></tr>
                <tr><td style="padding:0.5rem 1rem;border-top:1px solid var(--border);">Revisions</td><td style="padding:0.5rem 1rem;border-top:1px solid var(--border);"><%= revisionCount %></td></tr>
                <tr><td style="padding:0.5rem 1rem;border-top:1px solid var(--border);">Cross-References</td><td style="padding:0.5rem 1rem;border-top:1px solid var(--border);"><%= refCount %></td></tr>
                <tr><td style="padding:0.5rem 1rem;border-top:1px solid var(--border);">Context Path</td><td style="padding:0.5rem 1rem;border-top:1px solid var(--border);"><code>/dictionary</code></td></tr>
                <tr><td style="padding:0.5rem 1rem;border-top:1px solid var(--border);">Theme</td><td style="padding:0.5rem 1rem;border-top:1px solid var(--border);">Dark Scholarly / Gold</td></tr>
                <tr><td style="padding:0.5rem 1rem;border-top:1px solid var(--border);">Installer Tech ID</td><td style="padding:0.5rem 1rem;border-top:1px solid var(--border);">Max Rupplin</td></tr>
            </tbody>
        </table>
        </div>
    </div>
</section>

<footer class="footer"><span>Dictionary™ — Status — MEARVK LLC 2026</span></footer>
</body>
</html>
