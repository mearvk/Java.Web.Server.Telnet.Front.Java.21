<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.Properties, java.io.*" %>
<%
    // Handle login POST
    String error = null;
    if ("POST".equals(request.getMethod())) {
        String user = request.getParameter("username");
        String pass = request.getParameter("password");
        // Check against nwe-config admin credentials
        Properties p = new Properties();
        try (InputStream is = application.getResourceAsStream("/WEB-INF/db.properties")) { if (is != null) p.load(is); }
        String adminUser = p.getProperty("admin.user", "mearvk");
        String adminPass = p.getProperty("admin.password", "n21admin");
        if (adminUser.equals(user) && adminPass.equals(pass)) {
            session.setAttribute("admin", user);
            response.sendRedirect("dashboard.jsp");
            return;
        } else {
            error = "Invalid credentials.";
        }
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/>
    <link rel="preconnect" href="https://fonts.googleapis.com"/><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin/><link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:ital,wght@0,300;0,400;0,500;0,600;0,700;1,400;1,600&display=swap" rel="stylesheet"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>Admin Login — Brarner.M.Alete™</title>
    <link rel="stylesheet" href="../css/style.css"/>
    <style>
        .login-box { max-width:380px; margin:0 auto; padding:2.5rem; background:var(--bg-card); border:1px solid var(--border); border-radius:var(--radius-lg); }
        .login-box h2 { text-align:center; margin-bottom:1.5rem; font-size:1.5rem; }
        .form-group { margin-bottom:1.25rem; }
        .form-group label { display:block; font-size:0.8rem; font-weight:600; color:var(--text-secondary); margin-bottom:0.4rem; }
        .form-group input { width:100%; padding:0.65rem 0.75rem; font-size:0.9rem; background:var(--bg-dark); border:1px solid var(--border); border-radius:var(--radius); color:var(--text-primary); }
        .form-group input:focus { border-color:var(--accent); }
    </style>
<script src="../js/scroll-preserve.js"></script>
</head>
<body>
<nav class="nav"><div class="nav-inner">
    <a href="../index.jsp" class="nav-brand">Brarner.M.Alete™</a>
    <ul class="nav-links">
        <li><a href="../index.jsp">Overview</a></li>
        <li><a href="../species.jsp">Species</a></li>
        <li><a href="../status.jsp">Status</a></li>
    </ul>
    <a href="login.jsp" class="nav-cta active">Admin →</a>
</div></nav>

<section class="hero" style="padding:5rem 2rem;">
    <div class="login-box">
        <h2>Admin Login</h2>
<% if (error != null) { %><div style="margin-bottom:1rem;padding:0.75rem;border:1px solid #ef4444;border-radius:8px;color:#ef4444;font-size:0.85rem;"><%= error %></div><% } %>
        <form method="POST" action="login.jsp">
            <div class="form-group"><label for="username">Username</label><input type="text" id="username" name="username" placeholder="admin" required/></div>
            <div class="form-group"><label for="password">Password</label><input type="password" id="password" name="password" placeholder="••••••••" required/></div>
            <button type="submit" class="btn btn-primary" style="width:100%;">Sign In</button>
        </form>
    </div>
</section>

<footer class="footer"><div><span>&#169; 2026 MEARVK LLC. All rights reserved.</span></div></footer>
</body>
</html>
