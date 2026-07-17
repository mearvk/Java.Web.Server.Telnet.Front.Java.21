<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.net.*, java.io.*" %>
<%
    boolean authorized = false;
    String authMsg = "Checking...";
    try {
        java.net.HttpURLConnection conn = (java.net.HttpURLConnection) java.net.URI.create(
            "https://raw.githubusercontent.com/mearvk/Java.Web.Server.Telnet.Front.Java.21/main/psychiatry/secrets/public.key"
        ).toURL().openConnection();
        conn.setRequestMethod("HEAD"); conn.setConnectTimeout(5000); conn.setReadTimeout(5000);
        int code = conn.getResponseCode(); conn.disconnect();
        if (code == 200) { authorized = true; authMsg = "Authorized \u2014 public.key present"; }
        else { authMsg = "NOT AUTHORIZED"; }
    } catch (Exception e) { authMsg = "Check failed"; }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/>
    <link rel="preconnect" href="https://fonts.googleapis.com"/><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin/><link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:ital,wght@0,300;0,400;0,500;0,600;0,700;1,400;1,600&display=swap" rel="stylesheet"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>FOIA — CaliforniaCIA™</title>
    <link rel="stylesheet" href="css/style.css"/>
    <script src="js/scroll-preserve.js"></script>
    <script src="js/nwe-readme-viewer.js"></script>
</head>
<body>
<nav class="nav"><div class="nav-inner">
    <span class="nav-brand">CaliforniaCIA™</span>
    <ul class="nav-links">
        <li><a href="index.jsp">Overview</a></li>
        <li><a href="report.jsp">Report</a></li>
        <li><a href="foia.jsp" class="active">FOIA</a></li>
        <li><a href="search.jsp">Search</a></li>
        <li><a href="status.jsp">Status</a></li>
    </ul>
</div></nav>

<section class="hero"><div class="hero-inner">
    <span class="hero-tag">Freedom of Information Act</span>
    <h1>FOIA</h1>
    <p>Submit and track Freedom of Information Act requests. Access declassified documents and records through the CIA's FOIA portal.</p>
</div></section>
<div style="text-align:center;padding:0.5rem;font-size:0.7rem;color:<%= authorized ? "#22c55e" : "#dc2626" %>;"><%= authMsg %></div>

<!-- CD1 Connector Button + Floating Dialog -->
<div style="display:flex;justify-content:center;align-items:center;width:100%;padding:2rem 0;">
    <button id="cd1-btn" type="button" aria-pressed="false" style="all:unset;display:block;margin:0 auto;cursor:pointer;padding:0;border:none;background:transparent;transition:transform 0.3s cubic-bezier(0.42,-1.84,0.42,1.84),filter 0.3s ease;">
        <img src="images/black.button.png" alt="Connector" style="display:block;width:80px;height:80px;border-radius:50%;background:transparent;"/>
    </button>
</div>
<div id="cd1-overlay" style="display:none;position:fixed;inset:0;z-index:299;background:transparent;"></div>
<div id="cd1-dialog" style="display:none;position:fixed;top:50%;left:50%;transform:translate(-50%,-50%);z-index:300;background:#1a1a24;border:1px solid #27272a;border-radius:12px;padding:1.25rem;width:520px;max-width:90vw;box-shadow:0 8px 32px rgba(0,0,0,0.6);"><div style="font-size:0.9rem;font-weight:600;color:#a3e635;margin-bottom:0.75rem;">CIA FOIA Connector &#8212; Port 49211</div><div style="display:flex;gap:0.5rem;margin-bottom:0.75rem;"><select id="cd1-action" style="background:#111118;color:#fff;border:1px solid #27272a;border-radius:8px;padding:0.45rem;font-size:0.8rem;"><option value="connect">Connect</option><option value="foia">FOIA Request</option><option value="status">Status</option></select><button onclick="cd1Send()" style="background:#65a30d;color:#fff;border:none;border-radius:8px;padding:0.45rem 1rem;font-size:0.8rem;cursor:pointer;">Send</button><button onclick="cd1Ok()" style="background:#65a30d;color:#fff;border:none;border-radius:8px;padding:0.45rem 1rem;font-size:0.8rem;cursor:pointer;">OK</button></div><label style="font-size:0.7rem;color:#71717a;"><input type="checkbox" id="cd1-direct-port"/> Direct Port</label><textarea id="cd1-textarea" placeholder="Idle..." style="width:100%;min-height:120px;background:#fff;color:#111;border:1px solid #27272a;border-radius:8px;padding:0.75rem;font-family:monospace;font-size:0.8rem;margin-top:0.5rem;resize:vertical;"></textarea></div>
<script>window.CD1_MODULE_PORT="49211";</script>
<script src="js/cd1-connector.js"></script>

<section class="section"><div class="section-inner" style="max-width:700px;margin:0 auto;">
    <h2 style="color:#a3e635;">Submit FOIA Request</h2>
    <form method="POST" action="foia.jsp">
        <div class="form-group"><label>Subject / Topic</label><input type="text" name="subject" required placeholder="e.g. Operation name, document title, event, person"/></div>
        <div class="form-group"><label>Date Range (optional)</label>
            <div style="display:flex;gap:0.75rem;">
                <input type="text" name="date_from" placeholder="From (YYYY-MM-DD)" style="flex:1;"/>
                <input type="text" name="date_to" placeholder="To (YYYY-MM-DD)" style="flex:1;"/>
            </div>
        </div>
        <div class="form-group"><label>Requestor Name</label><input type="text" name="requestor" required placeholder="Your full legal name"/></div>
        <div class="form-group"><label>Email</label><input type="email" name="email" required placeholder="Contact email for response"/></div>
        <div class="form-group"><label>Justification / Details</label><textarea name="details" placeholder="Describe what you're looking for and why..."></textarea></div>
        <button type="submit" class="btn btn-primary">Submit FOIA Request</button>
    </form>
</div></section>

<section class="section"><div class="section-inner">
    <h2 style="color:#a3e635;">FOIA Resources</h2>
    <div class="table-wrap"><table>
        <thead><tr><th>Resource</th><th>Description</th></tr></thead>
        <tbody>
            <tr><td><a href="https://www.cia.gov/readingroom/" target="_blank">CIA Reading Room</a></td><td>Electronic reading room with declassified documents</td></tr>
            <tr><td><a href="https://www.cia.gov/readingroom/collection" target="_blank">Document Collections</a></td><td>Themed collections of declassified materials</td></tr>
            <tr><td>FOIA Request via Port 49211</td><td><code>FOIA|subject|requestor|email|details</code></td></tr>
            <tr><td>Track Request</td><td><code>FOIA_STATUS|requestId</code></td></tr>
        </tbody>
    </table></div>
</div></section>

<footer class="footer"><span>CaliforniaCIA™ — FOIA — Port 49211 — MEARVK LLC — NitroWebExpress™ 2026</span></footer>
</body></html>
