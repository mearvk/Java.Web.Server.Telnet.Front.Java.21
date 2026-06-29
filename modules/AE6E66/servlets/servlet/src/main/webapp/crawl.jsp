<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.io.*" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>Crawl — AE6E66™</title>
    <link rel="stylesheet" href="css/style.css"/>
</head>
<body>
<nav class="nav"><div class="nav-inner">
    <span class="nav-brand">AE6E66™</span>
    <ul class="nav-links">
        <li><a href="index.jsp">Overview</a></li>
        <li><a href="contacts.jsp">Contacts</a></li>
        <li><a href="sent.jsp">Sent</a></li>
        <li><a href="status.jsp">Status</a></li>
    </ul>
    <div class="nav-actions"><span class="nav-cta" style="opacity:0.7;cursor:default;">Crawl</span></div>
</div></nav>

<section class="hero" style="padding:4rem 2rem;">
    <div class="hero-inner">
        <span class="hero-tag">Parliament Crawler</span>
        <h1>Crawl Status</h1>
        <p>Crawls members.parliament.uk member IDs 0–999 for contact data and portraits.</p>
    </div>
</section>

<section class="section">
    <div class="section-inner">
<%
    // Check last crawl date
    String configDir = application.getRealPath("/") != null ?
        new File(application.getRealPath("/")).getParent() + "/../../../configuration" :
        "/home/mearvk/IdeaProjects/Java.Web.Server.Telnet.Front.Java.21/modules/AE6E66/configuration";
    File lastCrawlFile = new File(configDir, ".last-crawl");
    String lastCrawl = "Never";
    boolean crawlNeeded = true;
    if (lastCrawlFile.exists()) {
        BufferedReader br = new BufferedReader(new FileReader(lastCrawlFile));
        lastCrawl = br.readLine();
        br.close();
        if (lastCrawl != null && !lastCrawl.isEmpty()) {
            try {
                long crawlTime = java.text.DateFormat.getDateInstance().parse(lastCrawl).getTime();
                crawlNeeded = (System.currentTimeMillis() - crawlTime) > 30L * 24 * 60 * 60 * 1000;
            } catch (Exception ignored) {}
        }
    }
%>
        <div class="table-wrap">
            <table>
                <thead><tr><th>Property</th><th>Value</th></tr></thead>
                <tbody>
                    <tr><td>Last Crawl</td><td><%= lastCrawl %></td></tr>
                    <tr><td>Crawl Needed</td><td style="color:<%= crawlNeeded ? "#ef4444" : "#22c55e" %>;"><%= crawlNeeded ? "Yes (>30 days)" : "No (within 30 days)" %></td></tr>
                    <tr><td>Target</td><td><code>members.parliament.uk/member/{0..999}/contact</code></td></tr>
                    <tr><td>Policy</td><td>Skip if .last-crawl &lt; 30 days old</td></tr>
                    <tr><td>Force Re-crawl</td><td><code>rm modules/AE6E66/configuration/.last-crawl</code></td></tr>
                </tbody>
            </table>
        </div>
        <div style="margin-top:2rem;">
            <p style="font-size:0.85rem;color:var(--text-muted);">To trigger a crawl, run on the server:</p>
            <pre style="background:var(--bg-card);padding:1rem;border-radius:8px;margin-top:0.5rem;font-size:0.8rem;color:var(--text-secondary);overflow-x:auto;">java -cp modules/AE6E66/source source.AE6E66Main</pre>
        </div>
    </div>
</section>

<footer class="footer"><div><span>&#169; 2026 MEARVK LLC. All rights reserved.</span></div></footer>
</body>
</html>
