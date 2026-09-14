<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.Properties, java.io.*" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/>
    <link rel="preconnect" href="https://fonts.googleapis.com"/><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin/><link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:ital,wght@0,300;0,400;0,500;0,600;0,700;1,400;1,600&display=swap" rel="stylesheet"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>Contacts — AE6E66™</title>
    <link rel="stylesheet" href="css/style.css"/>
<script src="js/scroll-preserve.js"></script>
    <script src="js/nwe-readme-viewer.js"></script>
</head>
<body>
<nav class="nav"><div class="nav-inner">
    <span class="nav-brand">AE6E66™</span>
    <ul class="nav-links">
        <li><a href="index.jsp">Overview</a></li>
        <li><a href="contacts.jsp" class="active">Contacts</a></li>
        <li><a href="sent.jsp">Sent</a></li>
        <li><a href="status.jsp">Status</a></li>
    </ul>
    <div class="nav-actions"><a href="crawl.jsp" class="nav-cta">Crawl</a></div>
</div></nav>

<section class="hero" style="padding:4rem 2rem;">
    <div class="hero-inner">
        <span class="hero-tag">UK Parliament</span>
        <h1>Contacts</h1>
        <p>House of Lords + House of Commons members crawled from members.parliament.uk.</p>
    </div>
</section>

<section class="section">
    <div class="section-inner">
<%
    String sourceFilter = request.getParameter("source");
    Properties dbProps = new Properties();
    boolean propsLoaded = false;
    Connection conn = null;
    try {
        InputStream dbIn = application.getResourceAsStream("/WEB-INF/db.properties");
        if (dbIn != null) { dbProps.load(dbIn); dbIn.close(); propsLoaded = true; }
        if (!propsLoaded) {
            String[] tryPaths = { "/opt/tomcat/webapps/ae6e66/WEB-INF/db.properties" };
            for (String tp : tryPaths) { File f = new File(tp);
                if (f.exists()) { FileInputStream fis = new FileInputStream(f); dbProps.load(fis); fis.close(); propsLoaded = true; break; } }
        }
        Class.forName(dbProps.getProperty("db.driver", "com.mysql.cj.jdbc.Driver"));
        conn = DriverManager.getConnection(
            dbProps.getProperty("db.url", "jdbc:mysql://127.0.0.1:3306/nwe_ae6e66"),
            dbProps.getProperty("db.user", "root"),
            dbProps.getProperty("db.password", ""));

        if (sourceFilter == null || sourceFilter.isEmpty()) {
            // Show sources (HOL / HOC)
            ResultSet rs = conn.createStatement().executeQuery(
                "SELECT source, COUNT(*) AS cnt FROM contacts GROUP BY source ORDER BY source");
%>
        <h3>Browse by Chamber</h3>
        <div class="table-wrap">
            <table>
                <thead><tr><th>Chamber</th><th>Members</th></tr></thead>
                <tbody>
<%          while (rs.next()) { %>
                    <tr><td><a href="contacts.jsp?source=<%= rs.getString("source") %>"><%= rs.getString("source") %></a></td><td><%= rs.getInt("cnt") %></td></tr>
<%          } rs.close(); %>
                </tbody>
            </table>
        </div>
<%
        } else {
            PreparedStatement ps = conn.prepareStatement(
                "SELECT id, name, email, phone, ministry, source FROM contacts WHERE source=? ORDER BY name");
            ps.setString(1, sourceFilter);
            ResultSet rs = ps.executeQuery();
%>
        <h3><%= sourceFilter %> Members</h3>
        <p style="margin-bottom:1rem;"><a href="contacts.jsp">← All Chambers</a></p>
        <div class="table-wrap">
            <table>
                <thead><tr><th>ID</th><th>Name</th><th>Email</th><th>Phone</th><th>Ministry</th></tr></thead>
                <tbody>
<%          while (rs.next()) {
                String email = rs.getString("email");
                String phone = rs.getString("phone");
%>
                    <tr>
                        <td><%= rs.getInt("id") %></td>
                        <td><%= rs.getString("name") != null ? rs.getString("name") : "" %></td>
                        <td><%= email != null && !email.isEmpty() ? email : "—" %></td>
                        <td><%= phone != null && !phone.isEmpty() ? phone : "—" %></td>
                        <td><%= rs.getString("ministry") != null ? rs.getString("ministry") : "" %></td>
                    </tr>
<%          } rs.close(); ps.close(); %>
                </tbody>
            </table>
        </div>
<%
        }
    } catch (Exception e) {
%>
        <p style="color:#ef4444;">Database error: <%= e.getMessage() != null ? e.getMessage().replace("<","&lt;") : "unknown" %></p>
        <p style="color:#5f7a5f;font-size:0.8rem;">Props loaded: <%= propsLoaded %></p>
<%
    } finally {
        if (conn != null) try { conn.close(); } catch (Exception ignored) {}
    }
%>
    </div>
</section>

<footer class="footer"><div><span>&#169; 2026 MEARVK LLC. All rights reserved.</span></div></footer>
</body>
</html>
