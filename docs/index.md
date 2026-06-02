<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width,initial-scale=1" />
  <title>National Finance Engine — Home Suites</title>

  <style>
    :root{
      --color-title: #0B2545; /* current dark blue */
      --color-section: #1B3A63;
      --color-subsection: #2B4F80;
      --color-body: #222222;
      --color-link: #0A66C2;
      --max-width: 980px;
      --content-padding: 28px;
      --line-height: 1.6;
      --font-sans: "Inter", -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
      --sidebar-width: 310px;
      --sidebar-bg: #fbfdff;
      --sidebar-border: #e6eef9;
      --carolina-blue: #4B9CD3; /* light Carolina blue for large titles */
    }

    html, body {
      height: 100%;
      margin: 0;
      background: #ffffff;
      color: var(--color-body);
      font-family: var(--font-sans);
      -webkit-font-smoothing: antialiased;
      -moz-osx-font-smoothing: grayscale;
      line-height: var(--line-height);
      overflow-y: auto;
    }

    .site {
      display: flex;
      min-height: 100vh;
      box-sizing: border-box;
      position: relative;
    }

    /* Sidebar */
    .sidebar {
      width: var(--sidebar-width);
      min-width: 260px;
      background: var(--sidebar-bg);
      border-right: none;
      padding: 20px 18px;
      box-sizing: border-box;
      position: sticky;
      top: 0;
      align-self: flex-start;
      height: auto;
      max-height: 100vh;
      overflow: auto;
      box-shadow: 2px 0 6px rgba(11,37,69,0.04);
      -ms-overflow-style: none;
      scrollbar-width: none;
    }
    .sidebar::-webkit-scrollbar { display: none; width: 0; height: 0; }

    .sidebar .repo-link { display:block; font-weight:700; color:var(--color-title); text-decoration:none; margin-bottom:12px; font-size:0.98rem; }
    .sidebar .repo-link small { display:block; font-weight:600; color:var(--color-link); margin-top:4px; font-size:0.85rem; }

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
    .sidebar nav a:hover { background: #eef6ff; color: var(--color-title); text-decoration: none; }

    .sidebar .toc-title { color: var(--color-subsection); font-weight: 700; margin-bottom: 8px; font-size: 0.95rem; }

    /* Main content: page scrollbar handles vertical scrolling */
    .main {
      flex: 1 1 auto;
      padding: 28px;
      box-sizing: border-box;
      max-width: calc(var(--max-width) + var(--sidebar-width));
      margin: 0 auto;
      overflow: visible;
      max-height: none;
      padding-right: 28px;
    }

    /* Title area */
    .site-header {
      margin-bottom: 22px;
      text-align: center;
    }

    /* Project identifier above title */
    .project-id {
      color: var(--color-title); /* current dark blue */
      font-weight: 700;
      font-size: 0.95rem;
      margin-bottom: 8px;
      letter-spacing: 0.01em;
    }

    .title-stack {
      display: inline-block;
      text-align: center;
      line-height: 1.05;
      padding: 6px 12px;
      border-radius: 8px;
      margin: 0 auto 12px auto;
    }

    .title-line { display:block; font-weight:700; letter-spacing:-0.01em; }

    /* Primary lines use Carolina blue */
    .title-line.primary {
      font-size: 1.6rem;
      margin-bottom: 6px;
      color: var(--carolina-blue);
    }

    /* Secondary small connectors (kept subtle) */
    .title-line.secondary {
      font-size: 1.05rem;
      color: var(--color-section);
      font-weight: 600;
      margin-bottom: 6px;
    }

    /* Legal Protectorate line uses the current dark blue */
    .title-line.legal {
      font-size: 1.6rem;
      margin-bottom: 6px;
      color: var(--color-title);
      font-weight: 700;
    }

    .title-line.tertiary {
      font-size: 0.95rem;
      color: #555;
      font-weight: 600;
      margin-top: 6px;
    }

    .title-divider {
      height: 2px;
      width: 56%;
      margin: 10px auto 0;
      background: linear-gradient(90deg, rgba(11,37,69,0.9), rgba(10,102,194,0.85));
      border-radius: 2px;
      opacity: 0.9;
    }

    /* Container: left-aligned content, constrained width for readability */
    .container {
      width: 100%;
      max-width: var(--max-width);
      margin: 0 auto;
      padding: 0;
      box-sizing: border-box;
      text-align: left;
    }

    .container h1,
    .container h2,
    .container h3,
    .container p,
    .container li,
    .container pre,
    .container code {
      text-align: left;
      margin-left: 0;
      margin-right: 0;
    }

    .container pre, .container code {
      text-align: left;
      max-width: 100%;
      margin: 12px 0;
    }

    header.site-header { margin-bottom: 18px; }

    h1 { color: var(--color-title); font-size: 2.0rem; line-height: 1.12; margin: 0 0 0.6rem 0; font-weight: 700; letter-spacing: -0.01em; }
    .subtitle { color: #444; margin: 0 0 1.2rem 0; font-size: 0.98rem; text-align: left; max-width: var(--max-width); margin-left: auto; margin-right: auto; }

    h2 { color: var(--color-section); font-size: 1.45rem; margin: 1.2rem 0 0.5rem 0; font-weight: 600; }
    h3 { color: var(--color-subsection); font-size: 1.15rem; margin: 1.0rem 0 0.4rem 0; font-weight: 600; }

    p, li { color: var(--color-body); font-size: 0.98rem; margin: 0 0 0.9rem 0; line-height: 1.6; }
    code, pre { font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, "Roboto Mono", "Courier New", monospace; background: #f6f8fa; border-radius: 6px; color: #111827; }
    pre { padding: 1rem; overflow:auto; font-size:0.92rem; margin: 0 0 1rem 0; }

    a { color: var(--color-link); text-decoration: none; font-weight: 600; }
    a:hover { text-decoration: underline; }

    blockquote { border-left: 4px solid var(--sidebar-border); background: #fbfdff; padding: 0.6rem 1rem; margin: 0 0 1rem 0; color: #333; border-radius: 4px; }

    table { border-collapse: collapse; width: 100%; margin: 0.6rem 0 1rem 0; }
    th, td { border: 1px solid #e6e9ee; padding: 0.5rem 0.75rem; text-align: left; font-size: 0.95rem; }
    th { background: #f7fbff; color: var(--color-section); font-weight: 600; }

    footer { margin-top: 2.2rem; color: #666; font-size: 0.9rem; text-align: left; }

    /* Responsive */
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
      .main { padding: 18px; }
      .title-line.primary { font-size: 1.25rem; }
      .title-line.legal { font-size: 1.25rem; }
      .title-line.secondary { font-size: 1rem; }
      .title-divider { width: 72%; }
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

    <main class="main" role="main" aria-label="Main content">
      <div class="container">
        <header class="site-header" role="banner">
          <!-- Project identifier above the title, in current dark blue -->
          <div class="project-id">Java.Web.Server.Telnet.Front.Java.21</div>

          <div class="title-stack" aria-hidden="false">
            <!-- Combined lines with parentheses at end of the lines -->
            <span class="title-line primary">National Finance Engine (NFE)</span>
            <span class="title-line legal">National IQ Conservatorship &amp; Legal Protectorate (NICLP)</span>
            <div class="title-divider" aria-hidden="true"></div>
          </div>

          <p class="subtitle">Modular Java web server and Telnet front end for Java 21. Virtual threads, NIO file handling, and a command‑driven Telnet shell with a centralized <code>Main.java</code> entry point.</p>
        </header>

        <section id="purpose-and-governance-structure">
          <h2>1. Purpose and governance structure</h2>
          <p><strong>The National Finance Engine (NFE)</strong> and the <strong>National IQ Conservatorship &amp; Legal Protectorate (NICLP)</strong> form a dual‑layer digital infrastructure designed to support secure, remote, and ethically governed financial coordination within the United States. Developed by <strong>Max Rupplin</strong>, the framework integrates a national‑grade encrypted trading engine with a state‑aligned analytical and Positionortorship layer represented by <strong>NCIQ (North Carolina IQ)</strong>.</p>
          <p><strong>Note:</strong> NCIQ is not a trading engine; it functions as a state‑level analytical and coordination layer that interfaces with the national system.</p>
        </section>

        <section id="system-architecture">
          <h2>2. System Architecture</h2>
          <p>The NFE architecture combines a <strong>Telnet front‑end</strong> for lightweight, text‑based remote command access with one or more <strong>HTTP servers</strong> serving as authoritative transaction processors. The Telnet interface provides universal accessibility, while the HTTP servers manage cryptographic validation, transaction execution, and integration with blockchain nodes or regulated exchange APIs.</p>
          <p>This separation of concerns supports <strong>transparency</strong>, <strong>operational resilience</strong>, and secure remote access across diverse environments.</p>
        </section>

        <section id="encryption-and-security">
          <h2>3. Encryption and Security</h2>
          <p>The NFE incorporates <strong>AES 2.0</strong>, a next‑generation encryption model associated with federal‑level cryptographic research. AES 2.0 is designed to protect financial communications, secure identity‑related metadata, and maintain confidentiality under advanced threat conditions.</p>
          <p>This security posture aligns with responsible digital‑infrastructure development and supports national‑grade protection standards.</p>
        </section>

        <section id="calendar-coordinated-trading">
          <h2>4. Calendar‑Coordinated Trading</h2>
          <p>The system includes <strong>Calendar‑Coordinated Trading</strong>, enabling synchronized execution of trading actions across domestic and international time zones. This mechanism supports precision timing, coordinated strategy execution, and alignment with national operational windows.</p>
          <p>The calendar layer reinforces predictability and structured coordination across distributed environments.</p>
        </section>

        <section id="access-model-and-operational-resilience">
          <h2>5. Access Model and Operational Resilience</h2>
          <p>The Telnet‑based access model emphasizes <strong>universality, resilience, and minimalism</strong>. Its text‑driven interface ensures compatibility with legacy systems, low‑bandwidth networks, and secure or restricted terminals.</p>
          <p>This approach reduces attack surface and supports continuity planning. The distributed HTTP server model enhances <strong>fault tolerance</strong>, allowing the system to remain operational even when individual nodes experience degradation or failure.</p>
        </section>

        <section id="state-level-analytical-layer">
          <h2>6. State‑Level Analytical Layer (NICLP / NCIQ)</h2>
          <p>The <strong>National IQ Conservatorship &amp; Legal Protectorate (NICLP)</strong> provides a state‑aligned analytical and Positionortorship framework that supports structured coordination with the national system.</p>
          <p>Within this structure, <strong>NCIQ (North Carolina IQ)</strong> serves as the state‑level implementation. It provides a standardized environment for managing financial positions and coordinating strategies in alignment with national‑grade digital infrastructure.</p>
          <p><strong>NCIQ does not execute trades</strong>; it interfaces with the NFE to ensure structured, compliant, and technically aligned participation.</p>
        </section>

        <section id="federated-digital-finance-model">
          <h2>7. Federated Digital‑Finance Model</h2>
          <p>Together, the NFE and NICLP form a <strong>federated digital‑finance ecosystem</strong>, enabling national‑level cryptographic infrastructure, state‑level analytical autonomy, and secure, coordinated financial operations.</p>
          <p>This model supports regulatory adaptability and clear operational boundaries between national and state systems.</p>
        </section>

        <section id="international-coordination-and-compliance">
          <h2>8. International Coordination and Compliance</h2>
          <p>The NFE supports <strong>international trading coordination</strong> while maintaining compliance with U.S. national‑security protocols. Its encrypted, calendar‑synchronized environment enables cross‑border participation without exposing sensitive data to foreign intermediaries.</p>
          <p>This design aligns with responsible stewardship of digital‑finance capabilities and emerging standards for secure global financial interaction.</p>
        </section>

        <section id="open-source-transparency">
          <h2>9. Open‑Source Transparency</h2>
          <p>The project’s open‑source publication promotes independent verification, community collaboration, and transparent evaluation of security claims.</p>
          <p>This transparency aligns with ethical principles of public accountability and verifiable implementation.</p>
        </section>

        <section id="strategic-relevance">
          <h2>10. Strategic Relevance</h2>
          <p>As digital assets become more integrated into global markets, the need for secure, remote, and censorship‑resistant financial infrastructure continues to grow. The NFE’s combination of strong encryption, distributed architecture, lightweight access, and calendar‑based coordination positions it as a potential model for future national or regional financial systems.</p>
          <p>The system also reflects broader trends toward digital sovereignty, where secure, self‑governed digital infrastructures are prioritized over reliance on private platforms.</p>
        </section>

        <section id="summary">
          <h2>11. Summary</h2>
          <p>The National Finance Engine and the National IQ Conservatorship &amp; Legal Protectorate represent a structured, ethically grounded approach to secure digital‑finance coordination. Their emphasis on transparency, resilience, encryption, and state‑aligned governance provides a foundation for responsible participation in modern digital markets.</p>
        </section>

        <footer>
          <p>Documentation generated for <a href="https://github.com/mearvk/Java.Web.Server.Telnet.Front.Java.21" target="_blank" rel="noopener">mearvk/Java.Web.Server.Telnet.Front.Java.21</a>. For technical details, see the repository code and wiki pages.</p>
        </footer>
      </div>
    </main>
  </div>
</body>
</html>
