<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.Properties, java.io.*" %>
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"/><meta name="viewport" content="width=device-width, initial-scale=1.0"/><title>Report — CaliforniaNSA™</title><link rel="stylesheet" href="css/style.css"/></head>
<body>
<nav class="nav"><div class="nav-inner"><span class="nav-brand">CaliforniaNSA™</span><ul class="nav-links"><li><a href="index.jsp">Overview</a></li><li><a href="report.jsp" class="active">Report</a></li><li><a href="advisories.jsp">Advisories</a></li><li><a href="search.jsp">Search</a></li><li><a href="status.jsp">Status</a></li></ul></div></nav>
<section class="hero" style="padding:4rem 2rem;"><div class="hero-inner"><span class="hero-tag">Cybersecurity Reporting</span><h1>Report Incident</h1><p>Submit cybersecurity incidents, vulnerabilities, or threats. AI-categorized and queued for escalation.</p></div></section>
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
                try (Connection conn = DriverManager.getConnection(p.getProperty("db.url", "jdbc:mysql://127.0.0.1:3306/nwe_california_nsa"), p.getProperty("db.user", "root"), p.getProperty("db.password", ""));
                     PreparedStatement ps = conn.prepareStatement("INSERT INTO cyber_reports (category, report_text, status) VALUES (?, ?, 'pending')")) {
                    ps.setString(1, category); ps.setString(2, text.trim()); ps.executeUpdate();
                    msg = "Report submitted. Category: " + category;
                }
            } catch (Exception e) { msg = "Error: " + e.getMessage(); msgColor = "#ef4444"; }
        } else { msg = "Please fill in all fields."; msgColor = "#ef4444"; }
    }
%>
<% if (msg != null) { %><div style="margin-bottom:1.5rem;padding:1rem;border:1px solid <%=msgColor%>;border-radius:8px;color:<%=msgColor%>;font-size:0.9rem;"><%=msg%></div><% } %>
<form method="POST" action="report.jsp">
    <div class="form-group"><label>Category</label><select name="category" required>
        <option value="">— Select Category —</option>
        <option value="vulnerability">Vulnerability Disclosure</option>
        <option value="malware">Malware / Ransomware</option>
        <option value="intrusion">Network Intrusion</option>
        <option value="phishing">Phishing / Social Engineering</option>
        <option value="insider-threat">Insider Threat</option>
        <option value="data-breach">Data Breach</option>
        <option value="critical-infrastructure">Critical Infrastructure</option>
        <option value="signals">Signals Intelligence</option>
        <option value="other">Other</option>
    </select></div>
    <div class="form-group"><label>Details</label><textarea name="report_text" placeholder="Describe the incident, affected systems, IOCs, timeline..." required></textarea></div>
    <button type="submit" class="btn btn-primary" style="width:100%;">Submit Report</button>
</form>
<p style="margin-top:1.5rem;font-size:0.8rem;color:var(--text-muted);">For direct vulnerability reporting: <a href="https://www.nsa.gov/About/Cryptologic-Heritage/Historical-Figures-Posters/Report-a-Vulnerability/" target="_blank">nsa.gov — Report Vulnerability</a> | <a href="https://www.cisa.gov/report" target="_blank">CISA Reporting</a></p>
</div></section>
<footer class="footer"><div><span>&#169; 2026 MEARVK LLC. All rights reserved.</span></div></footer>
</body></html>
