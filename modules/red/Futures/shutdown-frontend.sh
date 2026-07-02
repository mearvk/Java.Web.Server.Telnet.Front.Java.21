#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# Futures™ (Democratic ProFront National 1.0) — Frontend Shutdown
# Undeploys the webapp from Tomcat.
# Usage: bash shutdown-frontend.sh [tomcat_home] [--stop-tomcat]
# ═══════════════════════════════════════════════════════════════
set -e

TOMCAT_HOME="${1:-${CATALINA_HOME:-/opt/tomcat}}"
CONTEXT="futures"
DEPLOY_DIR="$TOMCAT_HOME/webapps/$CONTEXT"
STOP_TOMCAT=false

for arg in "$@"; do
    [ "$arg" = "--stop-tomcat" ] && STOP_TOMCAT=true
done

echo "═══════════════════════════════════════════════════════════════"
echo " Futures™ — Frontend Shutdown"
echo "═══════════════════════════════════════════════════════════════"
echo ""

if [ -d "$DEPLOY_DIR" ]; then
    rm -rf "$DEPLOY_DIR"
    echo "[✓] Webapp undeployed: $DEPLOY_DIR"
else
    echo "[*] Webapp not deployed"
fi

rm -f "$TOMCAT_HOME/webapps/$CONTEXT.war" 2>/dev/null

if [ "$STOP_TOMCAT" = true ]; then
    echo "[*] Stopping Tomcat..."
    sudo systemctl stop tomcat 2>/dev/null || "$TOMCAT_HOME/bin/shutdown.sh" 2>/dev/null || true
    echo "[✓] Tomcat stopped"
fi

echo ""
echo "    Restart: bash start-frontend.sh"
echo "═══════════════════════════════════════════════════════════════"
