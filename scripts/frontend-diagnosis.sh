#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# NitroWebExpress™ — Frontend Diagnosis
# Finds why webapps return 404 after post-clone.sh / start-all.sh.
#
# Usage: bash scripts/frontend-diagnosis.sh [tomcat_home]
# ═══════════════════════════════════════════════════════════════════════════════
set -uo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TOMCAT_HOME="${1:-${CATALINA_HOME:-/home/mearvk/tomcat}}"

PASS=0; FAIL=0; WARN=0
pass() { PASS=$((PASS+1)); echo "  [PASS] $1"; }
fail() { FAIL=$((FAIL+1)); echo "  [FAIL] $1"; }
warn() { WARN=$((WARN+1)); echo "  [WARN] $1"; }
info() { echo "  [INFO] $1"; }

# context|deploy_script|backend_class|port|db
MODULES=(
    "california-fbi|modules/fbi/servlets/deploy-local.sh|source.CaliforniaFBIServer|49210|nwe_california_fbi"
    "california-cia|modules/cia/servlets/deploy-local.sh|source.CaliforniaCIAServer|49211|nwe_california_cia"
    "california-nsa|modules/nsa/servlets/deploy-local.sh|source.CaliforniaNSAServer|49212|nwe_california_nsa"
    "california-duke|modules/duke/servlets/deploy-local.sh|source.DukeUniversityServer|49213|nwe_duke"
    "library|modules/library/servlets/deploy-local.sh|source.StanfordLibraryServer|49214|nwe_library"
    "ae6e66|modules/AE6E66/servlets/deploy-local.sh|source.AE6E66Main|0|nwe_ae6e66"
    "futures|modules/red/Futures/servlets/deploy-local.sh|red.Futures.source.ai.server.DemocraticAIServer|5000|nwe_futures"
    "gdgh|modules/Green.Durham.Grass.and.Herb/servlets/deploy-local.sh|presidential.Green.Durham.Grass.and.Herb.source.listeners.BaseListener|20000|nwe_gdgh"
    "gray-registry|modules/gray/servlets/deploy-local.sh|modules.gray.source.GrayPortRegistryServer|9999|nwe_gray_registry"
    "gray85-registry|modules/gray.a85/servlets/deploy-local.sh|modules.gray.a85.source.Gray85PortRegistryServer|10085|nwe_gray85_registry"
    "blackbelt|modules/black-belt/servlets/deploy-local.sh||0|"
    "languages|modules/languages/servlets/deploy-local.sh||0|"
    "brarner.m.alete|modules/black/presidential/Brarner.M.Alete/install/deploy-local.sh||49152|BrarnerScience"
)

echo ""
echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║  NitroWebExpress™ — Frontend Diagnosis                                   ║"
echo "║  Tomcat:  $TOMCAT_HOME"
echo "║  Project: $PROJECT_ROOT"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"

# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "── 1. Tomcat Process & HTTP ──"
echo ""

TOMCAT_PID=$(pgrep -f "catalina" 2>/dev/null | head -1)
if [ -n "$TOMCAT_PID" ]; then
    pass "Tomcat running (PID $TOMCAT_PID)"
else
    fail "Tomcat NOT running"
    info "Fix: $TOMCAT_HOME/bin/startup.sh"
fi

HTTP_ROOT=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 http://localhost:8080/ 2>/dev/null || echo "000")
if [[ "$HTTP_ROOT" =~ ^(200|302|401|403)$ ]]; then
    pass "Tomcat root responds HTTP $HTTP_ROOT"
else
    fail "Tomcat root: HTTP $HTTP_ROOT"
fi

# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "── 2. server.xml autoDeploy ──"
echo ""

SERVER_XML="$TOMCAT_HOME/conf/server.xml"
if [ -f "$SERVER_XML" ]; then
    if grep -q 'autoDeploy="false"' "$SERVER_XML"; then
        fail "autoDeploy=false in server.xml — Tomcat won't load new webapps"
        info "Fix: set autoDeploy=\"true\" in <Host> element"
    else
        pass "autoDeploy enabled (true or default)"
    fi
    APP_BASE=$(grep -oP 'appBase="\K[^"]+' "$SERVER_XML" | head -1)
    APP_BASE="${APP_BASE:-webapps}"
    if [[ "$APP_BASE" == /* ]]; then
        WEBAPPS_DIR="$APP_BASE"
    else
        WEBAPPS_DIR="$TOMCAT_HOME/$APP_BASE"
    fi
    if [ -d "$WEBAPPS_DIR" ]; then
        pass "appBase exists: $WEBAPPS_DIR"
    else
        fail "appBase MISSING: $WEBAPPS_DIR"
    fi
else
    fail "server.xml not found: $SERVER_XML"
    WEBAPPS_DIR="$TOMCAT_HOME/webapps"
fi

# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "── 3. Context XML Pointers ──"
echo ""

CTX_DIR="$TOMCAT_HOME/conf/Catalina/localhost"
if [ -d "$CTX_DIR" ] && ls "$CTX_DIR"/*.xml &>/dev/null; then
    for CTX_FILE in "$CTX_DIR"/*.xml; do
        CTX_NAME=$(basename "$CTX_FILE" .xml)
        DOC_BASE=$(grep -oP 'docBase="\K[^"]+' "$CTX_FILE" 2>/dev/null)
        if [ -n "$DOC_BASE" ]; then
            if [ -d "$DOC_BASE" ]; then
                pass "$CTX_NAME → $DOC_BASE (exists)"
            else
                fail "$CTX_NAME → $DOC_BASE (MISSING — 404 guaranteed)"
                info "Fix: remove $CTX_FILE or fix docBase path"
            fi
        fi
    done
else
    info "No context XMLs in $CTX_DIR — Tomcat uses $WEBAPPS_DIR scanning"
fi

# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "── 4. Webapp Directory & web.xml ──"
echo ""

for MOD in "${MODULES[@]}"; do
    IFS='|' read -r CTX SCRIPT CLASS PORT DB <<< "$MOD"
    DIR="$WEBAPPS_DIR/$CTX"

    if [ ! -d "$DIR" ]; then
        fail "/$CTX — directory MISSING in $WEBAPPS_DIR"
        info "  Deploy: bash $PROJECT_ROOT/$SCRIPT"
        continue
    fi

    FILES=$(find "$DIR" -type f 2>/dev/null | wc -l)
    if [ "$FILES" -lt 2 ]; then
        fail "/$CTX — directory exists but only $FILES file(s)"
        continue
    fi

    if [ -f "$DIR/WEB-INF/web.xml" ]; then
        pass "/$CTX — web.xml present ($FILES files)"
    else
        fail "/$CTX — NO WEB-INF/web.xml ($FILES files) — Tomcat ignores this"
        info "  Tomcat requires web.xml to register the context"
    fi
done

# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "── 5. db.properties ──"
echo ""

for MOD in "${MODULES[@]}"; do
    IFS='|' read -r CTX SCRIPT CLASS PORT DB <<< "$MOD"
    [ -z "$DB" ] && continue
    DIR="$WEBAPPS_DIR/$CTX"
    [ ! -d "$DIR" ] && continue
    PROPS="$DIR/WEB-INF/db.properties"

    if [ -f "$PROPS" ] && grep -q "db.password=." "$PROPS" 2>/dev/null && ! grep -q "CHANGE_ME" "$PROPS" 2>/dev/null; then
        pass "/$CTX — db.properties OK"
    else
        fail "/$CTX — db.properties missing or placeholder"
        info "  Fix: source scripts/deploy-functions.sh && nwe_ensure_db_properties '$DIR' '$DB' '$PROJECT_ROOT'"
    fi
done

# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "── 6. Backend .class Verification ──"
echo ""

OUT="$PROJECT_ROOT/out"
if [ ! -d "$OUT" ]; then
    fail "out/ directory missing — nothing is compiled"
    info "Fix: bash scripts/compile-all-modules.sh"
else
    for MOD in "${MODULES[@]}"; do
        IFS='|' read -r CTX SCRIPT CLASS PORT DB <<< "$MOD"
        [ -z "$CLASS" ] && continue
        CLASS_FILE="$OUT/$(echo "$CLASS" | tr '.' '/').class"
        if [ -f "$CLASS_FILE" ]; then
            if javap -p "$CLASS_FILE" 2>/dev/null | grep -q "public static.*void main"; then
                pass "$CLASS — compiled with main()"
            elif javap -p "$CLASS_FILE" 2>/dev/null | grep -q "public void run"; then
                pass "$CLASS — compiled with run() (Thread)"
            else
                warn "$CLASS — compiled but no main() or run() found"
            fi
        else
            fail "$CLASS — NOT COMPILED: $CLASS_FILE missing"
            info "  Fix: bash scripts/compile-all-modules.sh"
        fi
    done
fi

# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "── 7. HTTP Endpoint Test ──"
echo ""

HTTP_OK=0; HTTP_FAIL=0

for MOD in "${MODULES[@]}"; do
    IFS='|' read -r CTX SCRIPT CLASS PORT DB <<< "$MOD"
    CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 3 "http://localhost:8080/$CTX/" 2>/dev/null || echo "000")

    if [[ "$CODE" =~ ^(200|302)$ ]]; then
        pass "/$CTX → HTTP $CODE"
        HTTP_OK=$((HTTP_OK+1))
    else
        fail "/$CTX → HTTP $CODE"
        HTTP_FAIL=$((HTTP_FAIL+1))
    fi
done

# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "── 8. Auto-Fix (redeploy failing modules + restart Tomcat) ──"
echo ""

if [ "$HTTP_FAIL" -gt 0 ]; then
    echo "  $HTTP_FAIL module(s) returning non-200. Attempting redeploy..."
    echo ""

    for MOD in "${MODULES[@]}"; do
        IFS='|' read -r CTX SCRIPT CLASS PORT DB <<< "$MOD"
        CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 2 "http://localhost:8080/$CTX/" 2>/dev/null || echo "000")
        [[ "$CODE" =~ ^(200|302)$ ]] && continue

        FULL="$PROJECT_ROOT/$SCRIPT"
        if [ -f "$FULL" ]; then
            # Skip BMA in auto-fix (165MB, too slow for diagnosis) — just check dir
            if [[ "$CTX" == "brarner.m.alete" ]]; then
                if [ -d "$WEBAPPS_DIR/$CTX" ] && [ -f "$WEBAPPS_DIR/$CTX/WEB-INF/web.xml" ]; then
                    echo "  [*] /$CTX — webapp exists, skipping large redeploy (restart Tomcat instead)"
                else
                    echo "  [*] /$CTX — needs full deploy (165MB): bash $FULL"
                fi
                continue
            fi
            echo -n "  [*] Redeploying /$CTX... "
            set +e
            timeout 60 bash "$FULL" "$TOMCAT_HOME" 2>&1 | tail -1
            RC=$?
            set -e
            [ $RC -eq 0 ] && echo "✓" || echo "✗ (exit $RC)"
        else
            echo "  [SKIP] /$CTX — no deploy script"
        fi
    done

    echo ""
    echo "  [*] Restarting Tomcat..."
    if [ -x "$TOMCAT_HOME/bin/shutdown.sh" ]; then
        "$TOMCAT_HOME/bin/shutdown.sh" >/dev/null 2>&1 || true
        sleep 4
        "$TOMCAT_HOME/bin/startup.sh" >/dev/null 2>&1
    else
        sudo systemctl restart tomcat 2>/dev/null || true
    fi
    echo "  [*] Waiting 10s for Tomcat to load contexts..."
    sleep 10

    echo ""
    echo "  ── Re-verify ──"
    echo ""
    FIXED=0; STILL=0
    for MOD in "${MODULES[@]}"; do
        IFS='|' read -r CTX SCRIPT CLASS PORT DB <<< "$MOD"
        CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 3 "http://localhost:8080/$CTX/" 2>/dev/null || echo "000")
        if [[ "$CODE" =~ ^(200|302)$ ]]; then
            echo "  [✓] /$CTX — HTTP $CODE"
            FIXED=$((FIXED+1))
        else
            echo "  [✗] /$CTX — HTTP $CODE"
            STILL=$((STILL+1))
        fi
    done
    echo ""
    info "Fixed: $FIXED | Still failing: $STILL"

    if [ "$STILL" -gt 0 ]; then
        echo ""
        echo "  ── Tomcat Error Logs ──"
        echo ""
        for LOG in "$TOMCAT_HOME/logs/catalina.out" "$TOMCAT_HOME/logs/localhost.$(date +%Y-%m-%d).log"; do
            if [ -f "$LOG" ]; then
                ERRORS=$(tail -80 "$LOG" 2>/dev/null | grep -i "SEVERE\|ERROR\|exception" | grep -v "^$" | tail -8)
                if [ -n "$ERRORS" ]; then
                    echo "  From $(basename "$LOG"):"
                    echo "$ERRORS" | sed 's/^/    /'
                    echo ""
                fi
            fi
        done
    fi
else
    pass "All $HTTP_OK endpoints responding — no fix needed"
fi

# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "╔═══════════════════════════════════════════════════════════════════════════╗"
printf "║  Results: PASS=%-3d  WARN=%-3d  FAIL=%-3d                                  ║\n" "$PASS" "$WARN" "$FAIL"
if [ "$FAIL" -eq 0 ]; then
    echo "║  ✓ All checks passed                                                     ║"
else
    echo "║  Recommended:                                                             ║"
    echo "║    1. bash scripts/compile-all-modules.sh                                 ║"
    echo "║    2. bash deploy-all.sh                                                  ║"
    echo "║    3. $TOMCAT_HOME/bin/shutdown.sh && sleep 3 && $TOMCAT_HOME/bin/startup.sh"
    echo "║    4. bash scripts/frontend-diagnosis.sh  (re-run)                        ║"
fi
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo ""
