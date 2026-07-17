<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.Properties, java.io.*" %>
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"/><meta name="viewport" content="width=device-width, initial-scale=1.0"/><title>Report — CaliforniaCIA™</title><link rel="stylesheet" href="css/style.css"/><script src="js/scroll-preserve.js"></script>
    <link rel="preconnect" href="https://fonts.googleapis.com"/><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin/><link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:ital,wght@0,300;0,400;0,500;0,600;0,700;1,400;1,600&display=swap" rel="stylesheet"/>
    <script src="js/nwe-readme-viewer.js"></script>
</head>
<body>
<nav class="nav"><div class="nav-inner"><span class="nav-brand">CaliforniaCIA™</span>
    <ul class="nav-links">
        <li><a href="index.jsp">Overview</a></li>
        <li><a href="report.jsp" class="active">Report</a></li>
        <li><a href="foia.jsp">FOIA</a></li>
        <li><a href="search.jsp">Search</a></li>
        <li><a href="status.jsp">Status</a></li>
    </ul>
</div></nav>
<section class="hero" style="padding:4rem 2rem;"><div class="hero-inner"><span class="hero-tag">Intelligence Reporting</span><h1>Submit Information</h1><p>Report intelligence information to local database. AI-categorized and queued for review.</p></div></section>

<!-- CD1 Connector Button + Floating Dialog -->
<div style="display:flex;justify-content:center;align-items:center;width:100%;padding:2rem 0;">
    <button id="cd1-btn" type="button" aria-pressed="false" style="all:unset;display:block;margin:0 auto;cursor:pointer;padding:0;border:none;background:transparent;transition:transform 0.3s cubic-bezier(0.42,-1.84,0.42,1.84),filter 0.3s ease;">
        <img src="images/black.button.png" alt="Connector" style="display:block;width:80px;height:80px;border-radius:50%;background:transparent;"/>
    </button>
</div>
<div id="cd1-overlay" style="display:none;position:fixed;inset:0;z-index:299;background:transparent;"></div>
<div id="cd1-dialog" style="display:none;position:fixed;top:50%;left:50%;transform:translate(-50%,-50%);z-index:300;background:#1a1a24;border:1px solid #27272a;border-radius:12px;padding:1.25rem;width:520px;max-width:90vw;box-shadow:0 8px 32px rgba(0,0,0,0.6);"><div style="font-size:0.9rem;font-weight:600;color:#a3e635;margin-bottom:0.75rem;">CIA Report Connector &#8212; Port 49211</div><div style="display:flex;gap:0.5rem;margin-bottom:0.75rem;"><select id="cd1-action" style="background:#111118;color:#fff;border:1px solid #27272a;border-radius:8px;padding:0.45rem;font-size:0.8rem;"><option value="connect">Connect</option><option value="report">Report</option><option value="status">Status</option></select><button onclick="cd1Send()" style="background:#65a30d;color:#fff;border:none;border-radius:8px;padding:0.45rem 1rem;font-size:0.8rem;cursor:pointer;">Send</button><button onclick="cd1Ok()" style="background:#65a30d;color:#fff;border:none;border-radius:8px;padding:0.45rem 1rem;font-size:0.8rem;cursor:pointer;">OK</button></div><label style="font-size:0.7rem;color:#71717a;"><input type="checkbox" id="cd1-direct-port"/> Direct Port</label><textarea id="cd1-textarea" placeholder="Idle..." style="width:100%;min-height:120px;background:#fff;color:#111;border:1px solid #27272a;border-radius:8px;padding:0.75rem;font-family:monospace;font-size:0.8rem;margin-top:0.5rem;resize:vertical;"></textarea></div>
<script>window.CD1_MODULE_PORT="49211";</script>
<script src="js/cd1-connector.js"></script>

<section class="section"><div class="section-inner" style="max-width:700px;">
<%
    String msg = null; String msgColor = "#22c55e";
    if ("POST".equals(request.getMethod())) {
        String category = request.getParameter("category");
        String text = request.getParameter("report_text");
        if (category != null && text != null && !text.trim().isEmpty()) {
            try {
                Properties p = new Properties();
                InputStream is = application.getResourceAsStream("/WEB-INF/db.properties");
                if (is != null) { p.load(is); is.close(); }
                Class.forName(p.getProperty("db.driver", "com.mysql.cj.jdbc.Driver"));
                try (Connection conn = DriverManager.getConnection(p.getProperty("db.url", "jdbc:mysql://127.0.0.1:3306/nwe_california_cia"), p.getProperty("db.user", "root"), p.getProperty("db.password", ""));
                     PreparedStatement ps = conn.prepareStatement("INSERT INTO intelligence_reports (category, report_text, status) VALUES (?, ?, 'pending')")) {
                    ps.setString(1, category); ps.setString(2, text.trim()); ps.executeUpdate();
                    msg = "Report submitted. Category: " + category;
                }
            } catch (Exception e) { msg = "Error: " + e.getMessage(); msgColor = "#ef4444"; }
        } else { msg = "Please fill in all fields."; msgColor = "#ef4444"; }
    }
%>
<% if (msg != null) { %><div style="margin-bottom:1.5rem;padding:1rem;border:1px solid <%=msgColor%>;border-radius:8px;color:<%=msgColor%>;font-size:0.9rem;"><%=msg%></div><% } %>
<h2 style="color:var(--accent-light);margin-bottom:1rem;">Submit Intelligence Report</h2>
<form method="POST" action="report.jsp">
    <div class="form-group"><label>Category</label><select name="category" required>
        <option value="">— Select Category —</option>
        <option value="counterintelligence">Counterintelligence</option>
        <option value="terrorism">Terrorism</option>
        <option value="espionage">Espionage</option>
        <option value="cyber-threats">Cyber Threats</option>
        <option value="weapons-proliferation">Weapons Proliferation</option>
        <option value="foreign-intelligence">Foreign Intelligence Activity</option>
        <option value="corruption">Government Corruption</option>
        <option value="other">Other</option>
    </select></div>
    <div class="form-group"><label>Details</label><textarea name="report_text" placeholder="Describe the intelligence, sources, dates, locations..." required></textarea></div>
    <button type="submit" class="btn btn-primary" style="width:100%;">Submit Report</button>
</form>
<p style="margin-top:1.5rem;font-size:0.8rem;color:var(--text-muted);">For direct CIA reporting: <a href="https://www.cia.gov/report-information/" target="_blank">cia.gov/report-information</a></p>
</div></section>
<footer class="footer"><div><span>CaliforniaCIA™ — Report — Port 49211 — MEARVK LLC — NitroWebExpress™ 2026</span></div></footer>
</body></html>
