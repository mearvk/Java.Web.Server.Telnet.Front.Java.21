#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# NitroWebExpress™ — California CIA Frontend Startup
# Usage: bash start-frontend.sh [tomcat_home]
# ═══════════════════════════════════════════════════════════════════════════════
set -uo pipefail

MOD_ROOT="$(cd "$(dirname "$0")" && pwd)"
TOMCAT_HOME="${1:-${CATALINA_HOME:-/home/mearvk/tomcat}}"
CONTEXT="california-cia"

echo ""
echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║  California CIA — Frontend Startup                                        ║"
echo "║  Context: /$CONTEXT                                                       ║"
echo "║  Tomcat:  $TOMCAT_HOME                                                    ║"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo ""

echo "  [*] Deploying to Tomcat..."
bash "$MOD_ROOT/servlets/deploy-local.sh" "$TOMCAT_HOME"
echo "  [✓] Deployed"
echo ""

if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/ 2>/dev/null | grep -q "200\|302\|401\|403"; then
    echo "  [✓] Tomcat already running"
else
    echo "  [*] Starting Tomcat..."
    if [ -x "$TOMCAT_HOME/bin/startup.sh" ]; then
        "$TOMCAT_HOME/bin/startup.sh" > /dev/null 2>&1; sleep 3
    else
        sudo systemctl start tomcat 2>/dev/null || true; sleep 3
    fi
fi

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:8080/$CONTEXT/" 2>/dev/null || echo "000")
if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "302" ]; then
    echo "  [✓] California CIA webapp is UP — http://localhost:8080/$CONTEXT/"
else
    echo "  [--] HTTP $HTTP_CODE — http://localhost:8080/$CONTEXT/"
fi

echo ""
echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║  Stop:      bash shutdown-frontend.sh                                     ║"
echo "║  Backend:   bash start-backend.sh                                         ║"
echo "║  Start all: bash ../../scripts/start-all.sh                               ║"
echo "║  Status:    bash ../../scripts/status.sh                                  ║"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo ""
