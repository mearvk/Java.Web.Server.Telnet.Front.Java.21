<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*" %>
<%
    Connection conn = null; boolean dbOk = false;
    try { Class.forName("com.mysql.cj.jdbc.Driver"); conn = DriverManager.getConnection("jdbc:mysql://127.0.0.1:3306/nwe_tandem_equals", "root", "$$Ironman1"); dbOk = true; }
    catch (Exception e) {}
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/><meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <link rel="preconnect" href="https://fonts.googleapis.com"/><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin/><link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:wght@300;400;500;600;700;800&display=swap" rel="stylesheet"/>
    <title>Control Curves — TandemEquals™</title>
    <link rel="stylesheet" href="css/style.css"/>
</head>
<body>
<nav class="nav"><div class="nav-inner">
    <span class="nav-brand">TandemEquals™</span>
    <ul class="nav-links">
        <li><a href="index.jsp">Overview</a></li>
        <li><a href="layers.jsp">Layers</a></li>
        <li><a href="curves.jsp" class="active">Control Curves</a></li>
        <li><a href="messaging.jsp">Messages</a></li>
        <li><a href="status.jsp">Status</a></li>
    </ul>
<div class="nav-actions"><%@ include file="auth-buttons.jsp" %></div></div></nav>

<section class="hero" style="padding:3rem 2rem;">
    <div class="hero-inner">
        <span class="hero-tag">Simplex Paths</span>
        <h1>Control <span>Curves</span></h1>
        <p>Complete simplex paths from perception through cognition and modulation to final expression.</p>
    </div>
</section>

<% if (!dbOk) { %>
<section class="section"><div class="section-inner"><p style="color:var(--accent);">Database offline.</p></div></section>
<% } else { %>

<section class="section">
    <div class="section-inner">
        <h2>Active Control Curves</h2>
        <div class="table-wrap"><table>
            <thead><tr><th>Curve</th><th>L1 Perception</th><th>L2 Cognition</th><th>L3 Modulation</th><th>L4 Expression</th><th>Simplex</th><th>Stability</th><th>Status</th></tr></thead>
            <tbody>
<%
    Statement st = conn.createStatement();
    ResultSet rs = st.executeQuery(
        "SELECT c.curve_name, p.signal_name, cog.pattern_name, m.modulator_name, e.expression_name, " +
        "c.simplex_value, c.stability, c.is_complete " +
        "FROM control_curve c " +
        "LEFT JOIN perception p ON c.perception_id = p.id " +
        "LEFT JOIN cognition cog ON c.cognition_id = cog.id " +
        "LEFT JOIN modulation m ON c.modulation_id = m.id " +
        "LEFT JOIN expression e ON c.expression_id = e.id " +
        "ORDER BY c.id");
    while (rs.next()) {
        double simplex = rs.getDouble(6);
        double stability = rs.getDouble(7);
        boolean complete = rs.getBoolean(8);
%>
            <tr>
                <td><strong><%= rs.getString(1) %></strong></td>
                <td style="color:var(--layer1);"><%= rs.getString(2) != null ? rs.getString(2) : "—" %></td>
                <td style="color:var(--layer2);"><%= rs.getString(3) != null ? rs.getString(3) : "—" %></td>
                <td style="color:var(--layer3);"><%= rs.getString(4) != null ? rs.getString(4) : "—" %></td>
                <td style="color:var(--layer4);"><%= rs.getString(5) != null ? rs.getString(5) : "—" %></td>
                <td><strong><%= String.format("%.2f", simplex) %></strong></td>
                <td>
                    <div style="display:flex;align-items:center;gap:0.4rem;">
                        <div style="width:50px;height:6px;background:var(--bg-card);border-radius:3px;overflow:hidden;">
                            <div style="width:<%= (int)(stability * 100) %>%;height:100%;background:<%= stability > 0.85 ? "var(--layer4)" : stability > 0.7 ? "var(--layer3)" : "var(--layer1)" %>;border-radius:3px;"></div>
                        </div>
                        <span style="font-size:0.7rem;"><%= String.format("%.0f%%", stability * 100) %></span>
                    </div>
                </td>
                <td><%= complete ? "<span style='color:var(--layer4);font-weight:600;'>Complete</span>" : "<span style='color:var(--text-muted);'>Partial</span>" %></td>
            </tr>
<%  } rs.close(); st.close(); %>
            </tbody>
        </table></div>
    </div>
</section>

<!-- Evaluation Log -->
<section class="section">
    <div class="section-inner">
        <h2>Recent Evaluations</h2>
<%
    st = conn.createStatement();
    rs = st.executeQuery("SELECT il.evaluated_at, c.curve_name, il.layer_evaluated, il.simplex_delta, il.evaluator FROM intellect_log il LEFT JOIN control_curve c ON il.curve_id = c.id ORDER BY il.evaluated_at DESC LIMIT 20");
    boolean hasLogs = false;
%>
        <div class="table-wrap"><table>
            <thead><tr><th>Time</th><th>Curve</th><th>Layer</th><th>Δ Simplex</th><th>Evaluator</th></tr></thead>
            <tbody>
<%  while (rs.next()) { hasLogs = true; %>
            <tr>
                <td><%= rs.getTimestamp(1) %></td>
                <td><%= rs.getString(2) != null ? rs.getString(2) : "—" %></td>
                <td>L<%= rs.getInt(3) %></td>
                <td><%= String.format("%+.3f", rs.getDouble(4)) %></td>
                <td><%= rs.getString(5) %></td>
            </tr>
<%  }
    if (!hasLogs) { %>
            <tr><td colspan="5" style="text-align:center;color:var(--text-muted);">No evaluations yet. Connect to port 49223 and send EVALUATE|1</td></tr>
<%  } rs.close(); st.close(); %>
            </tbody>
        </table></div>
    </div>
</section>

<% } if (conn != null) try { conn.close(); } catch (Exception e) {} %>

<footer class="footer"><span>TandemEquals™ — Control Curves — MEARVK LLC 2026</span></footer>
</body>
</html>
