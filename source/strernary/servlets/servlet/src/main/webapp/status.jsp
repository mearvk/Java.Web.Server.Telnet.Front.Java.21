<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.Properties, java.io.*" %>
<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"/>
    <link rel="preconnect" href="https://fonts.googleapis.com"/><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin/><link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:ital,wght@0,300;0,400;0,500;0,600;0,700;1,400;1,600&display=swap" rel="stylesheet"/><meta name="viewport" content="width=device-width,initial-scale=1.0"/>
<title>Status — Strernary™</title><link rel="stylesheet" href="css/style.css"/><script src="js/scroll-preserve.js"></script>
</head><body>
<nav class="nav"><div class="nav-inner"><span class="nav-brand">Strernary™</span>
<ul class="nav-links"><li><a href="index.jsp">Overview</a></li><li><a href="ask.jsp">Ask</a></li><li><a href="directory.jsp">Directory</a></li><li><a href="queries.jsp">Queries</a></li><li><a href="status.jsp" class="active">Status</a></li></ul>
</div></nav>

<section class="hero" style="padding:4rem 2rem;"><div class="hero-inner"><h1>Status</h1></div></section>

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
<% Properties dbProps = new Properties(); boolean propsLoaded = false; Connection conn = null;
    String dbStatus="Offline",dbVer="",queryCount="?";
    try { InputStream dbIn = application.getResourceAsStream("/WEB-INF/db.properties");
        if (dbIn != null) { dbProps.load(dbIn); dbIn.close(); propsLoaded = true; }
        if (!propsLoaded) { File f = new File("/opt/tomcat/webapps/strernary/WEB-INF/db.properties");
            if (f.exists()) { FileInputStream fis = new FileInputStream(f); dbProps.load(fis); fis.close(); propsLoaded = true; } }
        Class.forName(dbProps.getProperty("db.driver","com.mysql.cj.jdbc.Driver"));
        conn = DriverManager.getConnection(dbProps.getProperty("db.url","jdbc:mysql://127.0.0.1:3306/nwe_strernary"),dbProps.getProperty("db.user","root"),dbProps.getProperty("db.password",""));
        dbStatus="Online"; dbVer=conn.getMetaData().getDatabaseProductName()+" "+conn.getMetaData().getDatabaseProductVersion();
        try { ResultSet r=conn.createStatement().executeQuery("SELECT COUNT(*) FROM queries"); if(r.next()) queryCount=String.valueOf(r.getInt(1)); r.close(); } catch(Exception ignored){ queryCount="table pending"; }
    } catch(Exception e) { dbStatus="Error: "+(e.getMessage()!=null?e.getMessage().replace("<","&lt;"):"unknown");
    } finally { if(conn!=null) try{conn.close();}catch(Exception ignored){} } %>
<div class="table-wrap"><table><thead><tr><th>Service</th><th>Status</th><th>Details</th></tr></thead><tbody>
<tr><td>MySQL (nwe_strernary)</td><td><%=dbStatus%></td><td><%=dbVer%></td></tr>
<tr><td>Queries Served</td><td><%=queryCount%></td><td>All layers combined</td></tr>
<tr><td>Inference (DJL)</td><td style="color:#eab308;">Model not loaded (web UI uses heuristic layer)</td><td>Load via: java -cp source StrernaryServer</td></tr>
<tr><td>Port 20000 (TCP)</td><td style="color:var(--text-muted);">Check via telnet</td><td><code>telnet localhost 20000</code></td></tr>
<tr><td>Port 2000 (Directory)</td><td style="color:var(--text-muted);">Check via telnet</td><td><code>telnet localhost 2000</code></td></tr>
<tr><td>Servlet Container</td><td>Online</td><td><%=application.getServerInfo()%></td></tr>
<tr><td>JVM</td><td>Online</td><td><%=System.getProperty("java.version")%></td></tr>
</tbody></table></div></div></section>
</body></html>
