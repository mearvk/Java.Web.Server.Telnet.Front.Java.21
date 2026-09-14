#!/bin/bash
# Defined™ — Deploy Local
# Deploys JSP webapp to Tomcat
# Usage: bash modules/Defined/servlets/deploy-local.sh [tomcat_home]
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TOMCAT_HOME="${1:-${CATALINA_HOME:-/opt/apache-tomcat-11.0.2}}"
CONTEXT="defined"
DEPLOY_DIR="$TOMCAT_HOME/webapps/$CONTEXT"
NWE_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
WEBAPP_SRC="$SCRIPT_DIR/servlet/src/main/webapp"

echo "[*] Deploying Defined™ to $DEPLOY_DIR"

if [ ! -d "$TOMCAT_HOME/webapps" ]; then
    echo "[!] Tomcat not found at: $TOMCAT_HOME"
    echo "    Set CATALINA_HOME or pass path as argument."
    exit 1
fi

rm -rf "$DEPLOY_DIR"
mkdir -p "$DEPLOY_DIR/WEB-INF/lib" "$DEPLOY_DIR/WEB-INF/classes/com/mearvk/defined"
cp -r "$WEBAPP_SRC/"* "$DEPLOY_DIR/"

# Compile servlets
JAVA_SRC="$SCRIPT_DIR/servlet/src/main/java"
if command -v javac &>/dev/null && [ -d "$JAVA_SRC" ]; then
    SERVLET_API=$(find "$TOMCAT_HOME/lib" -name "jakarta.servlet-api*.jar" -o -name "servlet-api.jar" 2>/dev/null | head -1)
    if [ -n "$SERVLET_API" ]; then
        find "$JAVA_SRC" -name "*.java" | xargs javac \
            -cp "$SERVLET_API:$DEPLOY_DIR/WEB-INF/lib/*" \
            -d "$DEPLOY_DIR/WEB-INF/classes" 2>&1 && echo "[✓] Servlets compiled" || echo "[!] Compilation failed (non-fatal)"
    fi
fi

JDBC_JAR=$(find "$NWE_ROOT/jars/mysql" -name "mysql-connector-j*.jar" -type f 2>/dev/null | head -1)
[ -n "$JDBC_JAR" ] && cp "$JDBC_JAR" "$DEPLOY_DIR/WEB-INF/lib/"

chown -R tomcat:tomcat "$DEPLOY_DIR" 2>/dev/null || true
echo "[✓] Deployed: http://localhost:8080/$CONTEXT/"
