<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width,initial-scale=1" />
  <title>National Finance Engine — Home Suites</title>

  <style>
    :root{
      --color-title: #0B2545; /* dark blue */
      --color-section: #1B3A63;
      --color-subsection: #2B4F80;
      --color-body: #222222;
      --color-link: #0A66C2;
      --carolina-blue: #4B9CD3;
      --max-width: 980px;
      --sidebar-width: 310px;
      --sidebar-bg: #fbfdff;
      --sidebar-border: #e6eef9;
      --line-color: rgba(153,102,255,0.95); /* light purple line */
      --line-fill: rgba(153,102,255,0.18);  /* translucent fill */
    }

    html, body {
      height: 100%;
      margin: 0;
      background: #ffffff;
      color: var(--color-body);
      font-family: "Inter", system-ui, -apple-system, "Segoe UI", Roboto, Arial, sans-serif;
      line-height: 1.6;
      overflow-y: auto;
    }

    .site { display:flex; min-height:100vh; position:relative; box-sizing:border-box; }

    /* Sidebar */
    .sidebar {
      width: var(--sidebar-width);
      min-width: 260px;
      background: var(--sidebar-bg);
      padding: 20px 18px;
      box-sizing: border-box;
      position: sticky;
      top: 0;
      align-self: flex-start;
      max-height: 100vh;
      overflow: auto;
      box-shadow: 2px 0 6px rgba(11,37,69,0.04);
      -ms-overflow-style: none;
      scrollbar-width: none;
    }
    .sidebar::-webkit-scrollbar { display:none; width:0; height:0; }

    .repo-link { display:block; font-weight:700; color:var(--color-title); text-decoration:none; margin-bottom:12px; font-size:0.98rem; }
    .repo-link small { display:block; font-weight:600; color:var(--color-link); margin-top:4px; font-size:0.85rem; }

    .toc-title { color: var(--color-subsection); font-weight:700; margin-bottom:8px; font-size:0.95rem; }
    .sidebar nav ul { list-style:none; padding:0; margin:0; }
    .sidebar nav li { margin:0.45rem 0; }
    .sidebar nav a { color:var(--color-section); text-decoration:none; font-weight:600; font-size:0.95rem; padding:6px 8px; border-radius:6px; display:inline-block; }
    .sidebar nav a:hover { background:#eef6ff; color:var(--color-title); }

    /* Main */
    .main {
      flex:1 1 auto;
      padding:28px;
      box-sizing:border-box;
      max-width: calc(var(--max-width) + var(--sidebar-width));
      margin:0 auto;
      overflow: visible;
    }

    .container { width:95%; max-width: calc(var(--max-width) * 1.05); margin:0 auto; box-sizing:border-box; text-align:left; }

    /* Title area */
    .site-header { margin-bottom:22px; text-align:center; }
    .project-id { color:var(--color-title); font-weight:700; font-size:0.95rem; margin-bottom:8px; }
    .title-stack { display:inline-block; text-align:center; line-height:1.05; padding:6px 12px; border-radius:8px; margin:0 auto 12px auto; }
    .title-line { display:block; font-weight:700; letter-spacing:-0.01em; }
    .title-line.primary { font-size:1.6rem; color:var(--carolina-blue); margin-bottom:6px; }
    .title-line.legal { font-size:1.6rem; color:var(--color-title); margin-bottom:6px; }
    .title-divider { height:2px; width:56%; margin:10px auto 0; background:linear-gradient(90deg, rgba(11,37,69,0.9), rgba(10,102,194,0.85)); border-radius:2px; opacity:0.9; }

    .subtitle { color:#444; margin:0 0 1.2rem 0; font-size:0.98rem; text-align:left; max-width:var(--max-width); margin-left:auto; margin-right:auto; }

    h2 { color:var(--color-section); font-size:1.45rem; margin:1.2rem 0 0.5rem 0; font-weight:600; }
    p, li { color:var(--color-body); font-size:0.98rem; margin:0 0 0.9rem 0; }

    pre { background:#f6f8fa; border-radius:6px; padding:1rem; overflow:auto; font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, "Roboto Mono", monospace; }

    footer { margin-top:2.2rem; color:#666; font-size:0.9rem; text-align:left; }

    /* Progress card */
    .progress-card {
      background:#fff;
      border:1px solid #eef4fb;
      border-radius:8px;
      padding:12px;
      box-shadow:0 1px 4px rgba(16,24,40,0.04);
      margin: 18px 0;
    }
    .progress-header { display:flex; align-items:center; justify-content:space-between; gap:12px; margin-bottom:8px; }
    .progress-title { font-weight:700; color:var(--color-title); font-size:1rem; }
    .progress-sub { color:#666; font-size:0.92rem; }

    .token-row { display:flex; gap:8px; align-items:center; margin-top:8px; }
    .token-row input { padding:6px 8px; border-radius:6px; border:1px solid #e6e9ee; font-size:0.92rem; width:320px; }
    .token-row button { padding:6px 10px; border-radius:6px; border:1px solid #d0d7e6; background:#f7fbff; cursor:pointer; font-weight:600; color:var(--color-title); }

    .status { color:#666; font-size:0.9rem; margin-top:8px; }

    @media (max-width:920px) {
      .site { flex-direction:column; }
      .sidebar { position:relative; width:100%; border-bottom:1px solid var(--sidebar-border); box-shadow:none; max-height:none; }
      .container { width:92%; }
      .token-row input { width:100%; }
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
          <div class="project-id">Java.Web.Server.Telnet.Front.Java.21</div>

          <div class="title-stack" aria-hidden="false">
            <span class="title-line primary">National Finance Engine (NFE)</span>
            <span class="title-line legal">National IQ Conservatorship &amp; Legal Protectorate (NICLP)</span>
            <div class="title-divider" aria-hidden="true"></div>
          </div>

          <p class="subtitle">Modular Java web server and Telnet front end for Java 21. Virtual threads, NIO file handling, and a command‑driven Telnet shell with a centralized <code>Main.java</code> entry point.</p>
        </header>

        <!-- Progress / commits line chart card -->
        <section id="progress" class="progress-card" aria-labelledby="progressTitle">
          <div class="progress-header">
            <div>
              <div id="progressTitle" class="progress-title">Progress</div>
              <div class="progress-sub">Commits (last 52 weeks)</div>
            </div>
            <div id="commitSummary" style="color:#333;font-weight:600;font-size:0.95rem;">Loading…</div>
          </div>

          <canvas id="commitsChart" width="900" height="220" style="width:100%;height:220px;display:block;border-radius:6px;"></canvas>

          <div id="chartNote" class="status">Initializing…</div>

          <div class="token-row" style="margin-top:12px;">
            <input id="ghToken" type="password" placeholder="Optional: paste GitHub token to increase rate limits (session only)" aria-label="GitHub token" />
            <button id="saveTokenBtn" type="button">Use token</button>
            <button id="clearTokenBtn" type="button" style="background:#fff;border:1px solid #f0f0f0;">Clear</button>
          </div>
        </section>

        <!-- Content sections -->
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

  <script>
    (function () {
      const owner = 'mearvk';
      const repo = 'Java.Web.Server.Telnet.Front.Java.21';
      const commitsCanvas = document.getElementById('commitsChart');
      const ctx = commitsCanvas.getContext('2d');
      const summaryEl = document.getElementById('commitSummary');
      const noteEl = document.getElementById('chartNote');
      const tokenInput = document.getElementById('ghToken');
      const saveTokenBtn = document.getElementById('saveTokenBtn');
      const clearTokenBtn = document.getElementById('clearTokenBtn');

      function getToken() {
        return sessionStorage.getItem('gh_token') || '';
      }
      function setToken(t) {
        if (t) sessionStorage.setItem('gh_token', t);
        else sessionStorage.removeItem('gh_token');
      }

      saveTokenBtn.addEventListener('click', () => {
        setToken(tokenInput.value.trim());
        tokenInput.value = '';
        noteEl.textContent = 'Token saved for this session.';
      });
      clearTokenBtn.addEventListener('click', () => {
        setToken('');
        tokenInput.value = '';
        noteEl.textContent = 'Token cleared.';
      });

      // Utility: week start (Sunday) in UTC
      function weekStartUTC(date) {
        const d = new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()));
        const day = d.getUTCDay();
        d.setUTCDate(d.getUTCDate() - day);
        d.setUTCHours(0,0,0,0);
        return d.getTime();
      }

      // Fetch commits via GitHub REST API (paginated) since ISO date
      async function fetchCommitsSince(sinceIso) {
        const perPage = 100;
        let page = 1;
        let allCommits = [];
        const token = getToken();
        const headers = token ? { Authorization: 'token ' + token } : {};
        const baseUrl = `https://api.github.com/repos/${owner}/${repo}/commits`;
        while (true) {
          const url = `${baseUrl}?since=${encodeURIComponent(sinceIso)}&per_page=${perPage}&page=${page}`;
          const res = await fetch(url, { headers });
          if (res.status === 403) {
            const reset = res.headers.get('x-ratelimit-reset');
            throw new Error('Rate limited or access denied. ' + (reset ? 'Reset at ' + new Date(reset*1000).toLocaleString() : ''));
          }
          if (!res.ok) {
            throw new Error('Failed to fetch commits: ' + res.status + ' ' + res.statusText);
          }
          const commits = await res.json();
          if (!Array.isArray(commits) || commits.length === 0) break;
          allCommits = allCommits.concat(commits);
          if (commits.length < perPage) break;
          page++;
          if (page > 50) break;
        }
        return allCommits;
      }

      // Aggregate commits into weekly buckets
      function aggregateWeekly(commits, sinceTs) {
        const weeksMap = new Map();
        const now = Date.now();
        const oneWeekMs = 7 * 24 * 60 * 60 * 1000;
        for (let t = sinceTs; t <= now; t += oneWeekMs) {
          weeksMap.set(t, 0);
        }
        commits.forEach(c => {
          const dateStr = c.commit && c.commit.author && c.commit.author.date;
          if (!dateStr) return;
          const d = new Date(dateStr);
          const wk = weekStartUTC(d);
          if (wk < sinceTs) return;
          weeksMap.set(wk, (weeksMap.get(wk) || 0) + 1);
        });
        const arr = Array.from(weeksMap.entries()).sort((a,b)=>a[0]-b[0]).map(([weekStart,total])=>({weekStart, total}));
        return arr;
      }

      // Draw a smooth line chart with translucent fill
      function drawLineChart(weeklyData) {
        const totals = weeklyData.map(w => w.total);
        const max = Math.max(...totals, 1);
        const padding = 28;
        const deviceRatio = window.devicePixelRatio || 1;
        const clientW = commitsCanvas.clientWidth;
        const clientH = commitsCanvas.clientHeight;
        commitsCanvas.width = Math.round(clientW * deviceRatio);
        commitsCanvas.height = Math.round(clientH * deviceRatio);
        ctx.setTransform(deviceRatio, 0, 0, deviceRatio, 0, 0);
        ctx.clearRect(0,0,clientW,clientH);

        // background
        ctx.fillStyle = '#fff';
        ctx.fillRect(0,0,clientW,clientH);

        const availW = clientW - padding * 2;
        const availH = clientH - padding * 2;
        const pointCount = totals.length;
        const stepX = pointCount > 1 ? availW / (pointCount - 1) : availW;

        // compute points
        const points = totals.map((v, i) => {
          const x = padding + i * stepX;
          const y = padding + (1 - (v / max)) * availH;
          return { x, y, v };
        });

        // draw translucent fill under curve
        ctx.beginPath();
        if (points.length) {
          ctx.moveTo(points[0].x, clientH - padding);
          for (let i = 0; i < points.length; i++) {
            const p = points[i];
            ctx.lineTo(p.x, p.y);
          }
          ctx.lineTo(points[points.length - 1].x, clientH - padding);
          ctx.closePath();
          ctx.fillStyle = getComputedStyle(document.documentElement).getPropertyValue('--line-fill') || 'rgba(153,102,255,0.18)';
          ctx.fill();
        }

        // draw line
        ctx.beginPath();
        for (let i = 0; i < points.length; i++) {
          const p = points[i];
          if (i === 0) ctx.moveTo(p.x, p.y);
          else ctx.lineTo(p.x, p.y);
        }
        ctx.strokeStyle = getComputedStyle(document.documentElement).getPropertyValue('--line-color') || 'rgba(153,102,255,0.95)';
        ctx.lineWidth = 2;
        ctx.lineJoin = 'round';
        ctx.lineCap = 'round';
        ctx.stroke();

        // draw small circles at points
        ctx.fillStyle = getComputedStyle(document.documentElement).getPropertyValue('--line-color') || 'rgba(153,102,255,0.95)';
        for (let p of points) {
          ctx.beginPath();
          ctx.arc(p.x, p.y, 2.5, 0, Math.PI * 2);
          ctx.fill();
        }

        // axis label
        ctx.fillStyle = '#666';
        ctx.font = '12px system-ui, Inter, Arial';
        ctx.textAlign = 'right';
        ctx.fillText('Weekly commits', clientW - 8, 14);
      }

      // Main update flow
      async function updateCommits() {
        try {
          noteEl.textContent = 'Fetching commits via GitHub REST API…';
          const now = new Date();
          const oneWeekMs = 7 * 24 * 60 * 60 * 1000;
          const sinceDate = new Date(now.getTime() - 52 * oneWeekMs);
          const sinceWeekStart = new Date(weekStartUTC(sinceDate));
          const sinceIso = sinceWeekStart.toISOString();

          const commits = await fetchCommitsSince(sinceIso);
          const weekly = aggregateWeekly(commits, sinceWeekStart.getTime());

          // ensure 52 weeks
          if (weekly.length < 52) {
            const full = [];
            for (let i = 0; i < 52; i++) {
              const wk = sinceWeekStart.getTime() + i * oneWeekMs;
              const found = weekly.find(w => w.weekStart === wk);
              full.push(found ? found : { weekStart: wk, total: 0 });
            }
            weekly.splice(0, weekly.length, ...full);
          }

          drawLineChart(weekly);
          const totalYear = weekly.reduce((s,w)=>s+w.total,0);
          const updatedAt = new Date();
          summaryEl.textContent = `${totalYear} commits (last 52 weeks) · updated ${updatedAt.toLocaleString()}`;
          noteEl.textContent = 'Data fetched from GitHub REST commits endpoint.';
        } catch (err) {
          console.warn(err);
          try {
            const token = getToken();
            const headers = token ? { Authorization: 'token ' + token } : {};
            const repoRes = await fetch(`https://api.github.com/repos/${owner}/${repo}`, { headers });
            if (repoRes.ok) {
              const repoJson = await repoRes.json();
              summaryEl.textContent = `${repoJson.full_name} · ${repoJson.stargazers_count} ★ · ${repoJson.forks_count} forks`;
              noteEl.textContent = 'Weekly commit data unavailable; showing repo summary.';
            } else {
              summaryEl.textContent = 'Stats unavailable';
              noteEl.textContent = 'Unable to fetch commit data. Check network or token.';
            }
          } catch (e2) {
            summaryEl.textContent = 'Stats unavailable';
            noteEl.textContent = 'Unable to fetch commit data. Check network or token.';
          }
          // placeholder
          const clientW = commitsCanvas.clientWidth;
          const clientH = commitsCanvas.clientHeight;
          const deviceRatio = window.devicePixelRatio || 1;
          commitsCanvas.width = Math.round(clientW * deviceRatio);
          commitsCanvas.height = Math.round(clientH * deviceRatio);
          ctx.setTransform(deviceRatio, 0, 0, deviceRatio, 0, 0);
          ctx.clearRect(0,0,clientW,clientH);
          ctx.fillStyle = '#f6f8fa';
          ctx.fillRect(0,0,clientW,clientH);
          ctx.fillStyle = '#999';
          ctx.font = '14px system-ui, Inter';
          ctx.textAlign = 'center';
          ctx.fillText('Weekly commit data unavailable', clientW/2, clientH/2);
        }
      }

      // Initial load and periodic refresh
      const REFRESH_INTERVAL_MS = 2 * 60 * 1000; // 2 minutes
      updateCommits().catch(e => console.warn('Initial update failed', e));
      setInterval(() => {
        updateCommits().catch(e => console.warn('Scheduled update failed', e));
      }, REFRESH_INTERVAL_MS);

      // Redraw on resize (debounced)
      let resizeTimer;
      window.addEventListener('resize', () => {
        clearTimeout(resizeTimer);
        resizeTimer = setTimeout(() => {
          updateCommits().catch(()=>{});
        }, 300);
      });

      // initialize token input from sessionStorage
      tokenInput.value = sessionStorage.getItem('gh_token') || '';
    })();
  </script>
</body>
</html>
