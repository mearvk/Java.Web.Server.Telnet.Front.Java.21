#!/bin/bash
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TOMCAT_WEBAPPS="${TOMCAT_HOME:-/opt/tomcat}/webapps"
SRC="$SCRIPT_DIR/servlet/src/main/webapp"
echo "[*] Deploying CaliforniaCIA™ to $TOMCAT_WEBAPPS/california-cia"
rm -rf "$TOMCAT_WEBAPPS/california-cia"
mkdir -p "$TOMCAT_WEBAPPS/california-cia"
cp -r "$SRC/"* "$TOMCAT_WEBAPPS/california-cia/"
if command -v javac &>/dev/null; then
    mkdir -p "$TOMCAT_WEBAPPS/california-cia/WEB-INF/classes/com/mearvk/cia"
    javac -cp "${TOMCAT_HOME:-/opt/tomcat}/lib/*" -d "$TOMCAT_WEBAPPS/california-cia/WEB-INF/classes" \
        "$SCRIPT_DIR/servlet/src/main/java/com/mearvk/cia/"*.java 2>/dev/null || echo "[!] Servlet compilation skipped"
fi
echo "[OK] CaliforniaCIA™ deployed at /california-cia"
