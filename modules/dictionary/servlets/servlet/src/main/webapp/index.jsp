<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.*" %>
<%
    Connection conn = null; boolean dbOk = false;
    int termCount = 0, domainCount = 0;
    String search = request.getParameter("q");
    String domainFilter = request.getParameter("domain");
    if (search != null) search = search.trim();
    if (domainFilter != null && domainFilter.isEmpty()) domainFilter = null;

    List<Map<String, String>> entries = new ArrayList<>();
    List<String[]> domainList = new ArrayList<>();

    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        conn = DriverManager.getConnection("jdbc:mysql://127.0.0.1:3306/nwe_dictionary", "root", "$$Ironman1");
        dbOk = true;

        Statement st = conn.createStatement();
        ResultSet rs = st.executeQuery("SELECT COUNT(*) FROM terms WHERE is_published = TRUE");
        if (rs.next()) termCount = rs.getInt(1); rs.close(); st.close();

        st = conn.createStatement();
        rs = st.executeQuery("SELECT COUNT(*) FROM domains");
        if (rs.next()) domainCount = rs.getInt(1); rs.close(); st.close();

        // Domains for filter
        st = conn.createStatement();
        rs = st.executeQuery("SELECT domain_name, color FROM domains ORDER BY domain_name");
        while (rs.next()) domainList.add(new String[]{ rs.getString(1), rs.getString(2) });
        rs.close(); st.close();

        // Query terms
        String sql;
        PreparedStatement ps;
        if (search != null && !search.isEmpty()) {
            sql = "SELECT term, pronunciation, part_of_speech, definition, etymology, usage_example, related_module, domain, first_appearance, author FROM terms WHERE is_published = TRUE AND (term LIKE ? OR definition LIKE ?)";
            if (domainFilter != null) sql += " AND domain = ?";
            sql += " ORDER BY term ASC LIMIT 50";
            ps = conn.prepareStatement(sql);
            ps.setString(1, "%" + search + "%");
            ps.setString(2, "%" + search + "%");
            if (domainFilter != null) ps.setString(3, domainFilter);
        } else if (domainFilter != null) {
            sql = "SELECT term, pronunciation, part_of_speech, definition, etymology, usage_example, related_module, domain, first_appearance, author FROM terms WHERE is_published = TRUE AND domain = ? ORDER BY term ASC LIMIT 50";
            ps = conn.prepareStatement(sql);
            ps.setString(1, domainFilter);
        } else {
            sql = "SELECT term, pronunciation, part_of_speech, definition, etymology, usage_example, related_module, domain, first_appearance, author FROM terms WHERE is_published = TRUE ORDER BY term ASC LIMIT 50";
            ps = conn.prepareStatement(sql);
        }
        rs = ps.executeQuery();
        while (rs.next()) {
            Map<String, String> e = new LinkedHashMap<>();
            e.put("term", rs.getString(1));
            e.put("pronunciation", rs.getString(2));
            e.put("pos", rs.getString(3));
            e.put("definition", rs.getString(4));
            e.put("etymology", rs.getString(5));
            e.put("usage", rs.getString(6));
            e.put("module", rs.getString(7));
            e.put("domain", rs.getString(8));
            e.put("first", rs.getString(9));
            e.put("author", rs.getString(10));
            entries.add(e);
        }
        rs.close(); ps.close();
    } catch (Exception e) { dbOk = false; }
    if (conn != null) try { conn.close(); } catch (Exception e) {}
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/><meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <link rel="preconnect" href="https://fonts.googleapis.com"/><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin/><link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:wght@300;400;500;600;700;800&display=swap" rel="stylesheet"/>
    <title>Dictionary™ — NitroWebExpress™</title>
    <link rel="stylesheet" href="css/style.css"/>
</head>
<body>
<nav class="nav"><div class="nav-inner">
    <span class="nav-brand">Dictionary™</span>
    <ul class="nav-links">
        <li><a href="index.jsp" class="active">Browse</a></li>
        <li><a href="messaging.jsp">Messages</a></li>
        <li><a href="profile.jsp">Profile</a></li>
        <li><a href="status.jsp">Status</a></li>
    </ul>
<div class="nav-actions"><%@ include file="auth-buttons.jsp" %></div></div></nav>

<section class="hero">
    <div class="hero-inner">
        <span class="hero-tag">NitroWebExpress™ Terminology</span>
        <h1><span>Dictionary</span>™</h1>
        <p>Defines all rare, new, or system-specific terms. From dolyene to negamane. Installer Tech ID: Max Rupplin.</p>
    </div>
</section>

<section class="section">
    <div class="section-inner">

        <% if (!dbOk) { %>
        <p style="color:var(--accent);">Database offline. Run <code>bash modules/dictionary/servlets/setup-db.sh</code></p>
        <% } else { %>

        <!-- Stats -->
        <div class="stat-row">
            <div class="stat-pill"><div class="num"><%= termCount %></div><div class="lbl">Terms</div></div>
            <div class="stat-pill"><div class="num"><%= domainCount %></div><div class="lbl">Domains</div></div>
        </div>

        <!-- Search -->
        <form method="get" action="index.jsp" class="search-bar">
            <input type="text" name="q" placeholder="Search terms or definitions..." value="<%= search != null ? search.replace("\"","&quot;") : "" %>"/>
            <select name="domain">
                <option value="">All Domains</option>
                <% for (String[] d : domainList) { %>
                <option value="<%= d[0] %>" <%= d[0].equals(domainFilter) ? "selected" : "" %>><%= d[0] %></option>
                <% } %>
            </select>
            <button type="submit">Search</button>
        </form>

        <% if (search != null && !search.isEmpty()) { %>
        <p style="font-size:0.8rem;color:var(--text-muted);margin-bottom:1rem;">Showing results for "<strong><%= search.replace("<","&lt;") %></strong>"<%= domainFilter != null ? " in domain <strong>" + domainFilter + "</strong>" : "" %> — <%= entries.size() %> found</p>
        <% } %>

        <!-- Entries -->
        <% if (entries.isEmpty()) { %>
        <div style="text-align:center;padding:3rem;color:var(--text-muted);">
            <p>No terms found<%= search != null ? " matching \"" + search.replace("<","&lt;") + "\"" : "" %>.</p>
        </div>
        <% } else { for (Map<String, String> e : entries) { %>
        <div class="entry">
            <div>
                <span class="entry-term"><%= e.get("term") %></span>
                <% if (e.get("pronunciation") != null) { %><span class="entry-pron">/<%= e.get("pronunciation") %>/</span><% } %>
                <span class="entry-pos"><%= e.get("pos") %></span>
            </div>
            <div class="entry-def"><%= e.get("definition") %></div>
            <% if (e.get("usage") != null && !e.get("usage").isEmpty()) { %>
            <div class="entry-usage">"<%= e.get("usage") %>"</div>
            <% } %>
            <div class="entry-meta">
                <% if (e.get("domain") != null) { %><span>Domain: <strong><%= e.get("domain") %></strong></span><% } %>
                <% if (e.get("module") != null) { %><span>Module: <%= e.get("module") %></span><% } %>
                <% if (e.get("etymology") != null) { %><span>Origin: <%= e.get("etymology").length() > 80 ? e.get("etymology").substring(0,80) + "..." : e.get("etymology") %></span><% } %>
                <% if (e.get("author") != null) { %><span>by <%= e.get("author") %></span><% } %>
            </div>
        </div>
        <% } } %>

        <% } %>
    </div>
</section>

<footer class="footer">
    <span>Dictionary™ — NitroWebExpress™ Terminology — MEARVK LLC 2026 — Installer Tech ID: Max Rupplin</span>
</footer>
</body>
</html>
