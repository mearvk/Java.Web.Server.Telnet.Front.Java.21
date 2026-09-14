#!/bin/bash
# NCSU™ — Deploy Local
# Deploys JSP webapp to Tomcat with JDBC connector and compiled servlet classes.
# Usage: bash modules/ncsu/servlets/deploy-local.sh [tomcat_home]
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TOMCAT_HOME="${1:-${CATALINA_HOME:-/opt/apache-tomcat-11.0.2}}"
CONTEXT="california-ncsu"
DEPLOY_DIR="$TOMCAT_HOME/webapps/$CONTEXT"
NWE_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
WEBAPP_SRC="$SCRIPT_DIR/servlet/src/main/webapp"

echo "[*] Deploying NCSU™ to $DEPLOY_DIR"

# Validate Tomcat exists
if [ ! -d "$TOMCAT_HOME/webapps" ]; then
    echo "[!] Tomcat not found at: $TOMCAT_HOME"
    echo "    Set CATALINA_HOME or pass path as argument."
    exit 1
fi

# Validate webapp source exists
if [ ! -d "$WEBAPP_SRC" ]; then
    echo "[!] Webapp source not found: $WEBAPP_SRC"
    exit 1
fi

# Deploy webapp (preserves Tomcat structure)
rm -rf "$DEPLOY_DIR"
mkdir -p "$DEPLOY_DIR/WEB-INF/lib" "$DEPLOY_DIR/WEB-INF/classes/com/mearvk/ncsu"
cp -r "$WEBAPP_SRC/"* "$DEPLOY_DIR/"

# JDBC connector
JDBC_JAR=$(find "$NWE_ROOT/jars/mysql" -name "mysql-connector-j*.jar" -type f 2>/dev/null | head -1)
[ -z "$JDBC_JAR" ] && JDBC_JAR=$(find "$TOMCAT_HOME/lib" -name "mysql-connector-j*.jar" -type f 2>/dev/null | head -1)
if [ -n "$JDBC_JAR" ]; then
    cp "$JDBC_JAR" "$DEPLOY_DIR/WEB-INF/lib/"
    echo "[✓] JDBC: $(basename "$JDBC_JAR")"
else
    echo "[!] WARNING: mysql-connector-j not found — JSP database queries will fail"
fi

# Compile servlets (if javac available and source exists)
JAVA_SRC="$SCRIPT_DIR/servlet/src/main/java/com/mearvk/ncsu"
if command -v javac &>/dev/null && [ -d "$JAVA_SRC" ]; then
    SERVLET_API=$(find "$TOMCAT_HOME/lib" -name "servlet-api.jar" -o -name "jakarta.servlet-api*.jar" 2>/dev/null | head -1)
    if [ -n "$SERVLET_API" ]; then
        find "$JAVA_SRC" -name "*.java" | xargs javac \
            -cp "$SERVLET_API:$DEPLOY_DIR/WEB-INF/lib/*" \
            -d "$DEPLOY_DIR/WEB-INF/classes" 2>&1 && echo "[✓] Servlets compiled" || echo "[!] Servlet compilation failed (non-fatal)"
    else
        echo "[--] No servlet-api.jar in $TOMCAT_HOME/lib — skipping compilation"
    fi
fi

# Validate WEB-INF/web.xml exists
if [ ! -f "$DEPLOY_DIR/WEB-INF/web.xml" ]; then
    echo "[!] WARNING: No WEB-INF/web.xml — Tomcat may not recognize this webapp"
fi

# Validate at least one JSP exists
JSP_COUNT=$(find "$DEPLOY_DIR" -name "*.jsp" 2>/dev/null | wc -l)
if [ "$JSP_COUNT" -eq 0 ]; then
    echo "[!] WARNING: No JSP files found in deployment"
else
    echo "[✓] JSP pages: $JSP_COUNT"
fi

echo "[OK] NCSU™ deployed at /$CONTEXT"
