<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.*, java.io.*" %>
<%!
    static String esc(String s) { if (s == null) return ""; return s.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;"); }
%>
<%
    List<Map<String,String>> archs = new ArrayList<>();
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        try (Connection conn = DriverManager.getConnection("jdbc:mysql://127.0.0.1:3306/nwe_fiduciary", "root", "")) {
            ResultSet rs = conn.createStatement().executeQuery("SELECT name, description, structure_type, yield_profile, turn_period, jurisdiction, risk_grade, advantage_class FROM architectures ORDER BY risk_grade");
            while (rs.next()) {
                Map<String,String> r = new HashMap<>();
                r.put("name", rs.getString("name")); r.put("desc", rs.getString("description"));
                r.put("type", rs.getString("structure_type")); r.put("yield", rs.getString("yield_profile"));
                r.put("turn", rs.getString("turn_period")); r.put("juris", rs.getString("jurisdiction"));
                r.put("risk", rs.getString("risk_grade")); r.put("adv", rs.getString("advantage_class"));
                archs.add(r);
            }
        }
    } catch (Exception ignored) {}
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/><meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>Architectures — FiduciaryServices™</title>
    <link rel="stylesheet" href="css/style.css"/>
    <link rel="preconnect" href="https://fonts.googleapis.com"/><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin/>
    <link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:wght@300;400;500;600;700&display=swap" rel="stylesheet"/>
</head>
<body>
<nav class="nav"><div class="nav-inner">
    <span class="nav-brand">FiduciaryServices™</span>
    <ul class="nav-links">
        <li><a href="index.jsp">Overview</a></li>
        <li><a href="architectures.jsp" class="active">Architectures</a></li>
        <li><a href="yield.jsp">Yield & Turn</a></li>
        <li><a href="records.jsp">Records</a></li>
        <li><a href="datapool.jsp">Datapool</a></li>
        <li><a href="documents.jsp">Documents</a></li>
        <li><a href="bright.jsp">Legal Bright</a></li>
        <li><a href="findings.jsp">AI Findings</a></li>
    </ul>
</div></nav>

<section class="hero" style="padding:4rem 2rem;"><div class="hero-inner">
    <span class="hero-tag">Institutional Design Enabling Trust</span>
    <h1>Fiduciary Architectures</h1>
    <p>The structures that polyblend into a basic assumption of yield and turn — each architecture defines roles, duties, accountability, and distribution methods.</p>
</div></section>

<section class="section"><div class="section-inner">
    <% if (!archs.isEmpty()) { %>
    <% for (Map<String,String> a : archs) { %>
    <div class="card">
        <div style="display:flex;justify-content:space-between;align-items:center;flex-wrap:wrap;">
            <h3><%= esc(a.get("name")) %></h3>
            <span style="font-size:0.7rem;background:var(--accent);color:#fff;padding:0.2rem 0.6rem;border-radius:4px;"><%= esc(a.get("type")) %> • Risk: <%= esc(a.get("risk")) %></span>
        </div>
        <p style="margin:0.75rem 0;"><%= esc(a.get("desc")) %></p>
        <div class="table-wrap" style="margin-top:0.75rem;"><table>
            <tr><th>Yield Profile</th><td><%= esc(a.get("yield")) %></td><th>Turn Period</th><td><%= esc(a.get("turn")) %></td></tr>
            <tr><th>Jurisdiction</th><td><%= esc(a.get("juris")) %></td><th>Advantage Class</th><td><%= esc(a.get("adv")) %></td></tr>
        </table></div>
    </div>
    <% } %>
    <% } else { %>
    <p style="color:var(--text-muted);">No architectures loaded. Run <code>fiduciary --populate</code> or execute the SQL population script.</p>
    <% } %>
</div></section>

<footer class="footer"><div><span>© 2026 MEARVK LLC. FiduciaryServices™ — Light Blue Edition.</span></div></footer>
</body></html>
