<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.*, java.io.*" %>
<%!
    static String esc(String s) { if (s == null) return ""; return s.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;"); }
    static String trunc(String s, int max) { if (s == null) return ""; return s.length() > max ? s.substring(0, max) + "..." : s; }
%>
<%
    String filterHalf = request.getParameter("half");
    List<Map<String,String>> entries = new ArrayList<>();
    List<Map<String,String>> treasures = new ArrayList<>();
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        try (Connection conn = DriverManager.getConnection("jdbc:mysql://127.0.0.1:3306/nwe_fiduciary", "root", "")) {
            String sql = "SELECT calendar_half, entry_name, concern_type, LEFT(description, 400) AS description, benefit_to, nuisance_resolution, LEFT(council_note, 200) AS council_note, confidence FROM legal_bright";
            if ("TOP".equals(filterHalf)) sql += " WHERE calendar_half = 'TOP'";
            else if ("BOTTOM".equals(filterHalf)) sql += " WHERE calendar_half = 'BOTTOM'";
            sql += " ORDER BY calendar_half DESC, confidence DESC";
            ResultSet rs = conn.createStatement().executeQuery(sql);
            while (rs.next()) {
                Map<String,String> r = new HashMap<>();
                r.put("half", rs.getString("calendar_half")); r.put("name", rs.getString("entry_name"));
                r.put("type", rs.getString("concern_type")); r.put("desc", rs.getString("description"));
                r.put("benefit", rs.getString("benefit_to")); r.put("nuisance", rs.getString("nuisance_resolution"));
                r.put("council", rs.getString("council_note")); r.put("conf", rs.getString("confidence"));
                entries.add(r);
            }
            ResultSet rs2 = conn.createStatement().executeQuery(
                "SELECT law_structure, approach_type, treasure_class, fiduciary_standing, LEFT(profitable_idea, 200) AS idea, LEFT(council_resolution, 200) AS council, jurisdiction, confidence FROM treasure_fiduciary ORDER BY confidence DESC");
            while (rs2.next()) {
                Map<String,String> r = new HashMap<>();
                r.put("law", rs2.getString("law_structure")); r.put("approach", rs2.getString("approach_type"));
                r.put("class", rs2.getString("treasure_class")); r.put("standing", rs2.getString("fiduciary_standing"));
                r.put("idea", rs2.getString("idea")); r.put("council", rs2.getString("council"));
                r.put("juris", rs2.getString("jurisdiction")); r.put("conf", rs2.getString("confidence"));
                treasures.add(r);
            }
        }
    } catch (Exception ignored) {}
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/><meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>Legal Bright — FiduciaryServices™</title>
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
        <li><a href="records.jsp">Records</a></li>
        <li><a href="datapool.jsp">Datapool</a></li>
        <li><a href="documents.jsp">Documents</a></li>
        <li><a href="bright.jsp" class="active">Legal Bright</a></li>
        <li><a href="findings.jsp">AI Findings</a></li>
    </ul>
</div></nav>

<section class="hero" style="padding:4rem 2rem;"><div class="hero-inner">
    <span class="hero-tag">INT/IQ Calendar • Ideals & Totals • Treasure Fiduciary • Council</span>
    <h1>Legal Bright</h1>
    <p>The INT/IQ Calendar — Top half: personal interests benefiting the county, surrounding equal ideas as brilliant or pertinent. Bottom half: Treasure for Fiduciary, evident approach to all law structure, State Nuisance resolved as Council.</p>
</div></section>

<section class="section"><div class="section-inner">
    <h2>INT/IQ Calendar</h2>
    <div style="display:flex;gap:0.5rem;margin-bottom:1.5rem;">
        <a href="bright.jsp" class="btn btn-primary" style="font-size:0.75rem;">All</a>
        <a href="bright.jsp?half=TOP" class="btn" style="font-size:0.75rem;background:var(--bg-card);color:var(--accent-light);border:1px solid var(--border);">TOP HALF — Personal Interest → County Benefit</a>
        <a href="bright.jsp?half=BOTTOM" class="btn" style="font-size:0.75rem;background:var(--bg-card);color:var(--accent-light);border:1px solid var(--border);">BOTTOM HALF — Treasure • Nuisance • Try</a>
    </div>

    <% if (!entries.isEmpty()) { %>
    <% for (Map<String,String> e : entries) { %>
    <div class="card">
        <div style="display:flex;justify-content:space-between;align-items:center;flex-wrap:wrap;gap:0.5rem;">
            <h3><%= esc(e.get("name")) %></h3>
            <div style="display:flex;gap:0.4rem;">
                <span style="font-size:0.65rem;background:<%= "TOP".equals(e.get("half")) ? "#14532d" : "#1e3a5f" %>;color:<%= "TOP".equals(e.get("half")) ? "#86efac" : "#93c5fd" %>;padding:0.15rem 0.5rem;border-radius:3px;"><%= esc(e.get("half")) %> HALF</span>
                <span style="font-size:0.65rem;background:var(--bg-section);color:var(--text-muted);padding:0.15rem 0.5rem;border-radius:3px;"><%= esc(e.get("type")) %></span>
                <span style="font-size:0.65rem;background:var(--bg-section);color:var(--text-muted);padding:0.15rem 0.5rem;border-radius:3px;"><%= esc(e.get("conf")) %>%</span>
            </div>
        </div>
        <p style="margin:0.75rem 0;font-size:0.85rem;"><%= esc(e.get("desc")) %></p>
        <% if (e.get("benefit") != null) { %><p class="meta">Benefit to: <strong><%= esc(e.get("benefit")) %></strong></p><% } %>
        <% if (e.get("nuisance") != null && !e.get("nuisance").isEmpty()) { %><p class="meta" style="margin-top:0.3rem;">Nuisance Resolution: <%= esc(e.get("nuisance")) %></p><% } %>
        <% if (e.get("council") != null && !e.get("council").isEmpty()) { %><p class="meta" style="margin-top:0.3rem;color:var(--accent-light);">Council: <%= esc(trunc(e.get("council"), 200)) %></p><% } %>
    </div>
    <% } %>
    <% } else { %>
    <p style="color:var(--text-muted);">No Legal Bright entries loaded. Run:<br><code>mysql -u root nwe_fiduciary < modules/fiduciary/documents/legal_bright_iq_calendar.sql</code></p>
    <% } %>
</div></section>

<% if (!treasures.isEmpty()) { %>
<section class="section"><div class="section-inner">
    <h2>Treasure Fiduciary — Law Structure Approach</h2>
    <p style="color:var(--text-secondary);margin-bottom:1.5rem;">A Treasure Fiduciary can and may approach all law structure as evident. Capability + Permission.</p>

    <div class="table-wrap"><table>
        <thead><tr><th>Law Structure</th><th>Approach</th><th>Treasure Class</th><th>Standing</th><th>Jurisdiction</th><th>Conf</th></tr></thead>
        <tbody>
        <% for (Map<String,String> t : treasures) { %>
        <tr>
            <td><strong><%= esc(t.get("law")) %></strong></td>
            <td><span style="font-size:0.7rem;background:var(--accent);color:#fff;padding:0.1rem 0.4rem;border-radius:3px;"><%= esc(t.get("approach")) %></span></td>
            <td><%= esc(t.get("class")) %></td>
            <td style="font-size:0.8rem;"><%= esc(t.get("standing")) %></td>
            <td style="font-size:0.8rem;"><%= esc(t.get("juris")) %></td>
            <td><%= esc(t.get("conf")) %>%</td>
        </tr>
        <% if (t.get("idea") != null && !t.get("idea").isEmpty()) { %>
        <tr><td colspan="6" style="font-size:0.8rem;color:var(--text-muted);padding-left:2rem;">Profitable Idea: <%= esc(trunc(t.get("idea"), 180)) %></td></tr>
        <% } %>
        <% } %>
        </tbody>
    </table></div>
</div></section>
<% } %>

<footer class="footer"><div><span>© 2026 MEARVK LLC. FiduciaryServices™ — Light Blue Edition.</span></div></footer>
</body></html>
