<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.Properties, java.io.*" %>
<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"/><meta name="viewport" content="width=device-width,initial-scale=1.0"/>
<title>History — Black Belt™</title><link rel="stylesheet" href="css/style.css"/><script src="js/scroll-preserve.js"></script>
</head><body>
<nav class="nav"><div class="nav-inner"><span class="nav-brand">Black Belt™</span>
<ul class="nav-links"><li><a href="index.jsp">Overview</a></li><li><a href="ask.jsp">Ask</a></li><li><a href="belts.jsp">Belt Ranks</a></li><li><a href="history.jsp" class="active">History</a></li></ul>
</div></nav>
<section class="hero" style="padding:4rem 2rem;"><div class="hero-inner"><h1>Question History</h1><p>Recent questions asked about black belt methodology.</p></div></section>
<section class="section"><div class="section-inner">
<%  Properties dbProps = new Properties(); boolean propsLoaded = false; Connection conn = null;
    try { InputStream dbIn = application.getResourceAsStream("/WEB-INF/db.properties");
        if (dbIn != null) { dbProps.load(dbIn); dbIn.close(); propsLoaded = true; }
        if (!propsLoaded) { File f = new File("/opt/tomcat/webapps/blackbelt/WEB-INF/db.properties");
            if (f.exists()) { FileInputStream fis = new FileInputStream(f); dbProps.load(fis); fis.close(); propsLoaded = true; } }
        Class.forName(dbProps.getProperty("db.driver","com.mysql.cj.jdbc.Driver"));
        conn = DriverManager.getConnection(dbProps.getProperty("db.url","jdbc:mysql://127.0.0.1:3306/nwe_blackbelt"),dbProps.getProperty("db.user","root"),dbProps.getProperty("db.password",""));
        ResultSet rs = conn.createStatement().executeQuery("SELECT question, answer, ip, asked_at FROM questions ORDER BY asked_at DESC LIMIT 30");
%><div class="table-wrap"><table><thead><tr><th>Question</th><th>IP</th><th>Asked</th></tr></thead><tbody>
<% boolean has=false; while(rs.next()){has=true; %><tr><td><%= rs.getString("question") != null ? rs.getString("question").replace("<","&lt;") : "" %></td><td><code><%=rs.getString("ip")%></code></td><td><%=rs.getTimestamp("asked_at")%></td></tr>
<% } if(!has){ %><tr><td colspan="3" style="text-align:center;color:var(--text-muted);">No questions asked yet. <a href="ask.jsp">Ask one →</a></td></tr><% } rs.close();
    } catch(Exception e) { %><p style="color:#ef4444;"><%=e.getMessage()!=null?e.getMessage().replace("<","&lt;"):"DB not ready — run deploy script"%></p>
<% } finally { if(conn!=null) try{conn.close();}catch(Exception ignored){} } %>
</tbody></table></div></div></section>
<footer class="footer"><div><span>&#169; 2026 MEARVK LLC. All rights reserved.</span></div></footer></body></html>
