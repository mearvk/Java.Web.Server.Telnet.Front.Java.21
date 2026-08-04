<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*" %>
<%
    // On Tomcat, redirect immediately to data.jsp
    // On static preview, the meta-refresh below handles it
    try { response.sendRedirect("data.jsp"); return; } catch (Exception e) {}
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/>
    <meta http-equiv="refresh" content="0;url=data.jsp"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>Analytics™ — NitroWebExpress™</title>
    <style>
        body { font-family: -apple-system, sans-serif; background: #0d1117; color: #c9d1d9; display: flex; align-items: center; justify-content: center; min-height: 100vh; margin: 0; }
        .center { text-align: center; }
        h1 { color: #58a6ff; font-size: 1.5rem; margin-bottom: 0.5rem; }
        p { color: #8b949e; }
        a { color: #58a6ff; }
    </style>
</head>
<body>
<div class="center">
    <h1>Analytics™</h1>
    <p>Redirecting to <a href="data.jsp">Traffic Data →</a></p>
</div>
</body>
</html>
