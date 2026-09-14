#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════════════
# Defined™ — Install & Deploy (macOS)
# Theme: Dark Gray — Definition to Narrow Cause
#
# In memory of Steve Jobs, whose vision for personal computing
# and elegant design continues to inspire. The Mac is a beautiful
# machine for beautiful work.
#
# NitroWebExpress™ — MEARVK LLC
# Installer Tech ID: Max Rupplin
# ═══════════════════════════════════════════════════════════════════════════════
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MOD_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
NWE_ROOT="$(cd "$MOD_ROOT/../.." && pwd)"
TOMCAT_HOME="${1:-${CATALINA_HOME:-/usr/local/opt/tomcat/libexec}}"
[ ! -d "$TOMCAT_HOME/webapps" ] && TOMCAT_HOME="/opt/homebrew/opt/tomcat/libexec"
WEBAPP_SRC="$MOD_ROOT/servlets/servlet/src/main/webapp"
DEPLOY_DIR="$TOMCAT_HOME/webapps/defined"

echo ""
echo "╔═══════════════════════════════════════════════════════════════════════╗"
echo "║  Defined™ — Deploy Local (macOS)                                      ║"
echo "║  Theme: Dark Gray                                                     ║"
echo "║                                                                       ║"
echo "║  In memory of Steve Jobs — Think Different.                           ║"
echo "║  The Mac: a beautiful machine for beautiful work.                     ║"
echo "╚═══════════════════════════════════════════════════════════════════════╝"
echo ""

if [ ! -d "$TOMCAT_HOME/webapps" ]; then
    echo "  [!] Tomcat not found at: $TOMCAT_HOME"
    echo "      Install: brew install tomcat"
    echo "      Or set CATALINA_HOME"
    exit 1
fi

echo "  [*] Target: $DEPLOY_DIR"
echo "  [*] Cleaning previous deployment..."
rm -rf "$DEPLOY_DIR"
mkdir -p "$DEPLOY_DIR/WEB-INF/lib"

echo "  [*] Copying webapp files..."
cp -R "$WEBAPP_SRC/"* "$DEPLOY_DIR/"

# Locate MySQL JDBC connector
JDBC_JAR=$(find "$NWE_ROOT/jars/mysql" -name "mysql-connector-j-*.jar" 2>/dev/null | head -1)
if [ -n "$JDBC_JAR" ]; then
    cp "$JDBC_JAR" "$DEPLOY_DIR/WEB-INF/lib/"
    echo "  [*] JDBC connector: copied"
else
    echo "  [!] WARNING: mysql-connector-j not found"
fi

echo ""
echo "  [OK] Deployed successfully."
echo "       URL: http://localhost:8080/defined/"
echo ""
echo "╔═══════════════════════════════════════════════════════════════════════╗"
echo "║  Defined™ is ready on macOS.                                          ║"
echo "║  Port 49220 (AI Server) / Port 49221 (Protocol Backend)              ║"
echo "║  Thank you, Steve Jobs. Think Different.                              ║"
echo "╚═══════════════════════════════════════════════════════════════════════╝"
echo ""
