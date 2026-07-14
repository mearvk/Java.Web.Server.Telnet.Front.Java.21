#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# NitroWebExpress™ — Start All Services
# Orchestrates complete startup sequence:
#   1. MySQL
#   2. Backend modules (TCP servers)
#   3. Frontend modules (Tomcat webapps)
#
# Usage: bash scripts/start-all.sh [tomcat_home]
# ═══════════════════════════════════════════════════════════════════════════════
set -uo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TOMCAT_HOME="${1:-${CATALINA_HOME:-/home/mearvk/tomcat}}"

source "$PROJECT_ROOT/scripts/print-descriptor.sh" 2>/dev/null || true

echo ""
echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║                                                                           ║"
echo "║   NitroWebExpress™ — Complete System Startup                              ║"
echo "║   Sequence: MySQL → Backends → Frontends                                  ║"
echo "║   Log all commands with: tee start-all.log                                ║"
echo "║                                                                           ║"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo ""

# ── Phase 1: MySQL ────────────────────────────────────────────────────────────
echo ""
echo "───────────────────────────────────────────────────────────────────────────────"
echo "Phase 1/3: Starting MySQL..."
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

# ── Phase 2: Backend Modules ──────────────────────────────────────────────────
echo ""
echo "───────────────────────────────────────────────────────────────────────────────"
echo "Phase 2/3: Starting Backend Modules..."
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

# ── Phase 3: Frontend Modules ─────────────────────────────────────────────────
echo ""
echo "───────────────────────────────────────────────────────────────────────────────"
echo "Phase 3/3: Starting Frontend Modules..."
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
printf "║   Tomcat:   %-60s ║\n" "$TOMCAT_HOME"
printf "║   Project:  %-60s ║\n" "$PROJECT_ROOT"
echo "║                                                                           ║"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo ""

