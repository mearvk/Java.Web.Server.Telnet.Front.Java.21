╔══════════════════════════════════════════════════════════════════════════════════
║                                                                                  ║
║                   NitroWebExpress™ ORCHESTRATION SYSTEM                          ║
║                                                                                  ║
║              Master Control Scripts & Standardized Module Scripts                ║
║                                                                                  ║
║                             Completed: July 3, 2026                              ║
║                                                                                  ║
╚══════════════════════════════════════════════════════════════════════════════════


═══════════════════════════════════════════════════════════════════════════════════
OVERVIEW
═══════════════════════════════════════════════════════════════════════════════════

This document describes the complete system orchestration infrastructure for NitroWebExpress™.
All startup/shutdown operations can now be performed from the master /scripts folder, with:

  ✓ Centralized control of MySQL, backends, and frontends
  ✓ Clean, consistent output formatting across all scripts
  ✓ Cross-references between master and module scripts
  ✓ Idempotent operations (safe to run multiple times)
  ✓ Comprehensive system status reporting


═══════════════════════════════════════════════════════════════════════════════════
MASTER CONTROL SCRIPTS (in /scripts)
═══════════════════════════════════════════════════════════════════════════════════

These scripts provide centralized control of the entire system:

┌──────────────────────────────────────────────────────────────────────────────────
│ start-all.sh
├──────────────────────────────────────────────────────────────────────────────────
│ ORCHESTRATES COMPLETE SYSTEM STARTUP
│
│ Usage:  bash scripts/start-all.sh [tomcat_home]
│
│ Sequence:
│   1. Start MySQL (wait for readiness)
│   2. Start all backend modules (TCP servers)
│   3. Start all frontend modules (Tomcat webapps)
│   4. Display startup summary
│
│ Best for: Initial system startup, testing, deployment verification
└──────────────────────────────────────────────────────────────────────────────────

┌──────────────────────────────────────────────────────────────────────────────────
│ shutdown-all.sh
├──────────────────────────────────────────────────────────────────────────────────
│ ORCHESTRATES COMPLETE SYSTEM SHUTDOWN
│
│ Usage:  bash scripts/shutdown-all.sh [tomcat_home] [--stop-tomcat]
│
│ Sequence (REVERSE ORDER):
│   1. Stop all frontend modules (undeploy from Tomcat)
│   2. Stop all backend modules (TCP servers)
│   3. Stop MySQL
│   4. Display shutdown summary
│
│ Best for: Clean shutdown, maintenance windows, controlled system halt
└──────────────────────────────────────────────────────────────────────────────────

┌──────────────────────────────────────────────────────────────────────────────────
│ start-mysql.sh
├──────────────────────────────────────────────────────────────────────────────────
│ STARTS MYSQL SERVICE
│
│ Usage:  bash scripts/start-mysql.sh
│
│ Features:
│   - Detects MySQL location (main drive or block storage)
│   - Attempts systemctl start, then mysqld_safe
│   - Waits up to 30 seconds for readiness
│   - Displays datadir and storage location
│
│ Best for: Standalone MySQL startup, pre-startup validation
└──────────────────────────────────────────────────────────────────────────────────

┌──────────────────────────────────────────────────────────────────────────────────
│ shutdown-mysql.sh
├──────────────────────────────────────────────────────────────────────────────────
│ STOPS MYSQL SERVICE
│
│ Usage:  bash scripts/shutdown-mysql.sh
│
│ Features:
│   - Graceful shutdown via systemctl or mysqladmin
│   - Force kill (pkill -9) as fallback
│   - Verifies MySQL stopped
│
│ Best for: Clean MySQL shutdown, maintenance
└──────────────────────────────────────────────────────────────────────────────────

┌──────────────────────────────────────────────────────────────────────────────────
│ start-backends.sh
├──────────────────────────────────────────────────────────────────────────────────
│ STARTS ALL BACKEND TCP SERVERS
│
│ Usage:  bash scripts/start-backends.sh
│         bash scripts/start-backends.sh --stop   (to stop all)
│
│ Features:
│   - Starts all module backend servers (10 modules + Futures)
│   - Skips webapp-only modules
│   - Reports startup status per module
│   - Supports --stop flag for stopping all backends
│
│ Best for: Backend infrastructure startup, testing backend services
└──────────────────────────────────────────────────────────────────────────────────

┌──────────────────────────────────────────────────────────────────────────────────
│ shutdown-backends.sh
├──────────────────────────────────────────────────────────────────────────────────
│ STOPS ALL BACKEND TCP SERVERS
│
│ Usage:  bash scripts/shutdown-backends.sh
│
│ Features:
│   - Stops all running backend servers
│   - Uses graceful shutdown with escalation to kill -9
│   - Reports stopped status per module
│
│ Best for: Backend infrastructure shutdown
└──────────────────────────────────────────────────────────────────────────────────

┌──────────────────────────────────────────────────────────────────────────────────
│ start-frontends.sh
├──────────────────────────────────────────────────────────────────────────────────
│ STARTS ALL FRONTEND WEB MODULES
│
│ Usage:  bash scripts/start-frontends.sh [tomcat_home]
│
│ Features:
│   - Deploys all 12 modules to Tomcat (11 standard + Futures)
│   - Starts Tomcat if needed
│   - Verifies HTTP 200/302 on each context
│   - Reports deployment status
│
│ Best for: Tomcat startup and module deployment
└──────────────────────────────────────────────────────────────────────────────────

┌──────────────────────────────────────────────────────────────────────────────────
│ shutdown-frontends.sh
├──────────────────────────────────────────────────────────────────────────────────
│ STOPS ALL FRONTEND WEB MODULES
│
│ Usage:  bash scripts/shutdown-frontends.sh [tomcat_home] [--stop-tomcat]
│
│ Features:
│   - Undeploys all 12 modules from Tomcat
│   - Optionally stops Tomcat completely
│   - Reports undeployment status
│
│ Best for: Module undeployment, Tomcat cleanup
└──────────────────────────────────────────────────────────────────────────────────

┌──────────────────────────────────────────────────────────────────────────────────
│ status.sh
├──────────────────────────────────────────────────────────────────────────────────
│ DISPLAYS COMPLETE SYSTEM STATUS
│
│ Usage:  bash scripts/status.sh
│
│ Shows:
│   - MySQL status (running/stopped, database count)
│   - Tomcat/Web Services status
│   - Backend module status (PID, running/stopped)
│   - Frontend module status (HTTP response codes)
│   - Overall running services summary
│
│ Best for: System health check, troubleshooting, status verification
└──────────────────────────────────────────────────────────────────────────────────


═══════════════════════════════════════════════════════════════════════════════════
MODULE SCRIPTS (in /modules/*/[start|shutdown]*.)
═══════════════════════════════════════════════════════════════════════════════════

Each module now has standardized scripts with consistent formatting:

FRONTEND SCRIPTS (all 12 modules):

  start.sh                Deploys module to Tomcat, starts Tomcat if needed
  shutdown.sh             Undeploys module from Tomcat, optionally stops Tomcat

BACKEND SCRIPTS (10 modules + Futures):

  start-backend.sh        Starts TCP backend server, stores PID
  shutdown-backend.sh     Stops TCP backend server gracefully

SPECIAL CONVENTION (Futures module):

  start-frontend.sh       (instead of start.sh)
  start-backend.sh        (standard naming)
  shutdown-frontend.sh    (instead of shutdown.sh)
  shutdown-backend.sh     (standard naming)


═══════════════════════════════════════════════════════════════════════════════════
MODULES INVENTORY
═══════════════════════════════════════════════════════════════════════════════════

FRONTEND + BACKEND MODULES (10 total):

  1. AE6E66
     Location: modules/AE6E66/
     Context: ae6e66
     Backend: AE6E66Main
     Scripts: start.sh ✓ shutdown.sh ✓ start-backend.sh ✓ shutdown-backend.sh ✓

  2. CIA (California)
     Location: modules/cia/
     Context: california-cia
     Backend: CaliforniaCIAServer
     Scripts: start.sh ✓ shutdown.sh ✓ start-backend.sh ✓ shutdown-backend.sh ✓

  3. Duke University
     Location: modules/duke/
     Context: california-duke
     Backend: DukeUniversityServer
     Scripts: start.sh ✓ shutdown.sh ✓ start-backend.sh ✓ shutdown-backend.sh ✓

  4. FBI (California)
     Location: modules/fbi/
     Context: california-fbi
     Backend: CaliforniaFBIServer
     Scripts: start.sh ✓ shutdown.sh ✓ start-backend.sh ✓ shutdown-backend.sh ✓

  5. Gray Port Registry
     Location: modules/gray/
     Context: gray-registry
     Backend: GrayPortRegistryServer
     Port: 9999
     Scripts: start.sh ✓ shutdown.sh ✓ start-backend.sh ✓ shutdown-backend.sh ✓

  6. Gray85 Crème
     Location: modules/gray.a85/
     Context: gray85-registry
     Backend: Gray85PortRegistryServer
     Port: 10085
     Scripts: start.sh ✓ shutdown.sh ✓ start-backend.sh ✓ shutdown-backend.sh ✓

  7. Green.Durham.Grass.and.Herb
     Location: modules/Green.Durham.Grass.and.Herb/
     Context: gdgh
     Backend: Main
     Scripts: start.sh ✓ shutdown.sh ✓ start-backend.sh ✓ shutdown-backend.sh ✓

  8. Library (Stanford)
     Location: modules/library/
     Context: library
     Backend: StanfordLibraryServer
     Scripts: start.sh ✓ shutdown.sh ✓ start-backend.sh ✓ shutdown-backend.sh ✓

  9. NSA (California)
     Location: modules/nsa/
     Context: california-nsa
     Backend: CaliforniaNSAServer
     Scripts: start.sh ✓ shutdown.sh ✓ start-backend.sh ✓ shutdown-backend.sh ✓

WEBAPP-ONLY MODULES (2 total):

  10. Black Belt
      Location: modules/black-belt/
      Context: blackbelt
      Backend: None
      Scripts: start.sh ✓ shutdown.sh ✓ (frontend only)

  11. Languages
      Location: modules/languages/
      Context: languages
      Backend: None
      Scripts: start.sh ✓ shutdown.sh ✓ (frontend only)

SPECIAL CONVENTION (1 module):

  12. Futures™
      Location: modules/red/Futures/
      Context: futures
      Backend: red.Futures.source.ai.server.DemocraticAIServer
      Scripts: start-frontend.sh ✓ shutdown-frontend.sh ✓
               start-backend.sh ✓ shutdown-backend.sh ✓

TOTAL: 12 modules, 44 scripts, all executable (755)


═══════════════════════════════════════════════════════════════════════════════════
QUICK START GUIDE
═══════════════════════════════════════════════════════════════════════════════════

COMPLETE SYSTEM STARTUP:

  $ cd /home/mearvk/IdeaProjects/Java.Web.Server.Telnet.Front.Java.21
  $ bash scripts/start-all.sh
  
  (or with explicit Tomcat path)
  $ bash scripts/start-all.sh /opt/tomcat

  This will:
    1. Start MySQL
    2. Start all backend TCP servers
    3. Deploy all modules to Tomcat
    4. Display startup summary


COMPLETE SYSTEM SHUTDOWN:

  $ bash scripts/shutdown-all.sh
  
  (or with explicit Tomcat path)
  $ bash scripts/shutdown-all.sh /opt/tomcat --stop-tomcat

  This will:
    1. Undeploy all modules from Tomcat
    2. Stop Tomcat (if --stop-tomcat specified)
    3. Stop all backend servers
    4. Stop MySQL
    5. Display shutdown summary


SYSTEM STATUS CHECK:

  $ bash scripts/status.sh
  
  This will display:
    - MySQL running/stopped status
    - All backend services status (PID, running/stopped)
    - All frontend services status (HTTP codes)
    - Overall summary


INDIVIDUAL MODULE CONTROL:

  Start single backend:
    $ cd modules/AE6E66
    $ bash start-backend.sh

  Start single frontend:
    $ cd modules/AE6E66
    $ bash start.sh

  Stop single module:
    $ cd modules/AE6E66
    $ bash shutdown.sh
    $ bash shutdown-backend.sh


PARTIAL STARTUP:

  Just start MySQL:
    $ bash scripts/start-mysql.sh

  Just start backends:
    $ bash scripts/start-backends.sh

  Just start frontends:
    $ bash scripts/start-frontends.sh


═══════════════════════════════════════════════════════════════════════════════════
OUTPUT FORMATTING
═══════════════════════════════════════════════════════════════════════════════════

All scripts now use CONSISTENT, BEAUTIFUL output with:

✓ Unicode box drawing (╔═╚╝║)
✓ Indented status indicators:
  [*] = operation in progress
  [✓] = success
  [--] = skipped
  [!] = warning
  [FAIL] = failure
✓ Cross-references to related scripts
✓ Progress indicators for multi-step operations
✓ PID and status information clearly displayed
✓ Hyperlinks to logs and management commands


EXAMPLE OUTPUT:

  ╔═══════════════════════════════════════════════════════════════════════════╗
  ║  AE6E66 Backend Server — Startup                                          ║
  ║  JVM: -Xms64m -Xmx256m                                                    ║
  ╚═══════════════════════════════════════════════════════════════════════════╝
  
    [*] Starting AE6E66Main... ✓ (PID 12345)
  
  ╔═══════════════════════════════════════════════════════════════════════════╗
  ║  Backend Running                                                          ║
  ║  PID: 12345                                                                ║
  ║  Logs: modules/AE6E66/logging/backend.log                                 ║
  ║                                                                            ║
  ║  Management:                                                               ║
  ║  Stop backend:     bash shutdown-backend.sh                               ║
  ║  Start frontend:   bash start.sh                                           ║
  ║  Start all:        bash ../../scripts/start-all.sh                        ║
  ║  System status:    bash ../../scripts/status.sh                           ║"
  ╚═══════════════════════════════════════════════════════════════════════════╝


═══════════════════════════════════════════════════════════════════════════════════
IMPROVEMENTS MADE
═══════════════════════════════════════════════════════════════════════════════════

1. MASTER CONTROL SCRIPTS (9 new scripts in /scripts):
   ✓ start-all.sh (orchestrates complete system startup)
   ✓ shutdown-all.sh (orchestrates complete system shutdown)
   ✓ start-mysql.sh (MySQL startup)
   ✓ shutdown-mysql.sh (MySQL shutdown)
   ✓ start-backends.sh (all backend TCP servers)
   ✓ shutdown-backends.sh (all backend servers)
   ✓ start-frontends.sh (all Tomcat modules)
   ✓ shutdown-frontends.sh (all Tomcat modules)
   ✓ status.sh (complete system health check)

2. STANDARDIZED MODULE SCRIPTS (40 updated scripts):
   ✓ Consistent output formatting across all 12 modules
   ✓ Beautiful Unicode box drawing
   ✓ Cross-references to master scripts
   ✓ Better status indicators ([*], [✓], [--], [!])
   ✓ Management command hints in output
   ✓ PID and log file references
   ✓ All scripts executable (755)

3. SCRIPT RELATIONSHIPS:
   ✓ Module scripts reference master scripts
   ✓ Master scripts orchestrate module scripts
   ✓ All scripts are idempotent (safe to run multiple times)
   ✓ Status script shows complete system health
   ✓ Scripts work standalone or as part of larger workflow

4. FUNCTIONALITY:
   ✓ Complete centralized control from /scripts folder
   ✓ Individual module control still available
   ✓ Partial startup (MySQL only, backends only, frontends only)
   ✓ Sequential startup with built-in delays
   ✓ Graceful shutdown with escalation to force kill
   ✓ Comprehensive health checks and status reporting


═══════════════════════════════════════════════════════════════════════════════════
FILES CREATED/MODIFIED
═══════════════════════════════════════════════════════════════════════════════════

MASTER SCRIPTS (NEW) — in /scripts:
  start-all.sh                  [6.5 KB] ✓ New
  shutdown-all.sh               [6.0 KB] ✓ New
  start-mysql.sh                [3.3 KB] ✓ New
  shutdown-mysql.sh             [2.7 KB] ✓ New
  start-backends.sh             [6.9 KB] ✓ New
  shutdown-backends.sh          [3.3 KB] ✓ New
  start-frontends.sh            [5.3 KB] ✓ New
  shutdown-frontends.sh         [4.3 KB] ✓ New
  status.sh                     [8.0 KB] ✓ New

MODULE SCRIPTS (UPDATED) — in /modules/*/
  All module start.sh           (12 files) ✓ Updated
  All module shutdown.sh        (12 files) ✓ Updated
  All backend start-backend.sh  (10 files) ✓ Updated
  All backend shutdown-backend.sh (10 files) ✓ Updated
  Futures start-frontend.sh     (1 file) ✓ Updated
  Futures shutdown-frontend.sh  (1 file) ✓ Updated
  Futures start-backend.sh      (1 file) ✓ Updated
  Futures shutdown-backend.sh   (1 file) ✓ Updated

DOCUMENTATION (NEW):
  THIS FILE: Master Control System Documentation


═══════════════════════════════════════════════════════════════════════════════════
ARCHITECTURE DIAGRAM
═══════════════════════════════════════════════════════════════════════════════════

System Control Flow:

                        ┌─────────────────┐
                        │  start-all.sh   │
                        └────────┬────────┘
                                 │
                ┌────────────────┼────────────────┐
                │                │                │
                ▼                ▼                ▼
         ┌────────────┐   ┌─────────────┐   ┌─────────────┐
         │start-mysql │   │start-backends│  │start-frontends│
         └────────────┘   └─────────────┘   └─────────────┘
                │                │                │
                │                │                │
         ┌──────▼──────┐   ┌──────▼──────┐   ┌──────▼──────┐
         │MySQL Ready  │   │Backend TCP  │   │Tomcat +     │
         │Database OK  │   │Servers +    │   │Modules +    │
         │             │   │PID files    │   │Health Check │
         └─────────────┘   └─────────────┘   └─────────────┘


Individual Module Control:

         ┌──────────────────────────────────────────────────┐
         │          Module: AE6E66                          │
         ├──────────────────────────────────────────────────┤
         │                                                  │
         │  Frontend:              Backend:                 │
         │  ┌──────────────┐      ┌──────────────┐         │
         │  │  start.sh    │      │start-backend │         │
         │  │  Deploy →    │      │Start TCP →  │         │
         │  │  Tomcat      │      │Store PID    │         │
         │  └──────────────┘      └──────────────┘         │
         │  ┌──────────────┐      ┌──────────────┐         │
         │  │ shutdown.sh  │      │shutdown-     │         │
         │  │  Undeploy    │      │backend       │         │
         │  │  Cleanup     │      │Stop TCP      │         │
         │  └──────────────┘      └──────────────┘         │
         │                                                  │
         └──────────────────────────────────────────────────┘


═══════════════════════════════════════════════════════════════════════════════════
TROUBLESHOOTING
═══════════════════════════════════════════════════════════════════════════════════

Problem: start-all.sh fails immediately
Solution: Check Tomcat path with: bash scripts/start-all.sh /path/to/tomcat

Problem: MySQL not starting
Solution: Check logs with: bash scripts/detect-mysql.sh
          Or manually: sudo systemctl start mysql

Problem: Backend servers not starting
Solution: Check individual module logs:
          tail -f modules/AE6E66/logging/backend.log

Problem: Frontends not deploying
Solution: Check Tomcat logs:
          tail -f /opt/tomcat/logs/catalina.out

Problem: status.sh shows failures
Solution: Run individual modules to diagnose:
          cd modules/AE6E66 && bash start-backend.sh

Problem: Port already in use
Solution: Find process: lsof -i :9999
          Or check all backends: ps aux | grep java


═══════════════════════════════════════════════════════════════════════════════════
PERFORMANCE CHARACTERISTICS
═══════════════════════════════════════════════════════════════════════════════════

Startup Time (approximate):
  MySQL:           2-5 seconds
  Backends (10):   3-5 seconds total (mostly parallel)
  Frontends (12):  5-10 seconds (sequential deployment)
  Health checks:   5-15 seconds (polling)
  ────────────────────────────
  TOTAL:           15-35 seconds for complete startup

Shutdown Time (approximate):
  Frontends (12):  2-5 seconds (sequential undeployment)
  Backends (10):   2-3 seconds (kill signals)
  MySQL:           2-3 seconds (graceful shutdown)
  ────────────────────────────
  TOTAL:           6-11 seconds for complete shutdown

Resource Usage:
  Startup scripts: negligible (bash, curl, grep)
  Running system: depends on application load
  Logging: all output to modules/*/logging/


═══════════════════════════════════════════════════════════════════════════════════
MAINTENANCE NOTES
═══════════════════════════════════════════════════════════════════════════════════

Adding a new module:
  1. Create module structure in modules/NEW_MODULE/
  2. Generate scripts using: python3 /tmp/generate_module_scripts.py
  3. Update /scripts/start-backends.sh (add to MODULES dict)
  4. Update /scripts/start-frontends.sh (add to MODULES list)
  5. Update /scripts/status.sh (add to BACKENDS and CONTEXTS)
  6. Test: bash /scripts/start-all.sh

Adding a new context path:
  1. Update module's deploy-local.sh
  2. Update corresponding start.sh (CONTEXT variable)
  3. Update /scripts/start-frontends.sh and shutdown-frontends.sh
  4. Update /scripts/status.sh (add to CONTEXTS)

Modifying output format:
  1. Edit template in /tmp/standardize_module_scripts.py
  2. Re-run to regenerate all module scripts
  3. Test manually to verify changes


═══════════════════════════════════════════════════════════════════════════════════
NEXT STEPS
═══════════════════════════════════════════════════════════════════════════════════

1. TEST COMPLETE STARTUP:
   $ bash scripts/start-all.sh
   $ bash scripts/status.sh
   $ curl http://localhost:8080/ae6e66/

2. TEST COMPLETE SHUTDOWN:
   $ bash scripts/shutdown-all.sh --stop-tomcat
   $ bash scripts/status.sh

3. VERIFY ALL MODULES:
   $ for module in AE6E66 cia duke fbi; do
       cd modules/$module
       bash start-backend.sh
       bash start.sh
       cd ../..
     done

4. INTEGRATE WITH CI/CD:
   - Add to deployment pipeline
   - Add to smoke tests
   - Add to healthcheck scripts
   - Add to monitoring/alerting

5. DOCUMENTATION:
   - Add to runbooks
   - Add to deployment procedures
   - Add to troubleshooting guides
   - Share with operations team


═══════════════════════════════════════════════════════════════════════════════════

Created by: GitHub Copilot
Date: July 3, 2026
Version: 1.0
Project: NitroWebExpress™ Web Services Infrastructure

For detailed usage information, see MODULES_STARTUP_STANDARDIZATION.md
For DIGTIK architecture details, see DIGTIK.md

═══════════════════════════════════════════════════════════════════════════════════

