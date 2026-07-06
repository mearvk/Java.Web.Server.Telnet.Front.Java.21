# Module Startup Script Standardization — July 3, 2026

## Overview

All NitroWebExpress™ modules now follow the **BMA (Brarner.M.Alete) prototype** for startup/shutdown scripts. This ensures consistency, reliability, and ease of deployment across the entire platform.

## Standardized Script Set

Each module with web services (`servlets/` directory) now has:

### Frontend (Webapp) Scripts
- **`start.sh`** — Deploy webapp to Tomcat + start Tomcat if needed
- **`shutdown.sh`** — Undeploy webapp from Tomcat (with optional `--stop-tomcat` flag)

### Backend (TCP Servers) Scripts
- **`start-backend.sh`** — Start TCP backend server(s) (if module has `source/` directory)
- **`shutdown-backend.sh`** — Stop TCP backend server(s) (if module has `source/` directory)

## Special Case: Futures™ Module

Futures uses the **-frontend/-backend naming convention** (per DIGTIK.md):
- `start-frontend.sh` / `shutdown-frontend.sh` (webapp)
- `start-backend.sh` / `shutdown-backend.sh` (TCP server)

## Script Locations

| Module | Location | Frontend | Backend |
|--------|----------|----------|---------|
| **Brarner.M.Alete (BMA)** | `modules/black/presidential/Brarner.M.Alete/` | ✓ | ✓ |
| **AE6E66** | `modules/AE6E66/` | ✓ | ✓ |
| **Black Belt** | `modules/black-belt/` | ✓ | ✗ |
| **CIA** | `modules/cia/` | ✓ | ✓ |
| **Duke University** | `modules/duke/` | ✓ | ✓ |
| **FBI** | `modules/fbi/` | ✓ | ✓ |
| **Gray Port Registry** | `modules/gray/` | ✓ | ✓ |
| **Gray85 Crème** | `modules/gray.a85/` | ✓ | ✓ |
| **Green.Durham.Grass.and.Herb** | `modules/Green.Durham.Grass.and.Herb/` | ✓ | ✓ |
| **Languages** | `modules/languages/` | ✓ | ✗ |
| **Library (Stanford)** | `modules/library/` | ✓ | ✓ |
| **NSA** | `modules/nsa/` | ✓ | ✓ |
| **Futures** | `modules/red/Futures/` | ✓ | ✓ |

## Usage Examples

### Start a Module (Frontend Only)
```bash
cd modules/AE6E66
bash start.sh              # Uses default /opt/tomcat
# OR
bash start.sh /custom/tomcat/path
```

### Start a Module (Frontend + Backend)
```bash
cd modules/cia
bash start-backend.sh      # Start TCP server
bash start.sh              # Deploy and start Tomcat
```

### Stop a Module (Graceful)
```bash
cd modules/cia
bash shutdown.sh           # Undeploy from Tomcat
bash shutdown-backend.sh   # Stop TCP server
```

### Stop Everything (including Tomcat)
```bash
cd modules/cia
bash shutdown.sh --stop-tomcat
bash shutdown-backend.sh
```

## Key Features of Standardized Scripts

### 1. **Idempotent Startup**
- `start.sh` checks if Tomcat is already running before starting
- `start-backend.sh` checks if backend PID file exists before starting
- Safe to run multiple times

### 2. **Automatic Deployment**
- Calls `servlets/deploy-local.sh` (which handles JDBC driver, web.xml, etc.)
- **Critical**: Follows DIGTIK Lesson #11 — clean deploy with `rm -rf` first
- No stale compiled JSP classes or leftover files

### 3. **PID Tracking**
- Backend processes tracked in `$MOD_ROOT/data/pids/backend.pid`
- Graceful shutdown: `kill $PID`, then `kill -9` if needed
- Ensures no orphaned processes

### 4. **Logging**
- Frontend: uses `$TOMCAT_HOME/logs/catalina.out`
- Backend: logs to `$MOD_ROOT/logging/backend.log`
- Easy troubleshooting with clear error messages

### 5. **Health Checks**
- Frontend: verifies HTTP 200/302 response from deployed context
- Backend: confirms PID is alive after spawn (1-second delay)
- Reports clear status (UP / FAILED / LOADING)

### 6. **Variable JVM Tuning**
- Backend default: `-Xms64m -Xmx256m` (can be customized per module)
- Classpath includes: source/, lib/*, jars/*

## Generated Script Details

### Frontend Scripts (`start.sh` / `shutdown.sh`)

**start.sh:**
1. Deploy webapp via `servlets/deploy-local.sh`
2. Check if Tomcat running (curl on port 8080)
3. Start Tomcat if not running (`bin/startup.sh` or systemctl)
4. Verify deployment with HTTP health check
5. Report URL and instructions

**shutdown.sh:**
1. Remove deployment directory from `$TOMCAT_HOME/webapps/{context}`
2. Remove WAR file if present
3. Optionally stop Tomcat (if `--stop-tomcat` flag given)
4. Clean up symlinks (if any)

### Backend Scripts (`start-backend.sh` / `shutdown-backend.sh`)

**start-backend.sh:**
1. Create `data/pids/` and `logging/` directories
2. Build classpath: source/:lib/*:jars/*
3. Check if already running via PID file
4. Spawn Java process in background (1-second verification delay)
5. Write PID to `data/pids/backend.pid`
6. Report status (OK or FAILED with log path)

**shutdown-backend.sh:**
1. Load PID from `data/pids/backend.pid`
2. Check if still alive (`kill -0 $PID`)
3. Graceful shutdown: `kill $PID` + 2-second wait
4. Escalate if needed: `kill -9 $PID`
5. Clean up PID file
6. Report stopped/skipped count

## Module Configuration Reference

Each module's startup behavior is determined by:

```bash
CONTEXT="<webapp-url-path>"         # from servlets/deploy-local.sh
MODULE_CLASS="<main-class-name>"     # from source/*.java
JVM_OPTS="-Xms64m -Xmx256m"          # tunable per module
```

| Module | Context | Main Class | Notes |
|--------|---------|-----------|-------|
| AE6E66 | ae6e66 | AE6E66Main | Single-class backend |
| CIA | california-cia | CaliforniaCIAServer | California suite |
| Duke | california-duke | DukeUniversityServer | California suite |
| FBI | california-fbi | CaliforniaFBIServer | California suite |
| Gray | gray-registry | GrayPortRegistryServer | Port leasing (9999) |
| Gray85 | gray85-registry | Gray85PortRegistryServer | Port leasing (10085) |
| GDGH | gdgh | Main | Green.Durham.Grass.and.Herb |
| Library | library | StanfordLibraryServer | Stanford module |
| NSA | california-nsa | CaliforniaNSAServer | California suite |
| Futures | (varies) | red.Futures.source.ai.server.DemocraticAIServer | Separate class path |

## Best Practices

### 1. **Always Start Backend First**
```bash
bash start-backend.sh
sleep 2
bash start.sh
```

### 2. **Always Stop Frontend First**
```bash
bash shutdown.sh
sleep 2
bash shutdown-backend.sh
```

### 3. **Monitor Logs During Startup**
```bash
# Terminal 1: Watch Tomcat log
tail -f /opt/tomcat/logs/catalina.out

# Terminal 2: Watch backend log
tail -f logging/backend.log

# Terminal 3: Run startup
bash start.sh
```

### 4. **Check Module Health**
```bash
# Frontend
curl -s http://localhost:8080/{context}/ | head -20

# Backend
ps aux | grep DemocraticAIServer
cat data/pids/backend.pid
```

### 5. **Custom Tomcat Home**
```bash
# All scripts support CATALINA_HOME env var or parameter
export CATALINA_HOME=/custom/tomcat
bash start.sh

# OR
bash start.sh /custom/tomcat
```

## Troubleshooting

### Script Says "Already Running" But Website Down
```bash
# Force clean redeploy
bash shutdown.sh --stop-tomcat
sleep 3
bash start.sh
```

### Backend Processes Not Stopping
```bash
# Check what's running
ps aux | grep java

# Kill by name if PID file corrupted
pkill -f "DemocraticAIServer"
rm data/pids/*.pid
bash start-backend.sh
```

### JDBC Errors on First Deploy
- Check: `$TOMCAT_HOME/webapps/{context}/WEB-INF/lib/` has `mysql-connector-j-*.jar`
- Deploy script copies from: `modules/black/presidential/Brarner.M.Alete/jars/` or `$NWE_ROOT/jars/mysql/`
- If missing, redeploy: `bash shutdown.sh && bash start.sh`

### JSP Pages Show Blank (HTTP 200 but No Content)
- **Lesson #10**: Check if web.xml redeclares JspServlet — **remove it**
- **Lesson #11**: Stale classes in Tomcat's `work/` directory
  ```bash
  bash shutdown.sh --stop-tomcat
  rm -rf /opt/tomcat/work/Catalina/{context}/
  bash start.sh
  ```

## Integration with CI/CD

All scripts are designed for automation:

```bash
#!/bin/bash
set -e

NWE_ROOT="/home/mearvk/IdeaProjects/Java.Web.Server.Telnet.Front.Java.21"
cd "$NWE_ROOT"

# Compile all modules
bash scripts/compile-all-modules.sh

# Deploy each module
for module in modules/AE6E66 modules/cia modules/duke; do
    cd "$module"
    bash start-backend.sh
    bash start.sh
    sleep 5
    cd "$NWE_ROOT"
done

# Verify all ports up
bash scripts/start-backend-modules.sh --check
```

## Migration from Old Scripts

Modules that previously had inconsistent or missing scripts now have:

| Old | New |
|-----|-----|
| `start-frontend.sh` | `start.sh` (standardized) |
| `installation/start.sh` | `start-backend.sh` (standardized) |
| Missing `shutdown.sh` | Now present |
| Missing `shutdown-backend.sh` | Now present (if backend exists) |

**To upgrade existing deployments:**

```bash
# Terminal 1: Start backend
bash start-backend.sh

# Terminal 2: Start frontend
bash start.sh

# Verify both are running
curl http://localhost:8080/{context}/
ps aux | grep java
```

## Author & References

- **Generated**: July 3, 2026
- **Based on**: BMA (Brarner.M.Alete™) Prototype
- **Standards**: DIGTIK.md Lessons 1–24
- **Locations**: 
  - `modules/black/presidential/Brarner.M.Alete/` (reference implementation)
  - All other modules now follow same pattern

---

**All modules are now ready for production deployment with consistent, reliable startup/shutdown procedures.**

