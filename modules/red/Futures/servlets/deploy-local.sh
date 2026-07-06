#!/bin/bash
# Futures™ — Deploy Local
# Usage: bash modules/Futures/servlets/deploy-local.sh [tomcat_home]
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FUTURES_ROOT="$(dirname "$SCRIPT_DIR")"
WEBAPP_SRC="$FUTURES_ROOT/servlets/servlet/src/main/webapp"
TOMCAT_HOME="${1:-${CATALINA_HOME:-/home/mearvk/tomcat}}"
CONTEXT="futures"
DEPLOY_DIR="$TOMCAT_HOME/webapps/$CONTEXT"

echo "═══════════════════════════════════════════════════════════════"
echo " Futures™ — Deploy Local"
echo " Source:  $WEBAPP_SRC"
echo " Target:  $DEPLOY_DIR"
echo "═══════════════════════════════════════════════════════════════"

rm -rf "$DEPLOY_DIR"
mkdir -p "$DEPLOY_DIR/WEB-INF/lib"
cp -r "$WEBAPP_SRC/"* "$DEPLOY_DIR/"

# Copy JDBC driver (canonical — from BMA jars/)
NWE_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
JDBC_JAR=$(find "$NWE_ROOT/modules/black/presidential/Brarner.M.Alete/jars" "$NWE_ROOT/jars/mysql" -name "mysql-connector-j*.jar" -type f 2>/dev/null | head -1)
[ -z "$JDBC_JAR" ] && JDBC_JAR=$(find "$TOMCAT_HOME/lib" -name "mysql-connector-j*.jar" -type f 2>/dev/null | head -1)
if [ -n "$JDBC_JAR" ]; then
    cp "$JDBC_JAR" "$DEPLOY_DIR/WEB-INF/lib/"
    echo "[*] MySQL connector: $(basename \"$JDBC_JAR\")"
else
    echo "[!] WARNING: mysql-connector-j not found — JDBC pages will fail"
fi

chown -R tomcat:tomcat "$DEPLOY_DIR" 2>/dev/null || true
echo "[✓] Deployed: http://localhost:8080/$CONTEXT/"
echo "═══════════════════════════════════════════════════════════════"
