#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# Brarner.M.Alete™ — Shutdown Script
# Undeploys the webapp from Tomcat. Optionally stops Tomcat.
# Usage: bash shutdown.sh [tomcat_home] [--stop-tomcat]
# ═══════════════════════════════════════════════════════════════
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BMA_ROOT="$SCRIPT_DIR"
TOMCAT_HOME="${1:-${CATALINA_HOME:-/home/mearvk/tomcat}}"
CONTEXT="brarner.m.alete"
DEPLOY_DIR="$TOMCAT_HOME/webapps/$CONTEXT"
STOP_TOMCAT=false

for arg in "$@"; do
    if [ "$arg" = "--stop-tomcat" ]; then STOP_TOMCAT=true; fi
done

echo "═══════════════════════════════════════════════════════════════"
echo " Brarner.M.Alete™ — Shutdown"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# ── 1. Remove webapp from Tomcat ─────────────────────────────────────────────
if [ -d "$DEPLOY_DIR" ]; then
    echo "[*] Removing deployment: $DEPLOY_DIR"
    rm -rf "$DEPLOY_DIR"
    echo "[✓] Webapp undeployed"
else
    echo "[*] Webapp not deployed at: $DEPLOY_DIR"
fi

# Remove WAR file if present
WAR_FILE="$TOMCAT_HOME/webapps/$CONTEXT.war"
if [ -f "$WAR_FILE" ]; then
    rm -f "$WAR_FILE"
    echo "[*] WAR file removed: $WAR_FILE"
fi

# ── 2. Optionally stop Tomcat ────────────────────────────────────────────────
if [ "$STOP_TOMCAT" = true ]; then
    echo "[*] Stopping Tomcat..."
    if [ -x "$TOMCAT_HOME/bin/shutdown.sh" ]; then
        "$TOMCAT_HOME/bin/shutdown.sh" 2>/dev/null || true
    else
        sudo systemctl stop tomcat 2>/dev/null || true
    fi
    sleep 2
    echo "[✓] Tomcat stopped"
fi

# ── 3. Remove symlinks ───────────────────────────────────────────────────────
rm -f "$BMA_ROOT/www" "$BMA_ROOT/web" 2>/dev/null || true

echo ""
echo "[✓] Brarner.M.Alete™ shut down"
echo ""
echo "    Restart: bash start.sh"
echo "═══════════════════════════════════════════════════════════════"
