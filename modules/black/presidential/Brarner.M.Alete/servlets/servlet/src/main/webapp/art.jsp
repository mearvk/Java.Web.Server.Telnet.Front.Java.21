<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.Properties, java.io.InputStream" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <link rel="icon" type="image/png" href="images/favicon.png"/>
    <title>Art — Brarner.M.Alete™</title>
    <link rel="stylesheet" href="css/style.css"/>
</head>
<body>
<nav class="nav"><div class="nav-inner">
    <a href="index.jsp" class="nav-brand"><img src="images/mearvk.ltd.logo.left.png" alt="" style="height:40px;vertical-align:middle;margin-right:8px;background:transparent;"/>Brarner.M.Alete™<img src="images/mearvk.ltd.logo.right.png" alt="" style="height:40px;vertical-align:middle;margin-left:8px;background:transparent;"/></a>
    <ul class="nav-links">
        <li><a href="index.jsp">Overview</a></li>
        <li><a href="species.jsp">Species</a></li>
        <li><a href="postal.jsp">Postal</a></li>
        <li><a href="art.jsp" class="active">Art</a></li>
        <li><a href="science.jsp">Science</a></li>
        <li><a href="status.jsp">Status</a></li>
    </ul>
    <div class="nav-actions"><a href="admin/login.xhtml" class="nav-cta">Admin →</a></div>
</div></nav>

<section class="hero" style="padding:4rem 2rem;">
    <div class="hero-inner">
        <span class="hero-tag">Museum Collections</span>
        <h1>Art Database</h1>
        <p>Art museum collections indexer covering 22 major institutions with species-linked natural art references.</p>
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

        String museum = request.getParameter("museum");
        if (museum != null && !museum.isEmpty()) {
            PreparedStatement ps = conn.prepareStatement(
                "SELECT title, artist, year_created, medium FROM art_works WHERE museum_name=? ORDER BY title LIMIT 200");
            ps.setString(1, museum);
            ResultSet rs = ps.executeQuery();
%>
        <h3>Works at <%= museum %></h3>
        <p><a href="art.jsp">← Back to museums</a></p>
        <div class="table-wrap">
            <table>
                <thead><tr><th>Title</th><th>Artist</th><th>Year</th><th>Medium</th></tr></thead>
                <tbody>
<%
            boolean hasRows = false;
            while (rs.next()) { hasRows = true; %>
                    <tr>
                        <td><%= rs.getString("title") != null ? rs.getString("title") : "" %></td>
                        <td><%= rs.getString("artist") != null ? rs.getString("artist") : "" %></td>
                        <td><%= rs.getString("year_created") != null ? rs.getString("year_created") : "" %></td>
                        <td><%= rs.getString("medium") != null ? rs.getString("medium") : "" %></td>
                    </tr>
<%          }
            if (!hasRows) { %>
                    <tr><td colspan="4">No works found.</td></tr>
<%          } rs.close(); ps.close();
%>
                </tbody>
            </table>
        </div>
<%
        } else {
            PreparedStatement ps = conn.prepareStatement(
                "SELECT museum_name, COUNT(*) AS works FROM art_works WHERE museum_name IS NOT NULL GROUP BY museum_name ORDER BY museum_name");
            ResultSet rs = ps.executeQuery();
%>
        <h3>Museums</h3>
        <div class="table-wrap">
            <table>
                <thead><tr><th>Museum</th><th>Works</th></tr></thead>
                <tbody>
<%
            boolean hasRows = false;
            while (rs.next()) { hasRows = true; String m = rs.getString("museum_name"); %>
                    <tr><td><a href="art.jsp?museum=<%= java.net.URLEncoder.encode(m, "UTF-8") %>"><%= m %></a></td><td><%= rs.getInt("works") %></td></tr>
<%          }
            if (!hasRows) { %>
                    <tr><td colspan="2">No art data available.</td></tr>
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
