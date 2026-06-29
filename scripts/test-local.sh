#!/bin/bash
# NitroWebExpress™ — Master Local Test Suite
# Tests all modules: TCP connectivity, HTTP webapp codes, XML config validity,
# settings integrity, and memory/heap concerns.
# Usage: bash scripts/test-local.sh
set -uo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0; FAIL=0; WARN=0

ok()   { echo "  [PASS] $1"; PASS=$((PASS + 1)); }
fail() { echo "  [FAIL] $1"; FAIL=$((FAIL + 1)); }
warn() { echo "  [WARN] $1"; WARN=$((WARN + 1)); }

echo "═══════════════════════════════════════════════════════════════"
echo " NitroWebExpress™ — Master Local Test Suite"
echo " Root: $PROJECT_ROOT"
echo " Time: $(date)"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# ── 1. TCP Port Connectivity ─────────────────────────────────────────────────
echo "[1/6] TCP Port Connectivity..."
declare -A PORTS=(
    [49152]="NitroWebExpress"
    [49155]="ConnectionStatus"
    [49199]="Communicator"
    [49210]="CaliforniaFBI"
    [49211]="CaliforniaCIA"
    [49212]="CaliforniaNSA"
    [49213]="DukeUniversity"
    [49214]="StanfordLibrary"
    [49201]="JapanSignal"
    [49202]="RussiaSignal"
    [49203]="MexicoSignal"
    [49204]="GreeceSignal"
    [20000]="Strernary"
    [2000]="StrernaryDirectory"
    [5000]="Futures"
    [5512]="AES"
    [6682]="Bitcoin"
    [9999]="GrayPortRegistry"
    [10085]="Gray85Creme"
)

for PORT in "${!PORTS[@]}"; do
    if timeout 2 bash -c "echo >/dev/tcp/localhost/$PORT" 2>/dev/null; then
        ok "${PORTS[$PORT]} (port $PORT) — responding"
    else
        warn "${PORTS[$PORT]} (port $PORT) — not listening"
    fi
done

# ── 2. HTTP Webapp Status Codes ───────────────────────────────────────────────
echo ""
echo "[2/6] HTTP Webapp Status Codes (Tomcat)..."
WEBAPPS=(
    "/brarner.m.alete/:BMA"
    "/ae6e66/:AE6E66"
    "/futures/:Futures"
    "/gdgh/:GDGH"
    "/gray-registry/:GrayRegistry"
    "/gray85-registry/:Gray85Creme"
    "/blackbelt/:BlackBelt"
    "/languages/:Languages"
    "/strernary/:Strernary"
    "/california-fbi/:CaliforniaFBI"
    "/california-cia/:CaliforniaCIA"
    "/california-nsa/:CaliforniaNSA"
    "/duke/:DukeUniversity"
    "/stanford-library/:StanfordLibrary"
)

TOMCAT_PORT=8080
for ENTRY in "${WEBAPPS[@]}"; do
    PATH_PART="${ENTRY%%:*}"
    NAME="${ENTRY##*:}"
    CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 3 "http://localhost:$TOMCAT_PORT$PATH_PART" 2>/dev/null || echo "000")
    if [[ "$CODE" == "200" ]]; then
        ok "$NAME ($PATH_PART) — HTTP $CODE"
    elif [[ "$CODE" == "000" ]]; then
        warn "$NAME ($PATH_PART) — Tomcat unreachable"
    else
        fail "$NAME ($PATH_PART) — HTTP $CODE"
    fi
done

# ── 3. XML Configuration Validity ────────────────────────────────────────────
echo ""
echo "[3/6] XML Configuration Validity..."
XML_FILES=(
    "configuration/nwe-config.xml"
    "configuration/nio-masquerade-config.xml"
    "configuration/masquerade-modules.xml"
    "configuration/protocol-handlers.xml"
    "configuration/port-2000-directory-config.xml"
    "configuration/print-method.xml"
    "scripts/web/web-deploy-config.xml"
    "california/fbi/configuration/california-fbi-config.xml"
    "california/cia/configuration/california-cia-config.xml"
    "california/nsa/configuration/california-nsa-config.xml"
)

for XML in "${XML_FILES[@]}"; do
    FULL="$PROJECT_ROOT/$XML"
    if [ ! -f "$FULL" ]; then
        fail "$XML — file missing"
    elif python3 -c "import xml.etree.ElementTree as ET; ET.parse('$FULL')" 2>/dev/null; then
        ok "$XML — valid"
    else
        fail "$XML — parse error"
    fi
done

# ── 4. Settings Integrity ─────────────────────────────────────────────────────
echo ""
echo "[4/6] Settings Integrity..."

# Check admin password isn't default
ADMIN_PASS=$(grep -oP '(?<=<password>)[^<]+' "$PROJECT_ROOT/configuration/nwe-config.xml" 2>/dev/null)
if [[ "$ADMIN_PASS" == "n21admin" ]]; then
    warn "Admin password is still default (n21admin) — change before production"
else
    ok "Admin password changed from default"
fi

# Check HardenedBaseServer is selected
if grep -q 'id="HARDENED_BASE_SERVER" selected="true"' "$PROJECT_ROOT/configuration/nwe-config.xml" 2>/dev/null; then
    ok "HardenedBaseServer selected (512 conn, 10/IP)"
elif grep -q 'id="NATIONAL_AWARE_HARD_SERVICE" selected="true"' "$PROJECT_ROOT/configuration/nwe-config.xml" 2>/dev/null; then
    ok "NationalAwareHardService selected (5040 conn, weight-balanced)"
else
    warn "BaseServer selected — no connection limits active"
fi

# Check masquerade enabled
if grep -q '<enabled>true</enabled>' "$PROJECT_ROOT/configuration/nio-masquerade-config.xml" 2>/dev/null; then
    ok "NIO Masquerade layer enabled"
else
    fail "NIO Masquerade layer disabled"
fi

# Check antivirus enabled
if grep -A1 'id="Antivirus"' "$PROJECT_ROOT/configuration/nwe-config.xml" | grep -q '<enabled>true</enabled>'; then
    ok "Antivirus scanner enabled"
else
    warn "Antivirus scanner disabled"
fi

# Check heuristic classifier enabled
if grep -A1 'id="HeuristicClassifier"' "$PROJECT_ROOT/configuration/nwe-config.xml" | grep -q '<enabled>true</enabled>'; then
    ok "Heuristic classifier enabled"
else
    warn "Heuristic classifier disabled"
fi

# Check public.key exists
if [ -f "$PROJECT_ROOT/psychiatry/secrets/public.key" ]; then
    ok "public.key present locally"
else
    fail "public.key missing — software authorization may fail"
fi

# Verify public.key on GitHub
GH_CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "https://raw.githubusercontent.com/mearvk/Java.Web.Server.Telnet.Front.Java.21/main/psychiatry/secrets/public.key" 2>/dev/null || echo "000")
if [[ "$GH_CODE" == "200" ]]; then
    ok "public.key present on GitHub (HTTP $GH_CODE)"
else
    fail "public.key NOT found on GitHub (HTTP $GH_CODE) — authorization revoked"
fi

# ── 5. Database Connectivity ──────────────────────────────────────────────────
echo ""
echo "[5/6] Database Connectivity..."
bash "$PROJECT_ROOT/scripts/test-module-db-connectivity.sh" 2>/dev/null
DB_EXIT=$?
if [[ $DB_EXIT -eq 0 ]]; then
    ok "All database checks passed (see detail above)"
else
    warn "Some database checks failed (exit $DB_EXIT)"
fi

# ── 6. Memory / Heap Concerns ────────────────────────────────────────────────
echo ""
echo "[6/6] Memory & Heap Analysis..."

# System RAM
if [ -f /proc/meminfo ]; then
    TOTAL_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    AVAIL_KB=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
    TOTAL_MB=$((TOTAL_KB / 1024))
    AVAIL_MB=$((AVAIL_KB / 1024))
    USED_MB=$((TOTAL_MB - AVAIL_MB))

    echo "  System RAM: ${TOTAL_MB} MB total, ${AVAIL_MB} MB available, ${USED_MB} MB used"

    if [[ $AVAIL_MB -lt 512 ]]; then
        fail "Available RAM < 512 MB — NWE requires minimum 800 MB for full profile"
    elif [[ $AVAIL_MB -lt 1024 ]]; then
        warn "Available RAM < 1 GB — may not support DJL/full training profile"
    else
        ok "Available RAM: ${AVAIL_MB} MB (sufficient for full profile)"
    fi
else
    # macOS
    TOTAL_MB=$(sysctl -n hw.memsize 2>/dev/null | awk '{print int($1/1024/1024)}')
    if [ -n "$TOTAL_MB" ]; then
        echo "  System RAM: ${TOTAL_MB} MB total"
        [[ $TOTAL_MB -ge 2048 ]] && ok "System RAM: ${TOTAL_MB} MB" || warn "System RAM low: ${TOTAL_MB} MB"
    else
        warn "Cannot determine system RAM"
    fi
fi

# JVM heap estimate
JAVA_PROCS=$(pgrep -f "java.*NitroWebExpress\|java.*Main\|java.*CaliforniaFBI\|java.*Strernary" 2>/dev/null | head -5)
if [ -n "$JAVA_PROCS" ]; then
    for PID in $JAVA_PROCS; do
        RSS_KB=$(ps -o rss= -p "$PID" 2>/dev/null | tr -d ' ')
        if [ -n "$RSS_KB" ]; then
            RSS_MB=$((RSS_KB / 1024))
            CMD=$(ps -o args= -p "$PID" 2>/dev/null | cut -c1-60)
            echo "  PID $PID: ${RSS_MB} MB RSS — $CMD"
        fi
    done
else
    echo "  No NWE Java processes currently running"
fi

# Check recommended JVM flags
echo "  Recommended: -Xms256m -Xmx1024m -XX:+UseZGC"
echo "  Memory profiles: Minimal ~100MB | Standard ~450MB | Full+DJL ~800MB | Training ~1000MB"

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo " RESULTS: $PASS passed | $WARN warnings | $FAIL failed"
echo "═══════════════════════════════════════════════════════════════"

[[ $FAIL -gt 0 ]] && exit 1 || exit 0
