<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.Properties, java.io.*" %>
<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"/><meta name="viewport" content="width=device-width,initial-scale=1.0"/>
    <link rel="preconnect" href="https://fonts.googleapis.com"/><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin/><link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:ital,wght@0,300;0,400;0,500;0,600;0,700;1,400;1,600&display=swap" rel="stylesheet"/>
<title>Status — GrayPortRegistry™</title><link rel="stylesheet" href="css/style.css"/><script src="js/scroll-preserve.js"></script>
    <script src="js/nwe-readme-viewer.js"></script>
</head><body>
<nav class="nav"><div class="nav-inner"><span class="nav-brand">GrayPortRegistry™</span>
<ul class="nav-links"><li><a href="index.jsp">Overview</a></li><li><a href="leases.jsp">Leases</a></li><li><a href="bindings.jsp">Bindings</a></li><li><a href="status.jsp" class="active">Status</a></li></ul></div></nav>
<section class="hero" style="padding:4rem 2rem;"><div class="hero-inner"><h1>Status</h1></div></section>
<section class="section"><div class="section-inner">
<% Properties dbProps = new Properties(); boolean propsLoaded = false; Connection conn = null;
    String dbStatus="Offline",dbVer="",leaseCount="?",bindCount="?",blocksAvail="?";
    try { InputStream dbIn = application.getResourceAsStream("/WEB-INF/db.properties");
        if (dbIn != null) { dbProps.load(dbIn); dbIn.close(); propsLoaded = true; }
        if (!propsLoaded) { File f = new File("/opt/tomcat/webapps/gray-registry/WEB-INF/db.properties");
            if (f.exists()) { FileInputStream fis = new FileInputStream(f); dbProps.load(fis); fis.close(); propsLoaded = true; } }
        Class.forName(dbProps.getProperty("db.driver","com.mysql.cj.jdbc.Driver"));
        conn = DriverManager.getConnection(dbProps.getProperty("db.url","jdbc:mysql://127.0.0.1:3306/nwe_gray_registry"),dbProps.getProperty("db.user","root"),dbProps.getProperty("db.password",""));
        dbStatus="Online"; dbVer=conn.getMetaData().getDatabaseProductName()+" "+conn.getMetaData().getDatabaseProductVersion();
        ResultSet r1=conn.createStatement().executeQuery("SELECT COUNT(*) FROM leases"); if(r1.next()) leaseCount=String.valueOf(r1.getInt(1)); r1.close();
        ResultSet r2=conn.createStatement().executeQuery("SELECT COUNT(*) FROM bindings"); if(r2.next()) bindCount=String.valueOf(r2.getInt(1)); r2.close();
        blocksAvail = String.valueOf(1000 - Integer.parseInt(leaseCount));
    } catch(Exception e) { dbStatus="Error: "+(e.getMessage()!=null?e.getMessage().replace("<","&lt;"):"unknown");
    } finally { if(conn!=null) try{conn.close();}catch(Exception ignored){} } %>
<div class="table-wrap"><table><thead><tr><th>Service</th><th>Status</th><th>Details</th></tr></thead><tbody>
<tr><td>MySQL (nwe_gray_registry)</td><td><%=dbStatus%></td><td><%=dbVer%></td></tr>
<tr><td>Active Leases</td><td><%=leaseCount%></td><td>of 1000 blocks</td></tr>
<tr><td>Blocks Available</td><td><%=blocksAvail%></td><td>30M ports each</td></tr>
<tr><td>Total Bindings</td><td><%=bindCount%></td><td>AI-gated</td></tr>
<tr><td>Servlet Container</td><td>Online</td><td><%=application.getServerInfo()%></td></tr>
<tr><td>JVM</td><td>Online</td><td><%=System.getProperty("java.version")%></td></tr>
</tbody></table></div></div></section>
<footer class="footer"><div><span>&#169; 2026 MEARVK LLC.</span></div></footer></body></html>
