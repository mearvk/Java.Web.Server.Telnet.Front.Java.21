# DIGTIK.md — Servlet Website Edition Build Guide

## Overview

Each module in NitroWebExpress™ has a **servlet webapp edition** — a JSP-driven website that interfaces with the module's running TCP server on its designated port. The websites provide a browser-accessible front-end to the same data and services available via telnet/TCP protocol.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│  Browser (HTTPS)                                                │
│  https://lauradei.us/{context}/                                 │
└─────────────┬───────────────────────────────────────────────────┘
              │ HTTP/JSP
┌─────────────▼───────────────────────────────────────────────────┐
│  Tomcat (port 8080, localhost-bound)                            │
│  /opt/tomcat/webapps/{context}/                                 │
│  ├── JSP pages (server-side JDBC + Socket connections)         │
│  ├── WEB-INF/db.properties (MySQL credentials)                 │
│  └── WEB-INF/lib/mysql-connector-j-8.3.0.jar                  │
└─────────────┬──────────────────────┬────────────────────────────┘
              │ JDBC                 │ TCP Socket
┌─────────────▼──────────┐ ┌────────▼────────────────────────────┐
│  MySQL (127.0.0.1:3306)│ │  Running Module Server (TCP port)   │
│  nwe_{module} database │ │  e.g. Strernary on 20000            │
└────────────────────────┘ └─────────────────────────────────────┘
```

## Module Webapp Registry

| Module | Context Path | Theme Color | TCP Port(s) | Database |
|--------|-------------|-------------|-------------|----------|
| Brarner.M.Alete™ | `/brarner.m.alete` | Blue (#3b82f6) | — | `BrarnerScience` |
| AE6E66™ | `/ae6e66` | Emerald (#22c55e) | — | `nwe_ae6e66` |
| Futures™ | `/futures` | Red (#ef4444) | 5000 | `nwe_futures` |
| Green.Durham.Grass.and.Herb™ | `/gdgh` | Green (#16a34a) | 2000,20000,40002-7,49152 | `nwe_gdgh` |
| GrayPortRegistry™ | `/gray-registry` | Gray (#6b7280) | 9999 | `nwe_gray_registry` |
| Gray85 Crème™ | `/gray85-registry` | Amber (#d97706) | 10085 | `nwe_gray85_registry` |
| Black Belt™ | `/blackbelt` | Black/White (#f5f5f5) | — | `nwe_blackbelt` |
| Languages™ | `/languages` | Violet (#8b5cf6) | — | `nwe_languages` |
| Strernary™ | `/strernary` | Cyan (#06b6d4) | 20000, 2000 | `nwe_strernary` |
| Vietnam™ | `/vietnam` | Light Brown (#a0826d) | 49215 | `nwe_vietnam` |
| Emeter™ | `/emeter` | Light Blue (#7dd3fc) | 49216 | `nwe_emeter` |
| SpectrumTandem™ | `/spectrum-tandem` | White/Red (#cc0000) | 49222 | `nwe_spectrum_tandem` |
| Communicator™ | `/chat` | Deep Blue (#4a6cf7) | 49230 | `nwe_chat` |
| UNCW™ | `/uncw` | SeaCoast Teal (#00727A) | 49231 | `nwe_uncw` |
| Analytics™ | `/analytics` | GitHub Dark (#58a6ff) | — | `nwe_analytics` |
| TandemEquals™ | `/tandem-equals` | White/Red (#cc0000) | 49223 | `nwe_tandem_equals` |
| Dictionary™ | `/dictionary` | Scholarly Gold (#d4af37) | — | `nwe_dictionary` |
| FiduciaryServices™ | `/fiduciary` | Trust Green (#10b981) | 49240 | `nwe_fiduciary` |

## Interfacing Websites with Running Servers

Each JSP page can open a TCP socket to the module's running server and relay commands. Pattern:

```java
<%@ page import="java.net.Socket, java.io.*" %>
<%
    String serverHost = "127.0.0.1";
    int serverPort = 20000; // Module's TCP port
    String command = "ASK|" + request.getParameter("q");
    String response = "";

    try (Socket sock = new Socket(serverHost, serverPort)) {
        sock.setSoTimeout(5000);
        PrintWriter out = new PrintWriter(sock.getOutputStream(), true);
        BufferedReader in = new BufferedReader(new InputStreamReader(sock.getInputStream()));
        out.println(command);
        StringBuilder sb = new StringBuilder();
        String line;
        while ((line = in.readLine()) != null) sb.append(line).append("\n");
        response = sb.toString();
    } catch (Exception e) {
        response = "Server offline or unreachable: " + e.getMessage();
    }
%>
```

### Port Interface Map

| Website Page | TCP Command Sent | Server Port |
|-------------|-----------------|-------------|
| `strernary/ask.jsp` | `ASK\|text` | 20000 |
| `strernary/directory.jsp` | XML `<nwe-route>` | 2000 |
| `gdgh/listeners.jsp` | `STATUS` | 20000, 40002, 40003, 40007 |
| `futures/pipeline.jsp` | `STATUS` | 5000 |
| `gray-registry/leases.jsp` | `LIST` | 9999 |
| `gray85-registry/creme.jsp` | `CREME\|block_id` | 10085 |
| `spectrum-tandem/spectrum.jsp` | `SPECTRUM\|term` | 49222 |
| `spectrum-tandem/wordbank.jsp` | `WORDBANK` | 49222 |
| `spectrum-tandem/county.jsp` | `COUNTY\|name` | 49222 |
| `chat/index.jsp` | `STATUS`, `MSG\|user\|text` | 49230 |
| `chat/status.jsp` | `STATUS` | 49230 |
| `uncw/index.jsp` | `CHANCELLOR_STATUS` | 49231 |
| `uncw/profile.jsp` | `PROFILE`, `VIEW_PROFILE\|user` | 49231 |

## Standard Webapp Structure

Every module servlet webapp follows this structure:

```
{module}/servlets/
├── deploy-local.sh                    # Deploy to Tomcat + create DB
└── servlet/src/main/webapp/
    ├── WEB-INF/
    │   ├── web.xml                    # Servlet 6.0, JSP, multipart
    │   └── db.properties              # root@127.0.0.1:3306/nwe_{module}
    ├── css/style.css                  # Module-specific color theme
    ├── index.jsp                      # Overview + GitHub auth check
    ├── status.jsp                     # DB + server health
    └── {module-specific pages}.jsp    # Data pages with JDBC queries
```

## Lessons Learned

### Lesson 1: db.properties Must Use 127.0.0.1

```properties
db.url=jdbc:mysql://127.0.0.1:3306/nwe_module
```

NEVER use `localhost`. On Linux, `localhost` routes through unix socket which uses `auth_socket` plugin and ignores the password. `127.0.0.1` forces TCP and uses `caching_sha2_password`.

### Lesson 2: MySQL 8.4+ Uses caching_sha2_password

`mysql_native_password` was removed in MySQL 8.4. Configure root:

```sql
ALTER USER 'root'@'localhost' IDENTIFIED WITH caching_sha2_password BY '$$Ironman1';
FLUSH PRIVILEGES;
```

MySQL Connector/J 8.3.0 supports this natively.

### Lesson 3: JDBC Driver Must Be in WEB-INF/lib

The `mysql-connector-j-8.3.0.jar` must exist in the deployed `WEB-INF/lib/`. It's NOT enough to have it in Tomcat's shared lib if the webapp uses `Class.forName()` from within a JSP.

### Lesson 4: Properties Declared Outside try

```java
Properties dbProps = new Properties();
boolean propsLoaded = false;
try {
    // load and use
} catch (Exception e) {
    // can reference dbProps here for diagnostics
}
```

If declared inside `try`, the `catch` block can't access them — JSP compilation error.

### Lesson 5: Fallback Path Order for db.properties

```java
String[] tryPaths = {
    "/opt/tomcat/webapps/{context}/WEB-INF/db.properties",
    System.getProperty("user.dir") + "/servlets/.../db.properties",
    "/mnt/blockstorage/.../db.properties"
};
```

1. `application.getResourceAsStream("/WEB-INF/db.properties")` — always first
2. `application.getRealPath()` — second
3. Hardcoded absolute paths — fallback

### Lesson 6: GitHub Authorization Check

Every `index.jsp` checks `public.key` presence on GitHub:

```java
HttpURLConnection hc = (HttpURLConnection) new URL(
    "https://raw.githubusercontent.com/mearvk/Java.Web.Server.Telnet.Front.Java.21/main/psychiatry/secrets/public.key"
).openConnection();
hc.setRequestMethod("HEAD");
hc.setConnectTimeout(5000);
boolean authorized = (hc.getResponseCode() == 200);
```

If `public.key` is removed, all editions show "Revoked" and should halt operation per the license terms.

### Lesson 7: Socket Interface from JSP to Running Server

JSP pages can open a TCP socket to the module's running Java server and send protocol commands. This bridges the web UI to the live service. Always set `setSoTimeout(5000)` and handle `ConnectException` gracefully (show "server offline").

### Lesson 8: Consistent Deploy Pattern

Every `deploy-local.sh`:
1. Copies webapp source to `/opt/tomcat/webapps/{context}/`
2. Copies `mysql-connector-j-*.jar` to `WEB-INF/lib/`
3. Creates the MySQL database and tables
4. Sets ownership to `tomcat:tomcat`
5. Prints the access URL

### Lesson 9: Theme Color System

Each module has a distinct dark theme with one accent color. CSS variables:
- `--bg-dark` — page background (near-black with color tint)
- `--bg-section` — section background (slightly lifted)
- `--bg-card` — card/table header (3rd depth)
- `--border` — all borders (subtle, tinted)
- `--accent` — interactive elements, links, buttons
- `--accent-hover` — hover state

### Lesson 10: Do NOT Redeclare Tomcat's Built-in JSP Servlet

Tomcat 11 has `org.apache.jasper.servlet.JspServlet` pre-configured with the correct init-params and classpath setup (including `WEB-INF/lib` and `WEB-INF/classes`). Explicitly redeclaring it in `web.xml`:

```xml
<!-- BAD — breaks JSP compilation classpath on Tomcat 11 -->
<servlet>
    <servlet-name>jsp</servlet-name>
    <servlet-class>org.apache.jasper.servlet.JspServlet</servlet-class>
</servlet>
<servlet-mapping>
    <servlet-name>jsp</servlet-name>
    <url-pattern>*.jsp</url-pattern>
</servlet-mapping>
```

This overrides Tomcat's internal defaults. The result: HTTP 200 on the response (Tomcat starts sending headers) but the JSP fails to compile because `WEB-INF/lib/*.jar` isn't on the Jasper compilation classpath. Browser shows blank. Scripts checking `curl -o /dev/null -w "%{http_code}"` see 200.

**Fix:** Remove the explicit JSP servlet declaration. Tomcat handles `*.jsp` automatically. Only declare servlets/filters you actually wrote (like `SecurityHeadersFilter`).

### Lesson 11: Clean Deploy (rm -rf) Before Copy

Always `rm -rf "$DEPLOY_DIR"` before copying fresh webapp content. Without this, stale compiled `.class` files from previous JSP compilations (in `work/`) reference old code, and leftover files from deleted pages remain accessible. The California/Duke/Stanford modules got this right; the others were doing incremental overlay with `mkdir -p` + `cp -r`.

### Lesson 12: after-pull.sh for Remote Deployment

After `git pull` on the remote server:
```bash
sudo bash install/after-pull.sh
```

This syncs only changed files, verifies JDBC driver presence, tests DB connection, checks JSP page health, and restarts Tomcat/Apache only if needed.

## Remote Server

| Property | Value |
|----------|-------|
| Server | `45.32.31.139` (mail.lauradei.us) |
| Domain | `lauradei.us` |
| Tomcat | `/opt/tomcat` (port 8080, localhost-bound) |
| Apache | Proxy → Tomcat, serves static assets directly |
| SSL | Let's Encrypt, auto-renew |
| MySQL | `root@127.0.0.1:3306`, `caching_sha2_password` |

## Deploy All Modules

```bash
# BMA (primary)
sudo bash modules/black/presidential/Brarner.M.Alete/install/deploy-local.sh

# Other modules
sudo bash modules/AE6E66/servlets/deploy-local.sh
sudo bash modules/black/red/Futures/servlets/deploy-local.sh
sudo bash modules/black/presidential/Green.Durham.Grass.and.Herb/servlets/deploy-local.sh
sudo bash modules/black/belt/servlets/deploy-local.sh
sudo bash modules/gray/servlets/deploy-local.sh
sudo bash modules/gray.a85/servlets/deploy-local.sh
sudo bash modules/languages/servlets/deploy-local.sh
sudo bash source/strernary/servlets/deploy-local.sh

# New modules (July 2026)
sudo bash modules/spectrum-tandem/servlets/deploy-local.sh
sudo bash modules/chat/servlets/deploy-local.sh
sudo bash modules/uncw/servlets/deploy-local.sh
```

## Author

Max Rupplin — MEARVK LLC  
mearvk@mearvk.us | mearvk@outlook.com  
555 South Mangum St, Durham, NC 27701

**Installer Tech ID:** mearvk - Installer Tech 2 (Grade 9)  
**Authority:** Full system install, bare metal, kernel, boot, CA, identity, ethics.  
**Execution Level:** Level 3 (Local Tech) can deploy all modules via provided scripts.

---

## Installer Authority (DIGTIK Deployment)

All module deployment scripts (`setup-db.sh`, `deploy-local.sh`, `start-backend.sh`, `start-frontend.sh`) are designed for execution by a Level 3 Local Tech. The scripts encode Level 9 architectural decisions — the Level 3 executes, the Level 9 designs.

| Action | Minimum Grade | Script |
|--------|--------------|--------|
| Deploy any module webapp | 3 | `modules/{name}/servlets/deploy-local.sh` |
| Create module database | 3 | `modules/{name}/servlets/setup-db.sh` |
| Start/stop module backend | 3 | `modules/{name}/start-backend.sh` |
| Configure Postfix/Dovecot | 3 | `tools/postfix/configure-mail.sh` |
| Install Postfix/Dovecot | 3 | `tools/postfix/install_postfix.sh`, `tools/dovecot/install_dovecot.sh` |
| Modify kernel modules | 9 | Manual — no script (architectural decision) |
| Modify permission classes | 9 | Manual — no script (security architecture) |
| Generate root CA manually | 9 | Manual — watchdog handles auto-refresh for Level 3 |
| Register TechIDs | 9 | Manual — nnet provisioning |
| Design new modules | 9 | Architectural authority |


---

## Smartphone Edition

Mobile-first responsive webapp at `modules/black/presidential/Brarner.M.Alete/smartphone/`. Served from `/brarner.m.alete/smartphone/` context. Shares `WEB-INF/db.properties`, images, and JARs with the desktop edition.

### Smartphone Design Norms

| Requirement | Implementation |
|-------------|----------------|
| Viewport | `width=device-width, initial-scale=1.0, maximum-scale=5.0, user-scalable=yes` |
| Tap targets | Minimum 44px height/width (CSS `--tap-min: 44px`) |
| Navigation | Hamburger top nav (slide-out) + fixed bottom nav bar |
| Layout | Single-column, cards instead of tables, collapsible sections |
| CD1 Button | 100px diameter (touch-optimized, larger than desktop 80px) |
| Font sizes | Body 1rem minimum, headings 1.25-1.75rem, notes 0.8rem |
| Dark theme | Same CSS variables as desktop (`--bg-dark`, `--accent`, etc.) |
| Orientation | Landscape adjustments via `@media (orientation: landscape)` |
| PWA-ready | `theme-color` meta, `apple-mobile-web-app-capable`, service worker stub |
| Settings | localStorage persistence for port/role; syncs to session |

### Smartphone Directory Structure

```
smartphone/
├── css/mobile.css          — Mobile-first stylesheet
├── js/mobile.js            — Touch handlers, hamburger, settings, CD1
├── index.jsp               — Overview (modules as cards)
├── legal.jsp               — Legal Database (cards, collapsible precedent)
├── settings.jsp            — Port/role configuration
├── species.jsp             — (future)
├── postal.jsp              — (future)
├── art.jsp                 — (future)
├── science.jsp             — (future)
└── status.jsp              — (future)
```

### Port Routing & Settings (Multi-Port Pages)

Pages with multiple connector ports include port selector + role selector in the CD1 dialog:

| Page | Ports | CD1 Commands |
|------|-------|-------------|
| Legal | 18500–18507 | counts, precedent, uscode, caselaw, status, setport, unsetport, saveconfig |
| Art | 18400–18419 | connect, disconnect, poll, setport, unsetport, saveconfig |
| Overview | any | connect, disconnect, status, setport, unsetport, saveconfig |

**CD1 Port Commands:**
- `Set Port` — Routes the active connector to the selected port number
- `Unset Port` — Disconnects the connector from the selected port
- `Save Config` — Persists port + role to localStorage (client) and session (server)

**Role Levels:**
| Role | Permissions |
|------|-------------|
| Guest | Read-only. View data, browse tables. No port connections. |
| User | Search + connect. Can set/unset ports. Cannot persist server-side config. |
| Admin | Full control. All commands, save config, access all endpoints. |

Settings are stored in `localStorage` keys: `bma-port`, `bma-role`, `bma-save-time`. On page load, the CD1 dialog restores saved port/role values automatically.

### Lesson 13: Smartphone Deployment

The smartphone edition is deployed alongside the desktop webapp:

```bash
# In deploy-local.sh or after-pull.sh:
cp -r "$BMA_ROOT/smartphone" "$DEPLOY_DIR/smartphone/"
```

Access: `http://localhost:8080/brarner.m.alete/smartphone/`

The smartphone pages reference desktop images via `../servlets/servlet/src/main/webapp/images/` during development. In production (Tomcat deploy), use relative paths within the deployed context.

---

## Standards & Results (July 2026)

### Lesson 14: MySQL Block Storage Migration

On production servers with limited main drive space, MySQL data should live on block storage:

```bash
sudo bash scripts/migrate-mysql-to-blockstorage.sh
```

- Moves `/var/lib/mysql` → `/mnt/blockstorage/mysql`
- Creates symlink so all existing paths continue working
- Updates `/etc/mysql/mysql.conf.d/mysqld.cnf` datadir
- Updates AppArmor if present (Ubuntu)
- Rollback: `sudo bash scripts/migrate-mysql-to-blockstorage.sh --rollback`

All install/deploy/after-pull scripts now source `scripts/detect-mysql.sh` to detect whether MySQL is on main drive or block storage, and warn if main drive is low (<512MB).

### Lesson 15: Log Files Must Target Block Storage

The `nwe-main.log` grows extremely fast (12GB+ per session due to ANSI fade animations). Configuration in `nwe-config.xml` under `<logging>`:

| Preset | nwe-main.log max | Rotations | Total |
|--------|-----------------|-----------|-------|
| 1 (large) | 2 GB | 5 | 10 GB |
| 2 (medium) | 512 MB | 4 | 2 GB |
| 3 (small) | 64 MB | 3 | 192 MB |

Block storage enabled by default: `<block-storage-enabled>true</block-storage-enabled>`. Logs write to `/mnt/blockstorage/nwe/logs/` when mounted. `start-backend-modules.sh` auto-detects and redirects.

### Lesson 16: External Modules Need compile-all-modules.sh

The standard `bash/compile.check.sh` only compiles files under `source/`. External modules (California, Duke, Stanford, Gray, Futures) live in separate directories and need explicit compilation:

```bash
bash scripts/compile-all-modules.sh
```

This single script compiles all 6 groups with correct sourcepaths. Without it, ports 49210-49214, 5000, 9999, 10085, and 2000 will not start.

**Critical sourcepath note:** The Futures package is `red.Futures.source.ai.server` — javac needs `modules/black/` on the sourcepath (not `modules/black/red/Futures/source/`). The California modules use `package source;` so their sourcepath root is the directory containing `source/`.

### Lesson 17: Reflection for Optional Modules

If a module may not be present (e.g., Futures is a separate git repo), use reflection in Main.java:

```java
try { Class.forName("red.Futures.source.ai.server.DemocraticAIServer")
        .getDeclaredMethod("start").invoke(
            Class.forName("red.Futures.source.ai.server.DemocraticAIServer")
                .getDeclaredConstructor().newInstance());
} catch (ClassNotFoundException e) {
    // Module not compiled — skip gracefully
}
```

This allows `Main.java` to compile and run regardless of whether optional modules are present.

### Lesson 18: Communicator Encrypted Sessions

Communicator (port 49199) now supports end-to-end encryption:

| # | Cipher | Key Exchange |
|---|--------|-------------|
| 1 | AES-256-GCM | DH-2048 (RFC 3526 Group 14) |
| 2 | RSA-2048 | DH-2048 |
| 3 | RSA-4096 | DH-2048 |
| 4 | Twofish-256 | DH-2048 (BouncyCastle; fallback AES-CBC) |
| 5 | ECC-secp256r1 | ECDH (secp256r1) |
| 6 | ChaCha20-Poly1305 | DH-2048 |

Protocol: `encrypt <n>` → server DH pubkey → `encrypt accept <client_pubkey_hex>` → session encrypted.
Profile persistence: `profile cipher 6` saves default (auto-suggests on next login).

Source: `source/communicator/CommunicatorCrypto.java`

### Lesson 19: Strernary Protocol (strernary-protocol.xml)

All module-to-Strernary communication follows `configuration/strernary-protocol.xml`:

| Message | Format | Used By |
|---------|--------|---------|
| ASK | `ASK\|{query}` | All strernary-capable modules |
| ASK (context) | `ASK\|{MODULE} SEARCH field=val context=table` | FBI, CIA, NSA, Duke, Stanford, SpectrumTandem, Communicator, UNCW |
| ASK (hardened) | `ASK\|{MODULE} source={mod} ip={ip} trust={n} username={u} protocol={p} item={i} verb={v} int={n} query={q}` | SpectrumTandem, Communicator, UNCW (hardened mode) |
| CLASSIFY | `CLASSIFY\|{module}\|{text}` | FBI, CIA, NSA (auto-categorize) |
| TRAIN | `TRAIN\|{module}\|{category}\|{example}` | Knowledge base growth |
| RELAY | `RELAY\|{text}` | Cross-module routing |
| STATUS | `STATUS` | Health checks |

Java client: `commons.StrernaryConnector.ask()`, `.askHardened()`, `.classify()`, `.train()`, `.relay()`

### Lesson 20: CD1 Connector Format

Every BMA JSP page should include the CD1 connector dialog:

1. Circular button (`images/black.button.png`, 80px desktop / 100px mobile)
2. Overlay + fixed dialog with action dropdown, Send/OK buttons
3. Direct Port checkbox (bypasses Strernary port 20000)
4. Monospace textarea showing connection activity
5. `<script src="js/cd1-connector.js"></script>` before `</body>`
6. `<script>var CD1_MODULE_PORT = "49152";</script>` for module-specific port

Pages with CD1: index, science, art, postal, legal, analysis.
Pages without (intentional): status, register, guest, account-settings.

### Lesson 21: Module Startup/Shutdown Scripts

Every module has dedicated scripts at its root:

| Module | Frontend | Backend |
|--------|----------|---------|
| BMA | `start.sh` / `shutdown.sh` | `start-backend.sh` / `shutdown-backend.sh` |
| GDGH | `start-frontend.sh` / `shutdown-frontend.sh` | `installation/start.sh` / `stop.sh` |
| Futures | `start-frontend.sh` / `shutdown-frontend.sh` | `bash/start.sh` / `shutdown.sh` |
| Black Belt | `start.sh` / `shutdown.sh` | N/A (webapp only) |
| NWE Main | `scripts/startup.sh` | `scripts/start-backend-modules.sh` |

All frontend scripts: deploy + start Tomcat. All support `--stop-tomcat` flag.

### Lesson 22: test-jdbc.sh Verifies Full Stack

`install/test-jdbc.sh` now checks:
1. MySQL data location (main drive vs `/mnt/blockstorage`)
2. Config alignment (`mysql.auth.xml` vs `db.properties` — same host:port?)
3. Queries `@@datadir` from running MySQL to confirm actual location
4. JDBC connectivity with configured credentials
5. Table existence checks (animalia, etc.)
6. Lists all databases

Run after any infrastructure change (migration, credential update, reinstall).

### Lesson 23: Sequential Module Startup Takes 2 Minutes

NWE starts modules sequentially — each module does DB schema init (`CREATE DATABASE IF NOT EXISTS`, `CREATE TABLE IF NOT EXISTS`), opens `ServerSocket`, and starts accept loops. With 19 ports, this takes 60–120 seconds total.

**Strategy:**
- `start-backend-modules.sh` polls every 10 seconds for up to 2 minutes
- Reports progress: `[10 s] Ports up: 10 / 19`, `[20 s] Ports up: 14 / 19`, etc.
- Exits early when all 19 ports respond
- Final per-port status report shows which succeeded and which are still pending

**Do NOT** use a 5-second sleep and report "not yet" — this causes false alarms. The modules are working; they just haven't reached their turn in the sequential startup.

**Typical startup timeline (production server):**

| Time | Ports up | Modules starting |
|------|----------|-----------------|
| 10s | 3 | NWE, AES, Bitcoin (fast — no DB) |
| 20s | 10 | +ConnectionStatus, Communicator, Strernary, Signal servers |
| 40s | 14 | +StrernaryDirectory, CaliforniaFBI/CIA/NSA |
| 60s | 17 | +DukeUniversity, StanfordLibrary, GrayPortRegistry |
| 90s | 18-19 | +Gray85Creme, (Futures if cloned) |

**If a module never starts:** Check `nwe-main.log` for that module's exception. Common causes:
- `.class` file missing → run `bash scripts/compile-all-modules.sh`
- MySQL connection refused → check `systemctl status mysql`
- Port already in use → previous instance still running (`--stop` first)

### Lesson 24: Production Deployment Checklist (July 2026)

Successful production deploy at `lauradei.us` (45.32.31.139):

```bash
# 1. Pull latest
cd /mnt/blockstorage/Java.Web.Server.Telnet.Front.Java.21
git pull

# 2. Compile all modules
bash scripts/compile-all-modules.sh

# 3. Migrate MySQL to block storage (if not done)
sudo bash scripts/migrate-mysql-to-blockstorage.sh

# 4. Start backend (waits up to 2 min for all 19 ports)
bash scripts/start-backend-modules.sh

# 5. Deploy webapp
sudo bash modules/black/presidential/Brarner.M.Alete/install/deploy-local.sh

# 6. Verify
bash modules/black/presidential/Brarner.M.Alete/install/test-jdbc.sh
curl -s -o /dev/null -w "%{http_code}" https://lauradei.us/brarner.m.alete/
```

**Result:** 19/19 ports up, 12/12 JSP pages → 200, MySQL on block storage, logs on block storage.

### Lesson 25: New Modules (July 16 2026)

Three new modules added in a single session:

| Module | Port | Context | Theme | Database | Key Features |
|--------|------|---------|-------|----------|-------------|
| SpectrumTandem™ | 49222 | `/spectrum-tandem` | White/Red | `nwe_spectrum_tandem` | Dolyene (spectrum of int discipline), word bank, county precedent, revisions, pointers/indirections |
| Communicator™ | 49230 | `/chat` | Deep Blue | `nwe_chat` | DH-2048/RSA-2048/AES-256-GCM encrypted chat, federation (5 servers), file transfer, voice notes, admin, chat rooms (31 rooms, 7 categories), Concealment 3 rank, Gold Harvard Certificate |
| UNCW™ | 49231 | `/uncw` | SeaCoast Teal/Gold | `nwe_uncw` | UNCW Wilmington CS club, colleges, chancellors (current+past, max 2000), messaging (10 free/month), file sharing (80MB), audio playback, National ID verification, profiles/resumes |

**Shared infrastructure added:**
- `nwe-readme-viewer.js` — README.md button (upper right, all 21 modules) with markdown interpreter, IQ/Democratic speculation, red pixel flicker on white backgrounds
- GitHub button — links to discussions, silver-gray octocat icon
- `StrernaryConnector.askHardened()` — trust-aware Strernary calls with full metadata (source, IP, trust, username, protocol, handshake, item, verb, gifted int)
- `masquerade-modules.xml` — all three modules registered with `<strernary-hardened>true</strernary-hardened>`
- `strernary-protocol.xml` — registered with query-prefixes, verbs, items, trust levels
- `port-2000-directory-config.xml` — ports 49222, 49230, 49231 discoverable
- `chat-rooms.xml` — 31 rooms across 7 categories (Towns, Teens, Hobbies, Romance, AOL Live, Philosophy, Metaphysical)
- Profile pictures + resume uploads for Chat and UNCW modules
- Admin room monitoring (ADMIN_MONITOR, kick, mute, close/open rooms)

**Communicator™ notes:**
- Renamed from "NWE Chat" to "Communicator" on all pages
- Uses `trillian.jpeg` logo (images/MearvK.Ltd/communicator/)
- All gradients removed — flat Deep Blue theme
- Ethics: "We conceal God but do not work for Her."

**Startup additions:**
- `scripts/start-backends.sh` — MODULES array updated (+3)
- `scripts/compile-all-modules.sh` — sourcepaths and javac targets updated
- `scripts/nwe-ports.sh` — ports 49222, 49230, 49231 added
- `scripts/web/web-deploy-config.xml` — all three modules registered for auto-deploy
- `scripts/preview-styles.py` — modules added, JSP scriptlet stripping, index.jsp auto-resolve

**Deploy new modules:**
```bash
bash modules/spectrum-tandem/servlets/setup-db.sh
bash modules/spectrum-tandem/servlets/deploy-local.sh
bash modules/chat/servlets/setup-db.sh
bash modules/chat/servlets/deploy-local.sh
bash modules/uncw/servlets/setup-db.sh
bash modules/uncw/servlets/deploy-local.sh
```

---

## Analytics & Traffic Graphs (data.jsp)

GitHub-style traffic graphs for all JWSTF modules. Tracks page views (total + unique), new user registrations, file uploads, clones/downloads, referring sites, and popular content — all driven by MySQL and rendered client-side with Chart.js.

### Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│  Browser (HTTPS)                                                │
│  https://lauradei.us/analytics/data.jsp?module=Communicator    │
└─────────────┬───────────────────────────────────────────────────┘
              │ HTTP/JSP
┌─────────────▼───────────────────────────────────────────────────┐
│  Tomcat — /analytics/ context                                   │
│  data.jsp:                                                     │
│    1. Records visit to nwe_analytics (auto-track)               │
│    2. Queries last 14 days of graph data via JDBC               │
│    3. Injects JSON arrays into <script> block                   │
│    4. Chart.js renders 4 graphs client-side                     │
│  api.jsp:                                                       │
│    JSON endpoint for AJAX refresh (no page reload)              │
└─────────────┬───────────────────────────────────────────────────┘
              │ JDBC (127.0.0.1:3306)
┌─────────────▼───────────────────────────────────────────────────┐
│  MySQL — nwe_analytics database                                 │
│  Tables: page_views, visitor_log, new_users, uploads,           │
│          clones, referring_sites, popular_content, modules       │
└─────────────────────────────────────────────────────────────────┘
```

### Graphs (Chart.js, client-side JavaScript)

| Graph | Type | Datasets | Color |
|-------|------|----------|-------|
| Page Views | Area/Line | Total Views + Unique Visitors | Blue (#58a6ff) + Green (#3fb950) |
| New Users | Bar | Daily registrations | Purple (#bc8cff) |
| Uploads | Bar | Daily file/voice/image uploads | Orange (#d29922) |
| Clones | Line | Total Clones + Unique Cloners | Red (#f85149) + Orange (#d29922) |

All graphs show last 14 days by default (configurable via `?days=` param, max 90).

### Module Selector

Dropdown at top filters all graphs and tables by module. Options:
- `ALL` — aggregate across all modules
- Per-module: Brarner.M.Alete, AE6E66, Futures, Green.Durham.Grass.and.Herb, GrayPortRegistry, Gray85Creme, BlackBelt, Languages, Strernary, Vietnam, Emeter, SpectrumTandem, Communicator, UNCW

### Database Schema (nwe_analytics)

| Table | Purpose | Key Columns |
|-------|---------|-------------|
| `page_views` | Daily view counts per module | module_name, view_date, total_views, unique_visitors |
| `visitor_log` | Individual visit records (hashed IP) | module_name, visitor_hash, ip_address, user_agent, page_path, referrer |
| `new_users` | Daily registration counts per module | module_name, register_date, user_count |
| `uploads` | Daily upload counts + bytes per module | module_name, upload_date, upload_count, total_bytes |
| `clones` | Daily clone/download counts per module | module_name, clone_date, total_clones, unique_cloners |
| `referring_sites` | Traffic sources per day per module | module_name, referrer_domain, ref_date, visit_count |
| `popular_content` | Most-visited pages per day per module | module_name, page_path, content_date, view_count |
| `modules` | Registry of all tracked modules | module_name, context_path, theme_color, tcp_port |

### Tracking Integration (Other Modules)

Any module can auto-record visits by including the analytics tracker JSP:

```java
<%-- At top of any module's JSP page --%>
<% String ANALYTICS_MODULE = "Communicator"; %>
<%@ include file="/WEB-INF/analytics-track.jsp" %>
```

Copy `analytics-track.jsp` to each module's `WEB-INF/` directory. The tracker:
1. Hashes visitor IP (SHA-256, first 8 bytes) for privacy
2. Inserts into `visitor_log`
3. Upserts daily `page_views` (total + unique)
4. Upserts `popular_content` for the visited page
5. Records `referring_sites` if Referer header present
6. Fails silently — never breaks the host page

### JSON API (api.jsp)

For AJAX graph refresh without full page reload:

| Endpoint | Params | Returns |
|----------|--------|---------|
| `api.jsp?type=views&module=X&days=14` | — | `{labels:[], total:[], unique:[]}` |
| `api.jsp?type=users&module=X&days=14` | — | `{labels:[], count:[]}` |
| `api.jsp?type=uploads&module=X&days=14` | — | `{labels:[], count:[], bytes:[]}` |
| `api.jsp?type=clones&module=X&days=14` | — | `{labels:[], total:[], unique:[]}` |
| `api.jsp?type=referrers&module=X&days=14` | — | `{rows:[{domain,views,unique}]}` |
| `api.jsp?type=content&module=X&days=14` | — | `{rows:[{path,views,unique}]}` |

### Recording New Users & Uploads from Backend

Backend Java modules should record registrations and uploads via JDBC:

```java
// Record new user registration
PreparedStatement ps = conn.prepareStatement(
    "INSERT INTO nwe_analytics.new_users (module_name, register_date, user_count) " +
    "VALUES (?, CURDATE(), 1) ON DUPLICATE KEY UPDATE user_count = user_count + 1");
ps.setString(1, "Communicator");
ps.executeUpdate();

// Record upload
PreparedStatement ps2 = conn.prepareStatement(
    "INSERT INTO nwe_analytics.uploads (module_name, upload_date, upload_count, total_bytes) " +
    "VALUES (?, CURDATE(), 1, ?) ON DUPLICATE KEY UPDATE upload_count = upload_count + 1, total_bytes = total_bytes + VALUES(total_bytes)");
ps2.setString(1, "Communicator");
ps2.setLong(2, fileBytes);
ps2.executeUpdate();
```

### Deploy

```bash
# 1. Create database
bash modules/analytics/servlets/setup-db.sh

# 2. Deploy webapp
sudo bash modules/analytics/servlets/deploy-local.sh

# 3. Access
curl -s https://lauradei.us/analytics/data.jsp
```

### Files

```
modules/analytics/servlets/setup-db.sh                          - Database creation (7 tables, 14 modules)
modules/analytics/servlets/deploy-local.sh                      - Tomcat deployment script
modules/analytics/servlets/servlet/src/main/webapp/data.jsp    - Main traffic page (graphs + tables)
modules/analytics/servlets/servlet/src/main/webapp/api.jsp      - JSON API for AJAX refresh
modules/analytics/servlets/servlet/src/main/webapp/WEB-INF/web.xml         - Servlet 6.0 config
modules/analytics/servlets/servlet/src/main/webapp/WEB-INF/db.properties   - JDBC connection
modules/analytics/servlets/servlet/src/main/webapp/WEB-INF/analytics-track.jsp - Reusable tracking include
```

### Context Path

| Property | Value |
|----------|-------|
| Context | `/analytics` |
| Theme | GitHub Dark (#0d1117 base, #58a6ff accent) |
| Database | `nwe_analytics` |
| Graph Library | Chart.js 4.4.3 (CDN) |
| Lookback | 14 days default, 90 max |

### Lesson 26: Analytics Tracking Is Fire-and-Forget

The `analytics-track.jsp` include wraps all DB operations in try/catch and closes connections in `finally`. If `nwe_analytics` doesn't exist or MySQL is down, the tracking silently fails — the host page renders normally. This means:
- Deploy analytics DB ONCE (`setup-db.sh`)
- Include tracker in module pages at your pace
- Graphs populate automatically as traffic arrives
- No module depends on analytics being present

### Lesson 27: Chart.js from CDN, Not Bundled

Chart.js is loaded from `cdn.jsdelivr.net` — no local copy needed. This keeps webapp size small and benefits from browser caching across sites. If offline operation is needed, download `chart.umd.min.js` (~200KB) to the webapp's `js/` folder and update the `<script src>`.

---

## BMA Science Input Graphs (data.jsp)

Brarner.M.Alete™ has its own `data.jsp` showing science input activity across the 7 BMA interest categories. Each category tracks 4 metrics: **inputs**, **communications**, **posts**, and **downloads**.

### Categories

| Key | Display | Color | Related Database | Description |
|-----|---------|-------|-----------------|-------------|
| SSA | SSA | #f59e0b (Amber) | BrarnerScience.publications | Social Security Administration data inputs |
| Species | Species | #22c55e (Green) | BrarnerScience.species | Taxonomy, animalia, biodiversity entries |
| PostOffice | Post Office | #ef4444 (Red) | BrarnerPostal.postal_offices | Postal codes, office data, experiments |
| Science | Science | #3b82f6 (Blue) | BrarnerScience.publications | Publications, DOI resolution, experiments |
| Art | Art | #a855f7 (Purple) | BrarnerArt.art_collection | Art institutions, museum collections |
| Legal | Legal | #06b6d4 (Cyan) | — | Case law, legal precedent, statutes |
| Analysis | Analysis | #ec4899 (Pink) | — | Taxonomy analysis, file uploads, classification |

### Metrics Tracked

| Metric | What It Counts | Graph Type |
|--------|---------------|------------|
| Inputs | New data entries (species added, publications indexed, postal codes loaded) | Stacked Bar |
| Communications | Messages, CD1 connector interactions, TCP protocol exchanges | Stacked Area (Line) |
| Posts | User contributions, notes, discussion entries | Stacked Bar |
| Downloads | File downloads, DOI fetches, export requests | Multi-line |

### Graphs (4 panels, 2×2 grid)

All graphs show stacked data by category with the BMA color scheme:
1. **Science Inputs** — stacked bar chart, inputs per day per category
2. **Communications** — stacked area chart, comms per day per category
3. **Posts** — stacked bar chart, posts per day per category
4. **Downloads** — multi-line chart, downloads per day per category

### Time Range

Pills at top-right: 7 days | **14 days** (default) | 30 days | 90 days

### Breakdown Table

Below the graphs: a summary table showing total counts per category with percentage bars.

### Database Tables (in nwe_analytics)

| Table | Purpose |
|-------|---------|
| `bma_science_inputs` | Daily rollup: category × date → input_count, comm_count, post_count, download_count |
| `bma_input_log` | Granular event log (individual inputs with user hash, IP, metadata) |
| `bma_categories` | Category registry (key, display name, color, related DB) |

### Recording from Java Backend

BMA modules record inputs via JDBC to `nwe_analytics`:

```java
// When a species is added:
PreparedStatement ps = conn.prepareStatement(
    "INSERT INTO nwe_analytics.bma_science_inputs (category, activity_date, input_count) " +
    "VALUES ('Species', CURDATE(), 1) " +
    "ON DUPLICATE KEY UPDATE input_count = input_count + 1");
ps.executeUpdate();

// When a publication is downloaded:
PreparedStatement ps2 = conn.prepareStatement(
    "INSERT INTO nwe_analytics.bma_science_inputs (category, activity_date, download_count) " +
    "VALUES ('Science', CURDATE(), 1) " +
    "ON DUPLICATE KEY UPDATE download_count = download_count + 1");
ps2.executeUpdate();

// When a CD1 connector communication occurs:
PreparedStatement ps3 = conn.prepareStatement(
    "INSERT INTO nwe_analytics.bma_science_inputs (category, activity_date, comm_count) " +
    "VALUES ('PostOffice', CURDATE(), 1) " +
    "ON DUPLICATE KEY UPDATE comm_count = comm_count + 1");
ps3.executeUpdate();

// Granular log entry:
PreparedStatement ps4 = conn.prepareStatement(
    "INSERT INTO nwe_analytics.bma_input_log (category, event_type, user_hash, ip_address, description) " +
    "VALUES (?, ?, ?, ?, ?)");
ps4.setString(1, "Species");
ps4.setString(2, "input");
ps4.setString(3, visitorHash);
ps4.setString(4, clientIP);
ps4.setString(5, "Added species: Canis lupus familiaris");
ps4.executeUpdate();
```

### Deploy

```bash
# 1. Create analytics tables (if not already done)
bash modules/analytics/servlets/setup-db.sh

# 2. Create BMA-specific tables
bash modules/analytics/servlets/setup-bma-data.sh

# 3. Deploy BMA webapp (includes data.jsp)
sudo bash modules/black/presidential/Brarner.M.Alete/install/deploy-local.sh
```

### Access

```
https://lauradei.us/brarner.m.alete/data.jsp
https://lauradei.us/brarner.m.alete/data.jsp?range=30
```

### Files

```
modules/black/presidential/Brarner.M.Alete/servlets/servlet/src/main/webapp/data.jsp  - BMA data page
modules/analytics/servlets/setup-bma-data.sh  - BMA analytics table creation
```

---

## Messaging System (messaging.jsp)

A cross-module posting feature deployed to all 21 JWSTF modules. Accepts anonymous or profiled users. Clean, dark-themed interface matching existing NWE style.

### Features

| Feature | Anonymous | Profiled | Admin |
|---------|-----------|----------|-------|
| Post messages | ✓ | ✓ | ✓ |
| Post concerns | ✓ | ✓ | ✓ |
| Post ideas | ✓ | ✓ | ✓ |
| Custom display name | ✓ (optional) | ✓ (profile) | ✓ |
| Create subgroups | — | ✓ | ✓ |
| Edit own posts | — | ✓ | ✓ |
| Delete own posts | — | ✓ | ✓ |
| Delete any post | — | — | ✓ |
| Archive subgroups | — | ✓ (owner) | ✓ |
| Reply to posts | ✓ | ✓ | ✓ |

### Post Types

| Type | Badge Color | Purpose |
|------|-------------|---------|
| Message | Blue | General communication |
| Concern | Red | Report an issue, raise a worry |
| Idea | Green | Suggest an improvement or feature |
| Reply | Purple | Response to another post |

### Architecture

```
┌────────────────────────────────────────────────┐
│  messaging.jsp (per-module)                    │
│  Auto-detects module from context path         │
│  Shared user accounts across all modules       │
│  Module-scoped posts and subgroups             │
└──────────────────┬─────────────────────────────┘
                   │ JDBC (127.0.0.1:3306)
┌──────────────────▼─────────────────────────────┐
│  MySQL — nwe_messaging database                │
│  msg_users (shared across modules)             │
│  msg_subgroups (scoped per module)             │
│  msg_subgroup_members                          │
│  msg_posts (scoped per module)                 │
└────────────────────────────────────────────────┘
```

### Database Schema (nwe_messaging)

| Table | Purpose |
|-------|---------|
| `msg_users` | Profiled users (username, hash, admin flag) — shared across all modules |
| `msg_subgroups` | User-created topic groups, scoped per module (slug, description, owner) |
| `msg_subgroup_members` | Group membership (member, moderator, owner roles) |
| `msg_posts` | All messages (module, subgroup, user/anon, title, content, type, parent_id) |

### Key Design Decisions

1. **Shared user accounts** — One login works across all modules. User registers once.
2. **Module-scoped content** — Posts and subgroups are filtered by `module_name` (derived from context path).
3. **Anonymous by default** — No login required to post. Optional name field for anonymous users.
4. **Soft deletes** — Posts are marked `is_deleted = TRUE`, never physically removed.
5. **Edit tracking** — `edit_count` incremented on each edit, visible to all readers.
6. **Pin support** — Admin can pin posts (shown first in all views).

### BMA Custom Version

Brarner.M.Alete has a custom `messaging.jsp` with:
- Full BMA nav bar (Species, Postal, Art, Science, Analysis, Legal, Data, Messages, Status)
- Left sidebar with channel list and auth card
- 2-column layout (sidebar + main content)
- CD1 connector button
- BMA blue (#3b82f6) theme accent

### Generic Template

All other modules use the generic template version:
- Single-column layout
- Tab-style channel navigation
- Inline login/register row
- Auto-detects module name from context path
- Minimal — only needs `css/style.css` from host module

### Modules with messaging.jsp (21 total)

Brarner.M.Alete, AE6E66, Futures, Gray, Gray85Creme, BlackBelt, Languages, Strernary, Vietnam, Emeter, SpectrumTandem, Communicator, UNCW, Duke, Stanford (library), NCSU, FBI, CIA, NSA, UNC, Calendar, Defined

### Deploy

```bash
# 1. Create messaging database
bash modules/analytics/servlets/setup-messaging.sh

# 2. Re-deploy any module (messaging.jsp included automatically)
sudo bash modules/chat/servlets/deploy-local.sh
sudo bash modules/black/presidential/Brarner.M.Alete/install/deploy-local.sh
# etc.
```

### Access

```
https://lauradei.us/brarner.m.alete/messaging.jsp
https://lauradei.us/chat/messaging.jsp
https://lauradei.us/spectrum-tandem/messaging.jsp
https://lauradei.us/uncw/messaging.jsp
# ... any module context
```

### Lesson 28: messaging.jsp Is Fully Self-Contained

The `messaging.jsp` file contains all logic (auth, posting, groups, CRUD) in a single file with no external dependencies beyond:
- `com.mysql.cj.jdbc.Driver` (already in `WEB-INF/lib/` for every module)
- `css/style.css` (each module's own stylesheet)

No servlets, no filters, no additional JARs. It reads the context path to determine the module name automatically. Users who log in on one module are logged in on all modules (shared session if same Tomcat instance, or shared DB-backed accounts for cross-instance).

### Lesson 29: Rename .data.jsp → data.jsp

All data/analytics pages renamed from `.data.jsp` to `data.jsp`. The leading dot causes issues with some web servers and deployment tools that treat dotfiles as hidden. Plain `data.jsp` works universally.

### Lesson 30: profile.jsp Uses Shared nwe_messaging Accounts

The `profile.jsp` page reads from `nwe_messaging.msg_users` — the same accounts used by `messaging.jsp`. One account works everywhere. The page shows:
- Avatar (initial-based), display name, username, role
- Post count (all modules), groups created
- Member since, last active
- Edit form (display name + email, self only)
- User lookup (search by username)

BMA's version adds science category activity (Science, Species, PostOffice, Art, Legal, Analysis) from `nwe_analytics.bma_science_inputs`. Communicator's existing profile.jsp retains its custom upload features (profile picture, resume, federation stats).

---

## Government Web Forms — SSA & USPS (BMA Quick Reference)

Template for communicating at township, city, county, state, and national level via USPS Web Tools API and SSA form-forward. Configuration: `modules/black/presidential/Brarner.M.Alete/configuration/gov-forms-config.xml`

### USPS Web Tools API

| Property | Value |
|----------|-------|
| Endpoint | `https://secure.shippingapis.com/ShippingAPI.dll` |
| Method | **GET** (XML in query string: `?API=Verify&XML=...`) |
| Auth | `USERID` attribute in XML root element (env: `USPS_USERID`) |
| Rate limit | 5 addresses per request, reasonable use |
| Registration | https://www.usps.com/business/web-tools-apis/ |

### USPS APIs Available

| API | Query Param | Purpose | Required Fields |
|-----|-------------|---------|-----------------|
| **Verify** | `API=Verify` | Standardize/validate address | Address2, (City OR Zip5), State |
| **ZipCodeLookup** | `API=ZipCodeLookup` | Address → ZIP+4 | Address2, City, State |
| **CityStateLookup** | `API=CityStateLookup` | ZIP → City/State | Zip5 |

### USPS Verify — Form Data Elements

| Field | Required | Max Length | Description |
|-------|----------|-----------|-------------|
| `FirmName` | No | — | Business name |
| `Address1` | No | — | Secondary unit (APT, SUITE) |
| `Address2` | **Yes** | — | Street address (delivery line) |
| `City` | No* | 15 | City name (* required if no ZIP) |
| `State` | No* | 2 | Two-letter state code |
| `Urbanization` | No | 28 | Puerto Rico only |
| `Zip5` | No* | 5 | 5-digit ZIP (* required if no city/state) |
| `Zip4` | No | 4 | ZIP+4 extension |

### USPS Response Key Fields

| Field | Meaning |
|-------|---------|
| `DPVConfirmation` | Y=deliverable, D=primary only, S=secondary invalid, N=not deliverable |
| `Business` | Y=business, N=residential |
| `Vacant` | Y=vacant, N=occupied |
| `CarrierRoute` | USPS carrier route code (5 chars) |
| `Footnotes` | A-Z correction codes (see USPS docs) |

### SSA (Social Security Administration)

| Property | Value |
|----------|-------|
| Portal | `https://www.ssa.gov/myaccount/` |
| Auth | **Login.gov / ID.me** (browser-only, no public API key) |
| REST API | **None for individuals.** eCBSV requires institutional agreement. |
| Available | Upload Documents (eSignature), eCBSV (institutional), EWRWS (employer wage reporting) |

**SSA has NO public REST API for individual benefit queries.** The BMA integration templates form fields for local record-keeping and headless browser form-forward when authorized.

### Communication Scope (Township → National)

| Tier | USPS Use | SSA Use | BMA Port |
|------|----------|---------|----------|
| **Township** | Verify address within township ZIPs | Local field office lookup | `postal.jsp` (BrarnerPostal) |
| **City** | CityStateLookup → all ZIPs for city | City field office services | CD1 → port 9006 |
| **County** | Batch verify all county ZIP range | County disability determination | SpectrumTandem port 49222 |
| **State** | State code validation, ZIP ranges | State SSA office directory | CaliforniaNSA port 49212 |
| **National** | Full Address Validation (all states) | eCBSV, EWRWS, Upload Docs | NWE Main port 49152 |

### Java Client Usage (BMA)

```java
// In any BMA module Java file:
import source.gov.USPSClient;

USPSClient usps = new USPSClient(); // reads USPS_USERID from env
// Or: new USPSClient("YOUR_USERID");

// Verify address (township/city level)
String xml = usps.verifyAddress("555 South Mangum St", "Durham", "NC", "27701");

// City/State from ZIP (township identification)
String xml2 = usps.cityStateLookup("27701");
// → <City>DURHAM</City><State>NC</State>

// ZIP lookup (full ZIP+4 for an address)
String xml3 = usps.zipCodeLookup("555 South Mangum St", "Durham", "NC");

// Batch city/state (up to 5 ZIPs per call)
String xml4 = usps.cityStateLookupBatch("27701", "28201", "27601");
```

### Files

```
modules/black/presidential/Brarner.M.Alete/configuration/gov-forms-config.xml  — Full API templates
modules/black/presidential/Brarner.M.Alete/source/gov/USPSClient.java          — Java HTTP client
```

### CaliforniaXXX Modules (Future)

The CaliforniaFBI, CaliforniaCIA, CaliforniaNSA modules would use similar communication patterns at state and national scope. The `gov-forms-config.xml` template and `USPSClient.java` can be extended or copied to those modules when their postal/SSA communication features are built out. The communication scope table above maps each tier to its appropriate module port.

---

## Auth Buttons — Login/Register Pattern (All Modules)

Every module includes `auth-buttons.jsp` and `profile_creation.jsp` for consistent authentication.

### Pattern

```jsp
<%-- In any page's nav, inside or just before </div></nav>: --%>
<div class="nav-actions"><%@ include file="auth-buttons.jsp" %></div>
```

### How It Works

- **Not logged in** → Shows **Login** button (opens popup) + **Register** button (goes to `profile_creation.jsp`)
- **Logged in** → Shows **username** + **Profile** link + **Logout** button
- All buttons inherit the module's `--accent` CSS variable for color consistency
- Login popup submits `auth_action=login` via POST to the current page
- Registration creates account in `nwe_messaging.msg_users` (shared across all modules)
- One account works everywhere — login on one module, recognized on all

### Files (per module webapp)

| File | Purpose |
|------|---------|
| `auth-buttons.jsp` | Include file — login popup + register button + session display |
| `profile_creation.jsp` | Full registration page (username, display name, email, password) |

### Color Adaptation

The buttons use CSS variables from the host module's stylesheet:
- `var(--accent)` — button borders and fill
- `var(--border)` — subtle borders
- `var(--bg-section)` — popup background
- `var(--bg-card)` — input field background
- `var(--text)` — input text color

This means:
- On **BMA** (blue #3b82f6) → blue login/register buttons
- On **SpectrumTandem** (red #cc0000) → red buttons on white
- On **Communicator** (deep blue #4a6cf7) → deep blue buttons
- On **UNCW** (teal #00727A) → teal buttons
- On **Dictionary** (gold #d4af37) → gold buttons
- On **TandemEquals** (red #cc0000) → red buttons on white

### Modules With Custom Auth (Pre-existing)

BMA, Communicator, UNCW, FBI, CIA, NSA, Duke, AE6E66 already had their own Login/Register/Guest/Admin buttons before this standardization. Those are preserved as-is. The `auth-buttons.jsp` file is still available in their webapp for use on new pages.

---

## TandemEquals™ — Human Intellect Modulator Simplex & Control Curve

A four-layer model of human intellect processing — from raw perception through cognitive patterning, modulator shaping, to final expression. White and Red. Port 49223.

### The Four Layers

| Layer | Name | Color | Function | DB Table |
|-------|------|-------|----------|----------|
| 1 | **Perception** | #e74c3c (Red) | Intake signals — sensory, data, emotional, environmental, temporal | `perception` |
| 2 | **Cognition** | #3498db (Blue) | Pattern recognition — logic gates (AND/OR/XOR/THRESHOLD), inference, memory | `cognition` |
| 3 | **Modulation** | #f39c12 (Orange) | Calibration — gain, bias, filter, envelope, limiter, curve shaping | `modulation` |
| 4 | **Expression** | #27ae60 (Green) | Output — speech, action, decision, inhibition, creation, signal relay | `expression` |

### Control Curve (Simplex Path)

```
Perception → Cognition → Modulation → Expression
   (L1)         (L2)         (L3)          (L4)
```

Each control curve traces one complete simplex path:
- **Simplex value** — integrated signal strength across all four layers
- **Stability** — consistency over repeated evaluations (0.0–1.0)
- **Latency** — time from perception intake to expression output
- **Curve integral** — area under the control curve

### Database Schema (nwe_tandem_equals)

| Table | Purpose | Key Columns |
|-------|---------|-------------|
| `perception` | Raw intake signals | signal_name, signal_type, amplitude, frequency, clarity, origin |
| `cognition` | Pattern/logic layer | pattern_name, pattern_type, gate_type, threshold, confidence |
| `modulation` | Gain/filter/envelope | modulator_name, modulator_type, gain, bias, curve_type, simplex_order |
| `expression` | Output actuation | expression_name, expression_type, control_value, direction, intensity |
| `control_curve` | Complete simplex paths | curve_name, perception_id→expression_id, simplex_value, stability |
| `intellect_log` | Immutable evaluation history | curve_id, layer_evaluated, input/output vectors, evaluator |

### Modulation Curve Types

| Type | Behavior |
|------|----------|
| linear | Direct proportional response |
| exponential | Rapid rise/fall |
| logarithmic | Compressed dynamic range |
| sigmoid | S-curve (gentle saturation) |
| step | Binary threshold switch |

### TCP Protocol (Port 49223)

| Command | Response | Layer |
|---------|----------|-------|
| `PERCEPTION` | List all signals | L1 |
| `PERCEPTION\|name` | Search by signal name | L1 |
| `COGNITION` | List all patterns | L2 |
| `MODULATION` | List all modulators | L3 |
| `EXPRESSION` | List all outputs | L4 |
| `CURVE` | List control curves | All |
| `EVALUATE\|id` | Full simplex evaluation | All |
| `STATUS` | Table counts | — |

### JSP Pages

| Page | Content |
|------|---------|
| `index.jsp` | Overview — 4-layer cards, curve visualization, stats, protocol ref |
| `layers.jsp` | Detailed tables for each layer's data from MySQL |
| `curves.jsp` | Control curve table with stability bars + evaluation log |
| `status.jsp` | Backend connectivity, table counts, configuration |
| `messaging.jsp` | Community posting (shared messaging system) |

### Deploy

```bash
bash modules/tandem-equals/servlets/setup-db.sh
sudo bash modules/tandem-equals/servlets/deploy-local.sh
```

### Files

```
modules/tandem-equals/source/TandemEqualsServer.java          - TCP server (port 49223)
modules/tandem-equals/servlets/setup-db.sh                    - Database creation (6 tables, seeded)
modules/tandem-equals/servlets/deploy-local.sh                - Tomcat deployment
modules/tandem-equals/servlets/servlet/src/main/webapp/       - Webapp (5 JSP pages + CSS)
modules/tandem-equals/configuration/tandem-equals-config.xml  - Module configuration
modules/tandem-equals/README.md                               - Documentation
```

---

## FiduciaryServices™ — Global Transfer Wealth & ACH Payment API

A terminal-based AI for fiduciary services, global transfer wealth architecture, yield/turn models, and bank-to-bank ACH payment initiation across five pay-as-you-go platforms. Port 49240.

### ACH Transfer Platforms

| Provider | Monthly | ACH Per-Use | Card Online | Best For |
|----------|---------|-------------|-------------|----------|
| **Melio** | $0 | **FREE** (std), 1% same-day | 2.9% + $0.30 | Zero-fee standard business ACH |
| **Moov** | $0 | Pay-as-you-go | — | API-first, FedNow/RTP settlement |
| **Stripe** | $0 | 0.8% (cap $5) | 2.9% + $0.30 | E-commerce, custom code, intl |
| **Square** | $0 | 1% (min $1) | 2.9% + $0.30 | Invoices, virtual terminals |
| **Helcim** | $0 | 0.5% + $0.25 (cap $6) | ~2.27% + $0.25 (I+) | B2B, automated surcharging |

### Connection Methods

- **Melio** — Plaid instant link to online banking credentials. Recipients need no account.
- **Moov** — Developer API for two-legged standard and same-day FedNow/RTP settlement.
- **Stripe** — API key + Plaid for bank verification. Bearer token auth.
- **Square** — OAuth application credentials + bank account on file.
- **Helcim** — API token + merchant account.

### Database Schema (nwe_fiduciary)

| Table | Purpose |
|-------|---------|
| `knowledge_base` | Fiduciary Q&A knowledge |
| `architectures` | Trust, SWF, pension, foundation, escrow structures |
| `records` | Known fiduciary entities (Norway SWF, BlackRock, CalPERS, etc.) |
| `yield_models` | Polyblend yield components (treasury, equity, credit, real, alt) |
| `sessions` | Interactive Q&A session log |
| `original_documents` | Minister fiduciary facts, international records |
| `legal_bright` | INT/IQ Calendar (top/bottom half legal concerns) |
| `treasure_fiduciary` | Law structures, evidence basis, council resolutions |
| `ai_findings_order` | AI ordinal findings (open/closed/careful/sold) |
| `garden_news_doctrine` | Doctrine principles (person status, evidence status) |
| `ai_disposition` | AI attribute/value pairs by category |
| `ach_platforms` | Registered payment platforms (5 seeded) |
| `ach_accounts` | Known bank accounts (encrypted) |
| `ach_transfers` | Transfer ledger (amount, fee, status, audit) |
| `ach_audit_log` | Immutable audit trail for all transfers |

### TCP Protocol (Port 49240)

| Command | Response |
|---------|----------|
| `ASK\|query` | Fiduciary Q&A answer from knowledge base |
| `ARCHITECTURE` | List all fiduciary architectures |
| `RECORDS` | Known fiduciary entities |
| `YIELD` | Polyblend yield model |
| `TRANSFER\|platform\|routing:account\|amount` | Initiate ACH transfer |
| `STATUS\|reference` | Transfer status |
| `HISTORY` | Recent transfers |
| `PLATFORMS` | List ACH platforms and fees |

### C CLI Tools (tools/fiduciary/)

```bash
fiduciary                        # Interactive Q&A session
fiduciary --query "fiduciary"    # Single query
fiduciary --yield                # Yield/turn polyblend estimator
fiduciary --architecture         # List fiduciary architectures
fiduciary --records              # Known fiduciary entities
fiduciary --populate             # Populate/refresh knowledge base

ach_transfer --list-platforms    # Show all platforms and pricing
ach_transfer --platform melio --to 021000021:123456789 --amount 500.00
ach_transfer --fee-estimate --platform stripe --amount 5000 --method card
ach_transfer --status --reference ach_7f3a9b2c1d4e5f6a
ach_transfer --history --limit 20
```

### Java API (ACHTransferService.java)

```java
ACHTransferService service = ACHTransferService.getInstance();
service.setApiKey(Platform.STRIPE, System.getenv("STRIPE_SECRET_KEY"));
TransferRequest req = new TransferRequest(Platform.STRIPE, "021000021", "123456789",
    new BigDecimal("1000.00"));
req.method = PaymentMethod.ACH;
req.memo = "Invoice 4021";
TransferResult result = service.initiateTransfer(req);
```

### Security

| Feature | Implementation |
|---------|----------------|
| ABA Routing Validation | Checksum: 3(d1+d4+d7) + 7(d2+d5+d8) + (d3+d6+d9) mod 10 == 0 |
| Idempotency | UUID-based keys prevent duplicate transactions |
| API Keys | Env vars or CLI flag (never stored in code) |
| TLS | All API calls over HTTPS with cert verification |
| Audit Log | Every transfer recorded in MySQL `ach_audit_log` |
| Account Masking | Only last 4 digits shown in output |

### Deploy

```bash
# Database
bash modules/fiduciary/servlets/setup-db.sh

# Webapp
sudo bash modules/fiduciary/servlets/deploy-local.sh

# Backend TCP server
bash modules/fiduciary/start-backend.sh

# C tools (OS-level install)
cd tools/fiduciary && make && sudo make install
```

### Files

```
modules/fiduciary/start-frontend.sh                           - Deploy webapp
modules/fiduciary/shutdown-frontend.sh                        - Frontend shutdown
modules/fiduciary/start-backend.sh                            - Start TCP server (port 49240)
modules/fiduciary/shutdown-backend.sh                         - Stop backend
modules/fiduciary/servlets/setup-db.sh                        - Database creation (14 tables)
modules/fiduciary/servlets/deploy-local.sh                    - Tomcat deployment
modules/fiduciary/source/FiduciaryServicesServer.java         - TCP server
modules/fiduciary/configuration/                              - Module configuration
modules/fiduciary/documents/minister_fiduciary_facts.sql      - Minister facts (55KB)
modules/fiduciary/documents/legal_bright_iq_calendar.sql      - Legal bright (32KB)
modules/fiduciary/documents/ai_findings_order.sql             - AI findings (24KB)
tools/fiduciary/fiduciary.c                                   - Terminal Q&A AI (~50KB, C)
tools/fiduciary/ach_transfer.c                                - ACH Transfer CLI (~47KB, C)
tools/fiduciary/ACHTransferService.java                       - Java API (~43KB)
tools/fiduciary/Makefile                                      - Build rules (C + Java)
```

---

## Dictionary™ — NWE System Terminology (45+ Terms)

Defines all rare, new, or system-specific terms used across NitroWebExpress and the OS. Database-only module (no TCP server). Scholarly Gold (#d4af37).

### Term Domains (13)

| Domain | Color | Scope |
|--------|-------|-------|
| Spectrum | #cc0000 | SpectrumTandem and TandemEquals |
| Kernel | #f59e0b | Linux kernel modules |
| Ethics | #22c55e | White Ethics, moral philosophy |
| Intelligence | #3b82f6 | Dave, AI, cognitive systems |
| Security | #ef4444 | HPM, ClamAV, rootkit, encryption |
| Protocol | #8b5cf6 | EPMP, NWE TCP, network |
| Identity | #06b6d4 | User classes, nnet, permissions |
| Filesystem | #ec4899 | NEGAMANE, branding, immutability |
| Module | #f97316 | NWE module-specific |
| Architecture | #6366f1 | System design, build, structure |
| Mathematics | #14b8a6 | Simplex, matrix, curve, computational |
| Medical | #84cc16 | System health, diagnostics |
| Finance | #10b981 | ACH, banking, payment processing, fiduciary |

### ACH/Payment Terms Added (Aug 2026)

20 new terms for the payment processing domain:

| Term | Part of Speech | Domain |
|------|---------------|--------|
| ACH | protocol | Finance |
| routing number | noun | Finance |
| Melio | module | Finance |
| Moov | module | Finance |
| Stripe | module | Finance |
| Square | module | Finance |
| Helcim | module | Finance |
| FedNow | protocol | Finance |
| RTP | protocol | Finance |
| Plaid | module | Finance |
| idempotency key | noun | Protocol |
| interchange-plus | concept | Finance |
| pay-as-you-go | adjective | Architecture |
| surcharging | noun | Finance |
| fiduciary | noun | Architecture |
| global transfer wealth | concept | Architecture |
| yield and turn | concept | Mathematics |
| polyblend assumption | noun | Mathematics |
| ach_transfer | system | Module |
| NACHA | noun | Finance |

### Module Scripts

| Script | Purpose |
|--------|---------|
| `start-frontend.sh` | Deploy webapp to Tomcat |
| `shutdown-frontend.sh` | Frontend shutdown notice |
| `start-backend.sh` | Initialize database (no TCP server) |
| `shutdown-backend.sh` | No-op (DB-only module) |
| `servlets/setup-db.sh` | Create nwe_dictionary (4 tables, 13 domains, 45+ terms) |
| `servlets/deploy-local.sh` | Tomcat deployment |

### Deploy

```bash
bash modules/dictionary/servlets/setup-db.sh
sudo bash modules/dictionary/servlets/deploy-local.sh
```

### Files

```
modules/dictionary/start-frontend.sh                          - Deploy webapp
modules/dictionary/shutdown-frontend.sh                       - Frontend shutdown
modules/dictionary/start-backend.sh                           - Initialize database
modules/dictionary/shutdown-backend.sh                        - No-op (DB-only)
modules/dictionary/servlets/setup-db.sh                       - Database creation (45+ terms)
modules/dictionary/servlets/deploy-local.sh                   - Tomcat deployment
modules/dictionary/servlets/servlet/src/main/webapp/          - Webapp (JSP pages)
modules/dictionary/source/                                    - (future: DictionaryServer.java)
modules/dictionary/configuration/                             - (future: dictionary-config.xml)
```
