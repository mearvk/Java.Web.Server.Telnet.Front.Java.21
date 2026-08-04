<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.*, java.io.*, java.net.*" %>
<%!
    static String esc(String s) { if (s == null) return ""; return s.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;"); }
%>
<%
    // Connect to backend and get a response if question submitted
    String question = request.getParameter("question");
    String steveResponse = null;
    if (question != null && !question.trim().isEmpty()) {
        try (java.net.Socket sock = new java.net.Socket("127.0.0.1", 49235)) {
            sock.setSoTimeout(5000);
            PrintWriter pw = new PrintWriter(sock.getOutputStream(), true);
            BufferedReader br = new BufferedReader(new InputStreamReader(sock.getInputStream()));
            br.readLine(); br.readLine(); br.readLine(); // skip banner
            pw.println("ASK|" + question.trim());
            steveResponse = br.readLine();
            pw.println("QUIT");
        } catch (Exception e) {
            steveResponse = "ERROR|Cannot reach Armorer Steve backend (port 49235): " + e.getMessage();
        }
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/><meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>ArmorerSteve™ — Plate Armor Q&A</title>
    <link rel="stylesheet" href="css/style.css"/>
    <link rel="preconnect" href="https://fonts.googleapis.com"/><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin/>
    <link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:wght@300;400;500;600;700&display=swap" rel="stylesheet"/>
</head>
<body>
<nav class="nav"><div class="nav-inner">
    <span class="nav-brand">ArmorerSteve™</span>
    <ul class="nav-links">
        <li><a href="index.jsp" class="active">Ask Steve</a></li>
        <li><a href="costs.jsp">Cost Estimator</a></li>
        <li><a href="armorers.jsp">Known Armorers</a></li>
        <li><a href="regulations.jsp">Regulations</a></li>
        <li><a href="trade.jsp">Trade</a></li>
        <li><a href="messaging.jsp">Messages</a></li>
    </ul>
</div></nav>

<section class="hero">
    <div class="hero-inner">
        <span class="hero-tag">Plate Armor • Forging • Metal Theory • Cost Estimation</span>
        <h1>Armorer Steve™</h1>
        <p>A modest AI for plate armor knowledge — forging methods, modern metallurgy, shop setup costs, known armorers, competition series, regulations, and trade. Ask anything.</p>
    </div>
</section>

<section class="section">
    <div class="section-inner" style="max-width:800px;">
        <h2>Ask Armorer Steve</h2>
        <form method="GET" action="index.jsp">
            <div class="form-group">
                <label>Your Question</label>
                <textarea name="question" rows="3" placeholder="Ask about plate armor, forging, costs, armorers, regulations, trade..."><%= question != null ? esc(question) : "" %></textarea>
            </div>
            <button type="submit" class="btn btn-primary">Ask Steve</button>
        </form>

        <% if (steveResponse != null) { %>
        <div style="margin-top:1.5rem; padding:1.25rem; background:var(--bg-card); border:1px solid var(--border); border-radius:8px;">
            <div style="font-size:0.75rem; color:var(--accent-light); font-weight:600; margin-bottom:0.5rem;">ARMORER STEVE:</div>
            <div style="font-size:0.9rem; color:#fff; line-height:1.6; white-space:pre-wrap;"><%= esc(steveResponse) %></div>
        </div>
        <% } %>
    </div>
</section>

<section class="section">
    <div class="section-inner">
        <h2>Topics Steve Knows About</h2>
        <div class="table-wrap">
            <table>
                <thead><tr><th>Topic</th><th>Examples</th></tr></thead>
                <tbody>
                    <tr><td>Fundamentals</td><td>What is plate armor? Types of armor, historical periods</td></tr>
                    <tr><td>Materials</td><td>Steel types (1095, 4130, titanium), thickness, gauge</td></tr>
                    <tr><td>Forging</td><td>Hot forging, cold forging, raising, dishing, planishing</td></tr>
                    <tr><td>Metallurgy</td><td>Tempering, hardening, heat treatment, grain structure</td></tr>
                    <tr><td>Equipment</td><td>Anvils, hammers, forges, power hammers, English wheel</td></tr>
                    <tr><td>Costs</td><td>Shop setup ($1500–$60,000), equipment, materials, full suits</td></tr>
                    <tr><td>Known Armorers</td><td>Helmschmid, Negroli, Missaglia (historical); Wasson, Galevskyi (modern)</td></tr>
                    <tr><td>Competition</td><td>HMB, BUHURT, SCA, IMCF, Battle of the Nations, HEMA</td></tr>
                    <tr><td>Regulations</td><td>HMBIA standards, thickness requirements, helmet specs</td></tr>
                    <tr><td>Trade</td><td>Where to buy/sell, commissioning, auction houses, final capacitor trade</td></tr>
                </tbody>
            </table>
        </div>
    </div>
</section>

<section class="section">
    <div class="section-inner">
        <h2>Infrastructure</h2>
        <div class="table-wrap">
            <table>
                <thead><tr><th>Property</th><th>Value</th></tr></thead>
                <tbody>
                    <tr><td>TCP Port</td><td><code>49235</code> (NWE module)</td></tr>
                    <tr><td>OS Tool</td><td><code>/usr/local/bin/armorer</code> (C, terminal)</td></tr>
                    <tr><td>Database</td><td><code>nwe_armorer</code> (MySQL)</td></tr>
                    <tr><td>AI Backend</td><td>Strernary™ port 20000 (fallback)</td></tr>
                    <tr><td>Theme</td><td>Dark Blue + White Font</td></tr>
                    <tr><td>Installer</td><td>Max Rupplin — MEARVK LLC</td></tr>
                </tbody>
            </table>
        </div>
    </div>
</section>

<!-- download-roadmap-section -->
<section class="section" style="border-top:1px solid #27272a;">
    <div class="section-inner">
        <h2>Download &amp; Roadmap</h2>
        <div style="display:flex;gap:1.5rem;flex-wrap:wrap;margin-bottom:1.5rem;">
            <a href="https://github.com/mearvk/Java.Web.Server.Telnet.Front.Java.21/tree/main/modules/armorer" target="_blank" rel="noopener noreferrer" style="display:inline-flex;align-items:center;gap:0.5rem;padding:0.75rem 1.5rem;border-radius:8px;background:#238636;border:1px solid #2ea043;color:#fff;font-size:0.9rem;text-decoration:none;font-weight:600;transition:background 0.2s;">
                &#11015; Download Now (GitHub)
            </a>
            <a href="https://github.com/mearvk/Java.Web.Server.Telnet.Front.Java.21" target="_blank" rel="noopener noreferrer" style="display:inline-flex;align-items:center;gap:0.5rem;padding:0.75rem 1.5rem;border-radius:8px;background:#1a1a2e;border:1px solid #27272a;color:#a1a1aa;font-size:0.9rem;text-decoration:none;font-weight:500;">
                &#128230; Full NWE Distribution
            </a>
        </div>
        <div class="table-wrap"><table><thead><tr><th>Phase</th><th>Milestone</th><th>Status</th></tr></thead><tbody>
            <tr><td>1</td><td>Core backend &amp; servlet interface</td><td style="color:#22c55e;">&#10003; Complete</td></tr>
            <tr><td>2</td><td>Database schema &amp; MySQL integration</td><td style="color:#22c55e;">&#10003; Complete</td></tr>
            <tr><td>3</td><td>JSP front-end &amp; CD1 connector</td><td style="color:#22c55e;">&#10003; Complete</td></tr>
            <tr><td>4</td><td>Ubuntu kernel build integration</td><td style="color:#22c55e;">&#10003; Complete</td></tr>
            <tr><td>5</td><td>Security hardening &amp; auth</td><td style="color:#eab308;">&#9679; In Progress</td></tr>
            <tr><td>6</td><td>Production deployment &amp; monitoring</td><td style="color:#71717a;">&#9675; Planned</td></tr>
        </tbody></table></div>
        <p style="font-size:0.75rem;color:#71717a;margin-top:1rem;">Source: <a href="https://github.com/mearvk/Java.Web.Server.Telnet.Front.Java.21/tree/main/modules/armorer" target="_blank" style="color:#60a5fa;">https://github.com/mearvk/Java.Web.Server.Telnet.Front.Java.21/tree/main/modules/armorer</a></p>
    </div>
</section>
<footer class="footer"><div><span>© 2026 MEARVK LLC. ArmorerSteve™ — Dark Blue Edition. Plate armor, forging, and the metal arts.</span></div></footer>
</body></html>
