<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.*" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/>
    <link rel="preconnect" href="https://fonts.googleapis.com"/><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin/><link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:ital,wght@0,300;0,400;0,500;0,600;0,700;1,400;1,600&display=swap" rel="stylesheet"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>Calibration — Emeter™</title>
    <link rel="stylesheet" href="css/style.css"/>
    <script src="js/scroll-preserve.js"></script>
    <script src="js/nwe-readme-viewer.js"></script>
</head>
<body>
<nav class="nav"><div class="nav-inner">
    <span class="nav-brand">Emeter™</span>
    <ul class="nav-links">
        <li><a href="index.jsp">Overview</a></li>
        <li><a href="instructions.jsp">Instructions</a></li>
        <li><a href="calibration.jsp" class="active">Calibration</a></li>
        <li><a href="readings.jsp">Readings</a></li>
        <li><a href="status.jsp">Status</a></li>
    </ul>
</div></nav>

<section class="hero" style="padding:4rem 2rem;">
    <div class="hero-inner">
        <span class="hero-tag">Meter Setup &amp; Verification</span>
        <h1>Calibration</h1>
        <p>Step-by-step calibration procedures for all meter levels and settings.</p>
    </div>
</section>

<!-- CD1 Connector Button + Floating Dialog -->
<div style="display:flex;justify-content:center;align-items:center;width:100%;padding:2rem 0;">
    <button id="cd1-btn" type="button" aria-pressed="false" style="all:unset;display:block;margin:0 auto;cursor:pointer;padding:0;border:none;background:transparent;transition:transform 0.3s cubic-bezier(0.42,-1.84,0.42,1.84),filter 0.3s ease;">
        <img src="images/black.button.png" alt="Connector" style="display:block;width:80px;height:80px;border-radius:50%;background:transparent;"/>
    </button>
</div>
<div id="cd1-overlay" style="display:none;position:fixed;inset:0;z-index:299;background:transparent;"></div>
<div id="cd1-dialog" style="display:none;position:fixed;top:50%;left:50%;transform:translate(-50%,-50%);z-index:300;background:#1a1a1a;border:1px solid #333;border-radius:12px;padding:1.25rem;width:520px;max-width:90vw;box-shadow:0 8px 32px rgba(0,0,0,0.6);">
    <div style="font-size:0.9rem;font-weight:600;color:#e8e0d6;margin-bottom:0.75rem;">CD1 Connector &#8212; Port 49216</div>
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
<script>window.CD1_MODULE_PORT = "49216";</script>
<script src="js/cd1-connector.js"></script>


<section class="section">
    <div class="section-inner">
<%
    String dbUrl = "jdbc:mysql://127.0.0.1:3306/nwe_emeter";
    String dbUser = "root";
    String dbPass = "";
    String filterLevel = request.getParameter("level");

    List<Map<String, String>> rows = new ArrayList<>();
    String error = null;

    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        try (Connection conn = DriverManager.getConnection(dbUrl, dbUser, dbPass)) {
            StringBuilder sql = new StringBuilder("SELECT id, level_name, description, procedure_steps FROM calibration WHERE 1=1");
            List<String> params = new ArrayList<>();
            if (filterLevel != null && !filterLevel.isBlank()) {
                sql.append(" AND level_name LIKE ?");
                params.add("%" + filterLevel.trim() + "%");
            }
            sql.append(" ORDER BY id LIMIT 50");

            try (PreparedStatement ps = conn.prepareStatement(sql.toString())) {
                for (int i = 0; i < params.size(); i++) ps.setString(i + 1, params.get(i));
                ResultSet rs = ps.executeQuery();
                while (rs.next()) {
                    Map<String, String> row = new LinkedHashMap<>();
                    row.put("id", String.valueOf(rs.getInt("id")));
                    row.put("level_name", rs.getString("level_name"));
                    row.put("description", rs.getString("description"));
                    row.put("procedure_steps", rs.getString("procedure_steps"));
                    rows.add(row);
                }
            }
        }
    } catch (Exception e) {
        error = e.getMessage();
    }
%>
        <div style="margin-bottom:1.5rem;display:flex;gap:1rem;flex-wrap:wrap;align-items:flex-end;">
            <form method="get" style="display:flex;gap:0.75rem;flex-wrap:wrap;align-items:flex-end;">
                <div class="form-group" style="margin-bottom:0;">
                    <label>Level Name</label>
                    <input type="text" name="level" value="<%= filterLevel != null ? filterLevel : "" %>" placeholder="e.g. Set, Sensitivity..." style="width:220px;"/>
                </div>
                <button type="submit" class="btn btn-primary" style="padding:0.5rem 1rem;">Filter</button>
            </form>
        </div>

<% if (error != null) { %>
        <div style="padding:1rem;border:1px solid #ef4444;border-radius:8px;background:rgba(239,68,68,0.05);margin-bottom:1.5rem;">
            <span style="color:#ef4444;font-size:0.85rem;">Database error: <%= error %></span>
        </div>
<% } else if (rows.isEmpty()) { %>
        <div style="padding:1rem;border:1px solid var(--border);border-radius:8px;background:var(--bg-section);margin-bottom:1.5rem;">
            <span style="color:var(--text-muted);font-size:0.85rem;">No calibration records found. Database may be empty — run <code>setup-db.sh</code> to initialize.</span>
        </div>
<% } else { %>
        <div class="table-wrap">
            <table>
                <thead><tr><th>ID</th><th>Level</th><th>Description</th><th>Procedure Steps</th></tr></thead>
                <tbody>
<% for (Map<String, String> row : rows) { %>
                    <tr>
                        <td><code><%= row.get("id") %></code></td>
                        <td><strong><%= row.get("level_name") %></strong></td>
                        <td><%= row.get("description") %></td>
                        <td style="max-width:400px;white-space:pre-wrap;font-size:0.8rem;"><%= row.get("procedure_steps") %></td>
                    </tr>
<% } %>
                </tbody>
            </table>
        </div>
        <p style="margin-top:1rem;font-size:0.8rem;color:var(--text-muted);"><%= rows.size() %> calibration record(s).</p>
<% } %>
    </div>
</section>

<section class="section">
    <div class="section-inner">
        <h2>Quick Reference</h2>
        <div class="table-wrap">
            <table>
                <thead><tr><th>Step</th><th>Action</th><th>Expected Result</th></tr></thead>
                <tbody>
                    <tr><td>1</td><td>Turn on meter — allow 5-minute warm-up</td><td>Needle settles to rest position</td></tr>
                    <tr><td>2</td><td>Connect cans — subject holds with relaxed grip</td><td>Needle deflects from body resistance</td></tr>
                    <tr><td>3</td><td>Adjust Tone Arm to 2.0 (set position)</td><td>Needle centered on dial face</td></tr>
                    <tr><td>4</td><td>Set sensitivity (typically 16–32)</td><td>Can squeeze produces 1/3 to 1/2 dial deflection</td></tr>
                    <tr><td>5</td><td>Verify range switch for subject</td><td>TA reads within 2.0–3.5 range</td></tr>
                    <tr><td>6</td><td>Perform trim check</td><td>Needle returns to set after brief deflection</td></tr>
                </tbody>
            </table>
        </div>
    </div>
</section>

<footer class="footer"><div><span>&#169; 2026 MEARVK LLC. All rights reserved. Emeter™ — NitroWebExpress™</span></div></footer>
</body>
</html>
