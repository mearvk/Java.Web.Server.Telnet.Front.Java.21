#!/bin/bash
# Quick-fix: deploy modules returning HTTP 404
# Usage: sudo bash scripts/web/deploy-missing.sh
set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
TOMCAT_HOME="${CATALINA_HOME:-/opt/apache-tomcat-11.0.2}"
WEBAPPS="$TOMCAT_HOME/webapps"

deploy() {
    local CONTEXT="$1" SRC="$2"
    if [ ! -d "$SRC" ]; then echo "[SKIP] $CONTEXT — source not found: $SRC"; return; fi
    rm -rf "$WEBAPPS/$CONTEXT"
    mkdir -p "$WEBAPPS/$CONTEXT"
    cp -r "$SRC/"* "$WEBAPPS/$CONTEXT/"
    chown -R tomcat:tomcat "$WEBAPPS/$CONTEXT" 2>/dev/null || true
    echo "[OK] $CONTEXT deployed"
}

echo "[*] Deploying missing webapps..."

deploy "ae6e66" "$PROJECT_ROOT/modules/AE6E66/servlets/servlet/src/main/webapp"
deploy "futures" "$PROJECT_ROOT/modules/red/Futures/servlets/servlet/src/main/webapp"
deploy "gdgh" "$PROJECT_ROOT/modules/Green.Durham.Grass.and.Herb/servlets/servlet/src/main/webapp"
deploy "california-nsa" "$PROJECT_ROOT/modules/nsa/servlets/servlet/src/main/webapp"

echo "[*] Done. Verify: curl -s -o /dev/null -w '%{http_code}' http://localhost:8080/ae6e66/"
