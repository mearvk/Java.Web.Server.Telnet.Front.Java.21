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
<script src="js/scroll-preserve.js"></script>
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
        <li><a href="legal.jsp">Legal</a></li>
        <li><a href="status.jsp">Status</a></li>
    </ul>
    <div class="nav-actions">
        <a href="guest.jsp" class="nav-cta">Guest</a>
        <a href="register.jsp" class="nav-cta">Register</a>
        <a href="admin/login.xhtml" class="nav-cta">Admin →</a>
    </div>
</div></nav>

<section class="hero" style="padding:4rem 2rem;">
    <div class="hero-inner">
        <span class="hero-tag">Museum Collections</span>
        <h1>Art Database</h1>
        <p>Art museum collections indexer covering 22 major institutions with species-linked natural art references.</p>
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
    <div style="font-size:0.9rem;font-weight:600;color:#fff;margin-bottom:0.75rem;">BMA Connector &#8212; Art Division</div>
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
    Connection conn = null;
    Properties dbProps = new Properties();
    boolean propsLoaded = false;
    try {
        InputStream dbIn = application.getResourceAsStream("/WEB-INF/db.properties");
        if (dbIn != null) { dbProps.load(dbIn); dbIn.close(); propsLoaded = true; }
        if (!propsLoaded) {
            String rp = application.getRealPath("/WEB-INF/db.properties");
            if (rp != null && new java.io.File(rp).exists()) {
                java.io.FileInputStream fis = new java.io.FileInputStream(rp);
                dbProps.load(fis); fis.close(); propsLoaded = true;
            }
        }
        if (!propsLoaded) {
            String[] tryPaths = { "/opt/tomcat/webapps/brarner.m.alete/WEB-INF/db.properties",
                System.getProperty("user.dir") + "/servlets/servlet/src/main/webapp/WEB-INF/db.properties",
                "/mnt/blockstorage/Java.Web.Server.Telnet.Front.Java.21/modules/black/presidential/Brarner.M.Alete/servlets/servlet/src/main/webapp/WEB-INF/db.properties" };
            for (String tp : tryPaths) { java.io.File f = new java.io.File(tp);
                if (f.exists()) { java.io.FileInputStream fis = new java.io.FileInputStream(f); dbProps.load(fis); fis.close(); propsLoaded = true; break; } }
        }
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
        <p style="color:#a1a1aa;font-size:0.8rem;">User: <%= dbProps.getProperty("db.user","?") %> | URL: <%= dbProps.getProperty("db.url","?") %> | Props loaded: <%= propsLoaded %></p>
<%  } finally { if (conn != null) try { conn.close(); } catch (Exception ignored) {} }
%>
    </div>
</section>

<footer class="footer"><div class="footer-bottom" style="border:none;padding:0;">
    <span>&#169; 2026 MEARVK LLC. All rights reserved.</span>
</div></footer>

<script>
(function() {
    var btn = document.getElementById("cd1-btn");
    var dialog = document.getElementById("cd1-dialog");
    var overlay = document.getElementById("cd1-overlay");
    var textarea = document.getElementById("cd1-textarea");
    if (!btn || !dialog || !overlay || !textarea) return;
    btn.addEventListener("click", function() {
        if (dialog.style.display !== "none") {
            dialog.style.display = "none";
            overlay.style.display = "none";
            btn.style.transform = "";
            btn.style.filter = "";
            return;
        }
        btn.style.transform = "scale(0.9)";
        btn.style.filter = "drop-shadow(0 0 8px #3b82f6)";
        setTimeout(function() {
            btn.style.transform = "";
            btn.style.filter = "";
            dialog.style.display = "block";
            overlay.style.display = "block";
        }, 750);
    });
    overlay.addEventListener("click", function() { dialog.style.display = "none"; overlay.style.display = "none"; });
})();
function cd1Send() { var s = document.getElementById("cd1-action"); var t = document.getElementById("cd1-textarea"); if(!s||!t)return; t.value += "[" + new Date().toLocaleTimeString() + "] " + s.value + " sent.\n"; }
function cd1Ok() { var t = document.getElementById("cd1-textarea"); if(!t)return; t.value += "[" + new Date().toLocaleTimeString() + "] OK.\n"; }
</script>
</body>
</html>
