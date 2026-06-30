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
<script src="js/scroll-preserve.js"></script>
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
        <li><a href="analysis.jsp">Analysis</a></li>
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
    <!-- Signal Processor Upload — File Analysis (SCD1) -->
    <div style="margin-top:0.75rem;padding-top:0.75rem;border-top:1px solid #27272a;">
        <div style="font-size:0.78rem;font-weight:600;color:#a1a1aa;margin-bottom:0.5rem;">Signal Processor Upload</div>
        <div style="display:flex;gap:0.4rem;flex-wrap:wrap;margin-bottom:0.5rem;">
            <label style="display:flex;align-items:center;gap:0.3rem;font-size:0.72rem;color:#a1a1aa;cursor:pointer;padding:0.25rem 0.5rem;border:1px solid #27272a;border-radius:4px;"><input type="radio" name="type-scd1" value="data" checked style="accent-color:#dc2626;width:11px;height:11px;"/> Data</label>
            <label style="display:flex;align-items:center;gap:0.3rem;font-size:0.72rem;color:#a1a1aa;cursor:pointer;padding:0.25rem 0.5rem;border:1px solid #27272a;border-radius:4px;"><input type="radio" name="type-scd1" value="audio" style="accent-color:#dc2626;width:11px;height:11px;"/> Audio</label>
            <label style="display:flex;align-items:center;gap:0.3rem;font-size:0.72rem;color:#a1a1aa;cursor:pointer;padding:0.25rem 0.5rem;border:1px solid #27272a;border-radius:4px;"><input type="radio" name="type-scd1" value="image" style="accent-color:#dc2626;width:11px;height:11px;"/> Image</label>
        </div>
        <div style="display:flex;gap:0.5rem;align-items:center;flex-wrap:wrap;">
            <input type="file" id="file-scd1" onchange="analysisFileSelected('scd1')" style="font-size:0.72rem;color:#a1a1aa;max-width:240px;"/>
            <button onclick="analysisUpload('scd1')" id="btn-scd1" disabled style="background:#dc2626;color:#fff;border:none;border-radius:5px;padding:0.35rem 0.8rem;font-size:0.72rem;font-weight:600;cursor:pointer;">Analyze</button>
        </div>
        <div id="prog-scd1" style="display:none;margin-top:0.4rem;">
            <div style="width:100%;height:5px;background:#27272a;border-radius:3px;overflow:hidden;"><div id="bar-scd1" style="height:100%;width:0%;background:linear-gradient(90deg,#dc2626,#ef4444);border-radius:3px;transition:width 0.4s;"></div></div>
            <div style="display:flex;justify-content:space-between;font-size:0.66rem;color:#71717a;margin-top:0.1rem;"><span id="stage-scd1" style="color:#ef4444;font-weight:600;"></span><span id="pct-scd1"></span></div>
        </div>
        <div id="result-scd1" style="display:none;margin-top:0.4rem;"></div>
    </div>
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
<%
        // Lookup kingdom description
        PreparedStatement psDesc = conn.prepareStatement(
            "SELECT description, characteristics, example_species, wikipedia_url FROM taxonomy_descriptions WHERE rank_level='kingdom' AND taxon_name=?");
        psDesc.setString(1, kingdom);
        ResultSet rsDesc = psDesc.executeQuery();
        if (rsDesc.next()) {
            String kdesc = rsDesc.getString("description");
            String kchars = rsDesc.getString("characteristics");
            String kwiki = rsDesc.getString("wikipedia_url");
%>
        <div style="background:var(--bg-card);border:1px solid var(--border);border-left:3px solid var(--accent);border-radius:8px;padding:1rem;margin-bottom:1.5rem;">
            <div style="font-weight:600;margin-bottom:0.5rem;">Kingdom: <%= kingdom %></div>
            <div style="color:var(--text-secondary);font-size:0.85rem;margin-bottom:0.5rem;"><%= kdesc != null ? kdesc : "" %></div>
<% if (kchars != null && !kchars.isEmpty()) { %>
            <div style="color:var(--text-muted);font-size:0.8rem;"><strong>Characteristics:</strong> <%= kchars %></div>
<% } if (kwiki != null && !kwiki.isEmpty()) { %>
            <div style="margin-top:0.5rem;"><a href="<%= kwiki %>" target="_blank" style="color:var(--accent);font-size:0.8rem;">Wikipedia →</a></div>
<% } %>
            <!-- Analysis Upload for Kingdom -->
            <div class="analysis-upload-inline" style="margin-top:1rem;padding-top:1rem;border-top:1px solid var(--border);"
                 data-rank="kingdom" data-kingdom="<%= kingdom %>" data-class="" data-order="" data-family="" data-species="" data-common="">
                <div style="font-size:0.8rem;font-weight:600;color:var(--text-secondary);margin-bottom:0.5rem;">Signal Processor Upload — Kingdom: <%= kingdom %></div>
                <div style="display:flex;gap:0.5rem;flex-wrap:wrap;margin-bottom:0.5rem;">
                    <label style="display:flex;align-items:center;gap:0.3rem;font-size:0.75rem;color:var(--text-muted);cursor:pointer;padding:0.3rem 0.6rem;border:1px solid var(--border);border-radius:5px;"><input type="radio" name="type-kingdom" value="data" checked style="accent-color:#dc2626;width:12px;height:12px;"/> Data</label>
                    <label style="display:flex;align-items:center;gap:0.3rem;font-size:0.75rem;color:var(--text-muted);cursor:pointer;padding:0.3rem 0.6rem;border:1px solid var(--border);border-radius:5px;"><input type="radio" name="type-kingdom" value="audio" style="accent-color:#dc2626;width:12px;height:12px;"/> Audio</label>
                    <label style="display:flex;align-items:center;gap:0.3rem;font-size:0.75rem;color:var(--text-muted);cursor:pointer;padding:0.3rem 0.6rem;border:1px solid var(--border);border-radius:5px;"><input type="radio" name="type-kingdom" value="image" style="accent-color:#dc2626;width:12px;height:12px;"/> Image</label>
                </div>
                <div style="display:flex;gap:0.5rem;align-items:center;flex-wrap:wrap;">
                    <input type="file" id="file-kingdom" onchange="analysisFileSelected('kingdom')" style="font-size:0.78rem;color:var(--text-secondary);"/>
                    <button onclick="analysisUpload('kingdom')" id="btn-kingdom" disabled style="background:#dc2626;color:#fff;border:none;border-radius:6px;padding:0.4rem 1rem;font-size:0.75rem;font-weight:600;cursor:pointer;">Analyze</button>
                </div>
                <div id="prog-kingdom" style="display:none;margin-top:0.5rem;">
                    <div style="width:100%;height:6px;background:#27272a;border-radius:3px;overflow:hidden;"><div id="bar-kingdom" style="height:100%;width:0%;background:linear-gradient(90deg,#dc2626,#ef4444);border-radius:3px;transition:width 0.4s;"></div></div>
                    <div style="display:flex;justify-content:space-between;font-size:0.7rem;color:var(--text-muted);margin-top:0.2rem;"><span id="stage-kingdom" style="color:#ef4444;font-weight:600;">Uploading...</span><span id="pct-kingdom">0%</span></div>
                </div>
                <div id="result-kingdom" style="display:none;margin-top:0.5rem;"></div>
            </div>
        </div>
<%
        }
        rsDesc.close(); psDesc.close();
%>
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
                // Show class description
                PreparedStatement psClassDesc = conn.prepareStatement(
                    "SELECT description, characteristics, example_species, wikipedia_url FROM taxonomy_descriptions WHERE rank_level='class' AND taxon_name=?");
                psClassDesc.setString(1, selClass);
                ResultSet rsClassDesc = psClassDesc.executeQuery();
                if (rsClassDesc.next()) {
                    String cdesc = rsClassDesc.getString("description");
                    String cchars = rsClassDesc.getString("characteristics");
                    String cex = rsClassDesc.getString("example_species");
                    String cwiki = rsClassDesc.getString("wikipedia_url");
%>
                    <tr><td colspan="3" style="padding:0.75rem 1rem;background:var(--bg-card);border-left:3px solid var(--accent);">
                        <div style="font-weight:600;font-size:0.9rem;margin-bottom:0.4rem;">Class: <%= selClass %></div>
                        <div style="color:var(--text-secondary);font-size:0.82rem;margin-bottom:0.4rem;"><%= cdesc != null ? cdesc : "" %></div>
<% if (cchars != null && !cchars.isEmpty()) { %>
                        <div style="color:var(--text-muted);font-size:0.78rem;margin-bottom:0.3rem;"><strong>Characteristics:</strong> <%= cchars %></div>
<% } if (cex != null && !cex.isEmpty()) { %>
                        <div style="color:var(--text-muted);font-size:0.78rem;margin-bottom:0.3rem;"><strong>Examples:</strong> <em><%= cex %></em></div>
<% } if (cwiki != null && !cwiki.isEmpty()) { %>
                        <div><a href="<%= cwiki %>" target="_blank" style="color:var(--accent);font-size:0.78rem;">Wikipedia →</a></div>
<% } %>
                        <!-- Analysis Upload for Class -->
                        <div style="margin-top:0.75rem;padding-top:0.75rem;border-top:1px solid var(--border);"
                             data-rank="class" data-kingdom="<%= kingdom %>" data-class="<%= selClass %>" data-order="" data-family="" data-species="" data-common="">
                            <div style="font-size:0.75rem;font-weight:600;color:var(--text-secondary);margin-bottom:0.4rem;">Signal Processor Upload — Class: <%= selClass %></div>
                            <div style="display:flex;gap:0.4rem;flex-wrap:wrap;margin-bottom:0.4rem;">
                                <label style="display:flex;align-items:center;gap:0.3rem;font-size:0.72rem;color:var(--text-muted);cursor:pointer;padding:0.25rem 0.5rem;border:1px solid var(--border);border-radius:4px;"><input type="radio" name="type-class" value="data" checked style="accent-color:#dc2626;width:11px;height:11px;"/> Data</label>
                                <label style="display:flex;align-items:center;gap:0.3rem;font-size:0.72rem;color:var(--text-muted);cursor:pointer;padding:0.25rem 0.5rem;border:1px solid var(--border);border-radius:4px;"><input type="radio" name="type-class" value="audio" style="accent-color:#dc2626;width:11px;height:11px;"/> Audio</label>
                                <label style="display:flex;align-items:center;gap:0.3rem;font-size:0.72rem;color:var(--text-muted);cursor:pointer;padding:0.25rem 0.5rem;border:1px solid var(--border);border-radius:4px;"><input type="radio" name="type-class" value="image" style="accent-color:#dc2626;width:11px;height:11px;"/> Image</label>
                            </div>
                            <div style="display:flex;gap:0.5rem;align-items:center;flex-wrap:wrap;">
                                <input type="file" id="file-class" onchange="analysisFileSelected('class')" style="font-size:0.72rem;color:var(--text-secondary);max-width:220px;"/>
                                <button onclick="analysisUpload('class')" id="btn-class" disabled style="background:#dc2626;color:#fff;border:none;border-radius:5px;padding:0.35rem 0.8rem;font-size:0.72rem;font-weight:600;cursor:pointer;">Analyze</button>
                            </div>
                            <div id="prog-class" style="display:none;margin-top:0.4rem;">
                                <div style="width:100%;height:5px;background:#27272a;border-radius:3px;overflow:hidden;"><div id="bar-class" style="height:100%;width:0%;background:linear-gradient(90deg,#dc2626,#ef4444);border-radius:3px;transition:width 0.4s;"></div></div>
                                <div style="display:flex;justify-content:space-between;font-size:0.68rem;color:var(--text-muted);margin-top:0.15rem;"><span id="stage-class" style="color:#ef4444;font-weight:600;"></span><span id="pct-class"></span></div>
                            </div>
                            <div id="result-class" style="display:none;margin-top:0.4rem;"></div>
                        </div>
                    </td></tr>
<%
                }
                rsClassDesc.close(); psClassDesc.close();

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
                        // Order description
                        PreparedStatement psOrdDesc = conn.prepareStatement(
                            "SELECT description, characteristics, wikipedia_url FROM taxonomy_descriptions WHERE rank_level='order' AND taxon_name=?");
                        psOrdDesc.setString(1, selOrder);
                        ResultSet rsOrdDesc = psOrdDesc.executeQuery();
                        if (rsOrdDesc.next()) {
                            String odesc = rsOrdDesc.getString("description");
                            String ochars = rsOrdDesc.getString("characteristics");
                            String owiki = rsOrdDesc.getString("wikipedia_url");
%>
                                    <tr><td colspan="2" style="padding:0.6rem 1rem;background:var(--bg-card);border-left:3px solid var(--accent);">
                                        <div style="font-weight:600;font-size:0.85rem;margin-bottom:0.3rem;">Order: <%= selOrder %></div>
                                        <div style="color:var(--text-secondary);font-size:0.78rem;margin-bottom:0.3rem;"><%= odesc != null ? odesc : "" %></div>
<% if (ochars != null && !ochars.isEmpty()) { %>
                                        <div style="color:var(--text-muted);font-size:0.75rem;"><strong>Characteristics:</strong> <%= ochars %></div>
<% } if (owiki != null && !owiki.isEmpty()) { %>
                                        <div style="margin-top:0.3rem;"><a href="<%= owiki %>" target="_blank" style="color:var(--accent);font-size:0.75rem;">Wikipedia →</a></div>
<% } %>
                                        <!-- Analysis Upload for Order -->
                                        <div style="margin-top:0.6rem;padding-top:0.6rem;border-top:1px solid var(--border);"
                                             data-rank="order" data-kingdom="<%= kingdom %>" data-class="<%= selClass %>" data-order="<%= selOrder %>" data-family="" data-species="" data-common="">
                                            <div style="font-size:0.72rem;font-weight:600;color:var(--text-secondary);margin-bottom:0.35rem;">Signal Processor Upload — Order: <%= selOrder %></div>
                                            <div style="display:flex;gap:0.4rem;flex-wrap:wrap;margin-bottom:0.35rem;">
                                                <label style="display:flex;align-items:center;gap:0.25rem;font-size:0.7rem;color:var(--text-muted);cursor:pointer;padding:0.2rem 0.45rem;border:1px solid var(--border);border-radius:4px;"><input type="radio" name="type-order" value="data" checked style="accent-color:#dc2626;width:10px;height:10px;"/> Data</label>
                                                <label style="display:flex;align-items:center;gap:0.25rem;font-size:0.7rem;color:var(--text-muted);cursor:pointer;padding:0.2rem 0.45rem;border:1px solid var(--border);border-radius:4px;"><input type="radio" name="type-order" value="audio" style="accent-color:#dc2626;width:10px;height:10px;"/> Audio</label>
                                                <label style="display:flex;align-items:center;gap:0.25rem;font-size:0.7rem;color:var(--text-muted);cursor:pointer;padding:0.2rem 0.45rem;border:1px solid var(--border);border-radius:4px;"><input type="radio" name="type-order" value="image" style="accent-color:#dc2626;width:10px;height:10px;"/> Image</label>
                                            </div>
                                            <div style="display:flex;gap:0.4rem;align-items:center;flex-wrap:wrap;">
                                                <input type="file" id="file-order" onchange="analysisFileSelected('order')" style="font-size:0.7rem;color:var(--text-secondary);max-width:200px;"/>
                                                <button onclick="analysisUpload('order')" id="btn-order" disabled style="background:#dc2626;color:#fff;border:none;border-radius:4px;padding:0.3rem 0.7rem;font-size:0.7rem;font-weight:600;cursor:pointer;">Analyze</button>
                                            </div>
                                            <div id="prog-order" style="display:none;margin-top:0.35rem;">
                                                <div style="width:100%;height:5px;background:#27272a;border-radius:3px;overflow:hidden;"><div id="bar-order" style="height:100%;width:0%;background:linear-gradient(90deg,#dc2626,#ef4444);border-radius:3px;transition:width 0.4s;"></div></div>
                                                <div style="display:flex;justify-content:space-between;font-size:0.65rem;color:var(--text-muted);margin-top:0.1rem;"><span id="stage-order" style="color:#ef4444;font-weight:600;"></span><span id="pct-order"></span></div>
                                            </div>
                                            <div id="result-order" style="display:none;margin-top:0.35rem;"></div>
                                        </div>
                                    </td></tr>
<%
                        }
                        rsOrdDesc.close(); psOrdDesc.close();

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
                                // Family description
                                PreparedStatement psFamDesc = conn.prepareStatement(
                                    "SELECT description, characteristics, wikipedia_url FROM taxonomy_descriptions WHERE rank_level='family' AND taxon_name=?");
                                psFamDesc.setString(1, selFamily);
                                ResultSet rsFamDesc = psFamDesc.executeQuery();
                                if (rsFamDesc.next()) {
                                    String fdesc = rsFamDesc.getString("description");
                                    String fchars = rsFamDesc.getString("characteristics");
                                    String fwiki = rsFamDesc.getString("wikipedia_url");
%>
                                                    <tr><td style="padding:0.6rem 0.75rem;background:var(--bg-card);border-left:3px solid var(--accent);">
                                                        <div style="font-weight:600;font-size:0.82rem;margin-bottom:0.3rem;">Family: <%= selFamily %></div>
                                                        <div style="color:var(--text-secondary);font-size:0.76rem;margin-bottom:0.3rem;"><%= fdesc != null ? fdesc : "" %></div>
<% if (fchars != null && !fchars.isEmpty()) { %>
                                                        <div style="color:var(--text-muted);font-size:0.72rem;"><strong>Characteristics:</strong> <%= fchars %></div>
<% } if (fwiki != null && !fwiki.isEmpty()) { %>
                                                        <div style="margin-top:0.3rem;"><a href="<%= fwiki %>" target="_blank" style="color:var(--accent);font-size:0.72rem;">Wikipedia →</a></div>
<% } %>
                                                        <!-- Analysis Upload for Family -->
                                                        <div style="margin-top:0.6rem;padding-top:0.6rem;border-top:1px solid var(--border);"
                                                             data-rank="family" data-kingdom="<%= kingdom %>" data-class="<%= selClass %>" data-order="<%= selOrder %>" data-family="<%= selFamily %>" data-species="" data-common="">
                                                            <div style="font-size:0.7rem;font-weight:600;color:var(--text-secondary);margin-bottom:0.3rem;">Signal Processor Upload — Family: <%= selFamily %></div>
                                                            <div style="display:flex;gap:0.35rem;flex-wrap:wrap;margin-bottom:0.3rem;">
                                                                <label style="display:flex;align-items:center;gap:0.2rem;font-size:0.68rem;color:var(--text-muted);cursor:pointer;padding:0.2rem 0.4rem;border:1px solid var(--border);border-radius:4px;"><input type="radio" name="type-family" value="data" checked style="accent-color:#dc2626;width:10px;height:10px;"/> Data</label>
                                                                <label style="display:flex;align-items:center;gap:0.2rem;font-size:0.68rem;color:var(--text-muted);cursor:pointer;padding:0.2rem 0.4rem;border:1px solid var(--border);border-radius:4px;"><input type="radio" name="type-family" value="audio" style="accent-color:#dc2626;width:10px;height:10px;"/> Audio</label>
                                                                <label style="display:flex;align-items:center;gap:0.2rem;font-size:0.68rem;color:var(--text-muted);cursor:pointer;padding:0.2rem 0.4rem;border:1px solid var(--border);border-radius:4px;"><input type="radio" name="type-family" value="image" style="accent-color:#dc2626;width:10px;height:10px;"/> Image</label>
                                                            </div>
                                                            <div style="display:flex;gap:0.4rem;align-items:center;flex-wrap:wrap;">
                                                                <input type="file" id="file-family" onchange="analysisFileSelected('family')" style="font-size:0.68rem;color:var(--text-secondary);max-width:190px;"/>
                                                                <button onclick="analysisUpload('family')" id="btn-family" disabled style="background:#dc2626;color:#fff;border:none;border-radius:4px;padding:0.25rem 0.6rem;font-size:0.68rem;font-weight:600;cursor:pointer;">Analyze</button>
                                                            </div>
                                                            <div id="prog-family" style="display:none;margin-top:0.3rem;">
                                                                <div style="width:100%;height:4px;background:#27272a;border-radius:2px;overflow:hidden;"><div id="bar-family" style="height:100%;width:0%;background:linear-gradient(90deg,#dc2626,#ef4444);border-radius:2px;transition:width 0.4s;"></div></div>
                                                                <div style="display:flex;justify-content:space-between;font-size:0.63rem;color:var(--text-muted);margin-top:0.1rem;"><span id="stage-family" style="color:#ef4444;font-weight:600;"></span><span id="pct-family"></span></div>
                                                            </div>
                                                            <div id="result-family" style="display:none;margin-top:0.3rem;"></div>
                                                        </div>
                                                    </td></tr>
<%
                                }
                                rsFamDesc.close(); psFamDesc.close();

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

<!-- Signal Processor Upload Logic -->
<script>
(function() {
    'use strict';

    // Infer full taxonomy context from the upload div's data attributes or URL params
    function getContext(rank) {
        // For SCD1 in CD1 dialog, infer from URL params
        if (rank === 'scd1') {
            var params = new URLSearchParams(window.location.search);
            return {
                rank: params.get('family') ? 'family' : params.get('order') ? 'order' : params.get('class') ? 'class' : 'kingdom',
                kingdom: params.get('kingdom') || 'Animalia',
                className: params.get('class') || '',
                order: params.get('order') || '',
                family: params.get('family') || '',
                species: '',
                common: '',
                taxon: params.get('family') || params.get('order') || params.get('class') || params.get('kingdom') || 'Animalia'
            };
        }

        // For inline upload divs, read from data-* attributes on the container
        var fileInput = document.getElementById('file-' + rank);
        if (!fileInput) return null;

        // Walk up to find the container with data-rank
        var container = fileInput.closest('[data-rank]');
        if (!container) {
            // Fallback: use URL params
            var params2 = new URLSearchParams(window.location.search);
            return {
                rank: rank,
                kingdom: params2.get('kingdom') || 'Animalia',
                className: params2.get('class') || '',
                order: params2.get('order') || '',
                family: params2.get('family') || '',
                species: '',
                common: '',
                taxon: rank === 'kingdom' ? (params2.get('kingdom') || 'Animalia') :
                       rank === 'class' ? (params2.get('class') || '') :
                       rank === 'order' ? (params2.get('order') || '') :
                       rank === 'family' ? (params2.get('family') || '') : ''
            };
        }

        return {
            rank: container.getAttribute('data-rank') || rank,
            kingdom: container.getAttribute('data-kingdom') || '',
            className: container.getAttribute('data-class') || '',
            order: container.getAttribute('data-order') || '',
            family: container.getAttribute('data-family') || '',
            species: container.getAttribute('data-species') || '',
            common: container.getAttribute('data-common') || '',
            taxon: container.getAttribute('data-' + rank) || container.getAttribute('data-kingdom') || ''
        };
    }

    window.analysisFileSelected = function(rank) {
        var input = document.getElementById('file-' + rank);
        var btn = document.getElementById('btn-' + rank);
        if (input && input.files.length > 0 && btn) {
            btn.disabled = false;
        }
    };

    window.analysisUpload = function(rank) {
        var input = document.getElementById('file-' + rank);
        if (!input || !input.files.length) return;
        var file = input.files[0];

        // Get context (full hierarchy)
        var ctx = getContext(rank);
        if (!ctx) return;

        // Get selected type
        var typeName = (rank === 'scd1') ? 'type-scd1' : 'type-' + rank;
        var typeRadios = document.querySelectorAll('input[name="' + typeName + '"]');
        var type = 'data';
        for (var i = 0; i < typeRadios.length; i++) {
            if (typeRadios[i].checked) { type = typeRadios[i].value; break; }
        }

        // Disable button, show progress
        var btn = document.getElementById('btn-' + rank);
        btn.disabled = true;
        btn.textContent = 'Processing...';

        var prog = document.getElementById('prog-' + rank);
        prog.style.display = 'block';

        var resultBox = document.getElementById('result-' + rank);
        resultBox.style.display = 'none';
        resultBox.innerHTML = '';

        // Log to CD1 textarea if SCD1
        if (rank === 'scd1') {
            var ta = document.getElementById('cd1-textarea');
            if (ta) ta.value += '[' + new Date().toLocaleTimeString() + '] Signal Processor upload: ' + file.name + ' (' + ctx.rank + ': ' + ctx.taxon + ')\n';
        }

        // Build FormData with full taxonomy context
        var fd = new FormData();
        fd.append('file', file);
        fd.append('rank', ctx.rank);
        fd.append('taxon', ctx.taxon);
        fd.append('type', type);
        fd.append('kingdom', ctx.kingdom);
        fd.append('className', ctx.className);
        fd.append('order', ctx.order);
        fd.append('family', ctx.family);
        fd.append('species', ctx.species);
        fd.append('commonName', ctx.common);
        fd.append('source', 'SCD1');

        // Upload
        var xhr = new XMLHttpRequest();
        xhr.open('POST', 'api/analysis/upload', true);

        xhr.upload.onprogress = function(e) {
            if (e.lengthComputable) {
                var pct = Math.round((e.loaded / e.total) * 15);
                updateAnalysisProgress(rank, pct, 'Uploading...');
            }
        };

        xhr.onload = function() {
            if (xhr.status === 202 || xhr.status === 200) {
                var resp = JSON.parse(xhr.responseText);
                if (rank === 'scd1') {
                    var ta = document.getElementById('cd1-textarea');
                    if (ta) ta.value += '[' + new Date().toLocaleTimeString() + '] Signal Processor job: ' + resp.id + '\n';
                }
                pollAnalysisStatus(rank, resp.id);
            } else {
                var err = 'Upload failed';
                try { err = JSON.parse(xhr.responseText).error || err; } catch(ex) {}
                showAnalysisError(rank, err);
            }
        };

        xhr.onerror = function() { showAnalysisError(rank, 'Network error'); };
        xhr.send(fd);
    };

    function pollAnalysisStatus(rank, jobId) {
        var interval = setInterval(function() {
            fetch('api/analysis/status?id=' + jobId)
                .then(function(r) { return r.json(); })
                .then(function(data) {
                    updateAnalysisProgress(rank, data.progress, stageLabel(data.stage));
                    if (data.stage === 'complete') {
                        clearInterval(interval);
                        showAnalysisResult(rank, jobId);
                    } else if (data.stage === 'failed') {
                        clearInterval(interval);
                        showAnalysisError(rank, data.error || 'Analysis failed');
                    }
                })
                .catch(function() {
                    clearInterval(interval);
                    showAnalysisError(rank, 'Lost connection');
                });
        }, 800);
    }

    function updateAnalysisProgress(rank, pct, stage) {
        var bar = document.getElementById('bar-' + rank);
        var stageEl = document.getElementById('stage-' + rank);
        var pctEl = document.getElementById('pct-' + rank);
        if (bar) bar.style.width = pct + '%';
        if (stageEl) stageEl.textContent = stage;
        if (pctEl) pctEl.textContent = pct + '%';
    }

    function stageLabel(s) {
        switch(s) {
            case 'uploading':  return 'Uploading...';
            case 'scanning':   return 'ClamAV Scanning...';
            case 'heuristic':  return 'Heuristic Analysis...';
            case 'processing': return 'SignalProcessor\u2122...';
            case 'complete':   return 'Complete';
            case 'failed':     return 'Failed';
            default:           return s || '';
        }
    }

    function showAnalysisResult(rank, jobId) {
        var resultBox = document.getElementById('result-' + rank);
        resultBox.innerHTML = '<div style="font-size:0.72rem;color:#34d399;font-weight:600;">&#10003; Analysis Complete</div>'
            + '<a href="api/analysis/result?id=' + jobId + '" style="display:inline-block;margin-top:0.3rem;background:#166534;color:#fff;padding:0.3rem 0.7rem;border-radius:4px;font-size:0.68rem;font-weight:600;text-decoration:none;">&#128196; Download Results</a>'
            + '<div style="font-size:0.62rem;color:var(--text-muted);margin-top:0.3rem;">Graphs coming soon.</div>';
        resultBox.style.display = 'block';
        resetAnalysisBtn(rank);
        if (rank === 'scd1') {
            var ta = document.getElementById('cd1-textarea');
            if (ta) ta.value += '[' + new Date().toLocaleTimeString() + '] Signal Processor complete: ' + jobId + '\n';
        }
    }

    function showAnalysisError(rank, msg) {
        var resultBox = document.getElementById('result-' + rank);
        resultBox.innerHTML = '<div style="font-size:0.72rem;color:#ef4444;font-weight:600;">&#10007; Failed</div>'
            + '<div style="font-size:0.68rem;color:#fca5a5;">' + msg + '</div>';
        resultBox.style.display = 'block';
        resetAnalysisBtn(rank);
    }

    function resetAnalysisBtn(rank) {
        var btn = document.getElementById('btn-' + rank);
        if (btn) { btn.disabled = false; btn.textContent = 'Analyze'; }
    }
})();
</script>
</body>
</html>
