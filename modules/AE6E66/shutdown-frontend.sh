#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# NitroWebExpress™ — AE6E66 Frontend Shutdown
# Undeploys the AE6E66 webapp from Tomcat.
# Usage: bash shutdown-frontend.sh [tomcat_home] [--stop-tomcat]
# ═══════════════════════════════════════════════════════════════════════════════
set -uo pipefail

TOMCAT_HOME="${1:-${CATALINA_HOME:-/home/mearvk/tomcat}}"
CONTEXT="ae6e66"
STOP_TOMCAT=false
for arg in "$@"; do [ "$arg" = "--stop-tomcat" ] && STOP_TOMCAT=true; done

echo ""
echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║  AE6E66 — Frontend Shutdown                                               ║"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo ""

DEPLOY_DIR="$TOMCAT_HOME/webapps/$CONTEXT"
if [ -d "$DEPLOY_DIR" ]; then
    rm -rf "$DEPLOY_DIR"
    echo "  [✓] Webapp undeployed: $DEPLOY_DIR"
else
    echo "  [--] Webapp not deployed at $DEPLOY_DIR"
fi
rm -f "$TOMCAT_HOME/webapps/$CONTEXT.war" 2>/dev/null || true

if [ "$STOP_TOMCAT" = true ]; then
    echo "  [*] Stopping Tomcat..."
    sudo systemctl stop tomcat 2>/dev/null || "$TOMCAT_HOME/bin/shutdown.sh" 2>/dev/null || true
    echo "  [✓] Tomcat stopped"
fi

echo ""
echo "  Restart: bash start-frontend.sh"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo ""
