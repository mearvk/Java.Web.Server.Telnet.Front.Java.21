#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════════
# NitroWebExpress™ — UNC Chapel Hill Frontend Startup (Legacy)
# Deploys the webapp to Tomcat.
# Usage: bash start.sh [tomcat_home]
# ═══════════════════════════════════════════════════════════════════════════════════
set -e
MOD_ROOT="$(cd "$(dirname "$0")" && pwd)"
TOMCAT_HOME="${1:-${CATALINA_HOME:-/opt/apache-tomcat-11.0.2}}"
CONTEXT="california-unc"

echo ""
echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║  unc Frontend — Startup                                                 ║"
echo "║  Context: /$CONTEXT                                                      ║"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo ""
echo "  [*] Deploying to Tomcat..."
bash "$MOD_ROOT/servlets/deploy-local.sh" "$TOMCAT_HOME" > /dev/null 2>&1
echo "  [✓] Deployed"
echo ""
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/ 2>/dev/null | grep -q "200\|302\|401\|403"; then
    echo "  [✓] Tomcat already running"
else
    echo "  [*] Starting Tomcat..."
    "$TOMCAT_HOME/bin/startup.sh" > /dev/null 2>&1 || sudo systemctl start tomcat 2>/dev/null || true
    sleep 3
fi
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:8080/$CONTEXT/" 2>/dev/null || echo "000")
if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "302" ]; then
    echo "  [✓] unc Frontend is UP — http://localhost:8080/$CONTEXT/"
else
    echo "  [--] HTTP $HTTP_CODE — http://localhost:8080/$CONTEXT/"
fi
echo ""
echo "  Stop: bash shutdown.sh | Backend: bash start-backend.sh"
echo ""
