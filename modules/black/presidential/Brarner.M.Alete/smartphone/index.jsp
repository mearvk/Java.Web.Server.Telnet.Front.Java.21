<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.net.*, java.io.*" %>
<%
    String ghKeyUrl = "https://raw.githubusercontent.com/mearvk/Java.Web.Server.Telnet.Front.Java.21/main/psychiatry/secrets/public.key";
    boolean authorized = false;
    try { HttpURLConnection hc = (HttpURLConnection) new URL(ghKeyUrl).openConnection(); hc.setRequestMethod("HEAD"); hc.setConnectTimeout(5000); authorized = (hc.getResponseCode() == 200); hc.disconnect(); } catch (Exception e) {}
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=5.0, user-scalable=yes"/>
    <meta name="theme-color" content="#0a0a0f"/>
    <meta name="apple-mobile-web-app-capable" content="yes"/>
    <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent"/>
    <link rel="icon" type="image/png" href="../servlets/servlet/src/main/webapp/images/favicon.png"/>
    <title>BMA™ — Overview</title>
    <link rel="stylesheet" href="css/mobile.css"/>
</head>
<body>

<!-- Top Nav -->
<nav class="m-nav">
    <a href="index.jsp" class="m-nav-brand"><img src="../servlets/servlet/src/main/webapp/images/mearvk.ltd.logo.left.png" alt=""/>BMA™</a>
    <button id="m-hamburger" class="m-hamburger" aria-label="Menu"><span></span><span></span><span></span></button>
</nav>
<div id="m-menu" class="m-menu">
    <a href="index.jsp" class="active">Overview</a>
    <a href="species.jsp">Species</a>
    <a href="postal.jsp">Postal</a>
    <a href="art.jsp">Art</a>
    <a href="science.jsp">Science</a>
    <a href="legal.jsp">Legal Database</a>
    <a href="status.jsp">Status</a>
    <a href="settings.jsp">Settings</a>
</div>

<!-- Hero -->
<div class="m-hero">
    <span class="m-hero-tag">NC Socialist-College Block</span>
    <h1>Brarner.M.Alete™</h1>
    <p>Presidential species, postal, SSA, art, science, and legal module — MEARVK LLC</p>
</div>

<!-- CD1 Connector -->
<div class="m-cd1-wrap">
    <button id="m-cd1-btn" class="m-cd1-btn"><img src="../servlets/servlet/src/main/webapp/images/black.button.png" alt="Connector"/></button>
</div>
<div id="m-cd1-overlay" class="m-cd1-overlay"></div>
<div id="m-cd1-dialog" class="m-cd1-dialog">
    <div class="cd1-header">BMA Connector — Overview</div>
    <select id="cd1-action">
        <option value="connect">Connect</option>
        <option value="disconnect">Disconnect</option>
        <option value="status">Status</option>
        <option value="setport">Set Port</option>
        <option value="unsetport">Unset Port</option>
        <option value="saveconfig">Save Config</option>
    </select>
    <div class="cd1-controls">
        <input id="cd1-port" type="number" min="18400" max="49152" value="18500"/>
        <select id="cd1-role"><option value="guest">Guest</option><option value="user">User</option><option value="admin">Admin</option></select>
    </div>
    <div class="cd1-controls">
        <button class="cd1-btn-action" onclick="cd1Send()">Send</button>
        <button class="cd1-btn-action" onclick="cd1Ok()">OK</button>
    </div>
    <textarea id="cd1-textarea" placeholder="Connection idle..."></textarea>
</div>

<% if (authorized) { %>
<!-- Module Cards -->
<div class="m-section">
    <h2>Modules</h2>
    <div class="m-card"><div class="m-card-title">Species</div><div class="m-card-value">Animalia</div><div class="m-card-note">Phyla, classes, orders</div></div>
    <div class="m-card"><div class="m-card-title">Postal</div><div class="m-card-value">55 Cities</div><div class="m-card-note">NC post offices</div></div>
    <div class="m-card"><div class="m-card-title">Art</div><div class="m-card-value">20 Museums</div><div class="m-card-note">NC galleries & collections</div></div>
    <div class="m-card"><div class="m-card-title">Science</div><div class="m-card-value">Research</div><div class="m-card-note">Publications & sources</div></div>
    <div class="m-card"><div class="m-card-title">Legal Database</div><div class="m-card-value">6.8M</div><div class="m-card-note">Court opinions, USC, precedent</div></div>
    <div class="m-card"><div class="m-card-title">SSA</div><div class="m-card-value">50 States</div><div class="m-card-note">Social Security offices</div></div>
</div>
<% } else { %>
<div class="m-section" style="color:#fecaca;">Authorization Revoked — public.key not found.</div>
<% } %>

<!-- Bottom Nav -->
<nav class="m-bottom-nav">
    <a href="index.jsp"><span class="nav-icon">🏠</span>Home</a>
    <a href="legal.jsp"><span class="nav-icon">⚖️</span>Legal</a>
    <a href="status.jsp"><span class="nav-icon">📊</span>Status</a>
    <a href="settings.jsp"><span class="nav-icon">⚙️</span>Settings</a>
</nav>

<script src="js/mobile.js"></script>
</body>
</html>
