<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.net.*, java.io.*" %>
<%
    String ghKeyUrl = "https://raw.githubusercontent.com/mearvk/Java.Web.Server.Telnet.Front.Java.21/main/psychiatry/secrets/public.key";
    boolean authorized = false;
    try { HttpURLConnection hc = (HttpURLConnection) new URL(ghKeyUrl).openConnection(); hc.setRequestMethod("HEAD"); hc.setConnectTimeout(5000); authorized = (hc.getResponseCode() == 200); hc.disconnect(); } catch (Exception e) {}
    String searchParam = request.getParameter("q");
    if (searchParam != null) { searchParam = searchParam.trim(); if (searchParam.length() > 200 || searchParam.contains("../") || searchParam.contains("\0")) searchParam = null; }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=5.0, user-scalable=yes"/>
    <meta name="theme-color" content="#0a0a0f"/>
    <link rel="icon" type="image/png" href="../servlets/servlet/src/main/webapp/images/favicon.png"/>
    <title>BMA™ — Legal Database</title>
    <link rel="stylesheet" href="css/mobile.css"/>
<script src="js/scroll-preserve.js"></script>
</head>
<body>

<nav class="m-nav">
    <a href="index.jsp" class="m-nav-brand"><img src="../servlets/servlet/src/main/webapp/images/mearvk.ltd.logo.left.png" alt=""/>BMA™</a>
    <button id="m-hamburger" class="m-hamburger" aria-label="Menu"><span></span><span></span><span></span></button>
</nav>
<div id="m-menu" class="m-menu">
    <a href="index.jsp">Overview</a>
    <a href="species.jsp">Species</a>
    <a href="postal.jsp">Postal</a>
    <a href="art.jsp">Art</a>
    <a href="science.jsp">Science</a>
    <a href="legal.jsp" class="active">Legal Database</a>
    <a href="status.jsp">Status</a>
    <a href="settings.jsp">Settings</a>
</div>

<div class="m-hero">
    <span class="m-hero-tag">US Statutory Law & Case Law</span>
    <h1>Legal Database</h1>
    <p>US Code, case law, precedent, citations — GovInfo, CourtListener, Harvard CAP</p>
</div>

<!-- CD1 Connector (Touch) -->
<div class="m-cd1-wrap">
    <button id="m-cd1-btn" class="m-cd1-btn"><img src="../servlets/servlet/src/main/webapp/images/black.button.png" alt="Connector"/></button>
</div>
<div id="m-cd1-overlay" class="m-cd1-overlay"></div>
<div id="m-cd1-dialog" class="m-cd1-dialog">
    <div class="cd1-header">BMA Connector — Legal Database</div>
    <select id="cd1-action">
        <option value="counts">Whole Law Counts</option>
        <option value="precedent">Landmark Precedent</option>
        <option value="uscode">US Code Titles</option>
        <option value="caselaw">Case Law Stats</option>
        <option value="status">Server Status</option>
        <option value="setport">Set Port</option>
        <option value="unsetport">Unset Port</option>
        <option value="saveconfig">Save Config</option>
    </select>
    <div class="cd1-controls">
        <input id="cd1-port" type="number" min="18500" max="18507" value="18500"/>
        <select id="cd1-role"><option value="guest">Guest</option><option value="user">User</option><option value="admin">Admin</option></select>
    </div>
    <div class="cd1-controls">
        <button class="cd1-btn-action" onclick="cd1Send()">Send</button>
        <button class="cd1-btn-action" onclick="cd1Ok()">OK</button>
    </div>
    <textarea id="cd1-textarea" placeholder="Connection idle..."></textarea>
</div>

<% if (authorized) { %>

<!-- Whole Law Counts (Cards) -->
<div class="m-section">
    <h2>Whole Law Counts</h2>
    <div class="m-card"><div class="m-card-title">US Code Titles <span class="source-badge source-govinfo">GovInfo</span></div><div class="m-card-value">54</div><div class="m-card-note">27 positive law</div></div>
    <div class="m-card"><div class="m-card-title">USC Sections <span class="source-badge source-govinfo">GovInfo</span></div><div class="m-card-value">~200,000</div><div class="m-card-note">All titles combined</div></div>
    <div class="m-card"><div class="m-card-title">Court Opinions <span class="source-badge source-courtlistener">CourtListener</span></div><div class="m-card-value">6.8M</div><div class="m-card-note">1658–2026</div></div>
    <div class="m-card"><div class="m-card-title">Public Laws <span class="source-badge source-govinfo">GovInfo</span></div><div class="m-card-value">45</div><div class="m-card-note">119th Congress (2025–2026)</div></div>
    <div class="m-card"><div class="m-card-title">Precedents <span class="source-badge source-courtlistener">CourtListener</span></div><div class="m-card-value">24</div><div class="m-card-note">Key SCOTUS decisions</div></div>
    <div class="m-card"><div class="m-card-title">Sources <span class="source-badge source-harvard">Harvard</span></div><div class="m-card-value">3</div><div class="m-card-note">GovInfo + CourtListener + Harvard</div></div>
</div>

<!-- Search -->
<div class="m-section">
    <h2>Search</h2>
    <form method="get" action="legal.jsp" class="m-search">
        <input type="text" name="q" placeholder="Search case law, titles, precedent..." value="<%= searchParam != null ? searchParam.replace("\"","&quot;") : "" %>" maxlength="200"/>
        <button type="submit">Search</button>
    </form>
</div>

<!-- Landmark Precedent (Collapsible) -->
<div class="m-section">
    <h2>Landmark Precedent</h2>
    <div class="m-collapsible-header">Marbury v. Madison (1803)</div>
    <div class="m-collapsible-body">5 U.S. 137 — Judicial Review. Courts can strike down unconstitutional laws.</div>
    <div class="m-collapsible-header">Brown v. Board (1954)</div>
    <div class="m-collapsible-body">347 U.S. 483 — Civil Rights. Ended school segregation.</div>
    <div class="m-collapsible-header">Miranda v. Arizona (1966)</div>
    <div class="m-collapsible-body">384 U.S. 436 — Criminal Procedure. Miranda warnings required.</div>
    <div class="m-collapsible-header">Citizens United v. FEC (2010)</div>
    <div class="m-collapsible-body">558 U.S. 310 — First Amendment. Corporate political speech protected.</div>
    <div class="m-collapsible-header">Obergefell v. Hodges (2015)</div>
    <div class="m-collapsible-body">576 U.S. 644 — Equal Protection. Same-sex marriage nationwide.</div>
    <div class="m-collapsible-header">Dobbs v. Jackson (2022)</div>
    <div class="m-collapsible-body">597 U.S. 215 — Privacy. Overruled Roe v. Wade.</div>
    <div class="m-collapsible-header">Loper Bright v. Raimondo (2024)</div>
    <div class="m-collapsible-body">144 S.Ct. 2244 — Admin Law. Overruled Chevron deference.</div>
</div>

<!-- Port Map -->
<div class="m-section">
    <h2>Port Map</h2>
    <div class="m-card"><div class="m-card-title">18500</div><div class="m-card-value">Case Law</div></div>
    <div class="m-card"><div class="m-card-title">18501</div><div class="m-card-value">US Code</div></div>
    <div class="m-card"><div class="m-card-title">18502</div><div class="m-card-value">Public Laws</div></div>
    <div class="m-card"><div class="m-card-title">18503</div><div class="m-card-value">Precedent</div></div>
    <div class="m-card"><div class="m-card-title">18504</div><div class="m-card-value">Statutes</div></div>
    <div class="m-card"><div class="m-card-title">18505</div><div class="m-card-value">CFR</div></div>
    <div class="m-card"><div class="m-card-title">18506</div><div class="m-card-value">Counts</div></div>
    <div class="m-card"><div class="m-card-title">18507</div><div class="m-card-value">Citations</div></div>
</div>

<% } else { %>
<div class="m-section" style="color:#fecaca;">Authorization Revoked — public.key not found.</div>
<% } %>

<nav class="m-bottom-nav">
    <a href="index.jsp"><span class="nav-icon">🏠</span>Home</a>
    <a href="legal.jsp"><span class="nav-icon">⚖️</span>Legal</a>
    <a href="status.jsp"><span class="nav-icon">📊</span>Status</a>
    <a href="settings.jsp"><span class="nav-icon">⚙️</span>Settings</a>
</nav>

<script src="js/mobile.js"></script>
</body>
</html>
