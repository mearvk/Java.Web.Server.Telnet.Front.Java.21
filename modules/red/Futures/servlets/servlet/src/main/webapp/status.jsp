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
    <script src="js/nwe-readme-viewer.js"></script>
    <link rel="preconnect" href="https://fonts.googleapis.com"/><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin/><link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:ital,wght@0,300;0,400;0,500;0,600;0,700;1,400;1,600&display=swap" rel="stylesheet"/>
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

<!-- CD1 Connector Button + Floating Dialog -->
<div style="display:flex;justify-content:center;align-items:center;width:100%;padding:2rem 0;">
    <button id="cd1-btn" type="button" aria-pressed="false" style="all:unset;display:block;margin:0 auto;cursor:pointer;padding:0;border:none;background:transparent;transition:transform 0.3s cubic-bezier(0.42,-1.84,0.42,1.84),filter 0.3s ease;">
        <img src="images/black.button.png" alt="Connector" style="display:block;width:80px;height:80px;border-radius:50%;background:transparent;"/>
    </button>
</div>
<div id="cd1-overlay" style="display:none;position:fixed;inset:0;z-index:299;background:transparent;"></div>
<div id="cd1-dialog" style="display:none;position:fixed;top:50%;left:50%;transform:translate(-50%,-50%);z-index:300;background:#1a1a1a;border:1px solid #333;border-radius:12px;padding:1.25rem;width:520px;max-width:90vw;box-shadow:0 8px 32px rgba(0,0,0,0.6);">
    <div style="font-size:0.9rem;font-weight:600;color:#e8e0d6;margin-bottom:0.75rem;">CD1 Connector &#8212; Port 5000</div>
    <div style="display:flex;gap:0.5rem;margin-bottom:0.75rem;flex-wrap:wrap;align-items:center;">
        <select id="cd1-action" style="background:#222;color:#e8e0d6;border:1px solid #444;border-radius:8px;padding:0.45rem 2rem 0.45rem 0.75rem;font-size:0.8rem;cursor:pointer;appearance:none;">
            <option value="connect">Connect</option>
            <option value="disconnect">Disconnect</option>
            <option value="status">Status</option>
            <option value="hardreset">Hard Reset Connection</option>
        </select>
        <button onclick="cd1Send()" style="background:#666;color:#fff;border:none;border-radius:8px;padding:0.45rem 1rem;font-size:0.8rem;font-weight:600;cursor:pointer;">Send</button>
        <button onclick="cd1Ok()" style="background:#666;color:#fff;border:none;border-radius:8px;padding:0.45rem 1rem;font-size:0.8rem;font-weight:600;cursor:pointer;">OK</button>
    </div>
    <div style="display:flex;align-items:center;gap:0.5rem;margin-bottom:0.75rem;">
        <label style="display:flex;align-items:center;gap:0.4rem;color:#999;font-size:0.75rem;cursor:pointer;">
            <input type="checkbox" id="cd1-direct-port" style="accent-color:#888;width:14px;height:14px;cursor:pointer;"/>
            Direct Port (bypass Strernary&#8482; 20000)
        </label>
        <span id="cd1-mode-badge" style="font-size:0.65rem;background:#222;color:#aaa;padding:0.2rem 0.5rem;border-radius:4px;">STRERNARY</span>
    </div>
    <textarea id="cd1-textarea" placeholder="Connection idle..." spellcheck="false" style="width:100%;min-height:140px;background:#ffffff;color:#111;border:1px solid #333;border-radius:8px;padding:0.75rem;font-family:monospace;font-size:0.8rem;resize:vertical;"></textarea>
</div>
<script>window.CD1_MODULE_PORT = "5000";</script>
<script src="js/cd1-connector.js"></script>



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
