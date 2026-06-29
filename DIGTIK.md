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
