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

check "/index.jsp" "index.jsp"
check "/species.jsp" "species.jsp"
check "/postal.jsp" "postal.jsp"
check "/art.jsp" "art.jsp"
check "/science.jsp" "science.jsp"
check "/status.jsp" "status.jsp"
check "/css/style.css" "css/style.css"

echo ""
echo "───────────────────────────────────────────────────────────────"
echo " Results: ${PASS} passed | ${FAIL} failed"
echo "═══════════════════════════════════════════════════════════════"
