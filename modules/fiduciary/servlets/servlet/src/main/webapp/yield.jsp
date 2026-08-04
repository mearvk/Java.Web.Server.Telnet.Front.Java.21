<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.*, java.io.*" %>
<%!
    static String esc(String s) { if (s == null) return ""; return s.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;"); }
%>
<%
    List<Map<String,String>> models = new ArrayList<>();
    double polyblendYield = 0.0; double totalWeight = 0.0;
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        try (Connection conn = DriverManager.getConnection("jdbc:mysql://127.0.0.1:3306/nwe_fiduciary", "root", "")) {
            ResultSet rs = conn.createStatement().executeQuery("SELECT model_name, description, base_yield, turn_frequency, risk_factor, polyblend_weight, assumption_basis FROM yield_models ORDER BY polyblend_weight DESC");
            while (rs.next()) {
                Map<String,String> r = new HashMap<>();
                r.put("name", rs.getString("model_name")); r.put("desc", rs.getString("description"));
                r.put("yield", rs.getBigDecimal("base_yield").toPlainString());
                r.put("turn", rs.getString("turn_frequency"));
                r.put("risk", rs.getBigDecimal("risk_factor").toPlainString());
                r.put("weight", rs.getBigDecimal("polyblend_weight").toPlainString());
                r.put("basis", rs.getString("assumption_basis"));
                double y = rs.getDouble("base_yield"); double w = rs.getDouble("polyblend_weight");
                polyblendYield += y * w; totalWeight += w;
                models.add(r);
            }
        }
    } catch (Exception ignored) {}
    double compositeYield = totalWeight > 0 ? polyblendYield / totalWeight : 0;
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/><meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>Yield & Turn — FiduciaryServices™</title>
    <link rel="stylesheet" href="css/style.css"/>
    <link rel="preconnect" href="https://fonts.googleapis.com"/><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin/>
    <link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:wght@300;400;500;600;700&display=swap" rel="stylesheet"/>
</head>
<body>
<nav class="nav"><div class="nav-inner">
    <span class="nav-brand">FiduciaryServices™</span>
    <ul class="nav-links">
        <li><a href="index.jsp">Overview</a></li>
        <li><a href="architectures.jsp">Architectures</a></li>
        <li><a href="yield.jsp" class="active">Yield & Turn</a></li>
        <li><a href="records.jsp">Records</a></li>
        <li><a href="datapool.jsp">Datapool</a></li>
        <li><a href="documents.jsp">Documents</a></li>
        <li><a href="bright.jsp">Legal Bright</a></li>
        <li><a href="findings.jsp">AI Findings</a></li>
    </ul>
</div></nav>

<section class="hero" style="padding:4rem 2rem;"><div class="hero-inner">
    <span class="hero-tag">The Polyblend Assumption of Return on Structure</span>
    <h1>Yield & Turn</h1>
    <p>Yield is the return generated over time. Turn is the frequency of materialization. The polyblend weights multiple sources by reliability into a composite expectation — the basic assumption that enables fiduciary planning.</p>
</div></section>

<section class="section"><div class="section-inner" style="max-width:900px;">
    <h2>Composite Polyblend Yield</h2>
    <div class="card" style="text-align:center;">
        <div style="font-size:2.5rem;font-weight:800;color:var(--accent-light);"><%= String.format("%.4f", compositeYield) %>%</div>
        <div style="font-size:0.85rem;color:var(--text-secondary);margin-top:0.5rem;">Weighted composite yield assumption across all models</div>
        <div class="meta">Total polyblend weight: <%= String.format("%.3f", totalWeight) %> | Models: <%= models.size() %></div>
    </div>

    <% if (!models.isEmpty()) { %>
    <h2 style="margin-top:2rem;">Component Models</h2>
    <div class="table-wrap"><table>
        <thead><tr><th>Model</th><th>Base Yield</th><th>Turn Frequency</th><th>Risk Factor</th><th>Polyblend Weight</th><th>Basis</th></tr></thead>
        <tbody>
        <% for (Map<String,String> m : models) { %>
            <tr>
                <td style="font-weight:600;color:#fff;"><%= esc(m.get("name")) %></td>
                <td style="color:var(--accent-light);"><%= m.get("yield") %>%</td>
                <td><%= esc(m.get("turn")) %></td>
                <td><%= m.get("risk") %></td>
                <td style="font-weight:600;"><%= m.get("weight") %></td>
                <td style="font-size:0.8rem;"><%= esc(m.get("basis")) %></td>
            </tr>
        <% } %>
        </tbody>
    </table></div>
    <% } %>

    <h2 style="margin-top:2.5rem;">Understanding the Polyblend</h2>
    <div class="card">
        <p>The polyblend assumption avoids single-source dependency by weighting multiple yield streams:</p>
        <ul style="margin-top:0.75rem;padding-left:1.5rem;color:var(--text-secondary);font-size:0.85rem;line-height:2;">
            <li><strong>Fixed Income</strong> (government bonds, corporate credit) — stability, predictable coupons</li>
            <li><strong>Global Equity</strong> (MSCI World) — growth, dividends, long-term compounding</li>
            <li><strong>Real Assets</strong> (property, infrastructure) — inflation protection, tangible value</li>
            <li><strong>Alternative/Private</strong> — illiquidity premium, higher variance, higher potential</li>
        </ul>
        <p style="margin-top:0.75rem;">Each component contributes according to its weight, creating a diversified assumption suitable for long-horizon fiduciary planning.</p>
    </div>
</div></section>

<footer class="footer"><div><span>© 2026 MEARVK LLC. FiduciaryServices™ — Yield, Turn, and Polyblend. Light Blue Edition.</span></div></footer>
</body></html>
