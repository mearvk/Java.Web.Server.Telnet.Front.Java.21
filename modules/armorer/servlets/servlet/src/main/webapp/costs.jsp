<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.*, java.io.*, java.net.*" %>
<%!
    static String esc(String s) { if (s == null) return ""; return s.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;"); }
%>
<%
    String category = request.getParameter("category");
    String costResults = null;
    if (category != null && !category.trim().isEmpty()) {
        try (java.net.Socket sock = new java.net.Socket("127.0.0.1", 49235)) {
            sock.setSoTimeout(5000);
            PrintWriter pw = new PrintWriter(sock.getOutputStream(), true);
            BufferedReader br = new BufferedReader(new InputStreamReader(sock.getInputStream()));
            br.readLine(); br.readLine(); br.readLine();
            pw.println("COST|" + category.trim());
            costResults = br.readLine();
            pw.println("QUIT");
        } catch (Exception e) { costResults = "ERROR|" + e.getMessage(); }
    }

    // Also fetch all costs from DB for display
    List<Map<String,String>> allCosts = new ArrayList<>();
    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        try (Connection conn = DriverManager.getConnection("jdbc:mysql://127.0.0.1:3306/nwe_armorer", "root", "")) {
            PreparedStatement ps = conn.prepareStatement("SELECT item, description, cost_low, cost_high, currency, category, source FROM cost_estimates ORDER BY category, cost_low");
            ResultSet rs = ps.executeQuery();
            while (rs.next()) {
                Map<String,String> r = new HashMap<>();
                r.put("item", rs.getString("item"));
                r.put("desc", rs.getString("description"));
                r.put("low", rs.getBigDecimal("cost_low").toPlainString());
                r.put("high", rs.getBigDecimal("cost_high").toPlainString());
                r.put("cur", rs.getString("currency"));
                r.put("cat", rs.getString("category"));
                r.put("src", rs.getString("source"));
                allCosts.add(r);
            }
        }
    } catch (Exception ignored) {}
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/><meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>Cost Estimator — ArmorerSteve™</title>
    <link rel="stylesheet" href="css/style.css"/>
    <link rel="preconnect" href="https://fonts.googleapis.com"/><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin/>
    <link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:wght@300;400;500;600;700&display=swap" rel="stylesheet"/>
</head>
<body>
<nav class="nav"><div class="nav-inner">
    <span class="nav-brand">ArmorerSteve™</span>
    <ul class="nav-links">
        <li><a href="index.jsp">Ask Steve</a></li>
        <li><a href="costs.jsp" class="active">Cost Estimator</a></li>
        <li><a href="armorers.jsp">Known Armorers</a></li>
        <li><a href="regulations.jsp">Regulations</a></li>
        <li><a href="trade.jsp">Trade</a></li>
        <li><a href="messaging.jsp">Messages</a></li>
    </ul>
</div></nav>

<section class="hero" style="padding:4rem 2rem;"><div class="hero-inner">
    <span class="hero-tag">Shop Setup & Equipment Costs</span>
    <h1>Cost Estimator</h1>
    <p>Realistic cost estimates for setting up an armor forge — from hobby to professional. Equipment, materials, tools, and full suit pricing.</p>
</div></section>

<section class="section"><div class="section-inner" style="max-width:800px;">
    <h2>Search Costs</h2>
    <form method="GET" action="costs.jsp">
        <div class="form-group">
            <label>Search by item or category</label>
            <select name="category">
                <option value="">— All Categories —</option>
                <option value="equipment" <%= "equipment".equals(category) ? "selected" : "" %>>Equipment (Forges, Anvils, Presses)</option>
                <option value="hand_tools" <%= "hand_tools".equals(category) ? "selected" : "" %>>Hand Tools (Hammers, Tongs, Stakes)</option>
                <option value="power_tools" <%= "power_tools".equals(category) ? "selected" : "" %>>Power Tools (Grinders, Belt Sanders)</option>
                <option value="materials" <%= "materials".equals(category) ? "selected" : "" %>>Materials (Steel, Rivets, Leather)</option>
                <option value="safety" <%= "safety".equals(category) ? "selected" : "" %>>Safety Equipment</option>
            </select>
        </div>
        <button type="submit" class="btn btn-primary">Estimate</button>
    </form>
    <% if (costResults != null) { %>
    <div style="margin-top:1.5rem;padding:1rem;background:var(--bg-card);border:1px solid var(--border);border-radius:8px;font-size:0.85rem;color:#fff;white-space:pre-wrap;"><%= esc(costResults) %></div>
    <% } %>
</div></section>

<section class="section"><div class="section-inner">
    <h2>Shop Setup Tiers</h2>
    <div class="table-wrap"><table>
        <thead><tr><th>Tier</th><th>Budget</th><th>Includes</th><th>Suitable For</th></tr></thead>
        <tbody>
            <tr><td style="color:#4ade80;font-weight:600;">Hobby</td><td>$1,500 – $3,000</td><td>Portable gas forge, basic anvil (100 lb), hammer set, angle grinder, hand tools, safety gear</td><td>Learning, small projects, repair work</td></tr>
            <tr><td style="color:#60a5fa;font-weight:600;">Semi-Pro</td><td>$5,000 – $15,000</td><td>Coal/large gas forge, quality anvil (250 lb), power hammer or press, full stake set, belt grinder, dedicated space</td><td>Commission work, SCA/HEMA armor, part-time business</td></tr>
            <tr><td style="color:#c084fc;font-weight:600;">Professional</td><td>$20,000 – $60,000</td><td>Industrial power hammer, hydraulic press, multiple forges, English wheel, polishing station, dedicated workshop</td><td>Full-time business, HMB/competition armor, museum reproductions</td></tr>
        </tbody>
    </table></div>

    <% if (!allCosts.isEmpty()) { %>
    <h2 style="margin-top:2.5rem;">Full Cost Database</h2>
    <div class="table-wrap"><table>
        <thead><tr><th>Item</th><th>Description</th><th>Low</th><th>High</th><th>Source</th></tr></thead>
        <tbody>
        <% for (Map<String,String> c : allCosts) { %>
            <tr>
                <td style="font-weight:600;color:#fff;"><%= esc(c.get("item")) %></td>
                <td><%= esc(c.get("desc")) %></td>
                <td style="color:#4ade80;">$<%= c.get("low") %></td>
                <td style="color:#f59e0b;">$<%= c.get("high") %></td>
                <td style="font-size:0.75rem;"><%= esc(c.get("src")) %></td>
            </tr>
        <% } %>
        </tbody>
    </table></div>
    <% } %>
</div></section>

<footer class="footer"><div><span>© 2026 MEARVK LLC. ArmorerSteve™ — Dark Blue Edition.</span></div></footer>
</body></html>
