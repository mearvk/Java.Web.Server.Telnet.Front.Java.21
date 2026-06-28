<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.Properties, java.io.InputStream" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <link rel="icon" type="image/png" href="images/favicon.png"/>
    <title>Science — Brarner.M.Alete™</title>
    <link rel="stylesheet" href="css/style.css"/>
</head>
<body>
<nav class="nav"><div class="nav-inner">
    <a href="index.jsp" class="nav-brand"><img src="images/mearvk.ltd.logo.left.png" alt="" style="height:40px;vertical-align:middle;margin-right:8px;background:transparent;"/>Brarner.M.Alete™<img src="images/mearvk.ltd.logo.right.png" alt="" style="height:40px;vertical-align:middle;margin-left:8px;background:transparent;"/></a>
    <ul class="nav-links">
        <li><a href="index.jsp">Overview</a></li>
        <li><a href="species.jsp">Species</a></li>
        <li><a href="postal.jsp">Postal</a></li>
        <li><a href="art.jsp">Art</a></li>
        <li><a href="science.jsp" class="active">Science</a></li>
        <li><a href="status.jsp">Status</a></li>
    </ul>
    <div class="nav-actions"><a href="admin/login.xhtml" class="nav-cta">Admin →</a></div>
</div></nav>

<section class="hero" style="padding:4rem 2rem;">
    <div class="hero-inner">
        <span class="hero-tag">Publication Index</span>
        <h1>Science Database</h1>
        <p>Scientific publication indexer with DOI resolution and citation graph construction.</p>
    </div>
</section>

<section class="section">
    <div class="section-inner">
<%
    Connection conn = null;
    try {
        Properties dbProps = new Properties();
        InputStream dbIn = application.getResourceAsStream("/WEB-INF/db.properties");
        if (dbIn != null) { dbProps.load(dbIn); dbIn.close(); }
        Class.forName(dbProps.getProperty("db.driver", "com.mysql.cj.jdbc.Driver"));
        conn = DriverManager.getConnection(
            dbProps.getProperty("db.url", "jdbc:mysql://localhost:3306/BrarnerScience"),
            dbProps.getProperty("db.user", "root"),
            dbProps.getProperty("db.password", ""));

        String source = request.getParameter("source");
        if (source != null && !source.isEmpty()) {
            PreparedStatement ps = conn.prepareStatement(
                "SELECT title, authors, doi, year_published FROM publications WHERE source_name=? ORDER BY year_published DESC LIMIT 200");
            ps.setString(1, source);
            ResultSet rs = ps.executeQuery();
%>
        <h3>Publications from <%= source %></h3>
        <p><a href="science.jsp">← Back to sources</a></p>
        <div class="table-wrap">
            <table>
                <thead><tr><th>Title</th><th>Authors</th><th>DOI</th><th>Year</th></tr></thead>
                <tbody>
<%
            boolean hasRows = false;
            while (rs.next()) { hasRows = true; %>
                    <tr>
                        <td><%= rs.getString("title") != null ? rs.getString("title") : "" %></td>
                        <td><%= rs.getString("authors") != null ? rs.getString("authors") : "" %></td>
                        <td><%= rs.getString("doi") != null ? rs.getString("doi") : "" %></td>
                        <td><%= rs.getString("year_published") != null ? rs.getString("year_published") : "" %></td>
                    </tr>
<%          }
            if (!hasRows) { %>
                    <tr><td colspan="4">No publications found.</td></tr>
<%          } rs.close(); ps.close();
%>
                </tbody>
            </table>
        </div>
<%
        } else {
            PreparedStatement ps = conn.prepareStatement(
                "SELECT source_name, COUNT(*) AS pub_count FROM publications WHERE source_name IS NOT NULL GROUP BY source_name ORDER BY source_name");
            ResultSet rs = ps.executeQuery();
%>
        <h3>Publication Sources</h3>
        <div class="table-wrap">
            <table>
                <thead><tr><th>Source</th><th>Publications</th></tr></thead>
                <tbody>
<%
            boolean hasRows = false;
            while (rs.next()) { hasRows = true; String s = rs.getString("source_name"); %>
                    <tr><td><a href="science.jsp?source=<%= java.net.URLEncoder.encode(s, "UTF-8") %>"><%= s %></a></td><td><%= rs.getInt("pub_count") %></td></tr>
<%          }
            if (!hasRows) { %>
                    <tr><td colspan="2">No science data available.</td></tr>
<%          } rs.close(); ps.close();
%>
                </tbody>
            </table>
        </div>
<%
        }
    } catch (Exception e) { %>
        <p style="color:#ef4444;">Database error: <%= e.getMessage() != null ? e.getMessage().replace("<","&lt;") : "unknown" %></p>
<%  } finally { if (conn != null) try { conn.close(); } catch (Exception ignored) {} }
%>
    </div>
</section>

<footer class="footer"><div class="footer-bottom" style="border:none;padding:0;">
    <span>&#169; 2026 MEARVK LLC. All rights reserved.</span>
</div></footer>
</body>
</html>
