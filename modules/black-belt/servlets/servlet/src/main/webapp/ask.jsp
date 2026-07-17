<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*, java.util.Properties, java.io.*" %>
<%
    String question = request.getParameter("q");
    String answer = null;

    if (question != null && !question.trim().isEmpty()) {
        question = question.trim();
        String qLower = question.toLowerCase();

        // Keyword-based Q&A for black belt methodology
        if (qLower.contains("white belt") || qLower.contains("beginner")) {
            answer = "White Belt is the entry level — observation and basic understanding. No IQ requirement. You have read-only access to public modules. Focus: learn the system's vocabulary, understand data flow direction, observe without modifying.";
        } else if (qLower.contains("yellow belt")) {
            answer = "Yellow Belt requires IQ 120+. Focus: pattern recognition and data flow comprehension. You gain query access to standard modules. At this level you should understand how modules communicate, recognize protocol patterns (TCP socket commands), and trace data through the pipeline.";
        } else if (qLower.contains("green belt")) {
            answer = "Green Belt requires IQ 140+. Focus: systems integration and speculation. Access to CityAnalysis™ and international signal servers. You begin speculative analysis — training AI models, reading market signals, and integrating multiple data sources into coherent speculation reports.";
        } else if (qLower.contains("brown belt")) {
            answer = "Brown Belt requires IQ 160+. Focus: architecture and eigenvector mathematics. Access to the Eigenvector Math System, frame pipelines, and national observation vectors. You design routing paths (orderly vs virtue), define procedure frames, and work with BasicAnatomy/PerceivedOutput matrices.";
        } else if (qLower.contains("black belt")) {
            answer = "Black Belt requires IQ 180+. Full mastery. Access to all systems including AI training, color assignment (reserved for higher math geniuses), and the complete NIO masquerade layer. You define the system — color assignment, path types, frame dimensions, and forward multipliers. The system serves your design.";
        } else if (qLower.contains("iq") || qLower.contains("requirement")) {
            answer = "IQ Requirements by Belt: White (none), Yellow (120+), Green (140+), Brown (160+), Black (180+). IQ determines access level and the complexity of systems you may operate. The system adapts its responses based on demonstrated comprehension.";
        } else if (qLower.contains("color") || qLower.contains("colour")) {
            answer = "Color assignment is reserved for Black Belt (IQ 180+) practitioners — specifically higher math geniuses (Max Rupplin). Colors are applied to eigenvector output and represent the final interpretive layer of national observation data. Each color carries semantic weight in the output pipeline.";
        } else if (qLower.contains("eigenvector") || qLower.contains("matrix")) {
            answer = "The Eigenvector Math System routes national observation vectors through matrices (BasicAnatomy 5×5 input, PerceivedOutput 5×5 output) via a programmable frame pipeline. Requires Brown Belt minimum. Max hops: 51, frame dimensions: 128×128 min to 4000×12800 max. Path types: Orderly (pass-through) and Virtue (transform independently).";
        } else if (qLower.contains("future") || qLower.contains("completable")) {
            answer = "The Futures™ module uses Java CompletableFuture patterns as protective procedural infrastructure. supplyAsync() for intake, thenCompose() for due process, thenCombine() for parallel vetting, allOf() for consent gates, exceptionally() for ejection (rule of law), and handle() for learning accumulation.";
        } else if (qLower.contains("port") || qLower.contains("masquerade")) {
            answer = "The NIO Masquerade Layer binds 127.0.0.1 through 127.0.0.17. Standard mode: 0–65535 ports. Extended mode: 0–1048576 (65536 per IP across 18 IPs). Modules register via NioModuleScanner at startup. Port 2000 accepts XML forwarding packets for direct routing.";
        } else if (qLower.contains("how") && qLower.contains("start")) {
            answer = "Start at White Belt: read the README, observe the system structure, understand module names and their ports. Progress by demonstrating comprehension — each belt unlocks deeper access. There is no exam; progression is recognized by the Author (Max Rupplin) based on demonstrated mastery.";
        } else if (qLower.contains("discipline") || qLower.contains("principle")) {
            answer = "Core principles: Transparency (no hidden state), Equal Representation (every connection gets equal resources), Due Process (orderly sequential steps), Accountability (every failure reported), Protection of the Vulnerable, Rule of Law (exceptionally()), Peaceful Transfer (graceful shutdown). These are democratic values encoded as system design.";
        } else {
            answer = "I can answer questions about: belt ranks (white/yellow/green/brown/black), IQ requirements, color assignment, eigenvector math, the Futures pipeline, NIO masquerade ports, how to start, and core principles/discipline. Try asking about one of these topics.";
        }

        // Log the question to DB
        Properties dbProps = new Properties(); boolean propsLoaded = false; Connection conn = null;
        try {
            InputStream dbIn = application.getResourceAsStream("/WEB-INF/db.properties");
            if (dbIn != null) { dbProps.load(dbIn); dbIn.close(); propsLoaded = true; }
            if (!propsLoaded) { File f = new File("/opt/tomcat/webapps/blackbelt/WEB-INF/db.properties");
                if (f.exists()) { FileInputStream fis = new FileInputStream(f); dbProps.load(fis); fis.close(); propsLoaded = true; } }
            Class.forName(dbProps.getProperty("db.driver","com.mysql.cj.jdbc.Driver"));
            conn = DriverManager.getConnection(dbProps.getProperty("db.url","jdbc:mysql://127.0.0.1:3306/nwe_blackbelt"),dbProps.getProperty("db.user","root"),dbProps.getProperty("db.password",""));
            conn.createStatement().executeUpdate("CREATE TABLE IF NOT EXISTS questions (id INT AUTO_INCREMENT PRIMARY KEY, question TEXT, answer TEXT, ip VARCHAR(45), asked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)");
            PreparedStatement ps = conn.prepareStatement("INSERT INTO questions (question, answer, ip) VALUES (?, ?, ?)");
            ps.setString(1, question); ps.setString(2, answer);
            String ip = request.getHeader("X-Forwarded-For"); if (ip == null) ip = request.getRemoteAddr();
            ps.setString(3, ip); ps.executeUpdate(); ps.close();
        } catch (Exception ignored) {} finally { if (conn != null) try { conn.close(); } catch (Exception ignored) {} }
    }
%>
<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"/><meta name="viewport" content="width=device-width,initial-scale=1.0"/>
    <link rel="preconnect" href="https://fonts.googleapis.com"/><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin/><link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:ital,wght@0,300;0,400;0,500;0,600;0,700;1,400;1,600&display=swap" rel="stylesheet"/>
<title>Ask — Black Belt™</title><link rel="stylesheet" href="css/style.css"/><script src="js/scroll-preserve.js"></script>
    <script src="js/nwe-readme-viewer.js"></script>
</head><body>
<nav class="nav"><div class="nav-inner"><span class="nav-brand">Black Belt™</span>
<ul class="nav-links"><li><a href="index.jsp">Overview</a></li><li><a href="ask.jsp" class="active">Ask</a></li><li><a href="belts.jsp">Belt Ranks</a></li><li><a href="history.jsp">History</a></li></ul>
</div></nav>
<section class="hero" style="padding:4rem 2rem;"><div class="hero-inner"><span class="hero-tag">Knowledge Base</span><h1>Ask About Methodology</h1></div></section>
<section class="section"><div class="section-inner">
<div class="qa-form">
<form method="get" action="ask.jsp">
<input type="text" name="q" class="qa-input" placeholder="What is the black belt methodology?" value="<%= question != null ? question.replace("\"","&quot;") : "" %>" autocomplete="off"/>
<button type="submit" class="qa-btn">Ask →</button>
</form>
<% if (answer != null) { %>
<div class="qa-answer"><strong style="color:var(--text-primary);">Q:</strong> <%= question.replace("<","&lt;") %><br/><br/><strong style="color:var(--text-primary);">A:</strong> <%= answer %></div>
<% } %>
</div></div></section>
<footer class="footer"><div><span>&#169; 2026 MEARVK LLC. All rights reserved.</span></div></footer></body></html>
