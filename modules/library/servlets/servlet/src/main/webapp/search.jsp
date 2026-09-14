<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.Properties, java.io.*" %>
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"/><meta name="viewport" content="width=device-width, initial-scale=1.0"/><title>Search — StanfordLibrary™</title><link rel="stylesheet" href="css/style.css"/><script src="js/scroll-preserve.js"></script>
    <link rel="preconnect" href="https://fonts.googleapis.com"/><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin/><link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:ital,wght@0,300;0,400;0,500;0,600;0,700;1,400;1,600&display=swap" rel="stylesheet"/>
    <script src="js/nwe-readme-viewer.js"></script>
</head>
<body>
<nav class="nav"><div class="nav-inner"><span class="nav-brand">StanfordLibrary™</span><ul class="nav-links"><li><a href="index.jsp">Overview</a></li><li><a href="search.jsp" class="active">Search</a></li><li><a href="request.jsp">Request</a></li><li><a href="status.jsp">Status</a></li></ul></div></nav>
<section class="hero" style="padding:4rem 2rem;"><div class="hero-inner"><span class="hero-tag">Catalog Search</span><h1>Search Library</h1></div></section>

<!-- CD1 Connector Button + Floating Dialog -->
<div style="display:flex;justify-content:center;align-items:center;width:100%;padding:2rem 0;">
    <button id="cd1-btn" type="button" aria-pressed="false" style="all:unset;display:block;margin:0 auto;cursor:pointer;padding:0;border:none;background:transparent;transition:transform 0.3s cubic-bezier(0.42,-1.84,0.42,1.84),filter 0.3s ease;">
        <img src="images/black.button.png" alt="Connector" style="display:block;width:80px;height:80px;border-radius:50%;background:transparent;"/>
    </button>
</div>
<div id="cd1-overlay" style="display:none;position:fixed;inset:0;z-index:299;background:transparent;"></div>
<div id="cd1-dialog" style="display:none;position:fixed;top:50%;left:50%;transform:translate(-50%,-50%);z-index:300;background:#1a1a1a;border:1px solid #333;border-radius:12px;padding:1.25rem;width:520px;max-width:90vw;box-shadow:0 8px 32px rgba(0,0,0,0.6);"><div style="font-size:0.9rem;font-weight:600;color:#e8e0d6;margin-bottom:0.75rem;">CD1 Connector &mdash; Port 49214</div><div style="display:flex;gap:0.5rem;margin-bottom:0.75rem;flex-wrap:wrap;align-items:center;"><select id="cd1-action" style="background:#222;color:#e8e0d6;border:1px solid #444;border-radius:8px;padding:0.45rem 2rem 0.45rem 0.75rem;font-size:0.8rem;cursor:pointer;appearance:none;"><option value="connect">Connect</option><option value="disconnect">Disconnect</option><option value="status">Status</option><option value="hardreset">Hard Reset Connection</option></select><button onclick="cd1Send()" style="background:#666;color:#fff;border:none;border-radius:8px;padding:0.45rem 1rem;font-size:0.8rem;font-weight:600;cursor:pointer;">Send</button><button onclick="cd1Ok()" style="background:#666;color:#fff;border:none;border-radius:8px;padding:0.45rem 1rem;font-size:0.8rem;font-weight:600;cursor:pointer;">OK</button></div><div style="display:flex;align-items:center;gap:0.5rem;margin-bottom:0.75rem;"><label style="display:flex;align-items:center;gap:0.4rem;color:#999;font-size:0.75rem;cursor:pointer;"><input type="checkbox" id="cd1-direct-port" style="accent-color:#888;width:14px;height:14px;cursor:pointer;"/>Direct Port (bypass Strernary&trade; 20000)</label><span id="cd1-mode-badge" style="font-size:0.65rem;background:#222;color:#aaa;padding:0.2rem 0.5rem;border-radius:4px;">STRERNARY</span></div><textarea id="cd1-textarea" placeholder="Connection idle..." spellcheck="false" style="width:100%;min-height:140px;background:#ffffff;color:#111;border:1px solid #333;border-radius:8px;padding:0.75rem;font-family:monospace;font-size:0.8rem;resize:vertical;"></textarea></div>
<script>window.CD1_MODULE_PORT = "49214";</script>
<script src="js/cd1-connector.js"></script>
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
