<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.Properties, java.io.*" %>
<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"/><meta name="viewport" content="width=device-width,initial-scale=1.0"/>
<title>Bindings — Gray85 Crème™</title><link rel="stylesheet" href="css/style.css"/></head><body>
<nav class="nav"><div class="nav-inner"><span class="nav-brand">Gray85 Crème™</span>
<ul class="nav-links"><li><a href="index.jsp">Overview</a></li><li><a href="leases.jsp">Leases</a></li><li><a href="bindings.jsp" class="active">Bindings</a></li><li><a href="creme.jsp">Crème</a></li><li><a href="status.jsp">Status</a></li></ul></div></nav>
<section class="hero" style="padding:4rem 2rem;"><div class="hero-inner"><h1>Port Bindings</h1></div></section>
<section class="section"><div class="section-inner">
<% String blockFilter = request.getParameter("block"); Properties dbProps = new Properties(); boolean propsLoaded = false; Connection conn = null;
    try { InputStream dbIn = application.getResourceAsStream("/WEB-INF/db.properties");
        if (dbIn != null) { dbProps.load(dbIn); dbIn.close(); propsLoaded = true; }
        if (!propsLoaded) { File f = new File("/opt/tomcat/webapps/gray85-registry/WEB-INF/db.properties");
            if (f.exists()) { FileInputStream fis = new FileInputStream(f); dbProps.load(fis); fis.close(); propsLoaded = true; } }
        Class.forName(dbProps.getProperty("db.driver","com.mysql.cj.jdbc.Driver"));
        conn = DriverManager.getConnection(dbProps.getProperty("db.url","jdbc:mysql://127.0.0.1:3306/nwe_gray85_registry"),dbProps.getProperty("db.user","root"),dbProps.getProperty("db.password",""));
        String sql = blockFilter != null && !blockFilter.isEmpty() ? "SELECT id,block_id,port,bound_ip,is_creme,bound_at FROM bindings WHERE block_id=? ORDER BY bound_at DESC LIMIT 100" : "SELECT id,block_id,port,bound_ip,is_creme,bound_at FROM bindings ORDER BY bound_at DESC LIMIT 100";
        PreparedStatement ps = conn.prepareStatement(sql);
        if (blockFilter != null && !blockFilter.isEmpty()) ps.setInt(1, Integer.parseInt(blockFilter));
        ResultSet rs = ps.executeQuery();
%><div class="table-wrap"><table><thead><tr><th>ID</th><th>Block</th><th>Port</th><th>IP</th><th>Crème</th><th>Bound</th></tr></thead><tbody>
<% boolean has=false; while(rs.next()){has=true; boolean isCreme=rs.getBoolean("is_creme"); %><tr><td><%=rs.getInt("id")%></td><td><%=rs.getInt("block_id")%></td><td><code><%=rs.getLong("port")%></code></td><td><%=rs.getString("bound_ip")!=null?rs.getString("bound_ip"):""%></td><td style="color:<%=isCreme?"#d97706":"#6b7280"%>;"><%=isCreme?"★ Crème":"Open"%></td><td><%=rs.getTimestamp("bound_at")%></td></tr>
<% } if(!has){ %><tr><td colspan="6" style="text-align:center;color:var(--text-muted);">No bindings.</td></tr><% } rs.close(); ps.close();
    } catch(Exception e) { %><p style="color:#ef4444;">Database error: <%=e.getMessage()!=null?e.getMessage().replace("<","&lt;"):"unknown"%></p>
<% } finally { if(conn!=null) try{conn.close();}catch(Exception ignored){} } %>
</tbody></table></div></div></section>
<footer class="footer"><div><span>&#169; 2026 MEARVK LLC.</span></div></footer></body></html>
