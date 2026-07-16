<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.*" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>Instructions — Emeter™</title>
    <link rel="stylesheet" href="css/style.css"/>
    <script src="js/scroll-preserve.js"></script>
</head>
<body>
<nav class="nav"><div class="nav-inner">
    <span class="nav-brand">Emeter™</span>
    <ul class="nav-links">
        <li><a href="index.jsp">Overview</a></li>
        <li><a href="instructions.jsp" class="active">Instructions</a></li>
        <li><a href="calibration.jsp">Calibration</a></li>
        <li><a href="readings.jsp">Readings</a></li>
        <li><a href="status.jsp">Status</a></li>
    </ul>
    <div class="nav-actions">
        <a href="calibration.jsp" class="nav-cta">Calibration →</a>
    </div>
</div></nav>

<section class="hero" style="padding:4rem 2rem;">
    <div class="hero-inner">
        <span class="hero-tag">E-Meter Curriculum</span>
        <h1>Instructions</h1>
        <p>Complete instruction database — theory, operation, and advanced technique.</p>
    </div>
</section>

<section class="section">
    <div class="section-inner">
<%
    String dbUrl = "jdbc:mysql://127.0.0.1:3306/nwe_emeter";
    String dbUser = "root";
    String dbPass = "";
    String filterTopic = request.getParameter("topic");
    String filterLevel = request.getParameter("level");

    List<Map<String, String>> rows = new ArrayList<>();
    String error = null;

    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        try (Connection conn = DriverManager.getConnection(dbUrl, dbUser, dbPass)) {
            StringBuilder sql = new StringBuilder("SELECT id, topic, level, content, created_at FROM instructions WHERE 1=1");
            List<String> params = new ArrayList<>();
            if (filterTopic != null && !filterTopic.isBlank()) {
                sql.append(" AND topic LIKE ?");
                params.add("%" + filterTopic.trim() + "%");
            }
            if (filterLevel != null && !filterLevel.isBlank()) {
                sql.append(" AND level = ?");
                params.add(filterLevel.trim());
            }
            sql.append(" ORDER BY level, topic LIMIT 100");

            try (PreparedStatement ps = conn.prepareStatement(sql.toString())) {
                for (int i = 0; i < params.size(); i++) ps.setString(i + 1, params.get(i));
                ResultSet rs = ps.executeQuery();
                while (rs.next()) {
                    Map<String, String> row = new LinkedHashMap<>();
                    row.put("id", String.valueOf(rs.getInt("id")));
                    row.put("topic", rs.getString("topic"));
                    row.put("level", rs.getString("level"));
                    row.put("content", rs.getString("content"));
                    row.put("created_at", rs.getTimestamp("created_at") != null ? rs.getTimestamp("created_at").toString() : "—");
                    rows.add(row);
                }
            }
        }
    } catch (Exception e) {
        error = e.getMessage();
    }
%>
        <div style="margin-bottom:1.5rem;display:flex;gap:1rem;flex-wrap:wrap;align-items:flex-end;">
            <form method="get" style="display:flex;gap:0.75rem;flex-wrap:wrap;align-items:flex-end;">
                <div class="form-group" style="margin-bottom:0;">
                    <label>Topic</label>
                    <input type="text" name="topic" value="<%= filterTopic != null ? filterTopic : "" %>" placeholder="Search topics..." style="width:200px;"/>
                </div>
                <div class="form-group" style="margin-bottom:0;">
                    <label>Level</label>
                    <select name="level" style="width:160px;">
                        <option value="">All Levels</option>
                        <option value="Beginner" <%= "Beginner".equals(filterLevel) ? "selected" : "" %>>Beginner</option>
                        <option value="Intermediate" <%= "Intermediate".equals(filterLevel) ? "selected" : "" %>>Intermediate</option>
                        <option value="Advanced" <%= "Advanced".equals(filterLevel) ? "selected" : "" %>>Advanced</option>
                    </select>
                </div>
                <button type="submit" class="btn btn-primary" style="padding:0.5rem 1rem;">Filter</button>
            </form>
        </div>

<% if (error != null) { %>
        <div style="padding:1rem;border:1px solid #ef4444;border-radius:8px;background:rgba(239,68,68,0.05);margin-bottom:1.5rem;">
            <span style="color:#ef4444;font-size:0.85rem;">Database error: <%= error %></span>
        </div>
<% } else if (rows.isEmpty()) { %>
        <div style="padding:1rem;border:1px solid var(--border);border-radius:8px;background:var(--bg-section);margin-bottom:1.5rem;">
            <span style="color:var(--text-muted);font-size:0.85rem;">No instructions found. Database may be empty — run <code>setup-db.sh</code> to initialize.</span>
        </div>
<% } else { %>
        <div class="table-wrap">
            <table>
                <thead><tr><th>ID</th><th>Topic</th><th>Level</th><th>Content</th><th>Created</th></tr></thead>
                <tbody>
<% for (Map<String, String> row : rows) { %>
                    <tr>
                        <td><code><%= row.get("id") %></code></td>
                        <td><%= row.get("topic") %></td>
                        <td><%= row.get("level") %></td>
                        <td style="max-width:400px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;"><%= row.get("content").length() > 120 ? row.get("content").substring(0, 120) + "..." : row.get("content") %></td>
                        <td style="font-size:0.8rem;color:var(--text-muted);"><%= row.get("created_at") %></td>
                    </tr>
<% } %>
                </tbody>
            </table>
        </div>
        <p style="margin-top:1rem;font-size:0.8rem;color:var(--text-muted);"><%= rows.size() %> record(s) returned.</p>
<% } %>
    </div>
</section>

<footer class="footer"><div><span>&#169; 2026 MEARVK LLC. All rights reserved. Emeter™ — NitroWebExpress™</span></div></footer>
</body>
</html>
