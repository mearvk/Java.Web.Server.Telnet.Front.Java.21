<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.Properties, java.io.*" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Futures&#8482; — Training</title>
    <link rel="stylesheet" href="css/style.css">
<script src="js/scroll-preserve.js"></script>
</head>
<body>

<nav>
    <span class="brand">Futures&#8482;</span>
    <a href="index.jsp">Overview</a>
    <a href="pipeline.jsp">Pipeline</a>
    <a href="training.jsp" class="active">Training</a>
    <a href="safety.jsp">Safety</a>
    <a href="status.jsp">Status</a>
</nav>

<section>
    <h2>AI Training Runs — Last 20</h2>
<%
    Properties dbProps = new Properties();
    boolean propsLoaded = false;

    try {
        InputStream is = application.getResourceAsStream("/WEB-INF/db.properties");
        if (is != null) { dbProps.load(is); is.close(); propsLoaded = true; }
    } catch (Exception ignored) {}

    if (!propsLoaded) {
        try {
            FileInputStream fis = new FileInputStream("/opt/tomcat/webapps/futures/WEB-INF/db.properties");
            dbProps.load(fis); fis.close(); propsLoaded = true;
        } catch (Exception ignored) {}
    }

    if (!propsLoaded) {
%>
    <div class="error">Could not load db.properties from any known path.</div>
<%
    } else {
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            Class.forName(dbProps.getProperty("db.driver"));
            conn = DriverManager.getConnection(dbProps.getProperty("db.url"), dbProps.getProperty("db.user"), dbProps.getProperty("db.password"));
            ps = conn.prepareStatement("SELECT id, epoch, loss, accuracy, started_at, completed_at FROM training_runs ORDER BY id DESC LIMIT 20");
            rs = ps.executeQuery();
%>
    <table>
        <thead><tr><th>ID</th><th>Epoch</th><th>Loss</th><th>Accuracy</th><th>Started</th><th>Completed</th></tr></thead>
        <tbody>
<%
            while (rs.next()) {
%>
            <tr>
                <td><%= rs.getInt("id") %></td>
                <td><%= rs.getInt("epoch") %></td>
                <td><%= rs.getDouble("loss") %></td>
                <td><%= rs.getDouble("accuracy") %></td>
                <td><%= rs.getTimestamp("started_at") %></td>
                <td><%= rs.getTimestamp("completed_at") %></td>
            </tr>
<%
            }
%>
        </tbody>
    </table>
<%
        } catch (Exception e) {
%>
    <div class="error">Database error: <%= e.getMessage() %><br>Driver: <%= dbProps.getProperty("db.driver") %><br>URL: <%= dbProps.getProperty("db.url") %></div>
<%
        } finally {
            if (rs != null) try { rs.close(); } catch (Exception ignored) {}
            if (ps != null) try { ps.close(); } catch (Exception ignored) {}
            if (conn != null) try { conn.close(); } catch (Exception ignored) {}
        }
    }
%>
</section>

<footer>&copy; 2026 MEARVK LLC</footer>

</body>
</html>
