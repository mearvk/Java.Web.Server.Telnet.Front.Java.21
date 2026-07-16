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
```

## Author

Max Rupplin — MEARVK LLC  
mearvk@mearvk.us | mearvk@outlook.com  
555 South Mangum St, Durham, NC 27701


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
| ASK (context) | `ASK\|{MODULE} SEARCH field=val context=table` | FBI, CIA, NSA, Duke, Stanford |
| CLASSIFY | `CLASSIFY\|{module}\|{text}` | FBI, CIA, NSA (auto-categorize) |
| TRAIN | `TRAIN\|{module}\|{category}\|{example}` | Knowledge base growth |
| RELAY | `RELAY\|{text}` | Cross-module routing |
| STATUS | `STATUS` | Health checks |

Java client: `commons.StrernaryConnector.ask()`, `.classify()`, `.train()`, `.relay()`

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
