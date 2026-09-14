<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.Properties, java.io.*" %>
<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"/><meta name="viewport" content="width=device-width,initial-scale=1.0"/>
    <link rel="preconnect" href="https://fonts.googleapis.com"/><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin/><link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:ital,wght@0,300;0,400;0,500;0,600;0,700;1,400;1,600&display=swap" rel="stylesheet"/>
<title>Bindings — GrayPortRegistry™</title><link rel="stylesheet" href="css/style.css"/><script src="js/scroll-preserve.js"></script>
    <script src="js/nwe-readme-viewer.js"></script>
</head><body>
<nav class="nav"><div class="nav-inner"><span class="nav-brand">GrayPortRegistry™</span>
<ul class="nav-links"><li><a href="index.jsp">Overview</a></li><li><a href="leases.jsp">Leases</a></li><li><a href="bindings.jsp" class="active">Bindings</a></li><li><a href="status.jsp">Status</a></li></ul></div></nav>
<section class="hero" style="padding:4rem 2rem;"><div class="hero-inner"><h1>Port Bindings</h1></div></section>
<section class="section"><div class="section-inner">
<% String blockFilter = request.getParameter("block"); Properties dbProps = new Properties(); boolean propsLoaded = false; Connection conn = null;
    try { InputStream dbIn = application.getResourceAsStream("/WEB-INF/db.properties");
        if (dbIn != null) { dbProps.load(dbIn); dbIn.close(); propsLoaded = true; }
        if (!propsLoaded) { File f = new File("/opt/tomcat/webapps/gray-registry/WEB-INF/db.properties");
            if (f.exists()) { FileInputStream fis = new FileInputStream(f); dbProps.load(fis); fis.close(); propsLoaded = true; } }
        Class.forName(dbProps.getProperty("db.driver","com.mysql.cj.jdbc.Driver"));
        conn = DriverManager.getConnection(dbProps.getProperty("db.url","jdbc:mysql://127.0.0.1:3306/nwe_gray_registry"),dbProps.getProperty("db.user","root"),dbProps.getProperty("db.password",""));
        String sql = blockFilter != null && !blockFilter.isEmpty() ? "SELECT id,block_id,port,bound_ip,bound_at FROM bindings WHERE block_id=? ORDER BY bound_at DESC LIMIT 100" : "SELECT id,block_id,port,bound_ip,bound_at FROM bindings ORDER BY bound_at DESC LIMIT 100";
        PreparedStatement ps = conn.prepareStatement(sql);
        if (blockFilter != null && !blockFilter.isEmpty()) ps.setInt(1, Integer.parseInt(blockFilter));
        ResultSet rs = ps.executeQuery();
%><div class="table-wrap"><table><thead><tr><th>ID</th><th>Block</th><th>Port</th><th>Bound IP</th><th>Bound At</th></tr></thead><tbody>
<% boolean has=false; while(rs.next()){has=true; %><tr><td><%=rs.getInt("id")%></td><td><%=rs.getInt("block_id")%></td><td><code><%=rs.getLong("port")%></code></td><td><%=rs.getString("bound_ip")!=null?rs.getString("bound_ip"):""%></td><td><%=rs.getTimestamp("bound_at")%></td></tr>
<% } if(!has){ %><tr><td colspan="5" style="text-align:center;color:var(--text-muted);">No bindings found.</td></tr><% } rs.close(); ps.close();
    } catch(Exception e) { %><p style="color:#ef4444;">Database error: <%=e.getMessage()!=null?e.getMessage().replace("<","&lt;"):"unknown"%></p>
<% } finally { if(conn!=null) try{conn.close();}catch(Exception ignored){} } %>
</tbody></table></div></div></section>
<footer class="footer"><div><span>&#169; 2026 MEARVK LLC.</span></div></footer></body></html>
