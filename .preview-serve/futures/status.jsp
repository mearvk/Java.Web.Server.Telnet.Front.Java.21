<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.Properties, java.io.*" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Futures&#8482; — Status</title>
    <link rel="stylesheet" href="css/style.css">
<script src="js/scroll-preserve.js"></script>
</head>
<body>

<nav>
    <span class="brand">Futures&#8482;</span>
    <a href="index.jsp">Overview</a>
    <a href="pipeline.jsp">Pipeline</a>
    <a href="training.jsp">Training</a>
    <a href="safety.jsp">Safety</a>
    <a href="status.jsp" class="active">Status</a>
</nav>

<section>
    <h2>Health Check</h2>

    <div class="card">
        <h3 style="color: var(--accent); margin-bottom: 0.5rem;">JVM Info</h3>
        <table>
            <tr><td>Java Version</td><td><%= System.getProperty("java.version") %></td></tr>
            <tr><td>JVM Name</td><td><%= System.getProperty("java.vm.name") %></td></tr>
            <tr><td>OS</td><td><%= System.getProperty("os.name") + " " + System.getProperty("os.arch") %></td></tr>
            <tr><td>Free Memory</td><td><%= Runtime.getRuntime().freeMemory() / 1024 / 1024 %> MB</td></tr>
            <tr><td>Max Memory</td><td><%= Runtime.getRuntime().maxMemory() / 1024 / 1024 %> MB</td></tr>
            <tr><td>Servlet Container</td><td><%= application.getServerInfo() %></td></tr>
        </table>
    </div>

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

            int pipelineCount = 0;
            int trainingCount = 0;

            ps = conn.prepareStatement("SELECT COUNT(*) FROM pipeline_log");
            rs = ps.executeQuery();
            if (rs.next()) pipelineCount = rs.getInt(1);
            rs.close(); ps.close();

            ps = conn.prepareStatement("SELECT COUNT(*) FROM training_runs");
            rs = ps.executeQuery();
            if (rs.next()) trainingCount = rs.getInt(1);
            rs.close(); ps.close();
%>
    <div class="card">
        <h3 style="color: var(--accent); margin-bottom: 0.5rem;">Database — nwe_futures</h3>
        <table>
            <tr><td>Connection</td><td style="color: #22c55e;">Connected</td></tr>
            <tr><td>Pipeline Log Entries</td><td><%= pipelineCount %></td></tr>
            <tr><td>Training Runs</td><td><%= trainingCount %></td></tr>
        </table>
    </div>
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
