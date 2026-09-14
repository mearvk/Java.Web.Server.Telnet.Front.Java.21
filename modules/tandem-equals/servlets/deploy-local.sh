#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════════
# NitroWebExpress™ — TandemEquals Deploy Local
# ═══════════════════════════════════════════════════════════════════════════════════
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TOMCAT_HOME="${1:-${CATALINA_HOME:-/opt/apache-tomcat-11.0.2}}"
NWE_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

DEPLOY_DIR="$TOMCAT_HOME/webapps/tandem-equals"

echo "[*] Deploying TandemEquals™ to $DEPLOY_DIR"

rm -rf "$DEPLOY_DIR"
mkdir -p "$DEPLOY_DIR/WEB-INF/lib"

cp -r "$SCRIPT_DIR/servlet/src/main/webapp/"* "$DEPLOY_DIR/"

# JDBC driver
JDBC_JAR=$(find "$NWE_ROOT/jars/mysql" -name "mysql-connector-j*.jar" -type f 2>/dev/null | head -1)
if [ -z "$JDBC_JAR" ]; then
    JDBC_JAR=$(find "$NWE_ROOT" -path "*/WEB-INF/lib/mysql-connector-j*.jar" -type f 2>/dev/null | head -1)
fi
[ -n "$JDBC_JAR" ] && cp "$JDBC_JAR" "$DEPLOY_DIR/WEB-INF/lib/"

chown -R tomcat:tomcat "$DEPLOY_DIR" 2>/dev/null || true

echo "[OK] TandemEquals deployed at /tandem-equals"
echo "     Access: http://localhost:8080/tandem-equals/"
