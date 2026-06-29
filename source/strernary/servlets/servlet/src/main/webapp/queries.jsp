<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.Properties, java.io.*" %>
<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"/><meta name="viewport" content="width=device-width,initial-scale=1.0"/>
<title>Queries — Strernary™</title><link rel="stylesheet" href="css/style.css"/></head><body>
<nav class="nav"><div class="nav-inner"><span class="nav-brand">Strernary™</span>
<ul class="nav-links"><li><a href="index.jsp">Overview</a></li><li><a href="ask.jsp">Ask</a></li><li><a href="directory.jsp">Directory</a></li><li><a href="queries.jsp" class="active">Queries</a></li><li><a href="status.jsp">Status</a></li></ul>
</div></nav>
<section class="hero" style="padding:4rem 2rem;"><div class="hero-inner"><h1>Query Log</h1></div></section>
<section class="section"><div class="section-inner">
<%  Properties dbProps = new Properties(); boolean propsLoaded = false; Connection conn = null;
    try { InputStream dbIn = application.getResourceAsStream("/WEB-INF/db.properties");
        if (dbIn != null) { dbProps.load(dbIn); dbIn.close(); propsLoaded = true; }
        if (!propsLoaded) { File f = new File("/opt/tomcat/webapps/strernary/WEB-INF/db.properties");
            if (f.exists()) { FileInputStream fis = new FileInputStream(f); dbProps.load(fis); fis.close(); propsLoaded = true; } }
        Class.forName(dbProps.getProperty("db.driver","com.mysql.cj.jdbc.Driver"));
        conn = DriverManager.getConnection(dbProps.getProperty("db.url","jdbc:mysql://127.0.0.1:3306/nwe_strernary"),dbProps.getProperty("db.user","root"),dbProps.getProperty("db.password",""));
        ResultSet rs = conn.createStatement().executeQuery("SELECT question, layer, ip, asked_at FROM queries ORDER BY asked_at DESC LIMIT 50");
%><div class="table-wrap"><table><thead><tr><th>Query</th><th>Layer</th><th>IP</th><th>Time</th></tr></thead><tbody>
<% boolean has=false; while(rs.next()){has=true; String q=rs.getString("question"); %><tr><td><%= q!=null?(q.length()>80?q.substring(0,80).replace("<","&lt;")+"…":q.replace("<","&lt;")):"" %></td><td><code><%=rs.getString("layer")%></code></td><td><code><%=rs.getString("ip")%></code></td><td><%=rs.getTimestamp("asked_at")%></td></tr>
<% } if(!has){ %><tr><td colspan="4" style="text-align:center;color:var(--text-muted);">No queries yet. <a href="ask.jsp">Ask something →</a></td></tr><% } rs.close();
    } catch(Exception e) { %><p style="color:#ef4444;"><%=e.getMessage()!=null?e.getMessage().replace("<","&lt;"):"DB not ready"%></p>
<% } finally { if(conn!=null) try{conn.close();}catch(Exception ignored){} } %>
</tbody></table></div></div></section>
<footer class="footer"><div><span>&#169; 2026 MEARVK LLC.</span></div></footer></body></html>
