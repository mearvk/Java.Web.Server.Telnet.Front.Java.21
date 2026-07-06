#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════════
# NitroWebExpress™ — gray.a85 Frontend Shutdown
# Undeploys the webapp from Tomcat.
# Usage: bash shutdown.sh [tomcat_home] [--stop-tomcat]
# ═══════════════════════════════════════════════════════════════════════════════════
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MOD_ROOT="$SCRIPT_DIR"
PROJECT_ROOT="$(cd "$MOD_ROOT/../.." && pwd)"
TOMCAT_HOME="${1:-${CATALINA_HOME:-/home/mearvk/tomcat}}"
CONTEXT="gray85-registry"
DEPLOY_DIR="$TOMCAT_HOME/webapps/$CONTEXT"
STOP_TOMCAT=false

for arg in "$@"; do
    if [ "$arg" = "--stop-tomcat" ]; then STOP_TOMCAT=true; fi
done

echo ""
echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║  gray.a85 Frontend — Shutdown                                               ║"
echo "║  Context: /$CONTEXT                                                      ║"
echo "║  Tomcat:  $TOMCAT_HOME                                                    ║"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo ""

# ── 1. Remove webapp from Tomcat ─────────────────────────────────────────────
if [ -d "$DEPLOY_DIR" ]; then
    echo "  [*] Removing deployment..."
    rm -rf "$DEPLOY_DIR"
    echo "  [✓] Webapp undeployed"
else
    echo "  [--] Webapp not deployed"
fi

# Remove WAR file if present
WAR_FILE="$TOMCAT_HOME/webapps/$CONTEXT.war"
if [ -f "$WAR_FILE" ]; then
    rm -f "$WAR_FILE"
    echo "  [✓] WAR removed"
fi

# ── 2. Optionally stop Tomcat ────────────────────────────────────────────────
if [ "$STOP_TOMCAT" = true ]; then
    echo "  [*] Stopping Tomcat..."
    if [ -x "$TOMCAT_HOME/bin/shutdown.sh" ]; then
        "$TOMCAT_HOME/bin/shutdown.sh" > /dev/null 2>&1 || true
    else
        sudo systemctl stop tomcat 2>/dev/null || true
    fi
    sleep 2
    echo "  [✓] Tomcat stopped"
fi

echo ""
echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║  gray.a85 Frontend Stopped                                                  ║"
echo "║                                                                            ║"
echo "║  Management:                                                               ║"
echo "║  Restart module:   bash start.sh                                           ║"
echo "║  Stop backend:     bash shutdown-backend.sh                               ║"
echo "║  Shutdown all:     bash ../../scripts/shutdown-all.sh                     ║"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo ""
