<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.Properties, java.io.*" %>
<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"/><meta name="viewport" content="width=device-width,initial-scale=1.0"/>
    <link rel="preconnect" href="https://fonts.googleapis.com"/><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin/><link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:ital,wght@0,300;0,400;0,500;0,600;0,700;1,400;1,600&display=swap" rel="stylesheet"/>
<title>History — Languages™</title><link rel="stylesheet" href="css/style.css"/><script src="js/scroll-preserve.js"></script>
    <script src="js/nwe-readme-viewer.js"></script>
</head><body>
<nav class="nav"><div class="nav-inner"><span class="nav-brand">Languages™</span>
<ul class="nav-links"><li><a href="index.jsp">Overview</a></li><li><a href="translate.jsp">Translate</a></li><li><a href="history.jsp" class="active">History</a></li></ul>
</div></nav>
<section class="hero" style="padding:4rem 2rem;"><div class="hero-inner"><h1>Translation History</h1></div></section>
<section class="section"><div class="section-inner">
<%  Properties dbProps = new Properties(); boolean propsLoaded = false; Connection conn = null;
    try { InputStream dbIn = application.getResourceAsStream("/WEB-INF/db.properties");
        if (dbIn != null) { dbProps.load(dbIn); dbIn.close(); propsLoaded = true; }
        if (!propsLoaded) { File f = new File("/opt/tomcat/webapps/languages/WEB-INF/db.properties");
            if (f.exists()) { FileInputStream fis = new FileInputStream(f); dbProps.load(fis); fis.close(); propsLoaded = true; } }
        Class.forName(dbProps.getProperty("db.driver","com.mysql.cj.jdbc.Driver"));
        conn = DriverManager.getConnection(dbProps.getProperty("db.url","jdbc:mysql://127.0.0.1:3306/nwe_languages"),dbProps.getProperty("db.user","root"),dbProps.getProperty("db.password",""));
        ResultSet rs = conn.createStatement().executeQuery("SELECT source_text, from_lang, to_lang, ip, translated_at FROM translations ORDER BY translated_at DESC LIMIT 30");
%><div class="table-wrap"><table><thead><tr><th>Text</th><th>From</th><th>To</th><th>IP</th><th>Time</th></tr></thead><tbody>
<% boolean has=false; while(rs.next()){has=true; String txt=rs.getString("source_text"); %><tr><td><%= txt!=null?(txt.length()>60?txt.substring(0,60).replace("<","&lt;")+"…":txt.replace("<","&lt;")):"" %></td><td><code><%=rs.getString("from_lang")%></code></td><td><code><%=rs.getString("to_lang")%></code></td><td><code><%=rs.getString("ip")%></code></td><td><%=rs.getTimestamp("translated_at")%></td></tr>
<% } if(!has){ %><tr><td colspan="5" style="text-align:center;color:var(--text-muted);">No translations yet. <a href="translate.jsp">Translate something →</a></td></tr><% } rs.close();
    } catch(Exception e) { %><p style="color:#ef4444;"><%=e.getMessage()!=null?e.getMessage().replace("<","&lt;"):"DB not ready"%></p>
<% } finally { if(conn!=null) try{conn.close();}catch(Exception ignored){} } %>
</tbody></table></div></div></section>
<footer class="footer"><div><span>&#169; 2026 MEARVK LLC. All rights reserved.</span></div></footer></body></html>
