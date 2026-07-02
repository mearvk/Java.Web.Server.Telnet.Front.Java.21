#!/usr/bin/env bash
# Library — Deploy Local (macOS)
# Usage: bash install/macos/deploy-local.sh [tomcat_home]
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MOD_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
TOMCAT_HOME="${1:-${CATALINA_HOME:-/usr/local/opt/tomcat/libexec}}"
[ ! -d "$TOMCAT_HOME/webapps" ] && TOMCAT_HOME="/opt/homebrew/opt/tomcat/libexec"
if [ ! -d "$TOMCAT_HOME/webapps" ]; then
    echo "[!] Tomcat not found. Install: brew install tomcat"
    exit 1
fi
exec bash "$MOD_ROOT/servlets/deploy-local.sh" "$TOMCAT_HOME"
