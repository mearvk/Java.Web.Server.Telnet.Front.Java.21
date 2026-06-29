#!/bin/bash
# CaliforniaFBI™ — Deploy to local Tomcat
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WAR_NAME="california-fbi"
TOMCAT_WEBAPPS="${TOMCAT_HOME:-/opt/tomcat}/webapps"
SRC="$SCRIPT_DIR/servlet/src/main/webapp"

echo "[*] Deploying CaliforniaFBI™ to $TOMCAT_WEBAPPS/$WAR_NAME"

rm -rf "$TOMCAT_WEBAPPS/$WAR_NAME"
mkdir -p "$TOMCAT_WEBAPPS/$WAR_NAME"
cp -r "$SRC/"* "$TOMCAT_WEBAPPS/$WAR_NAME/"

# Compile servlets if javac available
if command -v javac &>/dev/null; then
    CLASSES="$TOMCAT_WEBAPPS/$WAR_NAME/WEB-INF/classes/com/mearvk/fbi"
    mkdir -p "$CLASSES"
    CLASSPATH="$TOMCAT_WEBAPPS/$WAR_NAME/WEB-INF/lib/*:${TOMCAT_HOME:-/opt/tomcat}/lib/*"
    javac -cp "$CLASSPATH" -d "$TOMCAT_WEBAPPS/$WAR_NAME/WEB-INF/classes" \
        "$SCRIPT_DIR/servlet/src/main/java/com/mearvk/fbi/"*.java 2>/dev/null || echo "[!] Servlet compilation skipped (missing deps)"
fi

echo "[OK] CaliforniaFBI™ deployed at /$WAR_NAME"
