#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════════
# NitroWebExpress™ — Defined™ Frontend Shutdown
# Theme: Dark Gray — Definition to Narrow Cause
# Undeploys the webapp from Tomcat.
# Usage: bash shutdown-frontend.sh [tomcat_home]
# ═══════════════════════════════════════════════════════════════════════════════════
set -e

MOD_ROOT="$(cd "$(dirname "$0")" && pwd)"
TOMCAT_HOME="${1:-${CATALINA_HOME:-/opt/apache-tomcat-11.0.2}}"
CONTEXT="defined"

echo ""
echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║  Defined™ Frontend — Shutdown                                             ║"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo ""

WEBAPP_DIR="$TOMCAT_HOME/webapps/$CONTEXT"

if [ -d "$WEBAPP_DIR" ]; then
    rm -rf "$WEBAPP_DIR"
    rm -f "$TOMCAT_HOME/webapps/$CONTEXT.war" 2>/dev/null
    echo "  [✓] Undeployed /$CONTEXT from Tomcat"
else
    echo "  [--] /$CONTEXT not deployed (nothing to remove)"
fi

echo ""
