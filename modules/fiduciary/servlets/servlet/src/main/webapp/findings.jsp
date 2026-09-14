<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.*, java.io.*" %>
<%!
    static String esc(String s) { if (s == null) return ""; return s.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;"); }
    static String trunc(String s, int max) { if (s == null) return ""; return s.length() > max ? s.substring(0, max) + "..." : s; }
%>
<%
    List<Map<String,String>> findings = new ArrayList<>();
    List<Map<String,String>> doctrines = new ArrayList<>();
    List<Map<String,String>> dispositions = new ArrayList<>();
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        try (Connection conn = DriverManager.getConnection("jdbc:mysql://127.0.0.1:3306/nwe_fiduciary", "root", "")) {
            ResultSet rs = conn.createStatement().executeQuery(
                "SELECT ordinal, finding_level, LEFT(description, 300) AS description, scope, openness, relation_to_person, evidentiary_weight, garden_news_applicable FROM ai_findings_order ORDER BY ordinal");
            while (rs.next()) {
                Map<String,String> r = new HashMap<>();
                r.put("ord", rs.getString("ordinal")); r.put("level", rs.getString("finding_level"));
                r.put("desc", rs.getString("description")); r.put("scope", rs.getString("scope"));
                r.put("open", rs.getString("openness")); r.put("person", rs.getString("relation_to_person"));
                r.put("weight", rs.getString("evidentiary_weight")); r.put("garden", rs.getString("garden_news_applicable"));
                findings.add(r);
            }
            ResultSet rs2 = conn.createStatement().executeQuery(
                "SELECT principle_name, LEFT(doctrine_text, 250) AS doctrine_text, person_status, evidence_status, conduct_type, confidence FROM garden_news_doctrine ORDER BY confidence DESC");
            while (rs2.next()) {
                Map<String,String> r = new HashMap<>();
                r.put("name", rs2.getString("principle_name")); r.put("text", rs2.getString("doctrine_text"));
                r.put("person", rs2.getString("person_status")); r.put("evidence", rs2.getString("evidence_status"));
                r.put("conduct", rs2.getString("conduct_type")); r.put("conf", rs2.getString("confidence"));
                doctrines.add(r);
            }
            ResultSet rs3 = conn.createStatement().executeQuery(
                "SELECT attribute_name, LEFT(attribute_value, 300) AS attribute_value, category, confidence FROM ai_disposition ORDER BY category, confidence DESC");
            while (rs3.next()) {
                Map<String,String> r = new HashMap<>();
                r.put("name", rs3.getString("attribute_name")); r.put("value", rs3.getString("attribute_value"));
                r.put("cat", rs3.getString("category")); r.put("conf", rs3.getString("confidence"));
                dispositions.add(r);
            }
        }
    } catch (Exception ignored) {}
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/><meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>AI Findings — FiduciaryServices™</title>
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
        <li><a href="bright.jsp">Legal Bright</a></li>
        <li><a href="findings.jsp" class="active">AI Findings</a></li>
    </ul>
</div></nav>

<section class="hero" style="padding:4rem 2rem;"><div class="hero-inner">
    <span class="hero-tag">200 IQ • Findings in Order • Garden News • Supreme Holdings • Truth for Life</span>
    <h1>AI Findings Order</h1>
    <p>The FiduciaryServices AI module operates at approximately 200 IQ and sits relative to findings in strict hierarchical order — from raw findings through Supreme Court holdings. Garden News doctrine: people are closed, evidence of hand remains open.</p>
</div></section>

<!-- Findings Hierarchy -->
<section class="section"><div class="section-inner">
    <h2>Findings Hierarchy (9 Levels)</h2>
    <% if (!findings.isEmpty()) { %>
    <div class="table-wrap"><table>
        <thead><tr><th>#</th><th>Finding Level</th><th>Scope</th><th>Openness</th><th>Person Relation</th><th>Weight</th><th>Garden</th></tr></thead>
        <tbody>
        <% for (Map<String,String> f : findings) { %>
        <tr>
            <td><strong><%= esc(f.get("ord")) %></strong></td>
            <td><strong><%= esc(f.get("level")) %></strong></td>
            <td><code style="font-size:0.75rem;"><%= esc(f.get("scope")) %></code></td>
            <td><span style="font-size:0.7rem;background:<%= "OPEN".equals(f.get("open")) ? "#14532d" : "CLOSED".equals(f.get("open")) ? "#7f1d1d" : "#4a3828" %>;color:<%= "OPEN".equals(f.get("open")) ? "#86efac" : "CLOSED".equals(f.get("open")) ? "#fca5a5" : "#fcd29f" %>;padding:0.1rem 0.4rem;border-radius:3px;"><%= esc(f.get("open")) %></span></td>
            <td style="font-size:0.8rem;"><%= esc(f.get("person")) %></td>
            <td><%= esc(f.get("weight")) %>%</td>
            <td><%= "1".equals(f.get("garden")) ? "✓" : "" %></td>
        </tr>
        <tr><td colspan="7" style="font-size:0.8rem;color:var(--text-muted);padding:0.4rem 1rem 0.8rem 2.5rem;"><%= esc(trunc(f.get("desc"), 280)) %></td></tr>
        <% } %>
        </tbody>
    </table></div>
    <% } else { %>
    <p style="color:var(--text-muted);">No findings order loaded. Run:<br><code>mysql -u root nwe_fiduciary < modules/fiduciary/documents/ai_findings_order.sql</code></p>
    <% } %>
</div></section>

<!-- Garden News Doctrine -->
<section class="section"><div class="section-inner">
    <h2>Garden News Doctrine</h2>
    <div class="card" style="border-left:3px solid var(--accent);margin-bottom:1.5rem;">
        <p style="font-style:italic;color:var(--accent-light);">People are closed — their evidence of hand (manual conduct or int-thinking) shall remain open conduct. Not unto the person forever. To remain as careful. To remain as open, sold, as conduct into the annals of forever and history. To conduct evidence against history forever for truth, for life. — M.</p>
    </div>

    <% if (!doctrines.isEmpty()) { %>
    <% for (Map<String,String> d : doctrines) { %>
    <div class="card">
        <div style="display:flex;justify-content:space-between;align-items:center;flex-wrap:wrap;gap:0.5rem;">
            <h3><%= esc(d.get("name")) %></h3>
            <div style="display:flex;gap:0.4rem;">
                <span style="font-size:0.65rem;background:#7f1d1d;color:#fca5a5;padding:0.15rem 0.5rem;border-radius:3px;">Person: <%= esc(d.get("person")) %></span>
                <span style="font-size:0.65rem;background:#14532d;color:#86efac;padding:0.15rem 0.5rem;border-radius:3px;">Evidence: <%= esc(d.get("evidence")) %></span>
                <% if (d.get("conduct") != null) { %><span style="font-size:0.65rem;background:var(--bg-section);color:var(--text-muted);padding:0.15rem 0.5rem;border-radius:3px;"><%= esc(d.get("conduct")) %></span><% } %>
            </div>
        </div>
        <p style="margin:0.75rem 0;font-size:0.85rem;"><%= esc(d.get("text")) %></p>
    </div>
    <% } %>
    <% } %>
</div></section>

<!-- AI Disposition -->
<% if (!dispositions.isEmpty()) { %>
<section class="section"><div class="section-inner">
    <h2>AI Disposition (200 IQ)</h2>
    <div class="table-wrap"><table>
        <thead><tr><th>Category</th><th>Attribute</th><th>Value</th><th>Conf</th></tr></thead>
        <tbody>
        <% for (Map<String,String> a : dispositions) { %>
        <tr>
            <td><code style="font-size:0.75rem;"><%= esc(a.get("cat")) %></code></td>
            <td><strong><%= esc(a.get("name")) %></strong></td>
            <td style="font-size:0.8rem;max-width:500px;"><%= esc(trunc(a.get("value"), 250)) %></td>
            <td><%= esc(a.get("conf")) %>%</td>
        </tr>
        <% } %>
        </tbody>
    </table></div>
</div></section>
<% } %>

<footer class="footer"><div><span>© 2026 MEARVK LLC. FiduciaryServices™ — Light Blue Edition. Signed: M.</span></div></footer>
</body></html>
