#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# NitroWebExpress™ — Start All Services
# Orchestrates complete startup sequence:
#   1. MySQL
#   2. Compile all modules
#   3. Backend modules (TCP servers)
#   4. Frontend modules (Tomcat webapps)
#
# Usage: bash scripts/start-all.sh [tomcat_home]
# ═══════════════════════════════════════════════════════════════════════════════
set -uo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TOMCAT_HOME="${1:-${CATALINA_HOME:-/opt/apache-tomcat-11.0.2}}"

source "$PROJECT_ROOT/scripts/print-descriptor.sh" 2>/dev/null || true

echo ""
echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║                                                                           ║"
echo "║   NitroWebExpress™ — Complete System Startup                              ║"
echo "║   Sequence: MySQL → Compile → Backends → Frontends                        ║"
echo "║   Log all commands with: tee start-all.log                                ║"
echo "║                                                                           ║"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo ""

# ── Phase 0: Stop existing services if running ────────────────────────────────
echo ""
echo "───────────────────────────────────────────────────────────────────────────────"
echo "Pre-flight: Checking for running services..."
echo "───────────────────────────────────────────────────────────────────────────────"
echo ""

NEED_STOP=0

# Check if Tomcat is running
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/ 2>/dev/null | grep -q "200\|302\|401\|403"; then
    echo "  [*] Tomcat is running — will shut down before redeploy"
    NEED_STOP=1
fi

# Check if Main.java / backends are running
if [ -f "$PROJECT_ROOT/data/nwe-main.pid" ] && kill -0 "$(cat "$PROJECT_ROOT/data/nwe-main.pid" 2>/dev/null)" 2>/dev/null; then
    echo "  [*] NWE Main process running (PID $(cat "$PROJECT_ROOT/data/nwe-main.pid")) — will shut down"
    NEED_STOP=1
fi

# Check if any NWE backend ports are active
for PORT in 49152 20000 2000 49199 5512 6682; do
    if timeout 1 bash -c "echo >/dev/tcp/localhost/$PORT" 2>/dev/null; then
        echo "  [*] Port $PORT is active — existing backends detected"
        NEED_STOP=1
        break
    fi
done

if [ "$NEED_STOP" -eq 1 ]; then
    echo ""
    echo "  [*] Stopping existing services first..."
    if [ -f "$PROJECT_ROOT/scripts/shutdown-all.sh" ]; then
        bash "$PROJECT_ROOT/scripts/shutdown-all.sh" 2>/dev/null || true
    else
        # Manual shutdown
        if [ -x "$TOMCAT_HOME/bin/shutdown.sh" ]; then
            "$TOMCAT_HOME/bin/shutdown.sh" >/dev/null 2>&1 || true
        fi
        if [ -f "$PROJECT_ROOT/data/nwe-main.pid" ]; then
            kill "$(cat "$PROJECT_ROOT/data/nwe-main.pid" 2>/dev/null)" 2>/dev/null || true
        fi
        bash "$PROJECT_ROOT/scripts/shutdown-backends.sh" 2>/dev/null || true
    fi
    sleep 3
    echo "  [✓] Existing services stopped"
else
    echo "  [✓] No running services detected — clean start"
fi

# ── Phase 1: MySQL ────────────────────────────────────────────────────────────
echo ""
echo "───────────────────────────────────────────────────────────────────────────────"
echo "Phase 1/4: Starting MySQL..."
echo "───────────────────────────────────────────────────────────────────────────────"
echo ""

if bash "$PROJECT_ROOT/scripts/start-mysql.sh"; then
    echo ""
    echo "  [✓] MySQL startup complete"
else
    echo ""
    echo "  [!] MySQL startup had issues (continuing anyway)"
fi

sleep 2

# ── Open Firewall Ports ───────────────────────────────────────────────────────
echo ""
echo "───────────────────────────────────────────────────────────────────────────────"
echo "Opening Firewall Ports..."
echo "───────────────────────────────────────────────────────────────────────────────"
echo ""

source "$PROJECT_ROOT/scripts/nwe-ports.sh"
nwe_open_ports

sleep 1

# ── Phase 2: Compile All Modules ──────────────────────────────────────────────
echo ""
echo "───────────────────────────────────────────────────────────────────────────────"
echo "Phase 2/4: Compiling All Modules..."
echo "───────────────────────────────────────────────────────────────────────────────"
echo ""

if bash "$PROJECT_ROOT/scripts/compile-all-modules.sh"; then
    echo ""
    echo "  [✓] Compilation complete"
else
    echo ""
    echo "  [!] Compilation had errors (backends may fail — check out/ directory)"
fi

# ── Phase 3: Backend Modules ──────────────────────────────────────────────────
echo ""
echo "───────────────────────────────────────────────────────────────────────────────"
echo "Phase 3/4: Starting Backend Modules..."
echo "───────────────────────────────────────────────────────────────────────────────"
echo ""

if bash "$PROJECT_ROOT/scripts/start-backends.sh"; then
    echo ""
    echo "  [✓] Backend startup complete"
else
    echo ""
    echo "  [!] Some backends failed to start (continuing anyway)"
fi

sleep 3

# ── Phase 4: Frontend Modules ─────────────────────────────────────────────────
echo ""
echo "───────────────────────────────────────────────────────────────────────────────"
echo "Phase 4/4: Starting Frontend Modules..."
echo "───────────────────────────────────────────────────────────────────────────────"
echo ""

if bash "$PROJECT_ROOT/scripts/start-frontends.sh" "$TOMCAT_HOME"; then
    echo ""
    echo "  [✓] Frontend startup complete"
else
    echo ""
    echo "  [!] Some frontends failed to start"
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo ""
echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║                                                                           ║"
echo "║   ✓ NitroWebExpress™ System Startup Complete!                             ║"
echo "║                                                                           ║"
echo "║   NEXT STEPS:                                                             ║"
echo "║   • Verify services:  bash scripts/status.sh                              ║"
echo "║   • View logs:        tail -f logging/*.log                               ║"
echo "║   • Test endpoints:   curl http://localhost:8080/ae6e66/                   ║"
echo "║   • Shutdown all:     bash scripts/shutdown-all.sh                         ║"
echo "║                                                                           ║"
echo "║   Tomcat:   $TOMCAT_HOME                                        ║"
echo "║   Project:  $PROJECT_ROOT ║"
echo "║                                                                           ║"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo ""

