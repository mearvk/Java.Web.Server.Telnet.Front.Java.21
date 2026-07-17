<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.Properties, java.io.*" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/>
    <link rel="preconnect" href="https://fonts.googleapis.com"/><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin/><link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:ital,wght@0,300;0,400;0,500;0,600;0,700;1,400;1,600&display=swap" rel="stylesheet"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>Report — CaliforniaFBI™</title>
    <link rel="stylesheet" href="css/style.css"/>
<script src="js/scroll-preserve.js"></script>
    <script src="js/nwe-readme-viewer.js"></script>
</head>
<body>
<nav class="nav"><div class="nav-inner">
    <span class="nav-brand">CaliforniaFBI™</span>
    <ul class="nav-links">
        <li><a href="index.jsp">Overview</a></li>
        <li><a href="report.jsp" class="active">Report</a></li>
        <li><a href="search.jsp">Search</a></li>
        <li><a href="status.jsp">Status</a></li>
    </ul>
    <div class="nav-actions"><a href="report.jsp" class="nav-cta">File Report →</a></div>
</div></nav>

<section class="hero" style="padding:4rem 2rem;">
    <div class="hero-inner">
        <span class="hero-tag">Crime Reporting</span>
        <h1>File a Report</h1>
        <p>Submit crime information to local database. Reports are AI-categorized and queued for FBI forwarding.</p>
    </div>
</section>

<section class="section">
    <div class="section-inner" style="max-width:700px;">
<%
    String msg = null;
    String msgColor = "#22c55e";
    if ("POST".equals(request.getMethod())) {
        String category = request.getParameter("category");
        String text = request.getParameter("report_text");
        if (category != null && text != null && !text.trim().isEmpty()) {
            try {
                Properties p = new Properties();
                InputStream is = application.getResourceAsStream("/WEB-INF/db.properties");
                if (is != null) { p.load(is); is.close(); }
                Class.forName(p.getProperty("db.driver", "com.mysql.cj.jdbc.Driver"));
                try (Connection conn = DriverManager.getConnection(
                        p.getProperty("db.url", "jdbc:mysql://127.0.0.1:3306/nwe_california_fbi"),
                        p.getProperty("db.user", "root"), p.getProperty("db.password", ""));
                     PreparedStatement ps = conn.prepareStatement(
                        "INSERT INTO crime_reports (category, report_text, status) VALUES (?, ?, 'pending')")) {
                    ps.setString(1, category);
                    ps.setString(2, text.trim());
                    ps.executeUpdate();
                    msg = "Report submitted successfully. Category: " + category;
                }
            } catch (Exception e) {
                msg = "Error: " + e.getMessage();
                msgColor = "#ef4444";
            }
        } else {
            msg = "Please fill in all fields.";
            msgColor = "#ef4444";
        }
    }
%>
<% if (msg != null) { %>
        <div style="margin-bottom:1.5rem;padding:1rem;border:1px solid <%=msgColor%>;border-radius:8px;color:<%=msgColor%>;font-size:0.9rem;"><%=msg%></div>
<% } %>
        <form method="POST" action="report.jsp">
            <div class="form-group">
                <label>Category</label>
                <select name="category" required>
                    <option value="">— Select Crime Category —</option>
                    <option value="violent-crime">Violent Crime</option>
                    <option value="cyber-crime">Cyber Crime (IC3)</option>
                    <option value="public-corruption">Public Corruption</option>
                    <option value="civil-rights">Civil Rights Violations</option>
                    <option value="terrorism">Terrorism / National Security</option>
                    <option value="fraud">Fraud / White Collar Crime</option>
                    <option value="organized-crime">Organized Crime</option>
                    <option value="drugs">Drug Trafficking</option>
                    <option value="missing-persons">Missing Persons / Kidnapping</option>
                    <option value="other">Other</option>
                </select>
            </div>
            <div class="form-group">
                <label>Report Details</label>
                <textarea name="report_text" placeholder="Describe the crime, location, persons involved, dates/times..." required></textarea>
            </div>
            <button type="submit" class="btn btn-primary" style="width:100%;">Submit Report</button>
        </form>
        <p style="margin-top:1.5rem;font-size:0.8rem;color:var(--text-muted);">
            Reports are stored locally with Installer ID Tech™ security and queued for FBI forwarding.
            For emergencies, call 911. For non-emergency FBI tips: <a href="https://tips.fbi.gov/" target="_blank">tips.fbi.gov</a>
        </p>
    </div>
</section>

<footer class="footer"><div><span>&#169; 2026 MEARVK LLC. All rights reserved.</span></div></footer>
</body>
</html>
