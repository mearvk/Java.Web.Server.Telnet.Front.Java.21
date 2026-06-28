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

<!-- CD1 Connector Button + Floating Dialog -->
<div style="display:flex;justify-content:center;align-items:center;width:100%;padding:2rem 0;">
    <button id="cd1-btn" type="button" aria-pressed="false" style="all:unset;display:block;margin:0 auto;cursor:pointer;padding:0;border:none;background:transparent;transition:transform 0.3s cubic-bezier(0.42,-1.84,0.42,1.84),filter 0.3s ease;">
        <img src="images/black.button.png" alt="Connector" style="display:block;width:80px;height:80px;border-radius:50%;background:transparent;"/>
    </button>
</div>
<div id="cd1-overlay" style="display:none;position:fixed;inset:0;z-index:299;background:transparent;"></div>
<div id="cd1-dialog" style="display:none;position:fixed;top:50%;left:50%;transform:translate(-50%,-50%);z-index:300;background:#111118;border:1px solid #27272a;border-radius:12px;padding:1.25rem;width:520px;max-width:90vw;box-shadow:0 8px 32px rgba(0,0,0,0.6);">
    <div style="font-size:0.9rem;font-weight:600;color:#fff;margin-bottom:0.75rem;">BMA Connector &#8212; Postal Division</div>
    <div style="display:flex;gap:0.5rem;margin-bottom:0.75rem;flex-wrap:wrap;">
        <select id="cd1-action" style="background:#1a1a24;color:#fff;border:1px solid #27272a;border-radius:8px;padding:0.45rem 2rem 0.45rem 0.75rem;font-size:0.8rem;cursor:pointer;appearance:none;">
            <option value="connect">Connect</option>
            <option value="disconnect">Disconnect</option>
            <option value="poll">Poll Area Data</option>
            <option value="hardreset">Hard Reset Connection</option>
        </select>
        <button onclick="cd1Send()" style="background:#3b82f6;color:#fff;border:none;border-radius:8px;padding:0.45rem 1rem;font-size:0.8rem;font-weight:600;cursor:pointer;">Send</button>
        <button onclick="cd1Ok()" style="background:#3b82f6;color:#fff;border:none;border-radius:8px;padding:0.45rem 1rem;font-size:0.8rem;font-weight:600;cursor:pointer;">OK</button>
    </div>
    <textarea id="cd1-textarea" placeholder="Connection idle..." spellcheck="false" style="width:100%;min-height:140px;background:#ffffff;color:#111;border:1px solid #27272a;border-radius:8px;padding:0.75rem;font-family:monospace;font-size:0.8rem;resize:vertical;"></textarea>
</div>

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

<script>
(function() {
    var btn = document.getElementById('cd1-btn');
    var dialog = document.getElementById('cd1-dialog');
    var overlay = document.getElementById('cd1-overlay');
    var textarea = document.getElementById('cd1-textarea');
    if (!btn || !dialog || !overlay || !textarea) return;
    btn.addEventListener('click', function() {
        var open = dialog.style.display !== 'none';
        dialog.style.display = open ? 'none' : 'block';
        overlay.style.display = open ? 'none' : 'block';
    });
    overlay.addEventListener('click', function() { dialog.style.display = 'none'; overlay.style.display = 'none'; });
})();
function cd1Send() { var s = document.getElementById('cd1-action'); var t = document.getElementById('cd1-textarea'); if(!s||!t)return; t.value += '[' + new Date().toLocaleTimeString() + '] ' + s.value + ' sent.\n'; }
function cd1Ok() { var t = document.getElementById('cd1-textarea'); if(!t)return; t.value += '[' + new Date().toLocaleTimeString() + '] OK.\n'; }
</script>
</body>
</html>
