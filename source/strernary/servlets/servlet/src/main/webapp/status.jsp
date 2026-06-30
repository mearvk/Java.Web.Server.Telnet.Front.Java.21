<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.Properties, java.io.*" %>
<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"/><meta name="viewport" content="width=device-width,initial-scale=1.0"/>
<title>Status — Strernary™</title><link rel="stylesheet" href="css/style.css"/><script src="js/scroll-preserve.js"></script>
</head><body>
<nav class="nav"><div class="nav-inner"><span class="nav-brand">Strernary™</span>
<ul class="nav-links"><li><a href="index.jsp">Overview</a></li><li><a href="ask.jsp">Ask</a></li><li><a href="directory.jsp">Directory</a></li><li><a href="queries.jsp">Queries</a></li><li><a href="status.jsp" class="active">Status</a></li></ul>
</div></nav>
<section class="hero" style="padding:4rem 2rem;"><div class="hero-inner"><h1>Status</h1></div></section>
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
<footer class="footer"><div><span>&#169; 2026 MEARVK LLC.</span></div></footer></body></html>
