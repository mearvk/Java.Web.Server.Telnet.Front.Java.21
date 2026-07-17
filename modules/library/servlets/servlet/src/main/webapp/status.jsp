<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.net.*, java.io.*" %>
<%
    String statusData = "";
    try (Socket s = new Socket()) {
        s.connect(new InetSocketAddress("127.0.0.1", 49214), 3000);
        s.setSoTimeout(3000);
        BufferedReader br = new BufferedReader(new InputStreamReader(s.getInputStream()));
        PrintWriter pw = new PrintWriter(s.getOutputStream(), true);
        br.readLine(); pw.println("STATUS"); statusData = br.readLine(); pw.println("QUIT");
    } catch (Exception e) { statusData = "Backend offline: " + e.getMessage(); }
    boolean authorized = false; String authMsg = "";
    try { java.net.HttpURLConnection conn = (java.net.HttpURLConnection) java.net.URI.create("https://raw.githubusercontent.com/mearvk/Java.Web.Server.Telnet.Front.Java.21/main/psychiatry/secrets/public.key").toURL().openConnection(); conn.setRequestMethod("HEAD"); conn.setConnectTimeout(5000); conn.setReadTimeout(5000); if (conn.getResponseCode()==200){authorized=true;authMsg="Authorized \u2014 public.key present";}else{authMsg="NOT AUTHORIZED";} conn.disconnect(); } catch(Exception e){authMsg="Check failed";}
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/>
    <link rel="preconnect" href="https://fonts.googleapis.com"/><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin/><link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:ital,wght@0,300;0,400;0,500;0,600;0,700;1,400;1,600&display=swap" rel="stylesheet"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>Status — StanfordLibrary™</title>
    <link rel="stylesheet" href="css/style.css"/>
    <script src="js/scroll-preserve.js"></script>
    <script src="js/nwe-readme-viewer.js"></script>
</head>
<body>
<nav class="nav"><div class="nav-inner">
    <span class="nav-brand">StanfordLibrary™</span>
    <ul class="nav-links">
        <li><a href="index.jsp">Overview</a></li>
        <li><a href="search.jsp">Search</a></li>
        <li><a href="request.jsp">Request</a></li>
        <li><a href="status.jsp" class="active">Status</a></li>
    </ul>
</div></nav>
<section class="hero"><div class="hero-inner"><span class="hero-tag">System Status</span><h1>Status</h1><p>Backend connectivity and module diagnostics.</p></div></section>
<div style="text-align:center;padding:0.5rem;font-size:0.7rem;color:<%= authorized ? "#22c55e" : "#dc2626" %>;"><%= authMsg %></div>

<!-- CD1 -->
<div style="display:flex;justify-content:center;align-items:center;width:100%;padding:2rem 0;"><button id="cd1-btn" type="button" aria-pressed="false" style="all:unset;display:block;margin:0 auto;cursor:pointer;padding:0;border:none;background:transparent;transition:transform 0.3s cubic-bezier(0.42,-1.84,0.42,1.84),filter 0.3s ease;"><img src="images/black.button.png" alt="Connector" style="display:block;width:80px;height:80px;border-radius:50%;background:transparent;"/></button></div>
<div id="cd1-overlay" style="display:none;position:fixed;inset:0;z-index:299;background:transparent;"></div>
<div id="cd1-dialog" style="display:none;position:fixed;top:50%;left:50%;transform:translate(-50%,-50%);z-index:300;background:#1a1a1a;border:1px solid #333;border-radius:12px;padding:1.25rem;width:520px;max-width:90vw;box-shadow:0 8px 32px rgba(0,0,0,0.6);"><div style="font-size:0.9rem;font-weight:600;color:#ccc;margin-bottom:0.75rem;">Library Connector — Port 49214</div><div style="display:flex;gap:0.5rem;margin-bottom:0.75rem;"><select id="cd1-action" style="background:#222;color:#eee;border:1px solid #444;border-radius:8px;padding:0.45rem;font-size:0.8rem;"><option value="connect">Connect</option><option value="status">Status</option></select><button onclick="cd1Send()" style="background:#666;color:#fff;border:none;border-radius:8px;padding:0.45rem 1rem;font-size:0.8rem;cursor:pointer;">Send</button><button onclick="cd1Ok()" style="background:#666;color:#fff;border:none;border-radius:8px;padding:0.45rem 1rem;font-size:0.8rem;cursor:pointer;">OK</button></div><label style="font-size:0.7rem;color:#888;"><input type="checkbox" id="cd1-direct-port"/> Direct Port</label><textarea id="cd1-textarea" placeholder="Idle..." style="width:100%;min-height:100px;background:#fff;color:#111;border:1px solid #333;border-radius:8px;padding:0.75rem;font-family:monospace;font-size:0.8rem;margin-top:0.5rem;resize:vertical;"></textarea></div>
<script>window.CD1_MODULE_PORT="49214";</script>
<script src="js/cd1-connector.js"></script>

<section class="section"><div class="section-inner">
    <h2>Backend Status</h2>
    <div class="table-wrap"><table><thead><tr><th>Field</th><th>Value</th></tr></thead><tbody>
        <tr><td>Port</td><td><code>49214</code></td></tr>
        <tr><td>Response</td><td><code><%= statusData %></code></td></tr>
        <tr><td>Backend Class</td><td><code>source.StanfordLibraryServer</code></td></tr>
        <tr><td>Database</td><td><code>nwe_library</code></td></tr>
    </tbody></table></div>
</div></section>
<footer class="footer"><span>StanfordLibrary™ — Status — Port 49214 — MEARVK LLC — NitroWebExpress™ 2026</span></footer>
</body></html>
