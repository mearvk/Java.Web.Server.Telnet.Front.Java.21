#!/bin/bash
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TOMCAT_WEBAPPS="${TOMCAT_HOME:-/home/mearvk/tomcat}/webapps"
SRC="$SCRIPT_DIR/servlet/src/main/webapp"
echo "[*] Deploying CaliforniaCIA™ to $TOMCAT_WEBAPPS/california-cia"
rm -rf "$TOMCAT_WEBAPPS/california-cia"
mkdir -p "$TOMCAT_WEBAPPS/california-cia"
cp -r "$SRC/"* "$TOMCAT_WEBAPPS/california-cia/"
mkdir -p "$TOMCAT_WEBAPPS/california-cia/WEB-INF/lib"
NWE_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
JDBC_JAR=$(find "$NWE_ROOT/modules/black/presidential/Brarner.M.Alete/jars" "$NWE_ROOT/jars/mysql" -name "mysql-connector-j*.jar" -type f 2>/dev/null | head -1)
[ -n "$JDBC_JAR" ] && cp "$JDBC_JAR" "$TOMCAT_WEBAPPS/california-cia/WEB-INF/lib/" && echo "[*] JDBC: $(basename "$JDBC_JAR")" || echo "[!] WARNING: mysql-connector-j not found"
if command -v javac &>/dev/null; then
    mkdir -p "$TOMCAT_WEBAPPS/california-cia/WEB-INF/classes/com/mearvk/cia"
    javac -cp "${TOMCAT_HOME:-/home/mearvk/tomcat}/lib/*" -d "$TOMCAT_WEBAPPS/california-cia/WEB-INF/classes" \
        "$SCRIPT_DIR/servlet/src/main/java/com/mearvk/cia/"*.java 2>/dev/null || echo "[!] Servlet compilation skipped"
fi
echo "[OK] CaliforniaCIA™ deployed at /california-cia"
