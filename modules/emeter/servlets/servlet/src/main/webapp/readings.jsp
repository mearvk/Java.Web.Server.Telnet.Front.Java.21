<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.*" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>Readings — Emeter™</title>
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
        <li><a href="calibration.jsp">Calibration</a></li>
        <li><a href="readings.jsp" class="active">Readings</a></li>
        <li><a href="status.jsp">Status</a></li>
    </ul>
</div></nav>

<section class="hero" style="padding:4rem 2rem;">
    <div class="hero-inner">
        <span class="hero-tag">Session Data</span>
        <h1>Readings</h1>
        <p>View submitted session readings — tone arm values, tone levels, and session notes.</p>
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
    String filterSession = request.getParameter("session_id");

    List<Map<String, String>> rows = new ArrayList<>();
    String error = null;

    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        try (Connection conn = DriverManager.getConnection(dbUrl, dbUser, dbPass)) {
            StringBuilder sql = new StringBuilder("SELECT id, session_id, timestamp, ta_value, tone_level, notes FROM readings WHERE 1=1");
            List<String> params = new ArrayList<>();
            if (filterSession != null && !filterSession.isBlank()) {
                sql.append(" AND session_id = ?");
                params.add(filterSession.trim());
            }
            sql.append(" ORDER BY timestamp DESC LIMIT 100");

            try (PreparedStatement ps = conn.prepareStatement(sql.toString())) {
                for (int i = 0; i < params.size(); i++) ps.setString(i + 1, params.get(i));
                ResultSet rs = ps.executeQuery();
                while (rs.next()) {
                    Map<String, String> row = new LinkedHashMap<>();
                    row.put("id", String.valueOf(rs.getInt("id")));
                    row.put("session_id", rs.getString("session_id"));
                    row.put("timestamp", rs.getTimestamp("timestamp") != null ? rs.getTimestamp("timestamp").toString() : "—");
                    row.put("ta_value", String.valueOf(rs.getDouble("ta_value")));
                    row.put("tone_level", rs.getString("tone_level"));
                    row.put("notes", rs.getString("notes") != null ? rs.getString("notes") : "—");
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
                    <label>Session ID</label>
                    <input type="text" name="session_id" value="<%= filterSession != null ? filterSession : "" %>" placeholder="Filter by session..." style="width:220px;"/>
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
            <span style="color:var(--text-muted);font-size:0.85rem;">No readings found. Submit readings via TCP <code>SUBMIT|&lt;ta_value&gt;,&lt;tone_level&gt;,&lt;session_id&gt;,&lt;notes&gt;</code> on port 49216.</span>
        </div>
<% } else { %>
        <div class="table-wrap">
            <table>
                <thead><tr><th>ID</th><th>Session</th><th>Timestamp</th><th>TA Value</th><th>Tone Level</th><th>Notes</th></tr></thead>
                <tbody>
<% for (Map<String, String> row : rows) { %>
                    <tr>
                        <td><code><%= row.get("id") %></code></td>
                        <td><code><%= row.get("session_id") %></code></td>
                        <td style="font-size:0.8rem;"><%= row.get("timestamp") %></td>
                        <td><strong><%= row.get("ta_value") %></strong></td>
                        <td><%= row.get("tone_level") %></td>
                        <td style="max-width:250px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;"><%= row.get("notes") %></td>
                    </tr>
<% } %>
                </tbody>
            </table>
        </div>
        <p style="margin-top:1rem;font-size:0.8rem;color:var(--text-muted);"><%= rows.size() %> reading(s) returned.</p>
<% } %>
    </div>
</section>

<footer class="footer"><div><span>&#169; 2026 MEARVK LLC. All rights reserved. Emeter™ — NitroWebExpress™</span></div></footer>
</body>
</html>
