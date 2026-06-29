#!/bin/bash
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TOMCAT_WEBAPPS="${TOMCAT_HOME:-/opt/tomcat}/webapps"
echo "[*] Deploying DukeUniversity™ to $TOMCAT_WEBAPPS/duke"
rm -rf "$TOMCAT_WEBAPPS/duke"; mkdir -p "$TOMCAT_WEBAPPS/duke"
cp -r "$SCRIPT_DIR/servlet/src/main/webapp/"* "$TOMCAT_WEBAPPS/duke/"
if command -v javac &>/dev/null; then
    mkdir -p "$TOMCAT_WEBAPPS/duke/WEB-INF/classes/com/mearvk/duke"
    javac -cp "${TOMCAT_HOME:-/opt/tomcat}/lib/*" -d "$TOMCAT_WEBAPPS/duke/WEB-INF/classes" "$SCRIPT_DIR/servlet/src/main/java/com/mearvk/duke/"*.java 2>/dev/null || true
fi
echo "[OK] DukeUniversity™ deployed at /duke"
