#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# NitroWebExpress™ — Install JDBC Driver to All Webapps
# Copies mysql-connector-j JAR into WEB-INF/lib/ for every deployed webapp
# that has a db.properties but is missing the driver.
#
# Usage: bash scripts/install-jdbc-all.sh [tomcat_home]
# ═══════════════════════════════════════════════════════════════════════════════
set -uo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TOMCAT_HOME="${1:-${CATALINA_HOME:-/opt/apache-tomcat-11.0.2}}"
WEBAPPS_DIR="$TOMCAT_HOME/webapps"

# Find JDBC JAR
JDBC_JAR=$(find "$PROJECT_ROOT/jars/mysql" -name "mysql-connector-j*.jar" -type f 2>/dev/null | sort -V | tail -1)
[ -z "$JDBC_JAR" ] && JDBC_JAR=$(find "$PROJECT_ROOT/modules/black/presidential/Brarner.M.Alete/jars" -name "mysql-connector-j*.jar" -type f 2>/dev/null | head -1)
[ -z "$JDBC_JAR" ] && JDBC_JAR=$(find "$TOMCAT_HOME/lib" -name "mysql-connector-j*.jar" -type f 2>/dev/null | head -1)

if [ -z "$JDBC_JAR" ]; then
    echo "[FAIL] MySQL JDBC connector JAR not found anywhere."
    echo "       Download from: https://dev.mysql.com/downloads/connector/j/"
    echo "       Place in: $PROJECT_ROOT/jars/mysql/"
    exit 1
fi

echo ""
echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║  NitroWebExpress™ — Install JDBC Driver                                   ║"
echo "║  JAR:     $(basename "$JDBC_JAR")"
echo "║  Webapps: $WEBAPPS_DIR"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo ""

INSTALLED=0
SKIPPED=0

for WEBAPP_DIR in "$WEBAPPS_DIR"/*/; do
    [ -d "$WEBAPP_DIR" ] || continue
    CONTEXT=$(basename "$WEBAPP_DIR")

    # Skip Tomcat built-ins
    [[ "$CONTEXT" == "ROOT" || "$CONTEXT" == "manager" || "$CONTEXT" == "host-manager" || "$CONTEXT" == "docs" || "$CONTEXT" == "examples" ]] && continue

    LIB_DIR="$WEBAPP_DIR/WEB-INF/lib"

    # Check if already has a mysql-connector
    if find "$LIB_DIR" -name "mysql-connector*" -type f 2>/dev/null | grep -q .; then
        SKIPPED=$((SKIPPED + 1))
        continue
    fi

    # Install
    mkdir -p "$LIB_DIR"
    cp "$JDBC_JAR" "$LIB_DIR/"
    printf "  [✓] %-25s ← %s\n" "/$CONTEXT" "$(basename "$JDBC_JAR")"
    INSTALLED=$((INSTALLED + 1))
done

echo ""
echo "  Installed: $INSTALLED | Already had driver: $SKIPPED"
echo ""

if [ "$INSTALLED" -gt 0 ]; then
    echo "  [*] Restart Tomcat to pick up new JARs:"
    echo "      $TOMCAT_HOME/bin/shutdown.sh; sleep 3; $TOMCAT_HOME/bin/startup.sh"
fi
echo ""
