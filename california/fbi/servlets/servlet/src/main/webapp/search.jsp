<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.Properties, java.io.*" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>Search — CaliforniaFBI™</title>
    <link rel="stylesheet" href="css/style.css"/>
</head>
<body>
<nav class="nav"><div class="nav-inner">
    <span class="nav-brand">CaliforniaFBI™</span>
    <ul class="nav-links">
        <li><a href="index.jsp">Overview</a></li>
        <li><a href="report.jsp">Report</a></li>
        <li><a href="search.jsp" class="active">Search</a></li>
        <li><a href="status.jsp">Status</a></li>
    </ul>
    <div class="nav-actions"><a href="report.jsp" class="nav-cta">File Report →</a></div>
</div></nav>

<section class="hero" style="padding:4rem 2rem;">
    <div class="hero-inner">
        <span class="hero-tag">AI-Assisted Search</span>
        <h1>Search Reports</h1>
    </div>
</section>

<section class="section">
    <div class="section-inner">
        <form method="GET" action="search.jsp" style="max-width:700px;margin:0 auto 2rem;">
            <div style="display:flex;gap:0.5rem;">
                <input type="text" name="q" placeholder="Search by keyword, category, or description..." value="<%= request.getParameter("q") != null ? request.getParameter("q").replace("\"","&quot;") : "" %>" style="flex:1;background:var(--bg-card);color:var(--text-primary);border:1px solid var(--border);border-radius:var(--radius);padding:0.6rem 0.75rem;font-size:0.875rem;"/>
                <button type="submit" class="btn btn-primary">Search</button>
            </div>
        </form>
<%
    String q = request.getParameter("q");
    if (q != null && !q.trim().isEmpty()) {
        q = q.trim();
%>
        <div class="table-wrap">
            <table>
                <thead><tr><th>ID</th><th>Category</th><th>Report</th><th>Status</th><th>Date</th></tr></thead>
                <tbody>
<%
        try {
            Properties p = new Properties();
            InputStream is = application.getResourceAsStream("/WEB-INF/db.properties");
            if (is != null) { p.load(is); is.close(); }
            Class.forName(p.getProperty("db.driver", "com.mysql.cj.jdbc.Driver"));
            try (Connection conn = DriverManager.getConnection(
                    p.getProperty("db.url", "jdbc:mysql://127.0.0.1:3306/nwe_california_fbi"),
                    p.getProperty("db.user", "root"), p.getProperty("db.password", ""));
                 PreparedStatement ps = conn.prepareStatement(
                    "SELECT id, category, LEFT(report_text,120), status, created_at FROM crime_reports WHERE report_text LIKE ? OR category LIKE ? ORDER BY created_at DESC LIMIT 50")) {
                ps.setString(1, "%" + q + "%");
                ps.setString(2, "%" + q + "%");
                ResultSet rs = ps.executeQuery();
                int count = 0;
                while (rs.next()) {
                    count++;
%>
                    <tr>
                        <td><%= rs.getInt(1) %></td>
                        <td><%= rs.getString(2) %></td>
                        <td><%= rs.getString(3) %></td>
                        <td><%= rs.getString(4) %></td>
                        <td><%= rs.getTimestamp(5) %></td>
                    </tr>
<%
                }
                if (count == 0) {
%>
                    <tr><td colspan="5" style="text-align:center;color:var(--text-muted);">No results for "<%= q %>"</td></tr>
<%
                }
            }
        } catch (Exception e) {
%>
                    <tr><td colspan="5" style="color:#ef4444;"><%= e.getMessage() %></td></tr>
<%
        }
%>
                </tbody>
            </table>
        </div>
<%
    }
%>
    </div>
</section>

<footer class="footer"><div><span>&#169; 2026 MEARVK LLC. All rights reserved.</span></div></footer>
</body>
</html>
