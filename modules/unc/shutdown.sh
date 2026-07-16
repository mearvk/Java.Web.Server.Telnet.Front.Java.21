#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════════
# NitroWebExpress™ — UNC Chapel Hill Frontend Shutdown (Legacy)
# Usage: bash shutdown.sh [tomcat_home] [--stop-tomcat]
# ═══════════════════════════════════════════════════════════════════════════════════
set -e
TOMCAT_HOME="${1:-${CATALINA_HOME:-/opt/apache-tomcat-11.0.2}}"
CONTEXT="california-unc"
DEPLOY_DIR="$TOMCAT_HOME/webapps/$CONTEXT"
STOP_TOMCAT=false
for arg in "$@"; do [ "$arg" = "--stop-tomcat" ] && STOP_TOMCAT=true; done

echo ""
echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║  unc Frontend — Shutdown                                                ║"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo ""
if [ -d "$DEPLOY_DIR" ]; then
    rm -rf "$DEPLOY_DIR"; echo "  [✓] Webapp undeployed"
else
    echo "  [--] Webapp not deployed"
fi
rm -f "$TOMCAT_HOME/webapps/$CONTEXT.war" 2>/dev/null || true
if [ "$STOP_TOMCAT" = true ]; then
    "$TOMCAT_HOME/bin/shutdown.sh" 2>/dev/null || sudo systemctl stop tomcat 2>/dev/null || true
    echo "  [✓] Tomcat stopped"
fi
echo ""
echo "  Restart: bash start.sh"
echo ""
