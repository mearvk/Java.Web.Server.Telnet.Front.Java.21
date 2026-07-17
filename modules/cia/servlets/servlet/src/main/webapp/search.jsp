<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.net.*, java.io.*, java.sql.*, java.util.*" %>
<%
    String searchQuery = request.getParameter("q");
    String searchCategory = request.getParameter("category");
    String results = "";
    
    if (searchQuery != null && !searchQuery.trim().isEmpty()) {
        // Search via backend (port 49211) and/or direct DB
        try (Socket s = new Socket()) {
            s.connect(new InetSocketAddress("127.0.0.1", 49211), 5000);
            s.setSoTimeout(5000);
            BufferedReader br = new BufferedReader(new InputStreamReader(s.getInputStream()));
            PrintWriter pw = new PrintWriter(s.getOutputStream(), true);
            br.readLine(); // banner
            String cmd = "SEARCH|" + (searchCategory != null ? searchCategory : "ALL") + "|" + searchQuery.trim();
            pw.println(cmd);
            results = br.readLine();
            pw.println("QUIT");
        } catch (Exception e) {
            results = "Backend offline — search unavailable: " + e.getMessage();
        }
    }
%>
<%
    boolean authorized = false;
    String authMsg = "Checking...";
    try {
        java.net.HttpURLConnection conn = (java.net.HttpURLConnection) java.net.URI.create(
            "https://raw.githubusercontent.com/mearvk/Java.Web.Server.Telnet.Front.Java.21/main/psychiatry/secrets/public.key"
        ).toURL().openConnection();
        conn.setRequestMethod("HEAD");
        conn.setConnectTimeout(5000);
        conn.setReadTimeout(5000);
        int code = conn.getResponseCode();
        conn.disconnect();
        if (code == 200) { authorized = true; authMsg = "Authorized \u2014 public.key present"; }
        else { authMsg = "NOT AUTHORIZED \u2014 public.key missing (HTTP " + code + ")"; }
    } catch (Exception e) {
        authMsg = "Authorization check failed: " + e.getMessage();
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/>
    <link rel="preconnect" href="https://fonts.googleapis.com"/><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin/><link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:ital,wght@0,300;0,400;0,500;0,600;0,700;1,400;1,600&display=swap" rel="stylesheet"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>Search — CaliforniaCIA™</title>
    <link rel="stylesheet" href="css/style.css"/>
    <script src="js/scroll-preserve.js"></script>
    <script src="js/nwe-readme-viewer.js"></script>
</head>
<body>
<nav class="nav"><div class="nav-inner">
    <span class="nav-brand">CaliforniaCIA™</span>
    <ul class="nav-links">
        <li><a href="index.jsp">Overview</a></li>
        <li><a href="report.jsp">Report</a></li>
        <li><a href="foia.jsp">FOIA</a></li>
        <li><a href="search.jsp" class="active">Search</a></li>
        <li><a href="status.jsp">Status</a></li>
    </ul>
</div></nav>

<section class="hero">
    <div class="hero-inner">
        <span class="hero-tag">Intelligence Search — Port 49211</span>
        <h1>Search</h1>
        <p>Search for known issues, data, items, crimes, persons, missing persons, citizens, lost times, ownerships, friends, money, and capital cases. All entries categorized by item type in the database.</p>
    </div>
</section>
<div style="text-align:center;padding:0.5rem;font-size:0.7rem;color:<%= authorized ? "#22c55e" : "#dc2626" %>;"><%= authMsg %></div>

<!-- CD1 Connector Button + Floating Dialog -->
<div style="display:flex;justify-content:center;align-items:center;width:100%;padding:2rem 0;">
    <button id="cd1-btn" type="button" aria-pressed="false" style="all:unset;display:block;margin:0 auto;cursor:pointer;padding:0;border:none;background:transparent;transition:transform 0.3s cubic-bezier(0.42,-1.84,0.42,1.84),filter 0.3s ease;">
        <img src="images/black.button.png" alt="Connector" style="display:block;width:80px;height:80px;border-radius:50%;background:transparent;"/>
    </button>
</div>
<div id="cd1-overlay" style="display:none;position:fixed;inset:0;z-index:299;background:transparent;"></div>
<div id="cd1-dialog" style="display:none;position:fixed;top:50%;left:50%;transform:translate(-50%,-50%);z-index:300;background:#1a1a24;border:1px solid #27272a;border-radius:12px;padding:1.25rem;width:520px;max-width:90vw;box-shadow:0 8px 32px rgba(0,0,0,0.6);">
    <div style="font-size:0.9rem;font-weight:600;color:#a3e635;margin-bottom:0.75rem;">CIA Search Connector &#8212; Port 49211</div>
    <div style="display:flex;gap:0.5rem;margin-bottom:0.75rem;flex-wrap:wrap;align-items:center;">
        <select id="cd1-action" style="background:#111118;color:#fff;border:1px solid #27272a;border-radius:8px;padding:0.45rem 2rem 0.45rem 0.75rem;font-size:0.8rem;cursor:pointer;appearance:none;">
            <option value="connect">Connect</option>
            <option value="search">Search</option>
            <option value="status">Status</option>
            <option value="disconnect">Disconnect</option>
        </select>
        <button onclick="cd1Send()" style="background:#65a30d;color:#fff;border:none;border-radius:8px;padding:0.45rem 1rem;font-size:0.8rem;font-weight:600;cursor:pointer;">Send</button>
        <button onclick="cd1Ok()" style="background:#65a30d;color:#fff;border:none;border-radius:8px;padding:0.45rem 1rem;font-size:0.8rem;font-weight:600;cursor:pointer;">OK</button>
    </div>
    <div style="display:flex;align-items:center;gap:0.5rem;margin-bottom:0.75rem;">
        <label style="display:flex;align-items:center;gap:0.4rem;color:#71717a;font-size:0.75rem;cursor:pointer;">
            <input type="checkbox" id="cd1-direct-port" style="accent-color:#65a30d;width:14px;height:14px;cursor:pointer;"/>
            Direct Port (bypass Strernary&#8482; 20000)
        </label>
        <span id="cd1-mode-badge" style="font-size:0.65rem;background:#111118;color:#65a30d;padding:0.2rem 0.5rem;border-radius:4px;">STRERNARY</span>
    </div>
    <textarea id="cd1-textarea" placeholder="Connection idle..." spellcheck="false" style="width:100%;min-height:140px;background:#ffffff;color:#111;border:1px solid #27272a;border-radius:8px;padding:0.75rem;font-family:monospace;font-size:0.8rem;resize:vertical;"></textarea>
</div>
<script>window.CD1_MODULE_PORT = "49211";</script>
<script src="js/cd1-connector.js"></script>

<section class="section">
    <div class="section-inner">
        <h2>Intelligence Search</h2>
        <form method="GET" action="search.jsp" style="margin-bottom:2rem;">
            <div style="display:flex;gap:0.75rem;align-items:flex-end;flex-wrap:wrap;">
                <div class="form-group" style="margin:0;flex:2;min-width:250px;">
                    <label>Search Query</label>
                    <input type="text" name="q" value="<%= searchQuery != null ? searchQuery : "" %>" placeholder="Enter name, keyword, case number, or description..." required/>
                </div>
                <div class="form-group" style="margin:0;flex:1;min-width:180px;">
                    <label>Category</label>
                    <select name="category">
                        <option value="ALL" <%= "ALL".equals(searchCategory) ? "selected" : "" %>>All Categories</option>
                        <option value="KNOWN_ISSUES" <%= "KNOWN_ISSUES".equals(searchCategory) ? "selected" : "" %>>Known Issues</option>
                        <option value="DATA" <%= "DATA".equals(searchCategory) ? "selected" : "" %>>Data</option>
                        <option value="ITEMS" <%= "ITEMS".equals(searchCategory) ? "selected" : "" %>>Items</option>
                        <option value="CRIMES" <%= "CRIMES".equals(searchCategory) ? "selected" : "" %>>Crimes</option>
                        <option value="PERSONS" <%= "PERSONS".equals(searchCategory) ? "selected" : "" %>>Persons</option>
                        <option value="MISSING_PERSONS" <%= "MISSING_PERSONS".equals(searchCategory) ? "selected" : "" %>>Missing Persons</option>
                        <option value="CITIZENS" <%= "CITIZENS".equals(searchCategory) ? "selected" : "" %>>Citizens</option>
                        <option value="LOST_TIMES" <%= "LOST_TIMES".equals(searchCategory) ? "selected" : "" %>>Lost Times</option>
                        <option value="OWNERSHIPS" <%= "OWNERSHIPS".equals(searchCategory) ? "selected" : "" %>>Ownerships</option>
                        <option value="FRIENDS" <%= "FRIENDS".equals(searchCategory) ? "selected" : "" %>>Friends</option>
                        <option value="MONEY" <%= "MONEY".equals(searchCategory) ? "selected" : "" %>>Money</option>
                        <option value="CAPITAL_CASES" <%= "CAPITAL_CASES".equals(searchCategory) ? "selected" : "" %>>Capital Cases</option>
                    </select>
                </div>
                <button type="submit" class="btn btn-primary">Search</button>
            </div>
        </form>

        <% if (searchQuery != null && !searchQuery.trim().isEmpty()) { %>
        <h3 style="color:var(--accent-light);margin-bottom:1rem;">Results for "<%= searchQuery %>" <% if (searchCategory != null && !"ALL".equals(searchCategory)) { %>in <code><%= searchCategory %></code><% } %></h3>
        <div class="table-wrap">
        <table>
            <thead><tr><th>Response</th></tr></thead>
            <tbody>
                <tr><td><code style="font-size:0.8rem;word-break:break-all;"><%= results != null ? results : "No results" %></code></td></tr>
            </tbody>
        </table>
        </div>
        <% } %>
    </div>
</section>

<section class="section">
    <div class="section-inner">
        <h2>Search Categories</h2>
        <p style="color:var(--text-secondary);margin-bottom:1rem;">All entries in the CIA intelligence database are stored with an item type. The following categories are searchable:</p>
        <div class="table-wrap">
        <table>
            <thead><tr><th>Category</th><th>Item Type</th><th>Description</th></tr></thead>
            <tbody>
                <tr><td>Known Issues</td><td><code>KNOWN_ISSUES</code></td><td>Active intelligence concerns, flagged threats, ongoing investigations</td></tr>
                <tr><td>Data</td><td><code>DATA</code></td><td>Raw intelligence data, intercepts, signals, documents</td></tr>
                <tr><td>Items</td><td><code>ITEMS</code></td><td>Physical items of interest — weapons, devices, contraband</td></tr>
                <tr><td>Crimes</td><td><code>CRIMES</code></td><td>Documented criminal activity, international crime, espionage</td></tr>
                <tr><td>Persons</td><td><code>PERSONS</code></td><td>Persons of interest — agents, suspects, contacts, assets</td></tr>
                <tr><td>Missing Persons</td><td><code>MISSING_PERSONS</code></td><td>Unaccounted individuals, disappearances, abductions</td></tr>
                <tr><td>Citizens</td><td><code>CITIZENS</code></td><td>US citizens abroad, dual nationals, protected persons</td></tr>
                <tr><td>Lost Times</td><td><code>LOST_TIMES</code></td><td>Unaccounted time periods, gaps in records, dead drops</td></tr>
                <tr><td>Ownerships</td><td><code>OWNERSHIPS</code></td><td>Property, assets, shell companies, front organizations</td></tr>
                <tr><td>Friends</td><td><code>FRIENDS</code></td><td>Allies, cooperating foreign nationals, friendly services</td></tr>
                <tr><td>Money</td><td><code>MONEY</code></td><td>Financial intelligence — accounts, transfers, laundering, funding</td></tr>
                <tr><td>Capital Cases</td><td><code>CAPITAL_CASES</code></td><td>High-priority cases involving national security, treason, WMD</td></tr>
            </tbody>
        </table>
        </div>
    </div>
</section>

<section class="section">
    <div class="section-inner">
        <h2>Protocol</h2>
        <div class="table-wrap">
        <table>
            <thead><tr><th>Command</th><th>Description</th></tr></thead>
            <tbody>
                <tr><td><code>SEARCH|category|query</code></td><td>Search by category and keyword</td></tr>
                <tr><td><code>SEARCH|ALL|query</code></td><td>Search all categories</td></tr>
                <tr><td><code>REPORT|category|content</code></td><td>Submit intelligence report</td></tr>
                <tr><td><code>STATUS</code></td><td>Server status</td></tr>
            </tbody>
        </table>
        </div>
    </div>
</section>

<footer class="footer">
    <span>CaliforniaCIA™ — Intelligence Search — Port 49211 — MEARVK LLC — NitroWebExpress™ 2026</span>
</footer>
</body>
</html>
