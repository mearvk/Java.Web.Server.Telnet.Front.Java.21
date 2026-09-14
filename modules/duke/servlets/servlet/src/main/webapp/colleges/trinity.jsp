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
        String collegeName = "Trinity College of Arts and Sciences";
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
    <title>Trinity College of Arts &amp; Sciences — Duke University</title>
    <link rel="stylesheet" href="../css/style.css"/>
    <style>
        .response-box {
            margin: 1.5rem 0;
            padding: 1rem 1.5rem;
            border-radius: 6px;
            font-size: 0.95rem;
        }
        .response-ok {
            background: rgba(75, 156, 211, 0.15);
            border: 1px solid #4B9CD3;
            color: #4B9CD3;
        }
        .response-error {
            background: rgba(220, 53, 69, 0.15);
            border: 1px solid #dc3545;
            color: #dc3545;
        }
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
        <h1>Trinity College of Arts &amp; Sciences</h1>
        <p>Duke's undergraduate liberal arts college — the intellectual heart of the university, offering rigorous education across the humanities, natural sciences, and social sciences.</p>
    </section>

    <section class="section">
        <h2>Key Facts</h2>
        <div class="table-wrap">
            <table>
                <tr><th>Programs Offered</th><td>35 departments across humanities, natural sciences, and social sciences</td></tr>
                <tr><th>Degrees</th><td>Bachelor of Arts (A.B.), Bachelor of Science (B.S.)</td></tr>
                <tr><th>Notable Departments</th><td>English, Biology, Political Science, Chemistry, Economics, Computer Science, History, Mathematics, Physics</td></tr>
                <tr><th>Approximate Enrollment</th><td>~6,500 undergraduates</td></tr>
            </table>
        </div>
    </section>

    <section class="section">
        <h2>Contact Information</h2>
        <div class="table-wrap">
            <table>
                <tr><th>Website</th><td><a href="https://trinity.duke.edu" style="color:#4B9CD3;">trinity.duke.edu</a></td></tr>
                <tr><th>Phone</th><td>(919) 684-2813</td></tr>
                <tr><th>Address</th><td>104 Allen Building, Box 90024, Durham NC 27708</td></tr>
            </table>
        </div>
    </section>

    <section class="section">
        <h2>Contact Trinity College</h2>
        <p>Send an inquiry directly to Trinity College of Arts &amp; Sciences.</p>

        <% if (responseMsg != null) { %>
            <div class="response-box <%= responseOk ? "response-ok" : "response-error" %>">
                <%= responseMsg %>
            </div>
        <% } %>

        <form method="POST" action="trinity.jsp">
            <div class="form-group">
                <label for="sender_name">Your Name</label>
                <input type="text" id="sender_name" name="sender_name" required placeholder="Full name"/>
            </div>
            <div class="form-group">
                <label for="sender_email">Your Email</label>
                <input type="email" id="sender_email" name="sender_email" required placeholder="email@example.com"/>
            </div>
            <div class="form-group">
                <label for="subject">Subject</label>
                <input type="text" id="subject" name="subject" required placeholder="Subject of your inquiry"/>
            </div>
            <div class="form-group">
                <label for="inquiry_type">Inquiry Type</label>
                <select id="inquiry_type" name="inquiry_type" required>
                    <option value="">— Select —</option>
                    <option value="Admissions">Admissions</option>
                    <option value="Academic Programs">Academic Programs</option>
                    <option value="Research Opportunities">Research Opportunities</option>
                    <option value="Student Life">Student Life</option>
                    <option value="Financial Aid">Financial Aid</option>
                </select>
            </div>
            <div class="form-group">
                <label for="message_body">Message</label>
                <textarea id="message_body" name="message_body" rows="5" required placeholder="Your message..."></textarea>
            </div>
            <button type="submit" class="btn btn-primary">Send Inquiry</button>
        </form>
    </section>

    <footer class="footer">
        <p>&copy; 2026 Duke University &mdash; NitroWebExpress Platform</p>
    </footer>
</body>
</html>
