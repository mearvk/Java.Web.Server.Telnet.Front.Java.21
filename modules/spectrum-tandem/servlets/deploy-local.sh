#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════════
# NitroWebExpress™ — SpectrumTandem Deploy Local
# Deploys JSP webapp to Tomcat with JDBC connector.
# Usage: bash modules/spectrum-tandem/servlets/deploy-local.sh [tomcat_home]
# ═══════════════════════════════════════════════════════════════════════════════════
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TOMCAT_HOME="${1:-${CATALINA_HOME:-/opt/apache-tomcat-11.0.2}}"
NWE_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

source "$NWE_ROOT/scripts/deploy-functions.sh" 2>/dev/null || true

if type nwe_deploy_module &>/dev/null; then
    nwe_deploy_module "SpectrumTandem" "spectrum-tandem" \
        "$SCRIPT_DIR/servlet/src/main/webapp" \
        "" \
        "$TOMCAT_HOME" "$NWE_ROOT"
else
    # Fallback if shared library unavailable
    DEPLOY_DIR="$TOMCAT_HOME/webapps/spectrum-tandem"
    echo "[*] Deploying SpectrumTandem™ to $DEPLOY_DIR"
    rm -rf "$DEPLOY_DIR"
    mkdir -p "$DEPLOY_DIR/WEB-INF/lib"
    cp -r "$SCRIPT_DIR/servlet/src/main/webapp/"* "$DEPLOY_DIR/"
    JDBC_JAR=$(find "$NWE_ROOT/jars/mysql" -name "mysql-connector-j*.jar" -type f 2>/dev/null | head -1)
    [ -n "$JDBC_JAR" ] && cp "$JDBC_JAR" "$DEPLOY_DIR/WEB-INF/lib/"
    chown -R tomcat:tomcat "$DEPLOY_DIR" 2>/dev/null || true
    echo "[OK] SpectrumTandem deployed at /spectrum-tandem"
fi
