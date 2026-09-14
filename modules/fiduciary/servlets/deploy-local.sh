#!/bin/bash
# Fiduciary Services™ — Deploy Local
# Deploys JSP webapp to Tomcat
# Usage: bash modules/fiduciary/servlets/deploy-local.sh [tomcat_home]
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TOMCAT_HOME="${1:-${CATALINA_HOME:-/opt/apache-tomcat-11.0.2}}"
CONTEXT="fiduciary"
DEPLOY_DIR="$TOMCAT_HOME/webapps/$CONTEXT"
NWE_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
WEBAPP_SRC="$SCRIPT_DIR/servlet/src/main/webapp"

echo "[*] Deploying Fiduciary Services™ to $DEPLOY_DIR"

if [ ! -d "$TOMCAT_HOME/webapps" ]; then
    echo "[!] Tomcat not found at: $TOMCAT_HOME"
    echo "    Set CATALINA_HOME or pass path as argument."
    exit 1
fi

rm -rf "$DEPLOY_DIR"
mkdir -p "$DEPLOY_DIR/WEB-INF/lib"
cp -r "$WEBAPP_SRC/"* "$DEPLOY_DIR/"

JDBC_JAR=$(find "$NWE_ROOT/jars/mysql" -name "mysql-connector-j*.jar" -type f 2>/dev/null | head -1)
[ -n "$JDBC_JAR" ] && cp "$JDBC_JAR" "$DEPLOY_DIR/WEB-INF/lib/"

chown -R tomcat:tomcat "$DEPLOY_DIR" 2>/dev/null || true
echo "[✓] Deployed: http://localhost:8080/$CONTEXT/"
