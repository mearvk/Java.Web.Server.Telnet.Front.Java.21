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
    <script src="js/nwe-readme-viewer.js"></script>
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
</div></nav>

<section class="hero" style="padding:4rem 2rem;">
    <div class="hero-inner">
        <span class="hero-tag">Vietnamese Martial Arts</span>
        <h1>Fighting Styles</h1>
        <p>Traditional and modern Vietnamese combat systems from the database.</p>
    </div>
</section>

<!-- CD1 Connector Button + Floating Dialog -->
<div style="display:flex;justify-content:center;align-items:center;width:100%;padding:2rem 0;">
    <button id="cd1-btn" type="button" aria-pressed="false" style="all:unset;display:block;margin:0 auto;cursor:pointer;padding:0;border:none;background:transparent;transition:transform 0.3s cubic-bezier(0.42,-1.84,0.42,1.84),filter 0.3s ease;">
        <img src="images/black.button.png" alt="Connector" style="display:block;width:80px;height:80px;border-radius:50%;background:transparent;"/>
    </button>
</div>
<div id="cd1-overlay" style="display:none;position:fixed;inset:0;z-index:299;background:transparent;"></div>
<div id="cd1-dialog" style="display:none;position:fixed;top:50%;left:50%;transform:translate(-50%,-50%);z-index:300;background:#1a1a1a;border:1px solid #333;border-radius:12px;padding:1.25rem;width:520px;max-width:90vw;box-shadow:0 8px 32px rgba(0,0,0,0.6);">
    <div style="font-size:0.9rem;font-weight:600;color:#e8e0d6;margin-bottom:0.75rem;">CD1 Connector &#8212; Port 49215</div>
    <div style="display:flex;gap:0.5rem;margin-bottom:0.75rem;flex-wrap:wrap;align-items:center;">
        <select id="cd1-action" style="background:#222;color:#e8e0d6;border:1px solid #444;border-radius:8px;padding:0.45rem 2rem 0.45rem 0.75rem;font-size:0.8rem;cursor:pointer;appearance:none;">
            <option value="connect">Connect</option>
            <option value="disconnect">Disconnect</option>
            <option value="status">Status</option>
            <option value="hardreset">Hard Reset Connection</option>
        </select>
        <button onclick="cd1Send()" style="background:#666;color:#fff;border:none;border-radius:8px;padding:0.45rem 1rem;font-size:0.8rem;font-weight:600;cursor:pointer;">Send</button>
        <button onclick="cd1Ok()" style="background:#666;color:#fff;border:none;border-radius:8px;padding:0.45rem 1rem;font-size:0.8rem;font-weight:600;cursor:pointer;">OK</button>
    </div>
    <div style="display:flex;align-items:center;gap:0.5rem;margin-bottom:0.75rem;">
        <label style="display:flex;align-items:center;gap:0.4rem;color:#999;font-size:0.75rem;cursor:pointer;">
            <input type="checkbox" id="cd1-direct-port" style="accent-color:#888;width:14px;height:14px;cursor:pointer;"/>
            Direct Port (bypass Strernary&#8482; 20000)
        </label>
        <span id="cd1-mode-badge" style="font-size:0.65rem;background:#222;color:#aaa;padding:0.2rem 0.5rem;border-radius:4px;">STRERNARY</span>
    </div>
    <textarea id="cd1-textarea" placeholder="Connection idle..." spellcheck="false" style="width:100%;min-height:140px;background:#ffffff;color:#111;border:1px solid #333;border-radius:8px;padding:0.75rem;font-family:monospace;font-size:0.8rem;resize:vertical;"></textarea>
</div>
<script>window.CD1_MODULE_PORT = "49215";</script>
<script src="js/cd1-connector.js"></script>


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
