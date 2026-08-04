<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.*, java.io.*, java.net.*" %>
<%!
    static String esc(String s) { if (s == null) return ""; return s.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;"); }
%>
<%
    String question = request.getParameter("question");
    String response = null;
    if (question != null && !question.trim().isEmpty()) {
        try (java.net.Socket sock = new java.net.Socket("127.0.0.1", 49236)) {
            sock.setSoTimeout(5000);
            PrintWriter pw = new PrintWriter(sock.getOutputStream(), true);
            BufferedReader br = new BufferedReader(new InputStreamReader(sock.getInputStream()));
            br.readLine(); br.readLine(); br.readLine(); br.readLine();
            pw.println("ASK|" + question.trim());
            response = br.readLine();
            pw.println("QUIT");
        } catch (Exception e) { response = "ERROR|Cannot reach FiduciaryServices backend (port 49236): " + e.getMessage(); }
    }

    // Fetch polyblend
    String polyblend = null;
    try (java.net.Socket sock = new java.net.Socket("127.0.0.1", 49236)) {
        sock.setSoTimeout(3000);
        PrintWriter pw = new PrintWriter(sock.getOutputStream(), true);
        BufferedReader br = new BufferedReader(new InputStreamReader(sock.getInputStream()));
        br.readLine(); br.readLine(); br.readLine(); br.readLine();
        pw.println("POLYBLEND");
        polyblend = br.readLine();
        pw.println("QUIT");
    } catch (Exception ignored) {}
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/><meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>FiduciaryServices™ — Global Transfer Wealth</title>
    <link rel="stylesheet" href="css/style.css"/>
    <link rel="preconnect" href="https://fonts.googleapis.com"/><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin/>
    <link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:wght@300;400;500;600;700&display=swap" rel="stylesheet"/>
</head>
<body>
<nav class="nav"><div class="nav-inner">
    <span class="nav-brand">FiduciaryServices™</span>
    <ul class="nav-links">
        <li><a href="index.jsp" class="active">Overview</a></li>
        <li><a href="architectures.jsp">Architectures</a></li>
        <li><a href="yield.jsp">Yield & Turn</a></li>
        <li><a href="records.jsp">Records</a></li>
        <li><a href="datapool.jsp">Datapool</a></li>
        <li><a href="documents.jsp">Documents</a></li>
        <li><a href="bright.jsp">Legal Bright</a></li>
        <li><a href="findings.jsp">AI Findings</a></li>
    </ul>
</div></nav>

<section class="hero">
    <div class="hero-inner">
        <span class="hero-tag">Fiduciaries • Global Transfer Wealth • Yield & Turn</span>
        <h1>FiduciaryServices™</h1>
        <p>The balance of internal design and remedy. The means to necessary advantages. Architectures, yield models, and the polyblend assumption — drawn from the existing datapool of the internet and public domain sources on any port of the known global internet.</p>
    </div>
</section>

<section class="section">
    <div class="section-inner" style="max-width:800px;">
        <h2>Ask FiduciaryServices</h2>
        <form method="GET" action="index.jsp">
            <div class="form-group">
                <label>Your Question</label>
                <textarea name="question" rows="3" placeholder="Ask about fiduciary duty, global transfer wealth, yield/turn, architectures, trust structures, remedy, or advantage..."><%= question != null ? esc(question) : "" %></textarea>
            </div>
            <button type="submit" class="btn btn-primary">Query</button>
        </form>
        <% if (response != null) { %>
        <div style="margin-top:1.5rem;padding:1.25rem;background:var(--bg-card);border:1px solid var(--border);border-radius:8px;">
            <div style="font-size:0.75rem;color:var(--accent-light);font-weight:600;margin-bottom:0.5rem;">FIDUCIARY SERVICES:</div>
            <div style="font-size:0.9rem;color:#fff;line-height:1.6;white-space:pre-wrap;"><%= esc(response) %></div>
        </div>
        <% } %>
    </div>
</section>

<% if (polyblend != null) { %>
<section class="section">
    <div class="section-inner" style="max-width:800px;">
        <h2>Current Polyblend Assumption</h2>
        <div class="card">
            <p style="font-size:0.85rem;color:#fff;line-height:1.5;"><%= esc(polyblend) %></p>
            <div class="meta">Polyblend combines multiple yield sources weighted by reliability into a composite expectation.</div>
        </div>
    </div>
</section>
<% } %>

<section class="section">
    <div class="section-inner">
        <h2>Core Concepts</h2>
        <div style="display:grid;grid-template-columns:repeat(auto-fill, minmax(300px, 1fr));gap:1rem;">
            <div class="card">
                <h3>Fiduciary Duty</h3>
                <p>The obligation to act in another's best interest. Loyalty, prudence, impartiality, transparency.</p>
                <div class="meta">The highest standard of care in law.</div>
            </div>
            <div class="card">
                <h3>Global Transfer Wealth</h3>
                <p>The balance of internal design and remedy — how wealth moves between parties, jurisdictions, and generations while preserving value.</p>
                <div class="meta">Trust transfers, estate succession, cross-border flows.</div>
            </div>
            <div class="card">
                <h3>Yield & Turn</h3>
                <p>Yield is return over time. Turn is frequency of materialization. Together they define productive capacity of a fiduciary arrangement.</p>
                <div class="meta">Polyblend: weighted combination of multiple sources.</div>
            </div>
            <div class="card">
                <h3>Architecture</h3>
                <p>The institutional design enabling trust — governance, distribution, succession, and accountability mechanisms.</p>
                <div class="meta">Express trust, foundation, pension, escrow, SICAV.</div>
            </div>
            <div class="card">
                <h3>Remedy</h3>
                <p>Mechanisms for correcting breach: surcharge, removal, constructive trust, equitable tracing, account of profits.</p>
                <div class="meta">The counterbalance that makes duty enforceable.</div>
            </div>
            <div class="card">
                <h3>Necessary Advantage</h3>
                <p>The means derived from careful stewardship — tax efficiency, compounding, institutional pricing, diversification, legal protections.</p>
                <div class="meta">Advantage serves the beneficiary purpose, not mere accumulation.</div>
            </div>
        </div>
    </div>
</section>

<section class="section">
    <div class="section-inner">
        <h2>Infrastructure</h2>
        <div class="table-wrap"><table>
            <thead><tr><th>Property</th><th>Value</th></tr></thead>
            <tbody>
                <tr><td>TCP Port</td><td><code>49236</code> (NWE module)</td></tr>
                <tr><td>OS Tool</td><td><code>/usr/local/bin/fiduciary</code> (C, terminal)</td></tr>
                <tr><td>Database</td><td><code>nwe_fiduciary</code> (MySQL)</td></tr>
                <tr><td>AI Backend</td><td>Strernary™ port 20000 (fallback)</td></tr>
                <tr><td>Theme</td><td>Light Blue + White Font</td></tr>
                <tr><td>Datapool Sources</td><td>SEC EDGAR, OECD, World Bank, Companies House, FRED, courts</td></tr>
                <tr><td>Installer</td><td>Max Rupplin — MEARVK LLC</td></tr>
            </tbody>
        </table></div>
    </div>
</section>

<!-- download-roadmap-section -->
<section class="section" style="border-top:1px solid #27272a;">
    <div class="section-inner">
        <h2>Download &amp; Roadmap</h2>
        <div style="display:flex;gap:1.5rem;flex-wrap:wrap;margin-bottom:1.5rem;">
            <a href="https://github.com/mearvk/Java.Web.Server.Telnet.Front.Java.21/tree/main/modules/fiduciary" target="_blank" rel="noopener noreferrer" style="display:inline-flex;align-items:center;gap:0.5rem;padding:0.75rem 1.5rem;border-radius:8px;background:#238636;border:1px solid #2ea043;color:#fff;font-size:0.9rem;text-decoration:none;font-weight:600;transition:background 0.2s;">
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
        <p style="font-size:0.75rem;color:#71717a;margin-top:1rem;">Source: <a href="https://github.com/mearvk/Java.Web.Server.Telnet.Front.Java.21/tree/main/modules/fiduciary" target="_blank" style="color:#60a5fa;">https://github.com/mearvk/Java.Web.Server.Telnet.Front.Java.21/tree/main/modules/fiduciary</a></p>
    </div>
</section>
<footer class="footer"><div><span>© 2026 MEARVK LLC. FiduciaryServices™ — The balance of internal design and remedy. Light Blue Edition.</span></div></footer>
</body></html>
