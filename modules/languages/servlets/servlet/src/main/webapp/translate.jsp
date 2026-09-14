<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.Properties, java.io.*" %>
<%
    String sourceText = request.getParameter("text");
    String fromLang = request.getParameter("from");
    String toLang = request.getParameter("to");
    String translation = null;

    if (sourceText != null && !sourceText.trim().isEmpty() && fromLang != null && toLang != null) {
        sourceText = sourceText.trim();
        if (sourceText.length() > 2000) sourceText = sourceText.substring(0, 2000);

        // AI/heuristic translation (placeholder — real DJL integration for production)
        if (fromLang.equals(toLang)) {
            translation = sourceText;
        } else {
            // Basic phrase markers for demonstration; real deployment uses DJL transformer
            translation = "[" + toLang.toUpperCase() + "] " + sourceText + " [translated from " + fromLang.toUpperCase() + " — DJL model required for full translation]";
        }

        // Log to DB
        Properties dbProps = new Properties(); boolean propsLoaded = false; Connection conn = null;
        try {
            InputStream dbIn = application.getResourceAsStream("/WEB-INF/db.properties");
            if (dbIn != null) { dbProps.load(dbIn); dbIn.close(); propsLoaded = true; }
            if (!propsLoaded) { File f = new File("/opt/tomcat/webapps/languages/WEB-INF/db.properties");
                if (f.exists()) { FileInputStream fis = new FileInputStream(f); dbProps.load(fis); fis.close(); propsLoaded = true; } }
            Class.forName(dbProps.getProperty("db.driver","com.mysql.cj.jdbc.Driver"));
            conn = DriverManager.getConnection(dbProps.getProperty("db.url","jdbc:mysql://127.0.0.1:3306/nwe_languages"),dbProps.getProperty("db.user","root"),dbProps.getProperty("db.password",""));
            conn.createStatement().executeUpdate("CREATE TABLE IF NOT EXISTS translations (id INT AUTO_INCREMENT PRIMARY KEY, source_text TEXT, from_lang VARCHAR(10), to_lang VARCHAR(10), result TEXT, ip VARCHAR(45), translated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)");
            PreparedStatement ps = conn.prepareStatement("INSERT INTO translations (source_text, from_lang, to_lang, result, ip) VALUES (?,?,?,?,?)");
            ps.setString(1, sourceText); ps.setString(2, fromLang); ps.setString(3, toLang); ps.setString(4, translation);
            String ip = request.getHeader("X-Forwarded-For"); if (ip == null) ip = request.getRemoteAddr();
            ps.setString(5, ip); ps.executeUpdate(); ps.close();
        } catch (Exception ignored) {} finally { if (conn != null) try { conn.close(); } catch (Exception ignored) {} }
    }
%>
<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"/><meta name="viewport" content="width=device-width,initial-scale=1.0"/>
    <link rel="preconnect" href="https://fonts.googleapis.com"/><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin/><link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:ital,wght@0,300;0,400;0,500;0,600;0,700;1,400;1,600&display=swap" rel="stylesheet"/>
<title>Translate — Languages™</title><link rel="stylesheet" href="css/style.css"/><script src="js/scroll-preserve.js"></script>
    <script src="js/nwe-readme-viewer.js"></script>
</head><body>
<nav class="nav"><div class="nav-inner"><span class="nav-brand">Languages™</span>
<ul class="nav-links"><li><a href="index.jsp">Overview</a></li><li><a href="translate.jsp" class="active">Translate</a></li><li><a href="history.jsp">History</a></li></ul>
</div></nav>
<section class="hero" style="padding:4rem 2rem;"><div class="hero-inner"><span class="hero-tag">AI Translation</span><h1>Translate</h1>
<p style="font-size:0.85rem;color:var(--text-muted);margin-top:0.5rem;">US Supreme Court — Custody &amp; Control — Original Barrister Class ATX10 Grade</p></div></section>
<section class="section"><div class="section-inner">
<div class="translate-form">
<form method="post" action="translate.jsp">
<div style="display:flex;gap:1rem;margin-bottom:1rem;flex-wrap:wrap;">
<select name="from" class="lang-select">
<option value="en-US" <%= "en-US".equals(fromLang)?"selected":"" %>>American English</option>
<option value="en-GB" <%= "en-GB".equals(fromLang)?"selected":"" %>>English (UK)</option>
<option value="fr" <%= "fr".equals(fromLang)?"selected":"" %>>French</option>
<option value="es" <%= "es".equals(fromLang)?"selected":"" %>>Spanish</option>
<option value="th" <%= "th".equals(fromLang)?"selected":"" %>>Thai</option>
<option value="it" <%= "it".equals(fromLang)?"selected":"" %>>Italian</option>
<option value="de" <%= "de".equals(fromLang)?"selected":"" %>>German</option>
<option value="ja" <%= "ja".equals(fromLang)?"selected":"" %>>Japanese</option>
<option value="zh" <%= "zh".equals(fromLang)?"selected":"" %>>Chinese</option>
<option value="ar" <%= "ar".equals(fromLang)?"selected":"" %>>Arabic</option>
<option value="ru" <%= "ru".equals(fromLang)?"selected":"" %>>Russian</option>
<option value="uk" <%= "uk".equals(fromLang)?"selected":"" %>>Ukrainian</option>
<option value="tr" <%= "tr".equals(fromLang)?"selected":"" %>>Turkish</option>
</select>
<span style="color:var(--text-muted);align-self:center;">→</span>
<select name="to" class="lang-select">
<option value="en-US" <%= "en-US".equals(toLang)?"selected":"" %>>American English</option>
<option value="en-GB" <%= "en-GB".equals(toLang)?"selected":"" %>>English (UK)</option>
<option value="fr" <%= "fr".equals(toLang)?"selected":"" %>>French</option>
<option value="es" <%= "es".equals(toLang)?"selected":"" %>>Spanish</option>
<option value="th" <%= "th".equals(toLang)?"selected":"" %>>Thai</option>
<option value="it" <%= "it".equals(toLang)?"selected":"" %>>Italian</option>
<option value="de" <%= "de".equals(toLang)?"selected":"" %>>German</option>
<option value="ja" <%= "ja".equals(toLang)?"selected":"" %>>Japanese</option>
<option value="zh" <%= "zh".equals(toLang)?"selected":"" %>>Chinese</option>
<option value="ar" <%= "ar".equals(toLang)?"selected":"" %>>Arabic</option>
<option value="ru" <%= "ru".equals(toLang)?"selected":"" %>>Russian</option>
<option value="uk" <%= "uk".equals(toLang)?"selected":"" %>>Ukrainian</option>
<option value="tr" <%= "tr".equals(toLang)?"selected":"" %>>Turkish</option>
</select>
</div>
<textarea name="text" class="translate-input" placeholder="Enter text to translate..."><%= sourceText != null ? sourceText.replace("<","&lt;") : "" %></textarea>
<button type="submit" class="translate-btn">Translate →</button>
</form>
<% if (translation != null) { %>
<div class="result-box">
<strong style="color:var(--accent);font-size:0.8rem;text-transform:uppercase;"><%= toLang %></strong>
<p style="margin-top:0.5rem;color:var(--text-primary);"><%= translation.replace("<","&lt;") %></p>
</div>
<% } %>
</div></div></section>
<footer class="footer"><div><span>&#169; 2026 MEARVK LLC. All rights reserved.</span></div></footer></body></html>
