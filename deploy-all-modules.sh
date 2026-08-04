#!/bin/bash
# ============================================================
# NitroWebExpress™ — Deploy All JSP Modules
# Deploys all NWE modules to Apache Tomcat webapps directory.
#
# Standard Locations:
#   Tomcat:    /opt/apache-tomcat-11.0.2  (or CATALINA_HOME)
#   Webapps:   $TOMCAT_HOME/webapps/<context>/
#   Apache2:   /etc/apache2/ (reverse proxy on 80/443)
#
# Usage:
#   bash deploy-all-modules.sh [tomcat_home]
#
# Copyright (C) 2026 MEARVK LLC
# ============================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TOMCAT_HOME="${1:-${CATALINA_HOME:-/opt/apache-tomcat-11.0.2}}"
MODULES_DIR="$SCRIPT_DIR/modules"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  NitroWebExpress™ — Deploy All Modules                      ║"
echo "║  Target: $TOMCAT_HOME"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Validate Tomcat installation
if [ ! -d "$TOMCAT_HOME/webapps" ]; then
    echo "[ERROR] Tomcat not found at: $TOMCAT_HOME"
    echo ""
    echo "  Install Tomcat or set CATALINA_HOME:"
    echo "    export CATALINA_HOME=/path/to/tomcat"
    echo "    bash $0"
    exit 1
fi

# Module context map (module_dir:context_path)
declare -a MODULE_MAP=(
    "AE6E66:ae6e66"
    "analytics:analytics"
    "armorer:armorer"
    "bitcoin:bitcoin"
    "black-belt:blackbelt"
    "calendar:calendar"
    "chat:chat"
    "cia:california-cia"
    "Defined:defined"
    "dictionary:dictionary"
    "duke:california-duke"
    "emeter:emeter"
    "fbi:california-fbi"
    "fiduciary:fiduciary"
    "gray:gray-registry"
    "gray.a85:gray85-registry"
    "Green.Durham.Grass.and.Herb:gdgh"
    "languages:languages"
    "library:library"
    "ncsu:california-ncsu"
    "nsa:california-nsa"
    "spectrum-tandem:spectrum-tandem"
    "tandem-equals:tandem-equals"
    "unc:california-unc"
    "uncw:uncw"
    "vietnam:vietnam"
)

SUCCESS=0
FAILED=0
SKIPPED=0

for entry in "${MODULE_MAP[@]}"; do
    IFS=':' read -r mod_dir context <<< "$entry"
    
    WEBAPP_SRC="$MODULES_DIR/$mod_dir/servlets/servlet/src/main/webapp"
    DEPLOY_DIR="$TOMCAT_HOME/webapps/$context"
    
    if [ ! -d "$WEBAPP_SRC" ]; then
        printf "  [--] %-30s (no webapp source)\n" "$mod_dir"
        SKIPPED=$((SKIPPED + 1))
        continue
    fi
    
    # Deploy webapp
    rm -rf "$DEPLOY_DIR"
    mkdir -p "$DEPLOY_DIR/WEB-INF/lib"
    cp -r "$WEBAPP_SRC/"* "$DEPLOY_DIR/"
    
    # JDBC connector
    JDBC_JAR=$(find "$SCRIPT_DIR/jars/mysql" -name "mysql-connector-j*.jar" -type f 2>/dev/null | head -1)
    [ -z "$JDBC_JAR" ] && JDBC_JAR=$(find "$TOMCAT_HOME/lib" -name "mysql-connector-j*.jar" -type f 2>/dev/null | head -1)
    [ -n "$JDBC_JAR" ] && cp "$JDBC_JAR" "$DEPLOY_DIR/WEB-INF/lib/" 2>/dev/null
    
    # Compile servlets if source exists
    JAVA_SRC="$MODULES_DIR/$mod_dir/servlets/servlet/src/main/java"
    if command -v javac &>/dev/null && [ -d "$JAVA_SRC" ]; then
        SERVLET_API=$(find "$TOMCAT_HOME/lib" -name "jakarta.servlet-api*.jar" -o -name "servlet-api.jar" 2>/dev/null | head -1)
        if [ -n "$SERVLET_API" ]; then
            mkdir -p "$DEPLOY_DIR/WEB-INF/classes"
            find "$JAVA_SRC" -name "*.java" | xargs javac \
                -cp "$SERVLET_API:$DEPLOY_DIR/WEB-INF/lib/*" \
                -d "$DEPLOY_DIR/WEB-INF/classes" 2>/dev/null || true
        fi
    fi
    
    # Set ownership
    chown -R tomcat:tomcat "$DEPLOY_DIR" 2>/dev/null || true
    
    JSP_COUNT=$(find "$DEPLOY_DIR" -name "*.jsp" 2>/dev/null | wc -l)
    printf "  [✓] %-30s → /%-20s (%d JSPs)\n" "$mod_dir" "$context" "$JSP_COUNT"
    SUCCESS=$((SUCCESS + 1))
done

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "  Deployed: $SUCCESS  |  Skipped: $SKIPPED  |  Failed: $FAILED"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "Webapp contexts deployed to: $TOMCAT_HOME/webapps/"
echo ""

# List all deployed contexts
echo "Access URLs (Tomcat direct — port 8080):"
for entry in "${MODULE_MAP[@]}"; do
    IFS=':' read -r mod_dir context <<< "$entry"
    if [ -d "$TOMCAT_HOME/webapps/$context" ]; then
        echo "  http://localhost:8080/$context/"
    fi
done

echo ""
echo "Apache2 reverse proxy (ports 80/443) serves these via ProxyPass."
echo "Restart Tomcat to activate: systemctl restart tomcat"
