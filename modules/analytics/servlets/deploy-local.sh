#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════════
# NitroWebExpress™ — Analytics Deploy Local
# Usage: bash modules/analytics/servlets/deploy-local.sh [tomcat_home]
# ═══════════════════════════════════════════════════════════════════════════════════
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TOMCAT_HOME="${1:-${CATALINA_HOME:-/opt/apache-tomcat-11.0.2}}"
NWE_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

source "$NWE_ROOT/scripts/deploy-functions.sh" 2>/dev/null || true

DEPLOY_DIR="$TOMCAT_HOME/webapps/analytics"

echo "[*] Deploying NWE Analytics™ to $DEPLOY_DIR"

# Clean deploy (Lesson 11)
rm -rf "$DEPLOY_DIR"
mkdir -p "$DEPLOY_DIR/WEB-INF/lib"

# Copy webapp
cp -r "$SCRIPT_DIR/servlet/src/main/webapp/"* "$DEPLOY_DIR/"

# JDBC driver
JDBC_JAR=$(find "$NWE_ROOT/jars/mysql" -name "mysql-connector-j*.jar" -type f 2>/dev/null | head -1)
if [ -z "$JDBC_JAR" ]; then
    JDBC_JAR=$(find "$NWE_ROOT" -path "*/WEB-INF/lib/mysql-connector-j*.jar" -type f 2>/dev/null | head -1)
fi
[ -n "$JDBC_JAR" ] && cp "$JDBC_JAR" "$DEPLOY_DIR/WEB-INF/lib/"

# Ownership
chown -R tomcat:tomcat "$DEPLOY_DIR" 2>/dev/null || true

echo "[OK] NWE Analytics deployed at /analytics"
echo "     Access: http://localhost:8080/analytics/.data.jsp"
echo "     Or:     https://lauradei.us/analytics/.data.jsp"
echo ""
echo "[*] Run setup-db.sh first if database not yet created:"
echo "    bash modules/analytics/servlets/setup-db.sh"
