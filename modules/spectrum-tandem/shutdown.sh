#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════════
# NitroWebExpress™ — SpectrumTandem Shutdown (Full)
# Undeploys webapp and stops backend.
# Usage: bash shutdown.sh [--stop-tomcat]
# ═══════════════════════════════════════════════════════════════════════════════════
set -uo pipefail

MOD_ROOT="$(cd "$(dirname "$0")" && pwd)"
TOMCAT_HOME="${CATALINA_HOME:-/opt/apache-tomcat-11.0.2}"
CONTEXT="spectrum-tandem"
STOP_TOMCAT=false

for arg in "$@"; do
    [ "$arg" = "--stop-tomcat" ] && STOP_TOMCAT=true
done

echo ""
echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║  SpectrumTandem — Full Shutdown                                         ║"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo ""

# ── 1. Undeploy webapp ───────────────────────────────────────────────────────────
bash "$MOD_ROOT/shutdown-frontend.sh" "$TOMCAT_HOME"

# ── 2. Stop backend ─────────────────────────────────────────────────────────────
bash "$MOD_ROOT/shutdown-backend.sh"

# ── 3. Optionally stop Tomcat ────────────────────────────────────────────────────
if [ "$STOP_TOMCAT" = true ]; then
    echo "  [*] Stopping Tomcat..."
    if [ -x "$TOMCAT_HOME/bin/shutdown.sh" ]; then
        "$TOMCAT_HOME/bin/shutdown.sh" > /dev/null 2>&1
    else
        sudo systemctl stop tomcat 2>/dev/null || true
    fi
    echo "  [✓] Tomcat stopped"
fi

echo ""
echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║  SpectrumTandem Fully Stopped                                           ║"
echo "║  Restart: bash start-backend.sh && bash start.sh                          ║"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo ""
