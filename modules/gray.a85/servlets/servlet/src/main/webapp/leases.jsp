<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.Properties, java.io.*" %>
<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"/><meta name="viewport" content="width=device-width,initial-scale=1.0"/>
<title>Leases — Gray85 Crème™</title><link rel="stylesheet" href="css/style.css"/></head><body>
<nav class="nav"><div class="nav-inner"><span class="nav-brand">Gray85 Crème™</span>
<ul class="nav-links"><li><a href="index.jsp">Overview</a></li><li><a href="leases.jsp" class="active">Leases</a></li><li><a href="bindings.jsp">Bindings</a></li><li><a href="creme.jsp">Crème</a></li><li><a href="status.jsp">Status</a></li></ul></div></nav>
<section class="hero" style="padding:4rem 2rem;"><div class="hero-inner"><h1>Active Leases</h1></div></section>
<section class="section"><div class="section-inner">
<%  Properties dbProps = new Properties(); boolean propsLoaded = false; Connection conn = null;
    try { InputStream dbIn = application.getResourceAsStream("/WEB-INF/db.properties");
        if (dbIn != null) { dbProps.load(dbIn); dbIn.close(); propsLoaded = true; }
        if (!propsLoaded) { File f = new File("/opt/tomcat/webapps/gray85-registry/WEB-INF/db.properties");
            if (f.exists()) { FileInputStream fis = new FileInputStream(f); dbProps.load(fis); fis.close(); propsLoaded = true; } }
        Class.forName(dbProps.getProperty("db.driver","com.mysql.cj.jdbc.Driver"));
        conn = DriverManager.getConnection(dbProps.getProperty("db.url","jdbc:mysql://127.0.0.1:3306/nwe_gray85_registry"),dbProps.getProperty("db.user","root"),dbProps.getProperty("db.password",""));
        ResultSet rs = conn.createStatement().executeQuery("SELECT id,block_id,term,btc_txid,lessee_ip,leased_at,expires_at FROM leases ORDER BY leased_at DESC LIMIT 50");
%><div class="table-wrap"><table><thead><tr><th>ID</th><th>Block</th><th>Term</th><th>TxID</th><th>IP</th><th>Leased</th><th>Expires</th></tr></thead><tbody>
<% boolean has=false; while(rs.next()){has=true; %><tr><td><%=rs.getInt("id")%></td><td><%=rs.getInt("block_id")%></td><td><%=rs.getString("term")%></td><td><code style="font-size:0.7rem;"><%=rs.getString("btc_txid")!=null?rs.getString("btc_txid").substring(0,Math.min(12,rs.getString("btc_txid").length()))+"…":"—"%></code></td><td><%=rs.getString("lessee_ip")!=null?rs.getString("lessee_ip"):""%></td><td><%=rs.getTimestamp("leased_at")%></td><td><%=rs.getTimestamp("expires_at")%></td></tr>
<% } if(!has){ %><tr><td colspan="7" style="text-align:center;color:var(--text-muted);">No active leases.</td></tr><% } rs.close();
    } catch(Exception e) { %><p style="color:#ef4444;">Database error: <%=e.getMessage()!=null?e.getMessage().replace("<","&lt;"):"unknown"%></p>
<% } finally { if(conn!=null) try{conn.close();}catch(Exception ignored){} } %>
</tbody></table></div></div></section>
<footer class="footer"><div><span>&#169; 2026 MEARVK LLC.</span></div></footer></body></html>
