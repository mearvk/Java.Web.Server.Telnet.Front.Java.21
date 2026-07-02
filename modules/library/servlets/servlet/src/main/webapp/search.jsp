<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.Properties, java.io.*" %>
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"/><meta name="viewport" content="width=device-width, initial-scale=1.0"/><title>Search — StanfordLibrary™</title><link rel="stylesheet" href="css/style.css"/><script src="js/scroll-preserve.js"></script>
</head>
<body>
<nav class="nav"><div class="nav-inner"><span class="nav-brand">StanfordLibrary™</span><ul class="nav-links"><li><a href="index.jsp">Overview</a></li><li><a href="search.jsp" class="active">Search</a></li><li><a href="request.jsp">Request</a></li><li><a href="status.jsp">Status</a></li></ul></div></nav>
<section class="hero" style="padding:4rem 2rem;"><div class="hero-inner"><span class="hero-tag">Catalog Search</span><h1>Search Library</h1></div></section>
<section class="section"><div class="section-inner">
<form method="GET" action="search.jsp" style="max-width:700px;margin:0 auto 2rem;"><div style="display:flex;gap:0.5rem;">
    <input type="text" name="q" placeholder="Search by title, author, subject..." value="<%= request.getParameter("q") != null ? request.getParameter("q").replace("\"","&quot;") : "" %>" style="flex:1;background:var(--bg-card);color:var(--text-primary);border:1px solid var(--border);border-radius:var(--radius);padding:0.6rem 0.75rem;font-size:0.875rem;"/>
    <button type="submit" class="btn btn-primary">Search</button>
    <a href="https://searchworks.stanford.edu/catalog?search_field=search&q=<%= request.getParameter("q") != null ? java.net.URLEncoder.encode(request.getParameter("q"),"UTF-8") : "" %>" target="_blank" class="btn btn-primary" style="background:#8C1515;">SearchWorks →</a>
</div></form>
<%
    String q = request.getParameter("q");
    if (q != null && !q.trim().isEmpty()) {
%>
<div class="table-wrap"><table><thead><tr><th>ID</th><th>Title</th><th>Type</th><th>Status</th><th>Date</th></tr></thead><tbody>
<%
        try {
            Properties p = new Properties(); InputStream is = application.getResourceAsStream("/WEB-INF/db.properties"); if (is != null) { p.load(is); is.close(); }
            Class.forName(p.getProperty("db.driver", "com.mysql.cj.jdbc.Driver"));
            try (Connection conn = DriverManager.getConnection(p.getProperty("db.url"), p.getProperty("db.user", "root"), p.getProperty("db.password", ""));
                 PreparedStatement ps = conn.prepareStatement("SELECT id, LEFT(title,100), resource_type, status, created_at FROM library_requests WHERE title LIKE ? ORDER BY created_at DESC LIMIT 50")) {
                ps.setString(1, "%" + q.trim() + "%"); ResultSet rs = ps.executeQuery(); int c = 0;
                while (rs.next()) { c++; %><tr><td><%=rs.getInt(1)%></td><td><%=rs.getString(2)%></td><td><%=rs.getString(3)%></td><td><%=rs.getString(4)%></td><td><%=rs.getTimestamp(5)%></td></tr><% }
                if (c == 0) { %><tr><td colspan="5" style="text-align:center;color:var(--text-muted);">No local results — try <a href="https://searchworks.stanford.edu/" target="_blank">SearchWorks</a></td></tr><% }
            }
        } catch (Exception e) { %><tr><td colspan="5" style="color:#ef4444;"><%=e.getMessage()%></td></tr><% }
%>
</tbody></table></div>
<% } %>
</div></section>
<footer class="footer"><div><span>&#169; 2026 MEARVK LLC. All rights reserved.</span></div></footer>
</body></html>
