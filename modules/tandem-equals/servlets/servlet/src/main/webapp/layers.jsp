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
    <title>Layers — TandemEquals™</title>
    <link rel="stylesheet" href="css/style.css"/>
</head>
<body>
<nav class="nav"><div class="nav-inner">
    <span class="nav-brand">TandemEquals™</span>
    <ul class="nav-links">
        <li><a href="index.jsp">Overview</a></li>
        <li><a href="layers.jsp" class="active">Layers</a></li>
        <li><a href="curves.jsp">Control Curves</a></li>
        <li><a href="messaging.jsp">Messages</a></li>
        <li><a href="status.jsp">Status</a></li>
    </ul>
<div class="nav-actions"><%@ include file="auth-buttons.jsp" %></div></div></nav>

<section class="hero" style="padding:3rem 2rem;">
    <div class="hero-inner">
        <span class="hero-tag">Intellect Layers</span>
        <h1>The Four <span>Layers</span></h1>
        <p>Each layer of the modulator simplex, from intake to output.</p>
    </div>
</section>

<% if (!dbOk) { %>
<section class="section"><div class="section-inner"><p style="color:var(--accent);">Database offline.</p></div></section>
<% } else { %>

<!-- Layer 1: Perception -->
<section class="section">
    <div class="section-inner">
        <h2><span class="layer-dot" style="background:var(--layer1);"></span>Layer 1 — Perception</h2>
        <p style="font-size:0.85rem;color:var(--text-muted);margin-bottom:1rem;">Raw intake signals. Sensory, emotional, temporal, environmental, data.</p>
        <div class="table-wrap"><table>
            <thead><tr><th>Signal</th><th>Type</th><th>Amplitude</th><th>Frequency</th><th>Clarity</th><th>Origin</th></tr></thead>
            <tbody>
<%  Statement st = conn.createStatement();
    ResultSet rs = st.executeQuery("SELECT signal_name, signal_type, amplitude, frequency, clarity, origin FROM perception WHERE is_active = TRUE ORDER BY id");
    while (rs.next()) { %>
            <tr><td><strong><%= rs.getString(1) %></strong></td><td><%= rs.getString(2) %></td><td><%= String.format("%.2f", rs.getDouble(3)) %></td><td><%= String.format("%.1f", rs.getDouble(4)) %></td><td><%= String.format("%.2f", rs.getDouble(5)) %></td><td><%= rs.getString(6) %></td></tr>
<%  } rs.close(); st.close(); %>
            </tbody>
        </table></div>
    </div>
</section>

<!-- Layer 2: Cognition -->
<section class="section">
    <div class="section-inner">
        <h2><span class="layer-dot" style="background:var(--layer2);"></span>Layer 2 — Cognition</h2>
        <p style="font-size:0.85rem;color:var(--text-muted);margin-bottom:1rem;">Pattern recognition, logic gates, analogy, inference, memory.</p>
        <div class="table-wrap"><table>
            <thead><tr><th>Pattern</th><th>Type</th><th>Gate</th><th>Threshold</th><th>Confidence</th><th>Inputs</th></tr></thead>
            <tbody>
<%  st = conn.createStatement();
    rs = st.executeQuery("SELECT pattern_name, pattern_type, gate_type, threshold, confidence, perception_ids FROM cognition WHERE is_active = TRUE ORDER BY id");
    while (rs.next()) { %>
            <tr><td><strong><%= rs.getString(1) %></strong></td><td><%= rs.getString(2) %></td><td><code><%= rs.getString(3) %></code></td><td><%= String.format("%.2f", rs.getDouble(4)) %></td><td><%= String.format("%.2f", rs.getDouble(5)) %></td><td><code><%= rs.getString(6) != null ? rs.getString(6) : "" %></code></td></tr>
<%  } rs.close(); st.close(); %>
            </tbody>
        </table></div>
    </div>
</section>

<!-- Layer 3: Modulation -->
<section class="section">
    <div class="section-inner">
        <h2><span class="layer-dot" style="background:var(--layer3);"></span>Layer 3 — Modulation</h2>
        <p style="font-size:0.85rem;color:var(--text-muted);margin-bottom:1rem;">Gain, filter, envelope, limiter. Simplex shaping of the signal before expression.</p>
        <div class="table-wrap"><table>
            <thead><tr><th>Modulator</th><th>Type</th><th>Gain</th><th>Bias</th><th>Curve</th><th>Simplex Order</th></tr></thead>
            <tbody>
<%  st = conn.createStatement();
    rs = st.executeQuery("SELECT modulator_name, modulator_type, gain, bias, curve_type, simplex_order FROM modulation WHERE is_active = TRUE ORDER BY simplex_order, id");
    while (rs.next()) { %>
            <tr><td><strong><%= rs.getString(1) %></strong></td><td><%= rs.getString(2) %></td><td><%= String.format("%.2f", rs.getDouble(3)) %></td><td><%= String.format("%.2f", rs.getDouble(4)) %></td><td><code><%= rs.getString(5) %></code></td><td><%= rs.getInt(6) %></td></tr>
<%  } rs.close(); st.close(); %>
            </tbody>
        </table></div>
    </div>
</section>

<!-- Layer 4: Expression -->
<section class="section">
    <div class="section-inner">
        <h2><span class="layer-dot" style="background:var(--layer4);"></span>Layer 4 — Expression</h2>
        <p style="font-size:0.85rem;color:var(--text-muted);margin-bottom:1rem;">Output actuation. Speech, decision, creation, inhibition, signal relay.</p>
        <div class="table-wrap"><table>
            <thead><tr><th>Expression</th><th>Type</th><th>Control Value</th><th>Direction</th><th>Intensity</th><th>Final</th></tr></thead>
            <tbody>
<%  st = conn.createStatement();
    rs = st.executeQuery("SELECT expression_name, expression_type, control_value, direction, intensity, is_final FROM expression ORDER BY id");
    while (rs.next()) { %>
            <tr><td><strong><%= rs.getString(1) %></strong></td><td><%= rs.getString(2) %></td><td><%= String.format("%.2f", rs.getDouble(3)) %></td><td><%= rs.getString(4) %></td><td><%= String.format("%.2f", rs.getDouble(5)) %></td><td><%= rs.getBoolean(6) ? "✓" : "—" %></td></tr>
<%  } rs.close(); st.close(); %>
            </tbody>
        </table></div>
    </div>
</section>

<% } if (conn != null) try { conn.close(); } catch (Exception e) {} %>

<footer class="footer"><span>TandemEquals™ — Layers — MEARVK LLC 2026</span></footer>
</body>
</html>
