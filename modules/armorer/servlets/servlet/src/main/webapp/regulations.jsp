<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.*, java.io.*" %>
<%!
    static String esc(String s) { if (s == null) return ""; return s.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;"); }
%>
<%
    List<Map<String,String>> regs = new ArrayList<>();
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        try (Connection conn = DriverManager.getConnection("jdbc:mysql://127.0.0.1:3306/nwe_armorer", "root", "")) {
            ResultSet rs = conn.createStatement().executeQuery("SELECT body, regulation_name, scope, description, series FROM regulations ORDER BY body");
            while (rs.next()) {
                Map<String,String> r = new HashMap<>();
                r.put("body", rs.getString("body")); r.put("name", rs.getString("regulation_name"));
                r.put("scope", rs.getString("scope")); r.put("desc", rs.getString("description"));
                r.put("series", rs.getString("series"));
                regs.add(r);
            }
        }
    } catch (Exception ignored) {}
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/><meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>Regulations — ArmorerSteve™</title>
    <link rel="stylesheet" href="css/style.css"/>
    <link rel="preconnect" href="https://fonts.googleapis.com"/><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin/>
    <link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:wght@300;400;500;600;700&display=swap" rel="stylesheet"/>
</head>
<body>
<nav class="nav"><div class="nav-inner">
    <span class="nav-brand">ArmorerSteve™</span>
    <ul class="nav-links">
        <li><a href="index.jsp">Ask Steve</a></li>
        <li><a href="costs.jsp">Cost Estimator</a></li>
        <li><a href="armorers.jsp">Known Armorers</a></li>
        <li><a href="regulations.jsp" class="active">Regulations</a></li>
        <li><a href="trade.jsp">Trade</a></li>
        <li><a href="messaging.jsp">Messages</a></li>
    </ul>
</div></nav>

<section class="hero" style="padding:4rem 2rem;"><div class="hero-inner">
    <span class="hero-tag">Standards & Compliance</span>
    <h1>Armor Regulations</h1>
    <p>Who decides armor standards? The regulatory bodies, thickness requirements, and series rules that govern armor in competition and military use.</p>
</div></section>

<section class="section"><div class="section-inner">
    <% if (!regs.isEmpty()) { %>
    <% for (Map<String,String> r : regs) { %>
    <div style="margin-bottom:1.5rem;padding:1.25rem;background:var(--bg-card);border:1px solid var(--border);border-radius:8px;">
        <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:0.5rem;">
            <span style="font-weight:700;color:#fff;font-size:1rem;"><%= esc(r.get("body")) %> — <%= esc(r.get("name")) %></span>
            <span style="font-size:0.7rem;background:var(--accent);color:#fff;padding:0.2rem 0.5rem;border-radius:4px;"><%= esc(r.get("series")) %></span>
        </div>
        <div style="font-size:0.75rem;color:var(--text-muted);margin-bottom:0.5rem;">Scope: <%= esc(r.get("scope")) %></div>
        <div style="font-size:0.85rem;color:var(--text-secondary);line-height:1.5;"><%= esc(r.get("desc")) %></div>
    </div>
    <% } %>
    <% } else { %>
    <p style="color:var(--text-muted);">No regulations in database yet. Run <code>armorer --populate</code> to seed.</p>
    <% } %>
</div></section>

<footer class="footer"><div><span>© 2026 MEARVK LLC. ArmorerSteve™ — Dark Blue Edition.</span></div></footer>
</body></html>
