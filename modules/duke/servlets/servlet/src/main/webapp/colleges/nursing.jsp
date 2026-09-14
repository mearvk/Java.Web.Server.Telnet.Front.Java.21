<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
String responseMsg = null;
boolean responseOk = false;

if ("POST".equals(request.getMethod())) {
    String senderName = request.getParameter("sender_name");
    String senderEmail = request.getParameter("sender_email");
    String subject = request.getParameter("subject");
    String inquiryType = request.getParameter("inquiry_type");
    String messageBody = request.getParameter("message_body");
    String collegeName = "Duke School of Nursing";
    if (messageBody != null && !messageBody.trim().isEmpty()) {
        String fullMessage = "From: " + senderName + " <" + senderEmail + "> | Subject: " + subject + " | Type: " + inquiryType + " | Message: " + messageBody.trim();
        try (java.net.Socket sock = new java.net.Socket("127.0.0.1", 49213)) {
            sock.setSoTimeout(5000);
            java.io.PrintWriter pw = new java.io.PrintWriter(sock.getOutputStream(), true);
            java.io.BufferedReader br = new java.io.BufferedReader(new java.io.InputStreamReader(sock.getInputStream()));
            br.readLine(); // skip banner
            br.readLine(); // skip commands line
            br.readLine(); // skip blank
            pw.println("QUERY|" + collegeName + "|" + fullMessage);
            String serverResponse = br.readLine();
            pw.println("QUIT");
            responseMsg = serverResponse;
            responseOk = true;
        } catch (Exception e) {
            responseMsg = "Communication error: " + e.getMessage();
            responseOk = false;
        }
    } else {
        responseMsg = "Please enter a message body.";
        responseOk = false;
    }
}
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <title>Duke School of Nursing — Duke University</title>
    <link rel="stylesheet" href="../css/style.css"/>
    <style>
        .response-box { margin: 1.5rem 0; padding: 1rem 1.5rem; border-radius: 6px; font-size: 0.95rem; }
        .response-ok { background: rgba(75,156,211,0.15); border: 1px solid #4B9CD3; color: #4B9CD3; }
        .response-err { background: rgba(220,53,69,0.15); border: 1px solid #dc3545; color: #dc3545; }
    </style>
</head>
<body>

<nav class="nav">
    <a href="../index.jsp">Overview</a>
    <a href="../colleges.jsp">Colleges</a>
    <a href="../query.jsp">Query</a>
    <a href="../messaging.jsp">Messages</a>
    <a href="../status.jsp">Status</a>
</nav>

<section class="hero">
    <h1>Duke School of Nursing</h1>
    <p>Consistently ranked among the top 5 nursing schools in the nation, Duke Nursing combines world-class clinical partnerships with Duke Health and cutting-edge research to advance healthcare.</p>
</section>

<section class="section">
    <h2>Key Facts</h2>
    <div class="table-wrap">
        <table>
            <tr><th>Programs Offered</th><td>Bachelor of Science in Nursing (BSN), Master of Science in Nursing (MSN), Doctor of Nursing Practice (DNP), PhD, Post-Graduate Certificates</td></tr>
            <tr><th>Degrees</th><td>BSN, MSN, DNP, PhD, Post-Graduate Certificates</td></tr>
            <tr><th>Notable Departments</th><td>Acute &amp; Critical Care, Family Health, Community Health, Health Innovation, Nursing Informatics</td></tr>
            <tr><th>Approximate Enrollment</th><td>~1,000 students across all programs</td></tr>
            <tr><th>Rankings</th><td>Top 5 nursing schools nationally</td></tr>
            <tr><th>Clinical Partnerships</th><td>Duke University Health System (DUHS) — integrated clinical training</td></tr>
        </table>
    </div>
</section>

<section class="section">
    <h2>Contact Information</h2>
    <div class="table-wrap">
        <table>
            <tr><th>Website</th><td><a href="https://nursing.duke.edu" target="_blank" rel="noopener">nursing.duke.edu</a></td></tr>
            <tr><th>Phone</th><td>(919) 684-3786</td></tr>
            <tr><th>Address</th><td>307 Trent Drive, DUMC 3322, Durham NC 27710</td></tr>
        </table>
    </div>
</section>

<section class="section">
    <h2>Contact the School of Nursing</h2>
    <% if (responseMsg != null) { %>
        <div class="response-box <%= responseOk ? "response-ok" : "response-err" %>"><%= responseMsg %></div>
    <% } %>
    <form method="POST" action="nursing.jsp">
        <div class="form-group">
            <label for="sender_name">Your Name</label>
            <input type="text" id="sender_name" name="sender_name" required placeholder="Full name"/>
        </div>
        <div class="form-group">
            <label for="sender_email">Your Email</label>
            <input type="email" id="sender_email" name="sender_email" required placeholder="you@example.com"/>
        </div>
        <div class="form-group">
            <label for="subject">Subject</label>
            <input type="text" id="subject" name="subject" required placeholder="Subject of your inquiry"/>
        </div>
        <div class="form-group">
            <label for="inquiry_type">Inquiry Type</label>
            <select id="inquiry_type" name="inquiry_type" required>
                <option value="">— Select —</option>
                <option value="BSN Admissions">BSN Admissions</option>
                <option value="Graduate Admissions">Graduate Admissions</option>
                <option value="DNP Programs">DNP Programs</option>
                <option value="Research Opportunities">Research Opportunities</option>
                <option value="Clinical Partnerships">Clinical Partnerships</option>
            </select>
        </div>
        <div class="form-group">
            <label for="message_body">Message</label>
            <textarea id="message_body" name="message_body" rows="5" required placeholder="Your message..."></textarea>
        </div>
        <button type="submit" class="btn btn-primary">Send Message</button>
    </form>
</section>

<footer class="footer">
    <p>&copy; 2026 Duke University &mdash; Duke School of Nursing</p>
</footer>

</body>
</html>
