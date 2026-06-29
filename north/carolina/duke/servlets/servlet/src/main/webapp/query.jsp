<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.Properties, java.io.*" %>
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"/><meta name="viewport" content="width=device-width, initial-scale=1.0"/><title>Query — DukeUniversity™</title><link rel="stylesheet" href="css/style.css"/></head>
<body>
<nav class="nav"><div class="nav-inner"><span class="nav-brand">DukeUniversity™</span><ul class="nav-links"><li><a href="index.jsp">Overview</a></li><li><a href="colleges.jsp">Colleges</a></li><li><a href="query.jsp" class="active">Query</a></li><li><a href="status.jsp">Status</a></li></ul></div></nav>
<section class="hero" style="padding:4rem 2rem;"><div class="hero-inner"><span class="hero-tag">College Query</span><h1>Submit Query</h1></div></section>
<section class="section"><div class="section-inner" style="max-width:700px;">
<%
    String msg = null; String msgColor = "#22c55e";
    if ("POST".equals(request.getMethod())) {
        String college = request.getParameter("college"), text = request.getParameter("query_text");
        if (college != null && text != null && !text.trim().isEmpty()) {
            try {
                Properties p = new Properties(); InputStream is = application.getResourceAsStream("/WEB-INF/db.properties"); if (is != null) { p.load(is); is.close(); }
                Class.forName(p.getProperty("db.driver", "com.mysql.cj.jdbc.Driver"));
                try (Connection conn = DriverManager.getConnection(p.getProperty("db.url"), p.getProperty("db.user", "root"), p.getProperty("db.password", ""));
                     PreparedStatement ps = conn.prepareStatement("INSERT INTO college_queries (college, query_text) VALUES (?, ?)")) {
                    ps.setString(1, college); ps.setString(2, text.trim()); ps.executeUpdate(); msg = "Query submitted to " + college;
                }
            } catch (Exception e) { msg = "Error: " + e.getMessage(); msgColor = "#ef4444"; }
        } else { msg = "Please fill in all fields."; msgColor = "#ef4444"; }
    }
%>
<% if (msg != null) { %><div style="margin-bottom:1.5rem;padding:1rem;border:1px solid <%=msgColor%>;border-radius:8px;color:<%=msgColor%>;font-size:0.9rem;"><%=msg%></div><% } %>
<form method="POST" action="query.jsp">
    <div class="form-group"><label>College/School</label><select name="college" required>
        <option value="">— Select —</option>
        <option value="Trinity College">Trinity College of Arts & Sciences</option>
        <option value="Pratt Engineering">Pratt School of Engineering</option>
        <option value="Fuqua Business">Fuqua School of Business</option>
        <option value="School of Law">School of Law</option>
        <option value="School of Medicine">School of Medicine</option>
        <option value="Nicholas Environment">Nicholas School of the Environment</option>
        <option value="Sanford Public Policy">Sanford School of Public Policy</option>
        <option value="Divinity School">Divinity School</option>
        <option value="Graduate School">Graduate School</option>
        <option value="School of Nursing">School of Nursing</option>
    </select></div>
    <div class="form-group"><label>Query</label><textarea name="query_text" placeholder="Your question about admissions, courses, research, programs..." required></textarea></div>
    <button type="submit" class="btn btn-primary" style="width:100%;">Submit Query</button>
</form>
</div></section>
<footer class="footer"><div><span>&#169; 2026 MEARVK LLC. All rights reserved.</span></div></footer>
</body></html>
