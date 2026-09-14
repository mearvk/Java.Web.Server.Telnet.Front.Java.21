<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.*, java.io.*" %>
<%!
    static String esc(String s) { if (s == null) return ""; return s.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;"); }
    static String trunc(String s, int max) { if (s == null) return ""; return s.length() > max ? s.substring(0, max) + "..." : s; }
%>
<%
    String filterCat = request.getParameter("category");
    String filterLabel = request.getParameter("label");
    List<Map<String,String>> docs = new ArrayList<>();
    List<String> categories = new ArrayList<>();
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        try (Connection conn = DriverManager.getConnection("jdbc:mysql://127.0.0.1:3306/nwe_fiduciary", "root", "")) {
            ResultSet rsCats = conn.createStatement().executeQuery("SELECT DISTINCT category FROM original_documents ORDER BY category");
            while (rsCats.next()) categories.add(rsCats.getString(1));

            String sql = "SELECT title, category, subcategory, jurisdiction, label, LEFT(document_text, 300) AS excerpt, source_authority, confidence FROM original_documents";
            if (filterCat != null && !filterCat.isEmpty()) sql += " WHERE category = '" + filterCat.replace("'","''") + "'";
            else if (filterLabel != null && !filterLabel.isEmpty()) sql += " WHERE label = '" + filterLabel.replace("'","''") + "'";
            sql += " ORDER BY category, confidence DESC";
            ResultSet rs = conn.createStatement().executeQuery(sql);
            while (rs.next()) {
                Map<String,String> r = new HashMap<>();
                r.put("title", rs.getString("title")); r.put("cat", rs.getString("category"));
                r.put("sub", rs.getString("subcategory")); r.put("juris", rs.getString("jurisdiction"));
                r.put("label", rs.getString("label")); r.put("excerpt", rs.getString("excerpt"));
                r.put("auth", rs.getString("source_authority")); r.put("conf", rs.getString("confidence"));
                docs.add(r);
            }
        }
    } catch (Exception ignored) {}
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/><meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>Documents — FiduciaryServices™</title>
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
        <li><a href="documents.jsp" class="active">Documents</a></li>
        <li><a href="bright.jsp">Legal Bright</a></li>
        <li><a href="findings.jsp">AI Findings</a></li>
    </ul>
</div></nav>

<section class="hero" style="padding:4rem 2rem;"><div class="hero-inner">
    <span class="hero-tag">Minister • International • County • Gentry • Standings • Winners • Ahead</span>
    <h1>Original Documents</h1>
    <p>Research documents retrieved and stored as original material — minister fiduciary facts, international law, county legislature, gentry hero precedent, legal standings, and who has won.</p>
</div></section>

<section class="section"><div class="section-inner">
    <h2>Filter by Category</h2>
    <div style="display:flex;gap:0.5rem;flex-wrap:wrap;margin-bottom:1.5rem;">
        <a href="documents.jsp" class="btn btn-primary" style="font-size:0.75rem;">All</a>
        <% for (String cat : categories) { %>
        <a href="documents.jsp?category=<%= esc(cat) %>" class="btn" style="font-size:0.75rem;background:var(--bg-card);color:var(--accent-light);border:1px solid var(--border);"><%= esc(cat) %></a>
        <% } %>
        <a href="documents.jsp?label=INTERNATIONAL" class="btn" style="font-size:0.75rem;background:#1e3a5f;color:#93c5fd;border:1px solid #2e4a6f;">INTERNATIONAL</a>
    </div>

    <% if (!docs.isEmpty()) { %>
    <% for (Map<String,String> d : docs) { %>
    <div class="card">
        <div style="display:flex;justify-content:space-between;align-items:center;flex-wrap:wrap;gap:0.5rem;">
            <h3><%= esc(d.get("title")) %></h3>
            <div style="display:flex;gap:0.4rem;">
                <span style="font-size:0.65rem;background:var(--accent);color:#fff;padding:0.15rem 0.5rem;border-radius:3px;"><%= esc(d.get("cat")) %></span>
                <span style="font-size:0.65rem;background:<%= "INTERNATIONAL".equals(d.get("label")) ? "#1e3a5f" : "var(--bg-section)" %>;color:<%= "INTERNATIONAL".equals(d.get("label")) ? "#93c5fd" : "var(--text-muted)" %>;padding:0.15rem 0.5rem;border-radius:3px;"><%= esc(d.get("label")) %></span>
                <span style="font-size:0.65rem;background:var(--bg-section);color:var(--text-muted);padding:0.15rem 0.5rem;border-radius:3px;">Confidence: <%= esc(d.get("conf")) %>%</span>
            </div>
        </div>
        <p style="margin:0.75rem 0;font-size:0.85rem;"><%= esc(trunc(d.get("excerpt"), 280)) %></p>
        <div class="meta">
            Jurisdiction: <%= esc(d.get("juris")) %> •
            <% if (d.get("auth") != null && !d.get("auth").isEmpty()) { %>Source: <%= esc(d.get("auth")) %> • <% } %>
            Subcategory: <%= esc(d.get("sub")) %>
        </div>
    </div>
    <% } %>
    <% } else { %>
    <p style="color:var(--text-muted);">No documents loaded. Run:<br><code>mysql -u root nwe_fiduciary < modules/fiduciary/documents/minister_fiduciary_facts.sql</code></p>
    <% } %>
</div></section>

<footer class="footer"><div><span>© 2026 MEARVK LLC. FiduciaryServices™ — Light Blue Edition.</span></div></footer>
</body></html>
