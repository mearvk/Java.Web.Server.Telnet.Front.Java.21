<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.*, java.io.*" %>
<%!
    static String esc(String s) { if (s == null) return ""; return s.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;"); }
%>
<%
    List<Map<String,String>> recs = new ArrayList<>();
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        try (Connection conn = DriverManager.getConnection("jdbc:mysql://127.0.0.1:3306/nwe_fiduciary", "root", "")) {
            ResultSet rs = conn.createStatement().executeQuery("SELECT entity_name, entity_type, jurisdiction, fiduciary_type, assets_under_management, established_year, notes FROM records ORDER BY established_year");
            while (rs.next()) {
                Map<String,String> r = new HashMap<>();
                r.put("name", rs.getString("entity_name")); r.put("type", rs.getString("entity_type"));
                r.put("juris", rs.getString("jurisdiction")); r.put("ftype", rs.getString("fiduciary_type"));
                r.put("aum", rs.getString("assets_under_management")); r.put("year", rs.getString("established_year"));
                r.put("notes", rs.getString("notes"));
                recs.add(r);
            }
        }
    } catch (Exception ignored) {}
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/><meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>Records — FiduciaryServices™</title>
    <link rel="stylesheet" href="css/style.css"/>
    <link rel="preconnect" href="https://fonts.googleapis.com"/><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin/>
    <link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:wght@300;400;500;600;700&display=swap" rel="stylesheet"/>
</head>
<body>
<nav class="nav"><div class="nav-inner">
    <span class="nav-brand">FiduciaryServices™</span>
    <ul class="nav-links">
        <li><a href="index.jsp">Overview</a></li>
        <li><a href="architectures.jsp">Architectures</a></li>
        <li><a href="yield.jsp">Yield & Turn</a></li>
        <li><a href="records.jsp" class="active">Records</a></li>
        <li><a href="datapool.jsp">Datapool</a></li>
        <li><a href="documents.jsp">Documents</a></li>
        <li><a href="bright.jsp">Legal Bright</a></li>
        <li><a href="findings.jsp">AI Findings</a></li>
    </ul>
</div></nav>

<section class="hero" style="padding:4rem 2rem;"><div class="hero-inner">
    <span class="hero-tag">Known Fiduciary Entities Worldwide</span>
    <h1>Fiduciary Records</h1>
    <p>Sovereign wealth funds, pension systems, asset managers, central banks — the major fiduciaries operating globally.</p>
</div></section>

<section class="section"><div class="section-inner">
    <% if (!recs.isEmpty()) { %>
    <div class="table-wrap"><table>
        <thead><tr><th>Entity</th><th>Type</th><th>Jurisdiction</th><th>Fiduciary Role</th><th>AUM</th><th>Est.</th></tr></thead>
        <tbody>
        <% for (Map<String,String> r : recs) { %>
        <tr><td><strong><%= esc(r.get("name")) %></strong></td><td><%= esc(r.get("type")) %></td><td><%= esc(r.get("juris")) %></td><td><%= esc(r.get("ftype")) %></td><td><%= esc(r.get("aum")) %></td><td><%= esc(r.get("year")) %></td></tr>
        <% if (r.get("notes") != null && !r.get("notes").isEmpty()) { %>
        <tr><td colspan="6" style="font-size:0.8rem;color:var(--text-muted);padding-left:2rem;"><%= esc(r.get("notes")) %></td></tr>
        <% } %>
        <% } %>
        </tbody>
    </table></div>
    <% } else { %>
    <p style="color:var(--text-muted);">No records loaded. Run <code>fiduciary --populate</code> to load known fiduciary records.</p>
    <% } %>
</div></section>

<footer class="footer"><div><span>© 2026 MEARVK LLC. FiduciaryServices™ — Light Blue Edition.</span></div></footer>
</body></html>
