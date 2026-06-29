#!/bin/bash
# AE6E66™ — Deploy Local (Embedded Tomcat or /opt/tomcat)
# Usage: bash modules/AE6E66/servlets/deploy-local.sh [tomcat_home]
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
AE6E66_ROOT="$(dirname "$SCRIPT_DIR")"
WEBAPP_SRC="$AE6E66_ROOT/servlets/servlet/src/main/webapp"
TOMCAT_HOME="${1:-${CATALINA_HOME:-/opt/tomcat}}"
CONTEXT="ae6e66"
DEPLOY_DIR="$TOMCAT_HOME/webapps/$CONTEXT"

echo "═══════════════════════════════════════════════════════════════"
echo " AE6E66™ — Deploy Local"
echo " Source:  $WEBAPP_SRC"
echo " Target:  $DEPLOY_DIR"
echo "═══════════════════════════════════════════════════════════════"

if [ ! -d "$WEBAPP_SRC" ]; then
    echo "[!] Webapp source not found"; exit 1
fi

rm -rf "$DEPLOY_DIR"
mkdir -p "$DEPLOY_DIR/WEB-INF/lib"
mkdir -p "$DEPLOY_DIR/WEB-INF/classes"
cp -r "$WEBAPP_SRC/"* "$DEPLOY_DIR/"

# Compile servlet classes (SecurityHeadersFilter etc.)
JAVA_SRC="$AE6E66_ROOT/servlets/servlet/src/main/java"
if [ -d "$JAVA_SRC" ]; then
    SERVLET_API="$TOMCAT_HOME/lib/servlet-api.jar"
    if [ ! -f "$SERVLET_API" ]; then
        SERVLET_API=$(find "$TOMCAT_HOME/lib" -name "jakarta.servlet-api*.jar" -o -name "servlet-api*.jar" 2>/dev/null | head -1)
    fi
    if [ -n "$SERVLET_API" ] && [ -f "$SERVLET_API" ]; then
        find "$JAVA_SRC" -name "*.java" | xargs javac -d "$DEPLOY_DIR/WEB-INF/classes" -cp "$SERVLET_API" 2>&1 && echo "[*] Compiled servlet classes" || echo "[!] Compile failed — check Jakarta Servlet API in $TOMCAT_HOME/lib"
    else
        echo "[!] No servlet-api jar found in $TOMCAT_HOME/lib — filter class not compiled"
    fi
fi

# Copy JDBC driver
BMA_JARS="$(dirname "$(dirname "$AE6E66_ROOT")")/presidential/Brarner.M.Alete/jars"
if ls "$BMA_JARS/mysql-connector-j"*.jar &>/dev/null; then
    cp "$BMA_JARS/mysql-connector-j"*.jar "$DEPLOY_DIR/WEB-INF/lib/"
    echo "[*] MySQL connector copied from BMA jars/"
elif ls "$AE6E66_ROOT/../../jars/mysql-connector-j"*.jar &>/dev/null 2>&1; then
    cp "$AE6E66_ROOT/../../jars/mysql-connector-j"*.jar "$DEPLOY_DIR/WEB-INF/lib/"
fi

chown -R tomcat:tomcat "$DEPLOY_DIR" 2>/dev/null || true

echo "[✓] Deployed to: $DEPLOY_DIR"
echo "    URL: http://localhost:8080/$CONTEXT/"
echo "═══════════════════════════════════════════════════════════════"
