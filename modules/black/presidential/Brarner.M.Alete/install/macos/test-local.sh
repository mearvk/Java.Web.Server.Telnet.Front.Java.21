#!/usr/bin/env bash
# Brarner.M.Alete™ — Test Local (macOS)
# Usage: bash install/macos/test-local.sh [port]
set -e

TOMCAT_PORT="${1:-8080}"
CONTEXT="brarner.m.alete"
BASE="http://localhost:${TOMCAT_PORT}/${CONTEXT}"

echo "═══════════════════════════════════════════════════════════════"
echo " Brarner.M.Alete™ — Local Connectivity Test (macOS)"
echo " Base URL: ${BASE}"
echo "═══════════════════════════════════════════════════════════════"
echo ""

PASS=0; FAIL=0

check() {
    local status
    status=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "${BASE}${1}" 2>/dev/null)
    if [ "$status" -ge 200 ] && [ "$status" -lt 400 ] 2>/dev/null; then
        echo "  [OK]   ${status}  ${2:-$1}"
        PASS=$((PASS + 1))
    else
        echo "  [FAIL] ${status}  ${2:-$1}"
        FAIL=$((FAIL + 1))
    fi
}

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WEBAPP_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")/servlets/servlet/src/main/webapp"
for jsp in $(find "$WEBAPP_DIR" -maxdepth 1 -name "*.jsp" -print0 2>/dev/null | xargs -0 -I{} basename {} | sort); do
    check "/${jsp}" "${jsp}"
done
check "/css/style.css" "css/style.css"

echo ""
echo "───────────────────────────────────────────────────────────────"
echo " Results: ${PASS} passed | ${FAIL} failed"
echo "═══════════════════════════════════════════════════════════════"
