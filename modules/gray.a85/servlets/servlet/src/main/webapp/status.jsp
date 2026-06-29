<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.Properties, java.io.*" %>
<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"/><meta name="viewport" content="width=device-width,initial-scale=1.0"/>
<title>Status — Gray85 Crème™</title><link rel="stylesheet" href="css/style.css"/></head><body>
<nav class="nav"><div class="nav-inner"><span class="nav-brand">Gray85 Crème™</span>
<ul class="nav-links"><li><a href="index.jsp">Overview</a></li><li><a href="leases.jsp">Leases</a></li><li><a href="bindings.jsp">Bindings</a></li><li><a href="creme.jsp">Crème</a></li><li><a href="status.jsp" class="active">Status</a></li></ul></div></nav>
<section class="hero" style="padding:4rem 2rem;"><div class="hero-inner"><h1>Status</h1></div></section>
<section class="section"><div class="section-inner">
<% Properties dbProps = new Properties(); boolean propsLoaded = false; Connection conn = null;
    String dbStatus="Offline",dbVer="",leaseCount="?",bindCount="?",cremeCount="?";
    try { InputStream dbIn = application.getResourceAsStream("/WEB-INF/db.properties");
        if (dbIn != null) { dbProps.load(dbIn); dbIn.close(); propsLoaded = true; }
        if (!propsLoaded) { File f = new File("/opt/tomcat/webapps/gray85-registry/WEB-INF/db.properties");
            if (f.exists()) { FileInputStream fis = new FileInputStream(f); dbProps.load(fis); fis.close(); propsLoaded = true; } }
        Class.forName(dbProps.getProperty("db.driver","com.mysql.cj.jdbc.Driver"));
        conn = DriverManager.getConnection(dbProps.getProperty("db.url","jdbc:mysql://127.0.0.1:3306/nwe_gray85_registry"),dbProps.getProperty("db.user","root"),dbProps.getProperty("db.password",""));
        dbStatus="Online"; dbVer=conn.getMetaData().getDatabaseProductName()+" "+conn.getMetaData().getDatabaseProductVersion();
        ResultSet r=conn.createStatement().executeQuery("SELECT COUNT(*) FROM leases"); if(r.next()) leaseCount=String.valueOf(r.getInt(1)); r.close();
        r=conn.createStatement().executeQuery("SELECT COUNT(*) FROM bindings"); if(r.next()) bindCount=String.valueOf(r.getInt(1)); r.close();
        r=conn.createStatement().executeQuery("SELECT COUNT(*) FROM creme_unlocks WHERE expires_at > NOW()"); if(r.next()) cremeCount=String.valueOf(r.getInt(1)); r.close();
    } catch(Exception e) { dbStatus="Error: "+(e.getMessage()!=null?e.getMessage().replace("<","&lt;"):"unknown");
    } finally { if(conn!=null) try{conn.close();}catch(Exception ignored){} } %>
<div class="table-wrap"><table><thead><tr><th>Service</th><th>Status</th><th>Details</th></tr></thead><tbody>
<tr><td>MySQL (nwe_gray85_registry)</td><td><%=dbStatus%></td><td><%=dbVer%></td></tr>
<tr><td>Active Leases</td><td><%=leaseCount%></td><td>of 1000 blocks</td></tr>
<tr><td>Total Bindings</td><td><%=bindCount%></td><td>85% open + 15% Crème</td></tr>
<tr><td>Active Crème Unlocks</td><td><%=cremeCount%></td><td>$1000/hr each</td></tr>
<tr><td>Servlet Container</td><td>Online</td><td><%=application.getServerInfo()%></td></tr>
<tr><td>JVM</td><td>Online</td><td><%=System.getProperty("java.version")%></td></tr>
</tbody></table></div></div></section>
<footer class="footer"><div><span>&#169; 2026 MEARVK LLC.</span></div></footer></body></html>
