<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.Properties, java.io.*" %>
<%
    String question = request.getParameter("q");
    String answer = null;
    if (question != null && !question.trim().isEmpty()) {
        question = question.trim();
        if (question.length() > 1000) question = question.substring(0, 1000);
        // Keyword heuristic inference (layer 3 — DJL model integration for production)
        String qLower = question.toLowerCase();
        if (qLower.contains("life") || qLower.contains("meaning")) {
            answer = "Life is a pattern of self-organizing information that persists through entropy. In systems terms: a process that maintains state across time by consuming energy and producing useful work.";
        } else if (qLower.contains("strernary") || qLower.contains("what are you")) {
            answer = "Strernary™ is a best-guess inference server on port 20000. I accept queries via ASK|text protocol and return responses using DJL/PyTorch (layer 1), OS port relay (layer 2), or keyword heuristics (layer 3, which you're using now).";
        } else if (qLower.contains("port") || qLower.contains("server")) {
            answer = "Strernary operates on port 20000 (inference) and port 2000 (directory/routing). The NIO Masquerade Layer bridges 127.0.0.1–17 for extended port space (up to 1,048,576 ports across 18 IPs).";
        } else if (qLower.contains("djl") || qLower.contains("model") || qLower.contains("pytorch")) {
            answer = "DJL (Deep Java Library) is Amazon's open-source framework for Java ML inference. Strernary uses DistilBERT (~250MB) for question-answering. Download jars with scripts/bash/strernary/download-djl.sh.";
        } else if (qLower.contains("directory") || qLower.contains("rank")) {
            answer = "The Directory Server (port 2000) provides: (1) List port 20000 IPs, (2) List port 49152 IPs, (3) Register Rank 4 JWSTNJ21 server via public.key verification, (4) XML packet forwarding via <nwe-route> packets.";
        } else if (qLower.contains("weather") || qLower.contains("time") || qLower.contains("date")) {
            answer = "Current server time: " + new java.text.SimpleDateFormat("yyyy-MM-dd HH:mm:ss z").format(new java.util.Date()) + ". Weather data available via the international signal servers (Japan 49201, Russia 49202, Mexico 49203, Greece 49204).";
        } else {
            answer = "Best-guess response (heuristic layer): I don't have a specific trained answer for that query. In production, the DJL DistilBERT model would provide a contextual response. Try asking about: Strernary, ports, DJL/models, directory services, or general knowledge.";
        }
        // Log query
        Properties dbProps = new Properties(); boolean propsLoaded = false; Connection conn = null;
        try { InputStream dbIn = application.getResourceAsStream("/WEB-INF/db.properties");
            if (dbIn != null) { dbProps.load(dbIn); dbIn.close(); propsLoaded = true; }
            if (!propsLoaded) { File f = new File("/opt/tomcat/webapps/strernary/WEB-INF/db.properties");
                if (f.exists()) { FileInputStream fis = new FileInputStream(f); dbProps.load(fis); fis.close(); propsLoaded = true; } }
            Class.forName(dbProps.getProperty("db.driver","com.mysql.cj.jdbc.Driver"));
            conn = DriverManager.getConnection(dbProps.getProperty("db.url","jdbc:mysql://127.0.0.1:3306/nwe_strernary"),dbProps.getProperty("db.user","root"),dbProps.getProperty("db.password",""));
            conn.createStatement().executeUpdate("CREATE TABLE IF NOT EXISTS queries (id INT AUTO_INCREMENT PRIMARY KEY, question TEXT, answer TEXT, layer VARCHAR(20), ip VARCHAR(45), asked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)");
            PreparedStatement ps = conn.prepareStatement("INSERT INTO queries (question, answer, layer, ip) VALUES (?,?,?,?)");
            ps.setString(1, question); ps.setString(2, answer); ps.setString(3, "heuristic");
            String ip = request.getHeader("X-Forwarded-For"); if (ip == null) ip = request.getRemoteAddr();
            ps.setString(4, ip); ps.executeUpdate(); ps.close();
        } catch (Exception ignored) {} finally { if (conn != null) try { conn.close(); } catch (Exception ignored) {} }
    }
%>
<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"/>
    <link rel="preconnect" href="https://fonts.googleapis.com"/><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin/><link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:ital,wght@0,300;0,400;0,500;0,600;0,700;1,400;1,600&display=swap" rel="stylesheet"/><meta name="viewport" content="width=device-width,initial-scale=1.0"/>
<title>Ask — Strernary™</title><link rel="stylesheet" href="css/style.css"/><script src="js/scroll-preserve.js"></script>
    <script src="js/nwe-readme-viewer.js"></script>
</head><body>
<nav class="nav"><div class="nav-inner"><span class="nav-brand">Strernary™</span>
<ul class="nav-links"><li><a href="index.jsp">Overview</a></li><li><a href="ask.jsp" class="active">Ask</a></li><li><a href="directory.jsp">Directory</a></li><li><a href="queries.jsp">Queries</a></li><li><a href="status.jsp">Status</a></li></ul>
</div></nav>

<section class="hero" style="padding:4rem 2rem;"><div class="hero-inner"><span class="hero-tag">ASK|text → Best-Guess</span><h1>Ask Strernary</h1><p>Submit a query. Inference via keyword heuristics (layer 3). DJL/PyTorch layer available when model is loaded.</p></div></section>

<!-- CD1 Connector Button + Floating Dialog -->
<div style="display:flex;justify-content:center;align-items:center;width:100%;padding:2rem 0;">
    <button id="cd1-btn" type="button" aria-pressed="false" style="all:unset;display:block;margin:0 auto;cursor:pointer;padding:0;border:none;background:transparent;transition:transform 0.3s cubic-bezier(0.42,-1.84,0.42,1.84),filter 0.3s ease;">
        <img src="images/black.button.png" alt="Connector" style="display:block;width:80px;height:80px;border-radius:50%;background:transparent;"/>
    </button>
</div>
<div id="cd1-overlay" style="display:none;position:fixed;inset:0;z-index:299;background:transparent;"></div>
<div id="cd1-dialog" style="display:none;position:fixed;top:50%;left:50%;transform:translate(-50%,-50%);z-index:300;background:#1a1a1a;border:1px solid #333;border-radius:12px;padding:1.25rem;width:520px;max-width:90vw;box-shadow:0 8px 32px rgba(0,0,0,0.6);">
    <div style="font-size:0.9rem;font-weight:600;color:#e8e0d6;margin-bottom:0.75rem;">CD1 Connector &#8212; Port 20000</div>
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
<script>window.CD1_MODULE_PORT = "20000";</script>
<script src="js/cd1-connector.js"></script>

<section class="section"><div class="section-inner">
<div class="ask-form">
<form method="get" action="ask.jsp">
<input type="text" name="q" class="ask-input" placeholder="ASK| What is Strernary?" value="<%= question != null ? question.replace("\"","&quot;").replace("<","&lt;") : "" %>" autocomplete="off"/>
<button type="submit" class="ask-btn">ASK →</button>
</form>
<% if (answer != null) { %>
<div class="answer-box"><strong style="color:var(--accent);font-size:0.75rem;">RESPONSE (Layer 3: Heuristic)</strong>
<p style="margin-top:0.75rem;color:var(--text-primary);"><%= answer.replace("<","&lt;") %></p></div>
<% } %>
</div></div></section>
</body></html>
