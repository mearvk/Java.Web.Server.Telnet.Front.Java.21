<!doctype html>
<html lang="en">
<head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width,initial-scale=1" />
    <title>National Finance Engine — Home Suites</title>

    <!-- Embedded leadership palette + typographic scale -->
    <style>
        :root{
            --color-title: #0B2545;
            --color-section: #1B3A63;
            --color-subsection: #2B4F80;
            --color-body: #222222;
            --color-link: #0A66C2;
            --max-width: 980px;
            --content-padding: 28px;
            --line-height: 1.6;
            --font-sans: "Inter", -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
            --sidebar-width: 260px;
            --sidebar-bg: #fbfdff;
            --sidebar-border: #e6eef9;
        }

        html,body{
            height:100%;
            margin:0;
            background:#ffffff;
            color:var(--color-body);
            font-family:var(--font-sans);
            -webkit-font-smoothing:antialiased;
            -moz-osx-font-smoothing:grayscale;
            line-height:var(--line-height);
        }

        /* Layout: left sidebar + main content */
        .site {
            display: flex;
            min-height: 100vh;
            box-sizing: border-box;
        }

        /* Sidebar */
        .sidebar {
            width: var(--sidebar-width);
            min-width: 220px;
            background: var(--sidebar-bg);
            /* removed hard vertical divider */
            border-right: none;
            padding: 20px 18px;
            box-sizing: border-box;
            position: sticky;
            top: 0;
            align-self: flex-start;
            /* allow internal scrolling but constrain to viewport */
            height: auto;
            max-height: 100vh;
            overflow: auto;
            /* subtle visual separation without a hard line */
            box-shadow: 2px 0 6px rgba(11,37,69,0.04);
            /* hide visible scrollbars while preserving scroll behavior */
            -ms-overflow-style: none; /* IE and Edge */
            scrollbar-width: none;    /* Firefox */
        }

        /* WebKit browsers (Chrome, Safari, Opera) - hide scrollbar */
        .sidebar::-webkit-scrollbar {
            display: none;
            width: 0;
            height: 0;
        }

        .sidebar .repo-link {
            display:block;
            font-weight:700;
            color:var(--color-title);
            text-decoration:none;
            margin-bottom:12px;
            font-size:0.98rem;
        }
        .sidebar .repo-link small {
            display:block;
            font-weight:600;
            color:var(--color-link);
            margin-top:4px;
            font-size:0.85rem;
        }

        .sidebar nav { margin-top: 12px; }
        .sidebar nav ul { list-style: none; padding: 0; margin: 0; }
        .sidebar nav li { margin: 0.45rem 0; }
        .sidebar nav a {
            color: var(--color-section);
            text-decoration: none;
            font-weight: 600;
            font-size: 0.95rem;
            display: inline-block;
            padding: 6px 8px;
            border-radius: 6px;
        }
        .sidebar nav a:hover {
            background: #eef6ff;
            color: var(--color-title);
            text-decoration: none;
        }

        .sidebar .toc-title {
            color: var(--color-subsection);
            font-weight: 700;
            margin-bottom: 8px;
            font-size: 0.95rem;
        }

        /* Main content */
        .main {
            flex: 1 1 auto;
            padding: 28px;
            box-sizing: border-box;
            max-width: calc(var(--max-width) + var(--sidebar-width));
            margin: 0 auto;
            /* hide visible scrollbar on main content while preserving scroll */
            overflow: auto;
            -ms-overflow-style: none; /* IE and Edge */
            scrollbar-width: none;    /* Firefox */
            max-height: 100vh;
        }

        /* WebKit browsers (Chrome, Safari, Opera) - hide scrollbar on main */
        .main::-webkit-scrollbar {
            display: none;
            width: 0;
            height: 0;
        }

        .container {
            max-width: var(--max-width);
            margin: 0 auto;
            padding: 0;
            box-sizing: border-box;
        }

        header.site-header{
            margin-bottom: 18px;
        }

        h1 {
            color: var(--color-title);
            font-size: 2.0rem;
            line-height: 1.12;
            margin: 0 0 0.6rem 0;
            font-weight: 700;
            letter-spacing: -0.01em;
        }

        .subtitle {
            color: #444;
            margin: 0 0 1.2rem 0;
            font-size: 0.98rem;
        }

        h2 {
            color: var(--color-section);
            font-size: 1.45rem;
            margin: 1.2rem 0 0.5rem 0;
            font-weight: 600;
        }

        h3 {
            color: var(--color-subsection);
            font-size: 1.15rem;
            margin: 1.0rem 0 0.4rem 0;
            font-weight: 600;
        }

        p, li {
            color: var(--color-body);
            font-size: 0.98rem;
            margin: 0 0 0.9rem 0;
        }

        code, pre {
            font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, "Roboto Mono", "Courier New", monospace;
            background: #f6f8fa;
            border-radius: 6px;
            color: #111827;
        }

        pre {
            padding: 1rem;
            overflow:auto;
            font-size:0.92rem;
            margin: 0 0 1rem 0;
        }

        a {
            color: var(--color-link);
            text-decoration: none;
            font-weight: 600;
        }
        a:hover { text-decoration: underline; }

        blockquote {
            border-left: 4px solid var(--sidebar-border);
            background: #fbfdff;
            padding: 0.6rem 1rem;
            margin: 0 0 1rem 0;
            color: #333;
            border-radius: 4px;
        }

        table {
            border-collapse: collapse;
            width: 100%;
            margin: 0.6rem 0 1rem 0;
        }
        th, td {
            border: 1px solid #e6e9ee;
            padding: 0.5rem 0.75rem;
            text-align: left;
            font-size: 0.95rem;
        }
        th {
            background: #f7fbff;
            color: var(--color-section);
            font-weight: 600;
        }

        footer {
            margin-top: 2.2rem;
            color: #666;
            font-size: 0.9rem;
        }

        /* Responsive: collapse sidebar above content on small screens */
        @media (max-width: 920px) {
            .site { flex-direction: column; }
            .sidebar {
                position: relative;
                width: 100%;
                height: auto;
                border-right: none;
                border-bottom: 1px solid var(--sidebar-border);
                box-shadow: none;
                max-height: none;
            }
            .main { padding: 18px; max-height: none; overflow: visible; }
        }

        @media (max-width:720px){
            :root { --max-width: 92%; --content-padding: 18px; }
            h1 { font-size: 1.6rem; }
            h2 { font-size: 1.2rem; }
            h3 { font-size: 1.05rem; }
            .sidebar { padding: 14px; }
            .sidebar nav a { font-size: 0.92rem; }
        }
    </style>
</head>
<body>
<div class="site" role="application">
    <!-- Left navigation sidebar -->
    <aside class="sidebar" role="navigation" aria-label="Documentation navigation">
        <a class="repo-link" href="https://github.com/mearvk/Java.Web.Server.Telnet.Front.Java.21" target="_blank" rel="noopener">
            mearvk / Java.Web.Server.Telnet.Front.Java.21
            <small>Repository · Wiki · Home Suites</small>
        </a>

        <div class="toc-title">Contents</div>
        <nav aria-label="Table of contents">
            <ul>
                <li><a href="#purpose-and-governance-structure">1. Purpose & governance</a></li>
                <li><a href="#system-architecture">2. System architecture</a></li>
                <li><a href="#encryption-and-security">3. Encryption & security</a></li>
                <li><a href="#calendar-coordinated-trading">4. Calendar‑Coordinated Trading</a></li>
                <li><a href="#access-model-and-operational-resilience">5. Access model & resilience</a></li>
                <li><a href="#state-level-analytical-layer">6. State‑level analytical layer</a></li>
                <li><a href="#federated-digital-finance-model">7. Federated model</a></li>
                <li><a href="#international-coordination-and-compliance">8. International coordination</a></li>
                <li><a href="#open-source-transparency">9. Open‑source transparency</a></li>
                <li><a href="#strategic-relevance">10. Strategic relevance</a></li>
                <li><a href="#summary">11. Summary</a></li>
            </ul>
        </nav>

        <hr style="border:none;border-top:1px solid #eef6ff;margin:12px 0;">

        <nav aria-label="Related links">
            <ul>
                <li><a href="https://github.com/mearvk/Java.Web.Server.Telnet.Front.Java.21/wiki" target="_blank" rel="noopener">Wiki Home</a></li>
                <li><a href="https://github.com/mearvk/Java.Web.Server.Telnet.Front.Java.21" target="_blank" rel="noopener">Repository</a></li>
                <li><a href="#summary">Quick summary</a></li>
            </ul>
        </nav>
    </aside>

    <!-- Main content area -->
    <main class="main" role="main">
        <div class="container">
            <header class="site-header" role="banner">
                <h1>National Finance Engine (NFE) &amp; National IQ Conservatorship &amp; Legal Protectorate (NICLP)</h1>
                <p class="subtitle">Modular Java web server and Telnet front end for Java 21. Virtual threads, NIO file handling, and a command‑driven Telnet shell with a centralized <code>Main.java</code> entry point.</p>
            </header>

            <section id="purpose-and-governance-structure">
                <h2>1. Purpose and governance structure</h2>
                <p><strong>The National Finance Engine (NFE)</strong> and the <strong>National IQ Conservatorship &amp; Legal Protectorate (NICLP)</strong> form a dual‑layer digital infrastructure designed to support secure, remote, and ethically governed financial coordination within the United States. Developed by <strong>Max Rupplin</strong>, the framework integrates a national‑grade encrypted trading engine with a state‑aligned analytical and Positionortorship layer represented by <strong>NCIQ (North Carolina IQ)</strong>.</p>
                <p><strong>Note:</strong> NCIQ is not a trading engine; it functions as a state‑level analytical and coordination layer that interfaces with the national system.</p>
            </section>

            <section id="system-architecture">
                <h2>2. System architecture</h2>
                <p>The NFE architecture combines a <strong>Telnet front‑end</strong> for lightweight, text‑based remote command access with one or more <strong>HTTP servers</strong> serving as authoritative transaction processors. The Telnet interface provides universal accessibility, while the HTTP servers manage cryptographic validation, transaction execution, and integration with blockchain nodes or regulated exchange APIs.</p>
                <p>This separation of concerns supports <strong>transparency</strong>, <strong>operational resilience</strong>, and secure remote access across diverse environments.</p>

                <h3>Telnet command handler (illustrative)</h3>
                <pre><code>switch (command) {
    case "status" -> out.println(serverStatus());
    case "register" -> registerHttpNode(args);
    case "trade" -> executeTrade(args);
    default -> out.println("Unknown command");
}</code></pre>

                <h3>Minimal HTTP handler (illustrative)</h3>
                <pre><code>HttpServer server = HttpServer.create(new InetSocketAddress(8080), 0);
server.createContext("/trade", exchange -> {
String body = new String(exchange.getRequestBody().readAllBytes());
TradeRequest req = TradeRequest.parse(body);
TradeResponse res = processTrade(req);
exchange.sendResponseHeaders(200, res.bytes().length);
exchange.getResponseBody().write(res.bytes());
});
server.start();</code></pre>
</section>

            <section id="encryption-and-security">
                <h2>3. Encryption and security</h2>
                <p>The NFE incorporates <strong>AES 2.0</strong>, a next‑generation encryption model associated with federal‑level cryptographic research. AES 2.0 is designed to protect financial communications, secure identity‑related metadata, and maintain confidentiality under advanced threat conditions.</p>
                <p>This security posture aligns with responsible digital‑infrastructure development and supports national‑grade protection standards.</p>

                <h3>AES 2.0 workflow (pseudocode)</h3>
                <pre><code>byte[] encrypted = AES20.encrypt(messageBytes, keyBytes);
byte[] signature = AES20.sign(encrypted, keyBytes);
boolean valid = AES20.verify(encrypted, signature, keyBytes);</code></pre>
</section>

            <section id="calendar-coordinated-trading">
                <h2>4. Calendar‑Coordinated Trading</h2>
                <p>The system includes <strong>Calendar‑Coordinated Trading</strong>, enabling synchronized execution of trading actions across domestic and international time zones. This mechanism supports precision timing, coordinated strategy execution, and alignment with national operational windows.</p>
                <p>The calendar layer reinforces predictability and structured coordination across distributed environments.</p>

                <h3>Scheduled trade execution (illustrative)</h3>
                <pre><code>ZonedDateTime target = ZonedDateTime.parse(requestedTime);
scheduler.schedule(() -> executeTrade(order), target.toInstant());</code></pre>
</section>

            <section id="access-model-and-operational-resilience">
                <h2>5. Access model and operational resilience</h2>
                <p>The Telnet‑based access model emphasizes <strong>universality, resilience, and minimalism</strong>. Its text‑driven interface ensures compatibility with legacy systems, low‑bandwidth networks, and secure or restricted terminals. This approach reduces attack surface and supports continuity planning.</p>
                <p>The distributed HTTP server model enhances <strong>fault tolerance</strong>, allowing the system to remain operational even when individual nodes experience degradation or failure.</p>

                <h3>Telnet session loop (illustrative)</h3>
                <pre><code>while (session.isOpen()) {
    out.print("&gt; ");
    String command = in.readLine();
    handleCommand(command);
}</code></pre>
</section>

            <section id="state-level-analytical-layer">
                <h2>6. State‑level analytical layer (NICLP / NCIQ)</h2>
                <p>The <strong>National IQ Conservatorship &amp; Legal Protectorate (NICLP)</strong> provides a state‑aligned analytical and Positionortorship framework that supports structured coordination with the national system. Within this structure, <strong>NCIQ (North Carolina IQ)</strong> serves as the state‑level implementation. It provides a standardized environment for managing financial positions and coordinating strategies in alignment with national‑grade digital infrastructure.</p>
                <p><strong>NCIQ does not execute trades</strong>; it interfaces with the NFE to ensure structured, compliant, and technically aligned participation.</p>
            </section>

            <section id="federated-digital-finance-model">
                <h2>7. Federated digital‑finance model</h2>
                <p>Together, the NFE and NICLP form a <strong>federated digital‑finance ecosystem</strong>, enabling national‑level cryptographic infrastructure, state‑level analytical autonomy, and secure, coordinated financial operations. This model supports regulatory adaptability and clear operational boundaries between national and state systems.</p>
            </section>

            <section id="international-coordination-and-compliance">
                <h2>8. International coordination and compliance</h2>
                <p>The NFE supports <strong>international trading coordination</strong> while maintaining compliance with U.S. national‑security protocols. Its encrypted, calendar‑synchronized environment enables cross‑border participation without exposing sensitive data to foreign intermediaries.</p>
                <p>This design aligns with responsible stewardship of digital‑finance capabilities and emerging standards for secure global financial interaction.</p>
            </section>

            <section id="open-source-transparency">
                <h2>9. Open‑source transparency</h2>
                <p>Publishing the project as open source promotes independent verification, community collaboration, and transparent evaluation of security claims. Transparency aligns with ethical principles of public accountability and verifiable implementation.</p>
            </section>

            <section id="strategic-relevance">
                <h2>10. Strategic relevance</h2>
                <p>As digital assets integrate into global markets, the need for <strong>secure, remote, and censorship‑resistant financial infrastructure</strong> grows. The NFE’s combination of strong encryption, distributed architecture, lightweight access, and calendar‑based coordination positions it as a potential model for future national or regional financial systems.</p>
                <p>The system also reflects trends toward <strong>digital sovereignty</strong>, where secure, self‑governed digital infrastructures are prioritized over reliance on private platforms.</p>
            </section>

            <section id="summary">
                <h2>11. Summary</h2>
                <p>The <strong>National Finance Engine</strong> and the <strong>National IQ Conservatorship &amp; Legal Protectorate</strong> represent a structured, ethically grounded approach to secure digital‑finance coordination. Their emphasis on transparency, resilience, encryption, and state‑aligned governance provides a foundation for responsible participation in modern digital markets.</p>
            </section>

            <footer>
                <p>Documentation generated for <a href="https://github.com/mearvk/Java.Web.Server.Telnet.Front.Java.21" target="_blank" rel="noopener">mearvk/Java.Web.Server.Telnet.Front.Java.21</a>. For technical details, see the repository code and wiki pages.</p>
            </footer>
        </div>
    </main>
</div>
</body>
</html>
