<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
    // Set guest cookie for 24 hours
    Cookie guestCookie = null;
    for (Cookie c : request.getCookies() != null ? request.getCookies() : new Cookie[0]) {
        if ("bma_guest".equals(c.getName())) { guestCookie = c; break; }
    }
    if (guestCookie == null) {
        guestCookie = new Cookie("bma_guest", String.valueOf(System.currentTimeMillis()));
        guestCookie.setMaxAge(60 * 60 * 24);
        guestCookie.setPath("/");
        response.addCookie(guestCookie);
    }
    String clientIp = request.getHeader("X-Forwarded-For");
    if (clientIp == null || clientIp.isEmpty()) clientIp = request.getRemoteAddr();
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/>
    <link rel="preconnect" href="https://fonts.googleapis.com"/><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin/><link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:ital,wght@0,300;0,400;0,500;0,600;0,700;1,400;1,600&display=swap" rel="stylesheet"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <link rel="icon" type="image/png" href="images/favicon.png"/>
    <title>Guest — Brarner.M.Alete™</title>
    <link rel="stylesheet" href="css/style.css"/>
<script src="js/scroll-preserve.js"></script>
    <script src="js/nwe-readme-viewer.js"></script>
</head>
<body>
<nav class="nav"><div class="nav-inner">
    <a href="index.jsp" class="nav-brand"><img src="images/mearvk.ltd.logo.left.png" alt="" style="height:40px;vertical-align:middle;margin-right:8px;background:transparent;"/>Brarner.M.Alete™<img src="images/mearvk.ltd.logo.right.png" alt="" style="height:40px;vertical-align:middle;margin-left:8px;background:transparent;"/></a>
    <ul class="nav-links">
        <li><a href="index.jsp">Overview</a></li>
        <li><a href="species.jsp">Species</a></li>
        <li><a href="postal.jsp">Postal</a></li>
        <li><a href="art.jsp">Art</a></li>
        <li><a href="science.jsp">Science</a></li>
        <li><a href="analysis.jsp">Analysis</a></li>
        <li><a href="legal.jsp">Legal</a></li>
        <li><a href="status.jsp">Status</a></li>
    </ul>
    <div class="nav-actions">
        <span class="nav-cta" style="opacity:0.7;cursor:default;">Guest</span>
        <a href="register.jsp" class="nav-cta">Register</a>
        <a href="admin/login.xhtml" class="nav-cta">Admin →</a>
    </div>
</div></nav>

<section class="hero" style="padding:4rem 2rem;">
    <div class="hero-inner">
        <span class="hero-tag">Guest Access</span>
        <h1>Welcome, Guest</h1>
        <p>You are remembered by cookie for <strong>24 hours</strong>.</p>
        <p style="margin-top:1rem;color:#a1a1aa;">Your IP: <code style="color:#3b82f6;"><%= clientIp %></code></p>
    </div>
</section>

<footer class="footer"><div class="footer-bottom">
    <span>&#169; 2026 MEARVK LLC. All rights reserved.</span>
</div></footer>
</body>
</html>
