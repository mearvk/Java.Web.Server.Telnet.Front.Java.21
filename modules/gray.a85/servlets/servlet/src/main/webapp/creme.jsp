<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.Properties, java.io.*" %>
<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"/><meta name="viewport" content="width=device-width,initial-scale=1.0"/>
<title>Crème Unlocks — Gray85 Crème™</title><link rel="stylesheet" href="css/style.css"/></head><body>
<nav class="nav"><div class="nav-inner"><span class="nav-brand">Gray85 Crème™</span>
<ul class="nav-links"><li><a href="index.jsp">Overview</a></li><li><a href="leases.jsp">Leases</a></li><li><a href="bindings.jsp">Bindings</a></li><li><a href="creme.jsp" class="active">Crème</a></li><li><a href="status.jsp">Status</a></li></ul></div></nav>
<section class="hero" style="padding:4rem 2rem;"><div class="hero-inner"><span class="hero-tag">$1000/unlock/hour</span><h1>Crème Unlocks</h1><p>Active and recent Crème port unlocks. 15% of each block is Crème-locked by planetary auditor.</p></div></section>
<section class="section"><div class="section-inner">
<%  Properties dbProps = new Properties(); boolean propsLoaded = false; Connection conn = null;
    try { InputStream dbIn = application.getResourceAsStream("/WEB-INF/db.properties");
        if (dbIn != null) { dbProps.load(dbIn); dbIn.close(); propsLoaded = true; }
        if (!propsLoaded) { File f = new File("/opt/tomcat/webapps/gray85-registry/WEB-INF/db.properties");
            if (f.exists()) { FileInputStream fis = new FileInputStream(f); dbProps.load(fis); fis.close(); propsLoaded = true; } }
        Class.forName(dbProps.getProperty("db.driver","com.mysql.cj.jdbc.Driver"));
        conn = DriverManager.getConnection(dbProps.getProperty("db.url","jdbc:mysql://127.0.0.1:3306/nwe_gray85_registry"),dbProps.getProperty("db.user","root"),dbProps.getProperty("db.password",""));
        ResultSet rs = conn.createStatement().executeQuery("SELECT id,block_id,port_offset,hours,btc_txid,unlocked_at,expires_at FROM creme_unlocks ORDER BY unlocked_at DESC LIMIT 50");
%><div class="table-wrap"><table><thead><tr><th>ID</th><th>Block</th><th>Port Offset</th><th>Hours</th><th>TxID</th><th>Unlocked</th><th>Expires</th></tr></thead><tbody>
<% boolean has=false; while(rs.next()){has=true; String tx=rs.getString("btc_txid"); %><tr><td><%=rs.getInt("id")%></td><td><%=rs.getInt("block_id")%></td><td><%=rs.getInt("port_offset")%></td><td><%=rs.getInt("hours")%></td><td><code style="font-size:0.7rem;"><%=tx!=null?tx.substring(0,Math.min(12,tx.length()))+"…":"—"%></code></td><td><%=rs.getTimestamp("unlocked_at")%></td><td><%=rs.getTimestamp("expires_at")%></td></tr>
<% } if(!has){ %><tr><td colspan="7" style="text-align:center;color:var(--text-muted);">No Crème unlocks yet.</td></tr><% } rs.close();
    } catch(Exception e) { %><p style="color:#ef4444;">Database error: <%=e.getMessage()!=null?e.getMessage().replace("<","&lt;"):"unknown"%></p>
<% } finally { if(conn!=null) try{conn.close();}catch(Exception ignored){} } %>
</tbody></table></div></div></section>
<footer class="footer"><div><span>&#169; 2026 MEARVK LLC.</span></div></footer></body></html>
