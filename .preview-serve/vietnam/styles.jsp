<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.*" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>Fighting Styles — Vietnam™</title>
    <link rel="stylesheet" href="css/style.css"/>
    <script src="js/scroll-preserve.js"></script>
</head>
<body>
<nav class="nav"><div class="nav-inner">
    <span class="nav-brand">Vietnam™</span>
    <ul class="nav-links">
        <li><a href="index.jsp">Overview</a></li>
        <li><a href="styles.jsp" class="active">Fighting Styles</a></li>
        <li><a href="languages.jsp">Languages</a></li>
        <li><a href="status.jsp">Status</a></li>
    </ul>
    <div class="nav-actions"><a href="languages.jsp" class="nav-cta">Languages →</a></div>
</div></nav>

<section class="hero" style="padding:4rem 2rem;">
    <div class="hero-inner">
        <span class="hero-tag">Vietnamese Martial Arts</span>
        <h1>Fighting Styles</h1>
        <p>Traditional and modern Vietnamese combat systems from the database.</p>
    </div>
</section>

<section class="section">
    <div class="section-inner">
<%
    String dbUrl = "jdbc:mysql://127.0.0.1:3306/nwe_vietnam";
    String dbUser = "root";
    String dbPass = "";
    String filterName = request.getParameter("name");
    List<Map<String,String>> rows = new ArrayList<>();
    String error = null;

    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        try (Connection conn = DriverManager.getConnection(dbUrl, dbUser, dbPass)) {
            String sql = "SELECT * FROM fighting_styles" + (filterName != null && !filterName.isBlank() ? " WHERE name LIKE ?" : "") + " ORDER BY id";
            PreparedStatement ps = conn.prepareStatement(sql);
            if (filterName != null && !filterName.isBlank()) ps.setString(1, "%" + filterName.trim() + "%");
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                Map<String,String> row = new LinkedHashMap<>();
                row.put("id", String.valueOf(rs.getInt("id")));
                row.put("name", rs.getString("name"));
                row.put("region", rs.getString("region"));
                row.put("era", rs.getString("era"));
                row.put("description", rs.getString("description"));
                row.put("techniques", rs.getString("techniques"));
                rows.add(row);
            }
        }
    } catch (Exception e) { error = e.getMessage(); }
%>
        <div style="margin-bottom:1.5rem;">
            <form method="get" action="styles.jsp" style="display:flex;gap:0.5rem;align-items:center;flex-wrap:wrap;">
                <input type="text" name="name" placeholder="Filter by name..." value="<%= filterName != null ? filterName : "" %>" style="background:#2a2518;color:#e8e0d6;border:1px solid #3d3528;border-radius:8px;padding:0.5rem 0.75rem;font-size:0.875rem;width:240px;"/>
                <button type="submit" class="btn btn-primary">Search</button>
                <a href="styles.jsp" class="btn btn-ghost">Clear</a>
            </form>
        </div>
<% if (error != null) { %>
        <div style="padding:1rem;border:1px solid #ef4444;border-radius:8px;margin-bottom:1rem;color:#ef4444;font-size:0.85rem;">Database error: <%= error %></div>
<% } %>
        <div class="table-wrap">
            <table>
                <thead><tr><th>#</th><th>Name</th><th>Region</th><th>Era</th><th>Description</th><th>Techniques</th></tr></thead>
                <tbody>
<% if (rows.isEmpty()) { %>
                    <tr><td colspan="6" style="text-align:center;color:#9e9486;">No fighting styles found.</td></tr>
<% } else { for (Map<String,String> row : rows) { %>
                    <tr>
                        <td><%= row.get("id") %></td>
                        <td style="color:#e8e0d6;font-weight:600;"><%= row.get("name") %></td>
                        <td><%= row.get("region") %></td>
                        <td><%= row.get("era") %></td>
                        <td><%= row.get("description") %></td>
                        <td><%= row.get("techniques") %></td>
                    </tr>
<% } } %>
                </tbody>
            </table>
        </div>
        <div style="margin-top:1rem;font-size:0.8rem;color:#9e9486;"><%= rows.size() %> record(s) found.</div>
    </div>
</section>

<footer class="footer"><div><span>&#169; 2026 MEARVK LLC. All rights reserved. Vietnam™ — Light Brown.</span></div></footer>
</body>
</html>
