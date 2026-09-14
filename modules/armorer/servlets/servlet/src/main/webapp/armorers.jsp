<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.*, java.io.*" %>
<%!
    static String esc(String s) { if (s == null) return ""; return s.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;"); }
%>
<%
    List<Map<String,String>> armorers = new ArrayList<>();
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        try (Connection conn = DriverManager.getConnection("jdbc:mysql://127.0.0.1:3306/nwe_armorer", "root", "")) {
            ResultSet rs = conn.createStatement().executeQuery("SELECT name, location, specialty, era, notable_works, series_wins, active FROM armorers ORDER BY series_wins DESC");
            while (rs.next()) {
                Map<String,String> r = new HashMap<>();
                r.put("name", rs.getString("name")); r.put("loc", rs.getString("location"));
                r.put("spec", rs.getString("specialty")); r.put("era", rs.getString("era"));
                r.put("works", rs.getString("notable_works")); r.put("wins", String.valueOf(rs.getInt("series_wins")));
                r.put("active", rs.getBoolean("active") ? "Active" : "Historical");
                armorers.add(r);
            }
        }
    } catch (Exception ignored) {}
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/><meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>Known Armorers — ArmorerSteve™</title>
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
        <li><a href="armorers.jsp" class="active">Known Armorers</a></li>
        <li><a href="regulations.jsp">Regulations</a></li>
        <li><a href="trade.jsp">Trade</a></li>
        <li><a href="messaging.jsp">Messages</a></li>
    </ul>
</div></nav>

<section class="hero" style="padding:4rem 2rem;"><div class="hero-inner">
    <span class="hero-tag">Historical & Modern Masters</span>
    <h1>Known Armorers</h1>
    <p>The masters of the metal arts — from medieval court armorers to modern competition forge operators. Ranked by series wins.</p>
</div></section>

<section class="section"><div class="section-inner">
    <% if (!armorers.isEmpty()) { %>
    <div class="table-wrap"><table>
        <thead><tr><th>Armorer</th><th>Location</th><th>Specialty</th><th>Era</th><th>Series Wins</th><th>Notable Works</th></tr></thead>
        <tbody>
        <% for (Map<String,String> a : armorers) { %>
            <tr>
                <td style="font-weight:700;color:#fff;"><%= esc(a.get("name")) %></td>
                <td><%= esc(a.get("loc")) %></td>
                <td><%= esc(a.get("spec")) %></td>
                <td style="font-size:0.8rem;"><%= esc(a.get("era")) %></td>
                <td style="color:#f59e0b;font-weight:600;text-align:center;"><%= a.get("wins") %></td>
                <td style="font-size:0.8rem;"><%= esc(a.get("works")) %></td>
            </tr>
        <% } %>
        </tbody>
    </table></div>
    <% } else { %>
    <p style="color:var(--text-muted);">No armorers in database yet. Run <code>armorer --populate</code> to seed the knowledge base.</p>
    <% } %>
</div></section>

<footer class="footer"><div><span>© 2026 MEARVK LLC. ArmorerSteve™ — Dark Blue Edition.</span></div></footer>
</body></html>
