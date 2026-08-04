#!/usr/bin/env python3
"""
NitroWebExpress™ — Local Style Preview Server

Serves module webapp directories as static files for CSS/layout/button preview.
JSP scriptlets won't execute (they show as raw text), but you can check:
  - Color themes and CSS styling
  - Button placement and CD1 connector dialog
  - Page layout and responsiveness
  - Navigation structure

Usage:
    python3 scripts/preview-styles.py [port]

Then open:
    http://localhost:9090/                       — Module index
    http://localhost:9090/defined/               — Defined module (dark gray)
    http://localhost:9090/vietnam/               — Vietnam module (light brown)
    http://localhost:9090/emeter/                — Emeter module (light blue)
    http://localhost:9090/california-fbi/        — FBI module (red)
    http://localhost:9090/futures/               — Futures module (red)
    http://localhost:9090/brarner.m.alete/       — BMA module (blue)
    ... etc.

Press Ctrl+C to stop.
"""

import http.server
import os
import sys
import json

PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 9090
PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# ═══════════════════════════════════════════════════════════════════════════════
# MODULE REGISTRY — Map context paths to webapp source directories
# ═══════════════════════════════════════════════════════════════════════════════
MODULES = {
    # ── Core Modules ──────────────────────────────────────────────────────────
    "vietnam": {
        "path": "modules/vietnam/servlets/servlet/src/main/webapp",
        "theme": "Light Brown",
        "port": 49215,
    },
    "emeter": {
        "path": "modules/emeter/servlets/servlet/src/main/webapp",
        "theme": "Light Blue",
        "port": 49216,
    },
    "california-fbi": {
        "path": "modules/fbi/servlets/servlet/src/main/webapp",
        "theme": "Red",
        "port": 49210,
    },
    "california-cia": {
        "path": "modules/cia/servlets/servlet/src/main/webapp",
        "theme": "Dark Blue",
        "port": 49211,
    },
    "california-nsa": {
        "path": "modules/nsa/servlets/servlet/src/main/webapp",
        "theme": "Black",
        "port": 49212,
    },
    "california-duke": {
        "path": "modules/duke/servlets/servlet/src/main/webapp",
        "theme": "Duke Blue",
        "port": 49213,
    },
    "california-ncsu": {
        "path": "modules/ncsu/servlets/servlet/src/main/webapp",
        "theme": "Wolfpack Red",
        "port": 49217,
    },
    "california-unc": {
        "path": "modules/unc/servlets/servlet/src/main/webapp",
        "theme": "Carolina Blue",
        "port": 49218,
    },
    "library": {
        "path": "modules/library/servlets/servlet/src/main/webapp",
        "theme": "Cardinal Red",
        "port": 49214,
    },
    "gray-registry": {
        "path": "modules/gray/servlets/servlet/src/main/webapp",
        "theme": "Gray",
        "port": 9999,
    },
    "gray85-registry": {
        "path": "modules/gray.a85/servlets/servlet/src/main/webapp",
        "theme": "Crème",
        "port": 10085,
    },
    "futures": {
        "path": "modules/red/Futures/servlets/servlet/src/main/webapp",
        "theme": "Red",
        "port": 5000,
    },
    "ae6e66": {
        "path": "modules/AE6E66/servlets/servlet/src/main/webapp",
        "theme": "UK Blue",
        "port": None,
    },
    "blackbelt": {
        "path": "modules/black-belt/servlets/servlet/src/main/webapp",
        "theme": "Black",
        "port": None,
    },
    "languages": {
        "path": "modules/languages/servlets/servlet/src/main/webapp",
        "theme": "White",
        "port": None,
    },
    "brarner.m.alete": {
        "path": "modules/black/presidential/Brarner.M.Alete/servlets/servlet/src/main/webapp",
        "theme": "Presidential Blue",
        "port": 49152,
    },
    "gdgh": {
        "path": "modules/Green.Durham.Grass.and.Herb/servlets/servlet/src/main/webapp",
        "theme": "Green",
        "port": 20000,
    },
    # ── Defined™ — Dark Gray Module ──────────────────────────────────────────
    "defined": {
        "path": "modules/Defined/servlets/servlet/src/main/webapp",
        "theme": "Dark Gray",
        "port": 49220,
        "description": "Definition to narrow cause: defined.",
        "backend_port": 49221,
        "protocols": [20, 21, 22, 25, 80, 443, 465, 587, 990, 993, 3306, 8080],
        "ufw_managed": [22, 443, 465, 587, 990, 993],
        "categories": [
            "banking", "middle-schools", "strong-middle-schools",
            "improbable-activity-youth", "firefights-20-plus-casualties",
            "fire-department-errors-3-plus", "schools-burned-down",
            "misuse-of-scientology", "known-misuse-public-officials",
            "unkind-language-books-reading", "unkind-misuse-heads-of-state",
            "absence-fbi-presence", "absence-border-protection",
            "unequal-treatment-us-treasury", "unequal-footing-us-state-department",
            "private-ownership-lsat", "torturers", "rapists",
            "convicted-murderers", "gods-going-crazy", "anti-god-rhetoric",
            "against-space-nasa", "anti-political-whisper",
            "sovietism-vs-socialism", "failing-schools", "failing-final-tests",
            "non-social-graces", "prayer-against-even-temper", "ntsb",
        ],
        "strernary_feedback": True,
        "connection_hours": "Weekdays 06:00-23:00, Weekends 08:00-20:00 EST",
        "installer_tech_id": "Max Rupplin",
    },
    # ── SpectrumTandem™ — White/Red Module ────────────────────────────────────
    "spectrum-tandem": {
        "path": "modules/spectrum-tandem/servlets/servlet/src/main/webapp",
        "theme": "White Red",
        "port": 49222,
        "description": "Dolyene spectrum of int discipline. Word bank, county precedent, revisions.",
        "installer_tech_id": "Max Rupplin",
    },
    # ── Communicator™ — Deep Blue Module ───────────────────────────────────
    "chat": {
        "path": "modules/chat/servlets/servlet/src/main/webapp",
        "theme": "Deep Blue",
        "port": 49230,
        "description": "Communicator™ — Encrypted chat. DH-2048 + RSA-2048 + AES-256-GCM. Federation, file transfer, voice, admin. No gradients.",
        "installer_tech_id": "Max Rupplin",
    },
    # ── UNCW™ — SeaCoast Teal/Gold Module ─────────────────────────────────────
    "uncw": {
        "path": "modules/uncw/servlets/servlet/src/main/webapp",
        "theme": "SeaCoast Teal",
        "port": 49231,
        "description": "UNCW Wilmington. CS Club, colleges, chancellors, file sharing, audio, messaging.",
        "installer_tech_id": "Max Rupplin",
    },
    # ── Strernary™ — Cyan/AI Module ───────────────────────────────────────────
    "strernary": {
        "path": "source/strernary/servlets/servlet/src/main/webapp",
        "theme": "Cyan",
        "port": 20000,
        "description": "Strernary™ Deep Inference. DJL/PyTorch/DistilBERT. ASK, CLASSIFY, TRAIN, RELAY. Port 20000 + Directory 2000.",
        "installer_tech_id": "Max Rupplin",
    },
    # ── Bitcoin™ — Warm Amber/Gold Module ─────────────────────────────────────
    "bitcoin": {
        "path": "modules/bitcoin/servlets/servlet/src/main/webapp",
        "theme": "Bitcoin Orange",
        "port": 6682,
        "description": "Bitcoin™ wallet management, transactions, trading. bitcoind RPC. Multi-timezone. Strernary AI market analysis.",
        "installer_tech_id": "Max Rupplin",
    },
    # ── CalendarD44™ — Fall Colors Module ──────────────────────────────────────
    "calendar": {
        "path": "modules/calendar/servlets/servlet/src/main/webapp",
        "theme": "Fall Colors",
        "port": 49200,
        "description": "CalendarD44™ scheduling engine. Date routing, interaction logging, scheduled delivery, timezone support.",
        "installer_tech_id": "Max Rupplin",
    },
    # ── TandemEquals™ — White/Red Module (Saimptom Resolution) ─────────────────
    "tandem-equals": {
        "path": "modules/tandem-equals/servlets/servlet/src/main/webapp",
        "theme": "White Red",
        "port": 49223,
        "description": "TandemEquals™ — Outward dilemma resolution via 42x42 saimptom matrix. Stereo mind recovery in ~12 answers. CHOICE + EQUAL NOISE + province wisdom. Kernel-aligned.",
        "installer_tech_id": "Max Rupplin",
    },
    # ── Analytics™ — GitHub Dark Module (Traffic Graphs) ────────────────────────
    "analytics": {
        "path": "modules/analytics/servlets/servlet/src/main/webapp",
        "theme": "GitHub Dark",
        "port": None,
        "description": "Analytics™ — GitHub-style traffic graphs. Page views, unique visitors, uploads, new users, referrers, popular content. Chart.js + MySQL.",
        "installer_tech_id": "Max Rupplin",
    },
    # ── Dictionary™ — Dark Scholarly / Gold Module ────────────────────────────
    "dictionary": {
        "path": "modules/dictionary/servlets/servlet/src/main/webapp",
        "theme": "Scholarly Gold",
        "port": None,
        "description": "Dictionary™ — Defines all rare, new, or system-specific terms (dolyene, saimptom, negamane, etc.). 12 domains, 25+ terms.",
        "installer_tech_id": "Max Rupplin",
    },
    # ── ArmorerSteve™ — Dark Blue / White Module ──────────────────────────────
    "armorer": {
        "path": "modules/armorer/servlets/servlet/src/main/webapp",
        "theme": "Dark Blue",
        "port": 49235,
        "description": "ArmorerSteve™ — Plate armor Q&A, cost estimator, forging methods, known armorers, competition series, regulations, trade, final capacitor trade.",
        "installer_tech_id": "Max Rupplin",
    },
    # ── FiduciaryServices™ — Light Blue / White Module ────────────────────────
    "fiduciary": {
        "path": "modules/fiduciary/servlets/servlet/src/main/webapp",
        "theme": "Light Blue",
        "port": 49236,
        "description": "FiduciaryServices™ — Global Transfer Wealth, fiduciary architectures, yield/turn polyblend, remedy, datapool. Legal Bright INT/IQ Calendar (top-half: ideals/totals for county benefit; bottom-half: Treasure Fiduciary evident approach). AI Findings Order (200 IQ: Garden News doctrine, Supreme Holdings, truth for life). The balance of internal design and the means to necessary advantages. Signed: M.",
        "installer_tech_id": "Max Rupplin",
        "database": "nwe_fiduciary",
        "tables": [
            "knowledge_base", "architectures", "records", "yield_models", "sessions",
            "original_documents", "legal_bright", "treasure_fiduciary",
            "ai_findings_order", "garden_news_doctrine", "ai_disposition",
        ],
        "sql_documents": [
            "modules/fiduciary/documents/minister_fiduciary_facts.sql",
            "modules/fiduciary/documents/legal_bright_iq_calendar.sql",
            "modules/fiduciary/documents/ai_findings_order.sql",
        ],
        "ai_iq": 200,
        "findings_order": [
            "Findings in Order",
            "Court Trials",
            "US Trials",
            "US Garden News",
            "US Certain Garden News",
            "US Trials about Garden News",
            "US Trials about US Garden News",
            "US New Int",
            "Closed US Supreme Holdings and Trials",
        ],
        "garden_news_doctrine": "People are closed. Evidence of hand remains open. Not unto the person forever. Careful. Open, sold. Annals of forever and history. Truth, for life.",
    },
}

# ═══════════════════════════════════════════════════════════════════════════════
# BUILD SERVE DIRECTORY
# ═══════════════════════════════════════════════════════════════════════════════
SERVE_DIR = os.path.join(PROJECT_ROOT, ".preview-serve")
os.makedirs(SERVE_DIR, exist_ok=True)

# Create the main index page
index_html = """<!DOCTYPE html>
<html><head><meta charset="UTF-8"><title>NWE Style Preview</title>
<style>
body { font-family: system-ui, -apple-system, sans-serif; background: #111; color: #eee; padding: 2rem; }
a { color: #60a5fa; text-decoration: none; }
a:hover { color: #93c5fd; text-decoration: underline; }
h1 { color: #fff; margin-bottom: 0.5rem; }
h2 { color: #ccc; margin-top: 2rem; border-bottom: 1px solid #333; padding-bottom: 0.5rem; }
h3 { color: #aaa; }
table { border-collapse: collapse; width: 100%; margin-bottom: 2rem; }
td, th { padding: 0.6rem 1rem; text-align: left; border-bottom: 1px solid #222; }
th { color: #999; background: #1a1a1a; }
tr:hover { background: #1a1a1a; }
.theme-badge { display: inline-block; padding: 2px 8px; border-radius: 3px; font-size: 0.8rem; }
.dark-gray { background: #333; color: #eee; }
.red { background: #7f1d1d; color: #fca5a5; }
.blue { background: #1e3a5f; color: #93c5fd; }
.green { background: #14532d; color: #86efac; }
.brown { background: #5c3d2e; color: #fcd29f; }
.wolfpack-red { background: #CC0000; color: #fff; }
.carolina-blue { background: #4B9CD3; color: #fff; }
.light-blue { background: #1e40af; color: #bfdbfe; }
.black { background: #000; color: #fff; border: 1px solid #333; }
.gray { background: #4b5563; color: #e5e7eb; }
.creme { background: #f5f0e0; color: #333; }
.white { background: #f8f8f8; color: #333; }
.white-red { background: #fff; color: #cc0000; border: 1px solid #cc0000; }
.deep-blue { background: #0a0e1a; color: #6b8aff; border: 1px solid #1e2a4a; }
.seacoast-teal { background: #0a1a1c; color: #00727A; border: 1px solid #1e4a4d; }
.cyan { background: #042f2e; color: #06b6d4; border: 1px solid #0e4f4e; }
.bitcoin-orange { background: #1a1610; color: #f7931a; border: 1px solid #3d3528; }
.fall-colors { background: #1c1610; color: #ea580c; border: 1px solid #4a3828; }
.github-dark { background: #0d1117; color: #58a6ff; border: 1px solid #30363d; }
.scholarly-gold { background: #0c0c10; color: #d4af37; border: 1px solid #2a2a3a; }
.dark-blue { background: #0a0a1a; color: #7ba4d4; border: 1px solid #1e1e3a; }
.section { margin: 1rem 0; padding: 1rem; background: #1a1a1a; border-radius: 8px; border: 1px solid #333; }
.affirmation { color: #d4af37; font-style: italic; margin: 1rem 0; padding: 1rem; border-left: 3px solid #d4af37; }
code { background: #222; padding: 2px 6px; border-radius: 3px; font-size: 0.9rem; }
</style></head><body>

<h1>NitroWebExpress&trade; &mdash; Module Preview Server</h1>
<p style="color:#999;">JSP server-side code won't execute (shows as raw text). CSS/JS/layout works normally.<br>
Serving from: <code>""" + PROJECT_ROOT + """</code></p>

<div class="affirmation">
US well in condition. US well loved. US is well in authority of command of the United States.
Well affirmed. Based on army, country and constitution. God is with America. And Max Rupplin.
For law and tech We stand. These Affirm We. Thus. This. A. America.
</div>

<h2>All Modules</h2>
<table>
<thead><tr><th>Context</th><th>Theme</th><th>Backend Port</th><th>Status</th></tr></thead>
<tbody>
"""

for ctx, info in sorted(MODULES.items()):
    path_val = info["path"] if isinstance(info, dict) else info
    theme = info.get("theme", "") if isinstance(info, dict) else ""
    port = info.get("port", "") if isinstance(info, dict) else ""
    full = os.path.join(PROJECT_ROOT, path_val)
    exists = os.path.isdir(full)
    status = "✓ Available" if exists else "— No webapp"
    port_str = str(port) if port else "—"

    theme_class = theme.lower().replace(" ", "-") if theme else ""
    theme_badge = f'<span class="theme-badge {theme_class}">{theme}</span>' if theme else ""

    if exists:
        link = f'<a href="/{ctx}/index.jsp">/{ctx}/</a>'
    else:
        link = f'<code>/{ctx}/</code>'

    index_html += f'<tr><td>{link}</td><td>{theme_badge}</td><td>{port_str}</td><td>{status}</td></tr>\n'

index_html += "</tbody></table>\n"

# ── Defined Module Detail Section ─────────────────────────────────────────────
index_html += """
<h2>Defined&trade; &mdash; Dark Gray Module (Port 49220)</h2>
<div class="section">
<p><strong>Definition to narrow cause: defined.</strong></p>
<p>Kinded and Secondary (implied as good). Installer Tech ID: Max Rupplin.</p>
<p style="color:#f87171;"><strong>NOTICE:</strong> Known trespass against final medical review may result in being discharged from Earth forever.</p>

<h3>Backend Telnet (Port 49221)</h3>
<p><code>telnet localhost 49221</code> &mdash; Protocol management, credentials, UFW control</p>
<p>Connection hours: Weekdays 06:00-23:00, Weekends 08:00-20:00 EST</p>

<h3>AI Server (Port 49220)</h3>
<p><code>telnet localhost 49220</code> &mdash; AI surveillance, moral assessment, NTSB communication</p>
<p>Scans: 4x daily (00:00, 06:00, 12:00, 18:00 EST) | Strernary feedback enabled</p>

<h3>Protocol Handlers (12 ports)</h3>
<table>
<thead><tr><th>Port</th><th>Protocol</th><th>Direction</th><th>UFW</th></tr></thead>
<tbody>
<tr><td>20</td><td>FTP-DATA</td><td>outbound</td><td>persistent</td></tr>
<tr><td>21</td><td>FTP</td><td>bidirectional</td><td>persistent</td></tr>
<tr><td>22</td><td>SSH</td><td>outbound</td><td>managed (open/close)</td></tr>
<tr><td>25</td><td>SMTP</td><td>outbound</td><td>persistent</td></tr>
<tr><td>80</td><td>HTTP</td><td>outbound</td><td>persistent</td></tr>
<tr><td>443</td><td>HTTPS (TLSv1.3)</td><td>outbound</td><td>managed (open/close)</td></tr>
<tr><td>465</td><td>SMTPS (implicit TLS)</td><td>outbound</td><td>managed (open/close)</td></tr>
<tr><td>587</td><td>SMTP Submission (STARTTLS)</td><td>outbound</td><td>managed (open/close)</td></tr>
<tr><td>990</td><td>FTPS (implicit TLS)</td><td>outbound</td><td>managed (open/close)</td></tr>
<tr><td>993</td><td>IMAPS (SSL IMAP)</td><td>outbound</td><td>managed (open/close)</td></tr>
<tr><td>3306</td><td>MySQL</td><td>local</td><td>persistent</td></tr>
<tr><td>8080</td><td>HTTP-ALT (Tomcat)</td><td>bidirectional</td><td>persistent</td></tr>
</tbody>
</table>

<h3>Categories (29)</h3>
<table>
<thead><tr><th>#</th><th>Category</th><th>Data Folder</th></tr></thead>
<tbody>
"""

categories = [
    "banking", "middle-schools", "strong-middle-schools",
    "improbable-activity-youth", "firefights-20-plus-casualties",
    "fire-department-errors-3-plus", "schools-burned-down",
    "misuse-of-scientology", "known-misuse-public-officials",
    "unkind-language-books-reading", "unkind-misuse-heads-of-state",
    "absence-fbi-presence", "absence-border-protection",
    "unequal-treatment-us-treasury", "unequal-footing-us-state-department",
    "private-ownership-lsat", "torturers", "rapists",
    "convicted-murderers", "gods-going-crazy", "anti-god-rhetoric",
    "against-space-nasa", "anti-political-whisper",
    "sovietism-vs-socialism", "failing-schools", "failing-final-tests",
    "non-social-graces", "prayer-against-even-temper", "ntsb",
]

for i, cat in enumerate(categories, 1):
    index_html += f'<tr><td>{i}</td><td>{cat}</td><td><code>data/categories/{cat}/</code></td></tr>\n'

index_html += """</tbody></table>

<h3>Reports</h3>
<table>
<thead><tr><th>Period</th><th>Priority Weights</th><th>Output</th></tr></thead>
<tbody>
<tr><td>Weekly</td><td>8, 8, 8, 1, 1</td><td><code>reports/weekly/</code></td></tr>
<tr><td>Monthly</td><td>40, 32, 1, 8, 1</td><td><code>reports/monthly/</code></td></tr>
<tr><td>Quarterly</td><td>12, 1, 2, 6, 8, 1, 10</td><td><code>reports/quarterly/</code></td></tr>
<tr><td>Half-Year</td><td>5, 5, 2, 1, 5</td><td><code>reports/half-year/</code></td></tr>
<tr><td>Annual</td><td>6, 2, 1, 2, 1, 6</td><td><code>reports/annual/</code> + <code>annual/</code></td></tr>
<tr><td>2-Year</td><td>accumulated</td><td><code>annual/</code></td></tr>
<tr><td>5-Year</td><td>accumulated</td><td><code>annual/</code></td></tr>
<tr><td>10-Year</td><td>accumulated</td><td><code>annual/</code></td></tr>
</tbody></table>

<h3>Strernary&trade; Feedback</h3>
<p>Folder: <code>data/strernary-feedback/</code> &mdash; International source and/or flavor from Strernary AI (port 20000).</p>
</div>

<h2>Main Server Links</h2>
<div class="section">
<table>
<thead><tr><th>Service</th><th>Port</th><th>Access</th></tr></thead>
<tbody>
<tr><td>NitroWebExpress Main</td><td>49152</td><td><code>telnet localhost 49152</code></td></tr>
<tr><td>Strernary AI</td><td>20000</td><td><code>telnet localhost 20000</code></td></tr>
<tr><td>Strernary Directory</td><td>2000</td><td><code>telnet localhost 2000</code></td></tr>
<tr><td>Communicator (Encrypted Chat)</td><td>49199</td><td><code>telnet localhost 49199</code></td></tr>
<tr><td>AES Encryption</td><td>5512</td><td><code>telnet localhost 5512</code></td></tr>
<tr><td>RSA Encryption</td><td>7743</td><td><code>telnet localhost 7743</code></td></tr>
<tr><td>DSA Encryption</td><td>7744</td><td><code>telnet localhost 7744</code></td></tr>
<tr><td>Bitcoin</td><td>6682</td><td><code>telnet localhost 6682</code></td></tr>
<tr><td>Connection Status</td><td>49155</td><td><code>telnet localhost 49155</code></td></tr>
<tr><td>ASCII Creator</td><td>49177</td><td><code>telnet localhost 49177</code></td></tr>
<tr><td>Module Installation</td><td>49166</td><td><code>telnet localhost 49166</code></td></tr>
<tr><td>Binary HTTP</td><td>49144</td><td><code>telnet localhost 49144</code></td></tr>
<tr><td>Tomcat (All Webapps)</td><td>8080</td><td><a href="http://localhost:8080/">http://localhost:8080/</a></td></tr>
</tbody></table>
</div>

<h2>Module Web Frontends (Tomcat 8080)</h2>
<div class="section">
<table>
<thead><tr><th>Module</th><th>URL</th><th>Theme</th><th>Backend Port</th></tr></thead>
<tbody>
<tr><td>Defined™</td><td><a href="http://localhost:8080/defined/">http://localhost:8080/defined/</a></td><td><span class="theme-badge dark-gray">Dark Gray</span></td><td>49220</td></tr>
<tr><td>Futures™</td><td><a href="http://localhost:8080/futures/">http://localhost:8080/futures/</a></td><td><span class="theme-badge red">Red</span></td><td>5000</td></tr>
<tr><td>CaliforniaFBI</td><td><a href="http://localhost:8080/california-fbi/">http://localhost:8080/california-fbi/</a></td><td><span class="theme-badge red">Red</span></td><td>49210</td></tr>
<tr><td>CaliforniaCIA</td><td><a href="http://localhost:8080/california-cia/">http://localhost:8080/california-cia/</a></td><td><span class="theme-badge blue">Dark Blue</span></td><td>49211</td></tr>
<tr><td>CaliforniaNSA</td><td><a href="http://localhost:8080/california-nsa/">http://localhost:8080/california-nsa/</a></td><td><span class="theme-badge black">Black</span></td><td>49212</td></tr>
<tr><td>DukeUniversity</td><td><a href="http://localhost:8080/california-duke/">http://localhost:8080/california-duke/</a></td><td><span class="theme-badge blue">Duke Blue</span></td><td>49213</td></tr>
<tr><td>NC State University</td><td><a href="http://localhost:8080/california-ncsu/">http://localhost:8080/california-ncsu/</a></td><td><span class="theme-badge wolfpack-red">Wolfpack Red</span></td><td>49217</td></tr>
<tr><td>UNC Chapel Hill</td><td><a href="http://localhost:8080/california-unc/">http://localhost:8080/california-unc/</a></td><td><span class="theme-badge carolina-blue">Carolina Blue</span></td><td>49218</td></tr>
<tr><td>StanfordLibrary</td><td><a href="http://localhost:8080/library/">http://localhost:8080/library/</a></td><td><span class="theme-badge red">Cardinal Red</span></td><td>49214</td></tr>
<tr><td>Vietnam</td><td><a href="http://localhost:8080/vietnam/">http://localhost:8080/vietnam/</a></td><td><span class="theme-badge brown">Light Brown</span></td><td>49215</td></tr>
<tr><td>Emeter</td><td><a href="http://localhost:8080/emeter/">http://localhost:8080/emeter/</a></td><td><span class="theme-badge light-blue">Light Blue</span></td><td>49216</td></tr>
<tr><td>GrayPortRegistry</td><td><a href="http://localhost:8080/gray-registry/">http://localhost:8080/gray-registry/</a></td><td><span class="theme-badge gray">Gray</span></td><td>9999</td></tr>
<tr><td>Gray85Crème</td><td><a href="http://localhost:8080/gray85-registry/">http://localhost:8080/gray85-registry/</a></td><td><span class="theme-badge creme">Crème</span></td><td>10085</td></tr>
<tr><td>AE6E66</td><td><a href="http://localhost:8080/ae6e66/">http://localhost:8080/ae6e66/</a></td><td><span class="theme-badge blue">UK Blue</span></td><td>—</td></tr>
<tr><td>Green.Durham</td><td><a href="http://localhost:8080/gdgh/">http://localhost:8080/gdgh/</a></td><td><span class="theme-badge green">Green</span></td><td>20000</td></tr>
<tr><td>Black Belt</td><td><a href="http://localhost:8080/blackbelt/">http://localhost:8080/blackbelt/</a></td><td><span class="theme-badge black">Black</span></td><td>—</td></tr>
<tr><td>Languages</td><td><a href="http://localhost:8080/languages/">http://localhost:8080/languages/</a></td><td><span class="theme-badge white">White</span></td><td>—</td></tr>
<tr><td>Brarner.M.Alete</td><td><a href="http://localhost:8080/brarner.m.alete/">http://localhost:8080/brarner.m.alete/</a></td><td><span class="theme-badge blue">Presidential Blue</span></td><td>49152</td></tr>
<tr><td>SpectrumTandem™</td><td><a href="http://localhost:8080/spectrum-tandem/">http://localhost:8080/spectrum-tandem/</a></td><td><span class="theme-badge white-red">White Red</span></td><td>49222</td></tr>
<tr><td>Communicator™</td><td><a href="http://localhost:8080/chat/">http://localhost:8080/chat/</a></td><td><span class="theme-badge deep-blue">Deep Blue</span></td><td>49230</td></tr>
<tr><td>UNCW™</td><td><a href="http://localhost:8080/uncw/">http://localhost:8080/uncw/</a></td><td><span class="theme-badge seacoast-teal">SeaCoast Teal</span></td><td>49231</td></tr>
<tr><td>TandemEquals™</td><td><a href="http://localhost:8080/tandem-equals/">http://localhost:8080/tandem-equals/</a></td><td><span class="theme-badge white-red">White Red</span></td><td>49223</td></tr>
<tr><td>Analytics™</td><td><a href="http://localhost:8080/analytics/">http://localhost:8080/analytics/</a></td><td><span class="theme-badge github-dark">GitHub Dark</span></td><td>—</td></tr>
<tr><td>ArmorerSteve™</td><td><a href="http://localhost:8080/armorer/">http://localhost:8080/armorer/</a></td><td><span class="theme-badge deep-blue">Dark Blue</span></td><td>49235</td></tr>
<tr><td>FiduciaryServices™</td><td><a href="http://localhost:8080/fiduciary/">http://localhost:8080/fiduciary/</a></td><td><span class="theme-badge light-blue">Light Blue</span></td><td>49236</td></tr>
</tbody></table>
</div>

<h2>FiduciaryServices&trade; &mdash; Light Blue Module (Port 49236)</h2>
<div class="section">
<p><strong>Global Transfer Wealth &amp; Architecture. The balance of internal design and remedy. The means to necessary advantages.</strong></p>
<p>AI Intelligence: 200 IQ | Database: nwe_fiduciary | Signed: M.</p>

<h3>Database Tables (11)</h3>
<table>
<thead><tr><th>Table</th><th>Purpose</th><th>Source SQL</th></tr></thead>
<tbody>
<tr><td>knowledge_base</td><td>Q&amp;A: fiduciary duty, trust types, structures, datapool</td><td>fiduciary.c (built-in)</td></tr>
<tr><td>architectures</td><td>Fiduciary architectures: express trust, SWF, pension, foundation</td><td>fiduciary.c (built-in)</td></tr>
<tr><td>records</td><td>Known fiduciaries: Norway GPF, Vanguard, BlackRock, CalPERS</td><td>fiduciary.c (built-in)</td></tr>
<tr><td>yield_models</td><td>Polyblend yield components: treasury, equity, credit, real, PE</td><td>fiduciary.c (built-in)</td></tr>
<tr><td>sessions</td><td>Q&amp;A session history</td><td>fiduciary.c (built-in)</td></tr>
<tr><td>original_documents</td><td>Minister facts, international law, county, gentry, standings, winners</td><td>minister_fiduciary_facts.sql</td></tr>
<tr><td>legal_bright</td><td>INT/IQ Calendar: top-half ideals/totals, bottom-half treasure/nuisance</td><td>legal_bright_iq_calendar.sql</td></tr>
<tr><td>treasure_fiduciary</td><td>Law structure approach: direct, council, try, resolution</td><td>legal_bright_iq_calendar.sql</td></tr>
<tr><td>ai_findings_order</td><td>200 IQ findings hierarchy: 9 levels from raw findings to Supreme Holdings</td><td>ai_findings_order.sql</td></tr>
<tr><td>garden_news_doctrine</td><td>People closed, evidence open, truth for life, annals forever</td><td>ai_findings_order.sql</td></tr>
<tr><td>ai_disposition</td><td>AI 200 IQ configuration: intelligence, doctrine, standard, purpose</td><td>ai_findings_order.sql</td></tr>
</tbody></table>

<h3>AI Findings Order (200 IQ Processing Hierarchy)</h3>
<table>
<thead><tr><th>#</th><th>Level</th><th>Scope</th><th>Openness</th><th>Person</th></tr></thead>
<tbody>
<tr><td>1</td><td>Findings in Order</td><td>UNIVERSAL</td><td>OPEN</td><td>OPEN_CONDUCT</td></tr>
<tr><td>2</td><td>Court Trials</td><td>JUDICIAL</td><td>OPEN</td><td>CLOSED</td></tr>
<tr><td>3</td><td>US Trials</td><td>US_FEDERAL_STATE</td><td>OPEN</td><td>CLOSED</td></tr>
<tr><td>4</td><td>US Garden News</td><td>US_PUBLIC_RECORD</td><td>CAREFUL</td><td>NOT_UNTO_PERSON</td></tr>
<tr><td>5</td><td>US Certain Garden News</td><td>US_VERIFIED</td><td>OPEN</td><td>NOT_UNTO_PERSON</td></tr>
<tr><td>6</td><td>US Trials about Garden News</td><td>US_JUDICIAL_PUBLIC</td><td>OPEN</td><td>NOT_UNTO_PERSON</td></tr>
<tr><td>7</td><td>US Trials about US Garden News</td><td>US_META_JUDICIAL</td><td>OPEN</td><td>NOT_UNTO_PERSON</td></tr>
<tr><td>8</td><td>US New Int</td><td>US_FRONTIER</td><td>CAREFUL</td><td>OPEN_CONDUCT</td></tr>
<tr><td>9</td><td>Closed US Supreme Holdings and Trials</td><td>US_SUPREME</td><td>CLOSED</td><td>ANNALS_FOREVER</td></tr>
</tbody></table>

<h3>Garden News Doctrine</h3>
<p style="color:#bfdbfe; font-style:italic; border-left: 3px solid #60a5fa; padding-left: 1rem;">
People are closed &mdash; their evidence of hand (manual conduct or int-thinking) shall remain open conduct.
Not unto the person forever. To remain as careful. To remain as open, sold, as conduct into the annals
of forever and history. To conduct evidence against history forever for truth, for life. &mdash; M.
</p>

<h3>Legal Bright &mdash; INT/IQ Calendar</h3>
<table>
<thead><tr><th>Half</th><th>Concern</th><th>Principle</th></tr></thead>
<tbody>
<tr><td>TOP</td><td>IDEAL</td><td>Personal interests &rarr; county benefits mainly. Surrounds equal ideas as brilliant or pertinent.</td></tr>
<tr><td>TOP</td><td>TOTAL</td><td>INT invested in county. IQ quality of ideas surrounding the county. Gap = concern priority.</td></tr>
<tr><td>BOTTOM</td><td>TREASURE</td><td>Treasure Fiduciary can and may approach all law structure as evident. Capability + Permission.</td></tr>
<tr><td>BOTTOM</td><td>NUISANCE</td><td>State Nuisance resolved ably and usually as Council. Deliberation, wisdom, able resolution.</td></tr>
<tr><td>BOTTOM</td><td>TRY</td><td>Profitable ideas tried with treasure backing. Try-nuisances resolved through Council.</td></tr>
</tbody></table>

<h3>Original Documents (Categories)</h3>
<table>
<thead><tr><th>Category</th><th>Label</th><th>Content</th></tr></thead>
<tbody>
<tr><td>MINISTER</td><td>DOMESTIC</td><td>Minister fiduciary duty, ongoing corporate, conflict, accountability, parliamentary</td></tr>
<tr><td>INTERNATIONAL</td><td>INTERNATIONAL</td><td>Hague Convention, UNIDROIT, Santiago Principles, sovereign ministers, IMF 2026</td></tr>
<tr><td>COUNTY</td><td>DOMESTIC</td><td>Board of supervisors, tax evidence, elected officials, public trusts, fiduciary income tax</td></tr>
<tr><td>GENTRY_HERO</td><td>DOMESTIC/INT'L</td><td>Historical stewardship, Keech v Sandford, Meinhard v Salmon, Credit Suisse $742M</td></tr>
<tr><td>STANDINGS</td><td>DOMESTIC/INT'L</td><td>Thole v US Bank, fiduciary shield, charitable enforcement, equitable obligations</td></tr>
<tr><td>WINNERS</td><td>DOMESTIC/INT'L</td><td>Ivanishvili $742M, Mendell, Asaro, Carnegie $2.3M, Norway GPF, Keech (1726)</td></tr>
<tr><td>AHEAD</td><td>DOMESTIC/INT'L</td><td>Forward position, digital age, county future, who wins next</td></tr>
<tr><td>LEGAL_BRIGHT</td><td>DOMESTIC</td><td>INT/IQ Calendar summary, Treasure Fiduciary, State Nuisance, Council</td></tr>
<tr><td>AI_DISPOSITION</td><td>DOMESTIC</td><td>200 IQ findings order, Garden News doctrine, Supreme Holdings</td></tr>
</tbody></table>

<h3>TCP Protocol (Port 49236)</h3>
<table>
<thead><tr><th>Command</th><th>Description</th></tr></thead>
<tbody>
<tr><td><code>ASK|&lt;question&gt;</code></td><td>Q&amp;A about fiduciary concepts</td></tr>
<tr><td><code>YIELD|&lt;model&gt;</code></td><td>Yield/turn model query</td></tr>
<tr><td><code>ARCHITECTURE|&lt;name&gt;</code></td><td>Fiduciary architecture lookup</td></tr>
<tr><td><code>RECORDS|&lt;keyword&gt;</code></td><td>Known fiduciary records</td></tr>
<tr><td><code>POLYBLEND</code></td><td>Composite yield assumption</td></tr>
<tr><td><code>DATAPOOL|&lt;source&gt;</code></td><td>Public data sources (EDGAR, OECD, etc.)</td></tr>
<tr><td><code>DOCUMENTS|&lt;category&gt;</code></td><td>Original documents (minister, international, county, gentry, etc.)</td></tr>
<tr><td><code>BRIGHT|&lt;keyword&gt;</code></td><td>Legal Bright INT/IQ Calendar entries</td></tr>
<tr><td><code>TREASURE|&lt;keyword&gt;</code></td><td>Treasure Fiduciary law structure approaches</td></tr>
<tr><td><code>STATUS</code></td><td>Server health</td></tr>
<tr><td><code>HELP</code></td><td>Command list</td></tr>
<tr><td><code>QUIT</code></td><td>Disconnect</td></tr>
</tbody></table>

<h3>Terminal Tool</h3>
<p><code>fiduciary</code> &mdash; Interactive Q&amp;A (C binary, MySQL-backed)</p>
<p><code>fiduciary --populate</code> &mdash; Populate/refresh knowledge base</p>
<p><code>fiduciary --query "garden news"</code> &mdash; Single query mode</p>
<p><code>fiduciary --architecture</code> &mdash; List architectures</p>
<p><code>fiduciary --yield</code> &mdash; Yield models</p>
<p><code>fiduciary --records</code> &mdash; Known records</p>
</div>

<p style="color:#666;margin-top:2rem;">NitroWebExpress&trade; &mdash; National Finance Engine v2811.1 &mdash; MEARVK LLC</p>
</body></html>
"""

with open(os.path.join(SERVE_DIR, "index.html"), "w", encoding="utf-8") as f:
    f.write(index_html)

# Create directory junctions/symlinks for each module
for ctx, info in MODULES.items():
    path_val = info["path"] if isinstance(info, dict) else info
    full = os.path.join(PROJECT_ROOT, path_val)
    link = os.path.join(SERVE_DIR, ctx)
    if os.path.isdir(full):
        if os.path.exists(link):
            if os.path.islink(link) or os.path.isdir(link):
                try:
                    os.remove(link)
                except:
                    try:
                        os.rmdir(link)
                    except:
                        pass
        try:
            os.symlink(full, link, target_is_directory=True)
        except OSError:
            # Windows without developer mode: use junction
            os.system(f'mklink /J "{link}" "{full}" >nul 2>&1')

# Ensure shared images directory exists in each module symlink for icon preview
# The nwe-readme-viewer.js references images/MearvK.Ltd/communicator/download.jpeg
shared_img_dir = os.path.join(PROJECT_ROOT, "scripts", "web", "images", "MearvK.Ltd", "communicator")
os.makedirs(shared_img_dir, exist_ok=True)

# Copy the original download.jpeg to the preview scripts dir if not present
import shutil
orig_jpeg = os.path.join(PROJECT_ROOT, "images", "MearvK.Ltd", "communicator", "download.jpeg")
preview_jpeg = os.path.join(shared_img_dir, "download.jpeg")
if os.path.exists(orig_jpeg) and not os.path.exists(preview_jpeg):
    shutil.copy2(orig_jpeg, preview_jpeg)
    print(f"  [*] Copied original download.jpeg ({os.path.getsize(orig_jpeg)} bytes)")

# Ensure all module webapp dirs have the original image
for ctx, info in MODULES.items():
    path_val = info["path"] if isinstance(info, dict) else info
    full = os.path.join(PROJECT_ROOT, path_val)
    img_target = os.path.join(full, "images", "MearvK.Ltd", "communicator", "download.jpeg")
    if os.path.isdir(full) and not os.path.exists(img_target):
        os.makedirs(os.path.dirname(img_target), exist_ok=True)
        if os.path.exists(orig_jpeg):
            shutil.copy2(orig_jpeg, img_target)

os.chdir(SERVE_DIR)


import re as _re

class QuietHandler(http.server.SimpleHTTPRequestHandler):
    extensions_map = {
        **http.server.SimpleHTTPRequestHandler.extensions_map,
        '.jsp': 'text/html',
        '.css': 'text/css',
        '.js': 'application/javascript',
        '.png': 'image/png',
        '.jpg': 'image/jpeg',
        '.jpeg': 'image/jpeg',
        '.svg': 'image/svg+xml',
        '.json': 'application/json',
        '.xml': 'application/xml',
    }

    def do_GET(self):
        # For JSP files, strip scriptlet blocks before serving
        path = self.path.split('?')[0]
        
        # If path ends with /, try to serve index.jsp
        if path.endswith('/'):
            translated = self.translate_path(path)
            index_jsp = os.path.join(translated, 'index.jsp')
            if os.path.isfile(index_jsp):
                self.path = path + 'index.jsp'
                path = self.path
        
        if path.endswith('.jsp'):
            translated = self.translate_path(path)
            try:
                with open(translated, 'r', encoding='utf-8') as f:
                    content = f.read()
                # Remove all JSP scriptlets: <%...%>, <%@...%>, <%=...%>, <%!...%>
                content = _re.sub(r'<%[@!=]?[\s\S]*?%>', '', content)
                encoded = content.encode('utf-8')
                self.send_response(200)
                self.send_header('Content-Type', 'text/html; charset=utf-8')
                self.send_header('Content-Length', str(len(encoded)))
                self.end_headers()
                self.wfile.write(encoded)
            except FileNotFoundError:
                self.send_error(404)
            except Exception as e:
                self.send_error(500, str(e))
        else:
            super().do_GET()

    def log_message(self, format, *args):
        if '.css' not in args[0] and '.js' not in args[0] and '.png' not in args[0] and '.jpg' not in args[0]:
            super().log_message(format, *args)


import sys, io
if sys.platform == 'win32':
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

print(f"""
╔═══════════════════════════════════════════════════════════════════════════╗
║  NitroWebExpress™ — Style Preview Server                                  ║
║  http://localhost:{PORT}/                                                    ║
║                                                                           ║
║  Main Server:                                                             ║
║    telnet localhost 49152         (NWE Main)                              ║
║    telnet localhost 20000         (Strernary AI)                          ║
║    telnet localhost 49199         (Communicator)                          ║
║                                                                           ║
║  Modules (Tomcat 8080):                                                   ║
║    http://localhost:8080/defined/          (Dark Gray — port 49220)       ║
║    http://localhost:8080/futures/          (Red — port 5000)              ║
║    http://localhost:8080/california-fbi/   (Red — port 49210)            ║
║    http://localhost:8080/california-cia/   (Dark Blue — port 49211)      ║
║    http://localhost:8080/california-nsa/   (Black — port 49212)          ║
║    http://localhost:8080/california-duke/  (Duke Blue — port 49213)      ║
║    http://localhost:8080/california-ncsu/ (Wolfpack Red — port 49217)   ║
║    http://localhost:8080/california-unc/  (Carolina Blue — port 49218)  ║
║    http://localhost:8080/library/          (Cardinal Red — port 49214)   ║
║    http://localhost:8080/vietnam/          (Light Brown — port 49215)    ║
║    http://localhost:8080/emeter/           (Light Blue — port 49216)     ║
║    http://localhost:8080/spectrum-tandem/  (White Red — port 49222)      ║
║    http://localhost:8080/chat/             (Deep Blue — 49230)    ║
║    http://localhost:8080/uncw/             (SeaCoast Teal — port 49231)  ║
║    http://localhost:8080/tandem-equals/   (White Red — port 49223)      ║
║    http://localhost:8080/analytics/       (GitHub Dark — traffic)       ║
║    http://localhost:8080/armorer/         (Dark Blue — port 49235)     ║
║    http://localhost:8080/gray-registry/    (Gray — port 9999)            ║
║    http://localhost:8080/gray85-registry/  (Crème — port 10085)          ║
║    http://localhost:8080/gdgh/             (Green — port 20000)          ║
║    http://localhost:8080/ae6e66/           (UK Blue)                     ║
║    http://localhost:8080/blackbelt/        (Black)                       ║
║    http://localhost:8080/languages/        (White)                       ║
║    http://localhost:8080/brarner.m.alete/  (Presidential Blue — 49152)  ║
║                                                                           ║
║  Defined™ Backend:                                                        ║
║    telnet localhost 49220         (AI Server — scans 4x daily)           ║
║    telnet localhost 49221         (Protocol Mgmt — hours restricted)     ║
║                                                                           ║
║  Preview:                                                                 ║
║    http://localhost:{PORT}/                (this index page)                 ║
║    http://localhost:{PORT}/defined/        (Defined Dark Gray preview)      ║
║    http://localhost:{PORT}/futures/        (Futures Red preview)            ║
║    http://localhost:{PORT}/vietnam/        (Vietnam Brown preview)          ║
║    http://localhost:{PORT}/spectrum-tandem/ (SpectrumTandem White/Red)      ║
║    http://localhost:{PORT}/chat/           (Communicator™ Deep Blue)          ║
║    http://localhost:{PORT}/uncw/           (UNCW SeaCoast Teal/Gold)        ║
║    http://localhost:{PORT}/tandem-equals/  (TandemEquals™ White/Red)        ║
║    http://localhost:{PORT}/analytics/      (Analytics GitHub Dark)           ║
║    http://localhost:{PORT}/armorer/        (ArmorerSteve™ Dark Blue)          ║
║    http://localhost:{PORT}/fiduciary/      (FiduciaryServices™ Light Blue)    ║
║                                                                           ║
║  NOTE: JSP scriptlets show as raw text. CSS/JS/layout works normally.     ║
║  Press Ctrl+C to stop.                                                    ║
╚═══════════════════════════════════════════════════════════════════════════╝
""")

try:
    with http.server.HTTPServer(("", PORT), QuietHandler) as httpd:
        httpd.serve_forever()
except KeyboardInterrupt:
    print("\n[*] Preview server stopped.")
finally:
    # Cleanup symlinks
    for ctx in MODULES:
        link = os.path.join(SERVE_DIR, ctx)
        try:
            os.remove(link)
        except:
            os.system(f'rmdir "{link}" >nul 2>&1')
    try:
        os.remove(os.path.join(SERVE_DIR, "index.html"))
        os.rmdir(SERVE_DIR)
    except:
        pass
