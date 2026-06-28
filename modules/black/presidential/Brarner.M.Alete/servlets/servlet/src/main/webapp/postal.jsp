<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.Properties, java.io.InputStream" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <link rel="icon" type="image/png" href="images/favicon.png"/>
    <title>Postal — Brarner.M.Alete™</title>
    <link rel="stylesheet" href="css/style.css"/>
</head>
<body>
<nav class="nav"><div class="nav-inner">
    <a href="index.jsp" class="nav-brand"><img src="images/mearvk.ltd.logo.left.png" alt="" style="height:40px;vertical-align:middle;margin-right:8px;background:transparent;"/>Brarner.M.Alete™<img src="images/mearvk.ltd.logo.right.png" alt="" style="height:40px;vertical-align:middle;margin-left:8px;background:transparent;"/></a>
    <ul class="nav-links">
        <li><a href="index.jsp">Overview</a></li>
        <li><a href="species.jsp">Species</a></li>
        <li><a href="postal.jsp" class="active">Postal</a></li>
        <li><a href="art.jsp">Art</a></li>
        <li><a href="science.jsp">Science</a></li>
        <li><a href="status.jsp">Status</a></li>
    </ul>
    <div class="nav-actions"><a href="admin/login.xhtml" class="nav-cta">Admin →</a></div>
</div></nav>

<section class="hero" style="padding:4rem 2rem;">
    <div class="hero-inner">
        <span class="hero-tag">Address Standardization</span>
        <h1>Postal Database</h1>
        <p>US Postal code lookup and validation for all 50 states and territories.</p>
    </div>
</section>

<section class="section">
    <div class="section-inner">
<%
    String stateFilter = request.getParameter("state");
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

        if (stateFilter != null && !stateFilter.isEmpty()) {
            PreparedStatement ps = conn.prepareStatement(
                "SELECT zip_code, city, state, county FROM postal WHERE state=? ORDER BY zip_code LIMIT 200");
            ps.setString(1, stateFilter);
            ResultSet rs = ps.executeQuery();
%>
        <h3>ZIP Codes in <%= stateFilter %></h3>
        <p><a href="postal.jsp">← Back to all states</a></p>
        <div class="table-wrap">
            <table>
                <thead><tr><th>ZIP</th><th>City</th><th>State</th><th>County</th></tr></thead>
                <tbody>
<%
            boolean hasRows = false;
            while (rs.next()) {
                hasRows = true;
%>
                    <tr>
                        <td><%= rs.getString("zip_code") != null ? rs.getString("zip_code") : "" %></td>
                        <td><%= rs.getString("city") != null ? rs.getString("city") : "" %></td>
                        <td><%= rs.getString("state") != null ? rs.getString("state") : "" %></td>
                        <td><%= rs.getString("county") != null ? rs.getString("county") : "" %></td>
                    </tr>
<%          }
            if (!hasRows) { %>
                    <tr><td colspan="4">No records found for state <%= stateFilter %>.</td></tr>
<%          }
            rs.close(); ps.close();
%>
                </tbody>
            </table>
        </div>
<%
        } else {
            // Show state summary
            PreparedStatement ps = conn.prepareStatement(
                "SELECT state, COUNT(*) AS zip_count FROM postal WHERE state IS NOT NULL AND state!='' GROUP BY state ORDER BY state");
            ResultSet rs = ps.executeQuery();
%>
        <h3>States</h3>
        <div class="table-wrap">
            <table>
                <thead><tr><th>State</th><th>ZIP Codes</th></tr></thead>
                <tbody>
<%
            boolean hasRows = false;
            while (rs.next()) {
                hasRows = true;
                String st = rs.getString("state");
%>
                    <tr><td><a href="postal.jsp?state=<%= java.net.URLEncoder.encode(st, "UTF-8") %>"><%= st %></a></td><td><%= rs.getInt("zip_count") %></td></tr>
<%          }
            if (!hasRows) { %>
                    <tr><td colspan="2">No postal data available.</td></tr>
<%          }
            rs.close(); ps.close();
%>
                </tbody>
            </table>
        </div>
<%
        }
    } catch (Exception e) {
%>
        <p style="color:#ef4444;">Database error: <%= e.getMessage() != null ? e.getMessage().replace("<","&lt;") : "unknown" %></p>
<%
    } finally {
        if (conn != null) try { conn.close(); } catch (Exception ignored) {}
    }
%>
    </div>
</section>

<footer class="footer"><div class="footer-bottom" style="border:none;padding:0;">
    <span>&#169; 2026 MEARVK LLC. All rights reserved.</span>
</div></footer>
</body>
</html>
