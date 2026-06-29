<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.Properties, java.io.InputStream" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <link rel="icon" type="image/png" href="images/favicon.png"/>
    <title>Species — Brarner.M.Alete™</title>
    <link rel="stylesheet" href="css/style.css"/>
</head>
<body>
<nav class="nav"><div class="nav-inner">
    <a href="index.jsp" class="nav-brand"><img src="images/mearvk.ltd.logo.left.png" alt="" style="height:40px;vertical-align:middle;margin-right:8px;background:transparent;"/>Brarner.M.Alete™<img src="images/mearvk.ltd.logo.right.png" alt="" style="height:40px;vertical-align:middle;margin-left:8px;background:transparent;"/></a>
    <ul class="nav-links">
        <li><a href="index.jsp">Overview</a></li>
        <li><a href="species.jsp" class="active">Species</a></li>
        <li><a href="postal.jsp">Postal</a></li>
        <li><a href="art.jsp">Art</a></li>
        <li><a href="science.jsp">Science</a></li>
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
        <span class="hero-tag">Biological Classification</span>
        <h1>Species Database</h1>
        <p>Comprehensive species classification with 12 sub-categories covering animalia, plantae, fungi, and protista kingdoms.</p>
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
    <div style="font-size:0.9rem;font-weight:600;color:#fff;margin-bottom:0.75rem;">BMA Connector &#8212; Species Division</div>
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
        <h2>Browse by Kingdom</h2>
<%
    String kingdom = request.getParameter("kingdom");
    if (kingdom == null || kingdom.isEmpty()) kingdom = "Animalia";

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
        String dbUrl = dbProps.getProperty("db.url", "jdbc:mysql://localhost:3306/BrarnerScience");
        String dbUser = dbProps.getProperty("db.user", "root");
        String dbPass = dbProps.getProperty("db.password", "");
        Class.forName(dbProps.getProperty("db.driver", "com.mysql.cj.jdbc.Driver"));
        conn = DriverManager.getConnection(dbUrl, dbUser, dbPass);

        // Classes for selected kingdom
        PreparedStatement psClass = conn.prepareStatement(
            "SELECT DISTINCT class_name, COUNT(DISTINCT order_name) AS orders, COUNT(DISTINCT family_name) AS families " +
            "FROM animalia WHERE kingdom=? AND class_name IS NOT NULL AND class_name!='' GROUP BY class_name ORDER BY class_name");
        psClass.setString(1, kingdom);
        ResultSet rsClass = psClass.executeQuery();
%>
        <div class="tabs">
            <a href="species.jsp?kingdom=Animalia" class="tab <%= "Animalia".equals(kingdom) ? "active" : "" %>">Animalia</a>
            <a href="species.jsp?kingdom=Plantae" class="tab <%= "Plantae".equals(kingdom) ? "active" : "" %>">Plantae</a>
            <a href="species.jsp?kingdom=Fungi" class="tab <%= "Fungi".equals(kingdom) ? "active" : "" %>">Fungi</a>
            <a href="species.jsp?kingdom=Protista" class="tab <%= "Protista".equals(kingdom) ? "active" : "" %>">Protista</a>
        </div>

        <h3><%= kingdom %> Classes</h3>
        <div class="table-wrap">
            <table>
                <thead><tr><th>Class</th><th>Orders</th><th>Families</th></tr></thead>
                <tbody>
<%
        String selClass = request.getParameter("class");
        boolean hasRows = false;
        while (rsClass.next()) {
            hasRows = true;
            String className = rsClass.getString("class_name");
            int orders = rsClass.getInt("orders");
            int families = rsClass.getInt("families");
            boolean isSelected = className != null && className.equals(selClass);
%>
                    <tr style="<%= isSelected ? "background:rgba(59,130,246,0.08);border-left:3px solid #3b82f6;" : "" %>">
                        <td><a href="species.jsp?kingdom=<%= kingdom %><%= isSelected ? "" : "&class=" + java.net.URLEncoder.encode(className, "UTF-8") %>" style="<%= isSelected ? "color:#3b82f6;font-weight:600;" : "" %>"><%= className != null ? className : "(unnamed)" %><%= isSelected ? " ▼" : "" %></a></td>
                        <td><%= orders %></td>
                        <td><%= families %></td>
                    </tr>
<%
            // Expand orders inline under the selected class
            if (isSelected) {
                PreparedStatement psOrder = conn.prepareStatement(
                    "SELECT DISTINCT order_name, COUNT(DISTINCT family_name) AS families " +
                    "FROM animalia WHERE class_name=? AND order_name IS NOT NULL AND order_name!='' GROUP BY order_name ORDER BY order_name");
                psOrder.setString(1, selClass);
                ResultSet rsOrder = psOrder.executeQuery();
                String selOrder = request.getParameter("order");
%>
                    <tr><td colspan="3" style="padding:0;">
                        <div style="margin:0.5rem 1rem 1rem 1.5rem;">
                            <strong style="font-size:0.85rem;color:#a1a1aa;">Orders in <%= selClass %></strong>
                            <table style="margin-top:0.5rem;width:100%;">
                                <thead><tr><th>Order</th><th>Families</th></tr></thead>
                                <tbody>
<%
                boolean hasOrders = false;
                while (rsOrder.next()) {
                    hasOrders = true;
                    String orderName = rsOrder.getString("order_name");
                    int fam = rsOrder.getInt("families");
                    boolean orderSelected = orderName != null && orderName.equals(selOrder);
%>
                                    <tr style="<%= orderSelected ? "background:rgba(59,130,246,0.06);" : "" %>">
                                        <td><a href="species.jsp?kingdom=<%= kingdom %>&class=<%= java.net.URLEncoder.encode(selClass, "UTF-8") %><%= orderSelected ? "" : "&order=" + java.net.URLEncoder.encode(orderName, "UTF-8") %>" style="<%= orderSelected ? "color:#3b82f6;font-weight:600;" : "" %>"><%= orderName != null ? orderName : "(unnamed)" %><%= orderSelected ? " ▼" : "" %></a></td>
                                        <td><%= fam %></td>
                                    </tr>
<%
                    // Expand families inline under the selected order
                    if (orderSelected) {
                        PreparedStatement psFamily = conn.prepareStatement(
                            "SELECT DISTINCT family_name FROM animalia WHERE order_name=? AND family_name IS NOT NULL AND family_name!='' ORDER BY family_name");
                        psFamily.setString(1, selOrder);
                        ResultSet rsFamily = psFamily.executeQuery();
                        String selFamily = request.getParameter("family");
%>
                                    <tr><td colspan="2" style="padding:0;">
                                        <div style="margin:0.5rem 0 0.5rem 1.5rem;">
                                            <strong style="font-size:0.8rem;color:#a1a1aa;">Families in <%= selOrder %></strong>
                                            <table style="margin-top:0.4rem;width:100%;">
                                                <thead><tr><th>Family</th></tr></thead>
                                                <tbody>
<%
                        boolean hasFamilies = false;
                        while (rsFamily.next()) {
                            hasFamilies = true;
                            String familyName = rsFamily.getString("family_name");
                            boolean famSelected = familyName != null && familyName.equals(selFamily);
%>
                                                    <tr style="<%= famSelected ? "background:rgba(59,130,246,0.06);" : "" %>">
                                                        <td><a href="species.jsp?kingdom=<%= kingdom %>&class=<%= java.net.URLEncoder.encode(selClass, "UTF-8") %>&order=<%= java.net.URLEncoder.encode(selOrder, "UTF-8") %><%= famSelected ? "" : "&family=" + java.net.URLEncoder.encode(familyName, "UTF-8") %>" style="<%= famSelected ? "color:#3b82f6;font-weight:600;" : "" %>"><%= familyName != null ? familyName : "(unnamed)" %><%= famSelected ? " ▼" : "" %></a></td>
                                                    </tr>
<%
                            // Expand species under selected family
                            if (famSelected) {
                                PreparedStatement psSpecies = conn.prepareStatement(
                                    "SELECT species_name, common_name, description FROM species WHERE family_name=? ORDER BY species_name");
                                psSpecies.setString(1, selFamily);
                                ResultSet rsSpecies = psSpecies.executeQuery();
%>
                                                    <tr><td style="padding:0;">
                                                        <div style="margin:0.5rem 0 0.5rem 1.5rem;">
                                                            <strong style="font-size:0.8rem;color:#a1a1aa;">Species in <%= selFamily %></strong>
                                                            <table style="margin-top:0.4rem;width:100%;">
                                                                <thead><tr><th>Species</th><th>Common Name</th><th>Description</th></tr></thead>
                                                                <tbody>
<%
                                boolean hasSpecies = false;
                                while (rsSpecies.next()) {
                                    hasSpecies = true;
                                    String sName = rsSpecies.getString("species_name");
                                    String cName = rsSpecies.getString("common_name");
                                    String desc = rsSpecies.getString("description");
%>
                                                                    <tr><td><em><%= sName != null ? sName : "" %></em></td><td><%= cName != null ? cName : "" %></td><td><%= desc != null ? desc : "" %></td></tr>
<%
                                }
                                if (!hasSpecies) {
%>
                                                                    <tr><td colspan="3">No species records yet.</td></tr>
<%
                                }
                                rsSpecies.close(); psSpecies.close();
%>
                                                                </tbody>
                                                            </table>
                                                        </div>
                                                    </td></tr>
<%
                            }
                        }
                        if (!hasFamilies) {
%>
                                                    <tr><td>No families found.</td></tr>
<%
                        }
                        rsFamily.close(); psFamily.close();
%>
                                                </tbody>
                                            </table>
                                        </div>
                                    </td></tr>
<%
                    }
                }
                if (!hasOrders) {
%>
                                    <tr><td colspan="2">No orders found.</td></tr>
<%
                }
                rsOrder.close(); psOrder.close();
%>
                                </tbody>
                            </table>
                        </div>
                    </td></tr>
<%
            }
        }
        if (!hasRows) {
%>
                    <tr><td colspan="3">No classes found for <%= kingdom %>.</td></tr>
<%
        }
        rsClass.close();
        psClass.close();
%>
                </tbody>
            </table>
        </div>
<%
    } catch (Exception e) {
%>
        <p style="color:#ef4444;">Database error: <%= e.getMessage() != null ? e.getMessage().replace("<","&lt;") : "unknown" %></p>
        <p style="color:#a1a1aa;font-size:0.8rem;">User: <%= dbProps.getProperty("db.user","?") %> | URL: <%= dbProps.getProperty("db.url","?") %> | Props loaded: <%= propsLoaded %></p>
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
