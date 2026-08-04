<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.*, java.io.*, java.net.*" %>
<%!
    static String esc(String s) { if (s == null) return ""; return s.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;"); }
%>
<%
    String keyword = request.getParameter("keyword");
    String tradeResults = null;
    if (keyword != null && !keyword.trim().isEmpty()) {
        try (java.net.Socket sock = new java.net.Socket("127.0.0.1", 49235)) {
            sock.setSoTimeout(5000);
            PrintWriter pw = new PrintWriter(sock.getOutputStream(), true);
            BufferedReader br = new BufferedReader(new InputStreamReader(sock.getInputStream()));
            br.readLine(); br.readLine(); br.readLine();
            pw.println("TRADE|" + keyword.trim());
            tradeResults = br.readLine();
            pw.println("QUIT");
        } catch (Exception e) { tradeResults = "ERROR|" + e.getMessage(); }
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/><meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>Trade — ArmorerSteve™</title>
    <link rel="stylesheet" href="css/style.css"/>
    <link rel="preconnect" href="https://fonts.googleapis.com"/><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin/>
    <link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:wght@300;400;500;600;700&display=swap" rel="stylesheet"/>
</head>
<body>
<nav class="nav"><div class="nav-inner">
    <span class="nav-brand">ArmorerSteve™</span>
    <ul class="nav-links">
        <li><a href="index.jsp">Ask Steve</a></li>
        <li><a href="costs.jsp">Cost Estimator</a></li>
        <li><a href="armorers.jsp">Known Armorers</a></li>
        <li><a href="regulations.jsp">Regulations</a></li>
        <li><a href="trade.jsp" class="active">Trade</a></li>
        <li><a href="messaging.jsp">Messages</a></li>
    </ul>
</div></nav>

<section class="hero" style="padding:4rem 2rem;"><div class="hero-inner">
    <span class="hero-tag">Market • Commissioning • Final Capacitor Trade</span>
    <h1>Armor Trade</h1>
    <p>Where armor trades, by whom, at what price. Commission records, market venues, series INT, and the final capacitor trade between forges.</p>
</div></section>

<section class="section"><div class="section-inner" style="max-width:800px;">
    <h2>Search Trade Records</h2>
    <form method="GET" action="trade.jsp">
        <div class="form-group">
            <label>Search by keyword (armor type, seller, series, capacitor grade)</label>
            <input type="text" name="keyword" placeholder="e.g., BUHURT, helmet, Grade A, Illusion..." value="<%= keyword != null ? esc(keyword) : "" %>"/>
        </div>
        <button type="submit" class="btn btn-primary">Search Trade</button>
    </form>
    <% if (tradeResults != null) { %>
    <div style="margin-top:1.5rem;padding:1rem;background:var(--bg-card);border:1px solid var(--border);border-radius:8px;font-size:0.85rem;color:#fff;white-space:pre-wrap;"><%= esc(tradeResults) %></div>
    <% } %>
</div></section>

<section class="section"><div class="section-inner">
    <h2>Trading Venues</h2>
    <div class="table-wrap"><table>
        <thead><tr><th>Venue</th><th>Type</th><th>Price Range</th><th>Notes</th></tr></thead>
        <tbody>
            <tr><td>Direct Commission</td><td>Maker-to-buyer</td><td>$2,500–$80,000+</td><td>3–12 month wait, custom fitted, highest quality</td></tr>
            <tr><td>Facebook Armor Groups</td><td>Peer-to-peer</td><td>$500–$5,000</td><td>Used gear, quick sales, negotiable pricing</td></tr>
            <tr><td>Events (Pennsic, Gulf Wars)</td><td>In-person</td><td>$200–$3,000</td><td>Try-before-buy, vendor areas, volume deals</td></tr>
            <tr><td>Auction Houses (Christie's, Sotheby's)</td><td>Historical pieces</td><td>$10,000–$2,000,000+</td><td>Authenticated antiques, provenance documented</td></tr>
            <tr><td>Bulk Suppliers (India/Pakistan)</td><td>Production</td><td>$300–$1,500</td><td>Budget pieces, mild steel, display quality</td></tr>
            <tr><td>Ukraine/Poland Workshops</td><td>Competition</td><td>$2,000–$6,000</td><td>HMB-legal, properly hardened, battle-tested</td></tr>
        </tbody>
    </table></div>

    <h2 style="margin-top:2.5rem;">Final Capacitor Trade</h2>
    <div style="padding:1.25rem;background:var(--bg-card);border:1px solid var(--border);border-radius:8px;">
        <p style="color:#fff;font-size:0.9rem;line-height:1.6;">
            The <strong>final capacitor trade</strong> is the culminating exchange in a competition series where the winning armorer
            or team trades their highest-grade forge capability. A <em>capacitor grade</em> represents the stored skill, tooling,
            and material investment of a forge:
        </p>
        <div class="table-wrap" style="margin-top:1rem;"><table>
            <thead><tr><th>Grade</th><th>Forge Capability</th><th>Output Quality</th><th>Trade Value</th></tr></thead>
            <tbody>
                <tr><td style="color:#ef4444;font-weight:700;">A</td><td>Full professional, power hammer, dedicated team</td><td>Tournament-winning harnesses, series champions</td><td>Preferential commission rights, name recognition</td></tr>
                <tr><td style="color:#f59e0b;font-weight:700;">B</td><td>Semi-pro, quality tooling, experienced maker</td><td>Reliable competition armor, consistent output</td><td>Queue priority, bulk pricing agreements</td></tr>
                <tr><td style="color:#60a5fa;font-weight:700;">C</td><td>Skilled hobbyist, basic professional setup</td><td>Serviceable armor, occasional commission</td><td>Material sourcing partnerships, mentorship</td></tr>
            </tbody>
        </table></div>
        <p style="color:var(--text-secondary);font-size:0.85rem;margin-top:1rem;">
            Series INT (international) determines the global ranking of forge capacitor grades. Winners are decided
            by competition results (Battle of the Nations, IMCF Worlds) and quality assessment panels. The final
            trade occurs post-season when the champion forge's priority commission rights transfer.
        </p>
    </div>
</div></section>

<footer class="footer"><div><span>© 2026 MEARVK LLC. ArmorerSteve™ — Dark Blue Edition. Plate armor trade and forge economics.</span></div></footer>
</body></html>
