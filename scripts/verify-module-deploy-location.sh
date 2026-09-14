#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# NitroWebExpress™ — Verify Module Deploy Locations
# Checks that deployed webapps in Tomcat have all classes, JARs, and configs
# that their WEB-INF/web.xml references actually present.
#
# Verifies:
#   1. Every <servlet-class> in web.xml has a matching .class file in WEB-INF/classes
#   2. Every <filter-class> in web.xml has a matching .class file in WEB-INF/classes
#   3. JDBC driver JAR present in WEB-INF/lib (if db.properties exists)
#   4. db.properties exists and has real credentials
#   5. JSP files referenced by web.xml welcome-file-list exist
#   6. Source webapp matches deployed webapp (drift detection)
#
# Usage: bash scripts/verify-module-deploy-location.sh [tomcat_home]
# ═══════════════════════════════════════════════════════════════════════════════
set -uo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TOMCAT_HOME="${1:-${CATALINA_HOME:-/opt/apache-tomcat-11.0.2}}"
WEBAPPS_DIR="$TOMCAT_HOME/webapps"

PASS=0; FAIL=0; WARN=0
pass() { PASS=$((PASS+1)); echo "  [PASS] $1"; }
fail() { FAIL=$((FAIL+1)); echo "  [FAIL] $1"; }
warn() { WARN=$((WARN+1)); echo "  [WARN] $1"; }

# context|source_webapp_dir
declare -A MODULE_SOURCES=(
    ["california-fbi"]="modules/fbi/servlets/servlet/src/main/webapp"
    ["california-cia"]="modules/cia/servlets/servlet/src/main/webapp"
    ["california-nsa"]="modules/nsa/servlets/servlet/src/main/webapp"
    ["california-duke"]="modules/duke/servlets/servlet/src/main/webapp"
    ["library"]="modules/library/servlets/servlet/src/main/webapp"
    ["ae6e66"]="modules/AE6E66/servlets/servlet/src/main/webapp"
    ["futures"]="modules/red/Futures/servlets/servlet/src/main/webapp"
    ["gdgh"]="modules/Green.Durham.Grass.and.Herb/servlets/servlet/src/main/webapp"
    ["gray-registry"]="modules/gray/servlets/servlet/src/main/webapp"
    ["gray85-registry"]="modules/gray.a85/servlets/servlet/src/main/webapp"
    ["blackbelt"]="modules/black-belt/servlets/servlet/src/main/webapp"
    ["languages"]="modules/languages/servlets/servlet/src/main/webapp"
    ["brarner.m.alete"]="modules/black/presidential/Brarner.M.Alete/servlets/servlet/src/main/webapp"
)

echo ""
echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║  NitroWebExpress™ — Verify Module Deploy Locations                        ║"
echo "║  Tomcat webapps: $WEBAPPS_DIR"
echo "║  Project root:   $PROJECT_ROOT"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"

for CONTEXT in $(echo "${!MODULE_SOURCES[@]}" | tr ' ' '\n' | sort); do
    SRC_REL="${MODULE_SOURCES[$CONTEXT]}"
    SRC_DIR="$PROJECT_ROOT/$SRC_REL"
    DEPLOY_DIR="$WEBAPPS_DIR/$CONTEXT"

    echo ""
    echo "── /$CONTEXT ──"

    # 1. Check deployed directory exists
    if [ ! -d "$DEPLOY_DIR" ]; then
        fail "Webapp not deployed: $DEPLOY_DIR missing"
        continue
    fi

    # 2. Check web.xml exists
    WEB_XML="$DEPLOY_DIR/WEB-INF/web.xml"
    if [ ! -f "$WEB_XML" ]; then
        fail "No WEB-INF/web.xml — Tomcat won't load this context"
        continue
    fi
    pass "web.xml present"

    # 3. Check every <servlet-class> has a .class file
    SERVLET_CLASSES=$(grep -oP '(?<=<servlet-class>)[^<]+' "$WEB_XML" 2>/dev/null | grep -v "org.apache")
    for CLASS in $SERVLET_CLASSES; do
        CLASS_FILE="$DEPLOY_DIR/WEB-INF/classes/$(echo "$CLASS" | tr '.' '/').class"
        if [ -f "$CLASS_FILE" ]; then
            pass "servlet-class: $CLASS → found"
        else
            fail "servlet-class: $CLASS → MISSING at $CLASS_FILE"
            # Check if it's in a JAR instead
            if ls "$DEPLOY_DIR/WEB-INF/lib/"*.jar &>/dev/null; then
                for JAR in "$DEPLOY_DIR/WEB-INF/lib/"*.jar; do
                    if jar tf "$JAR" 2>/dev/null | grep -q "$(echo "$CLASS" | tr '.' '/').class"; then
                        warn "  (found in JAR: $(basename "$JAR") — OK if intended)"
                        break
                    fi
                done
            fi
        fi
    done

    # 4. Check every <filter-class> has a .class file
    FILTER_CLASSES=$(grep -oP '(?<=<filter-class>)[^<]+' "$WEB_XML" 2>/dev/null | grep -v "org.apache")
    for CLASS in $FILTER_CLASSES; do
        CLASS_FILE="$DEPLOY_DIR/WEB-INF/classes/$(echo "$CLASS" | tr '.' '/').class"
        if [ -f "$CLASS_FILE" ]; then
            pass "filter-class: $CLASS → found"
        else
            fail "filter-class: $CLASS → MISSING at $CLASS_FILE"
            echo "         Tomcat will fail to start this webapp (ClassNotFoundException)"
        fi
    done

    # 5. Check JDBC driver if db.properties exists
    DB_PROPS="$DEPLOY_DIR/WEB-INF/db.properties"
    if [ -f "$DB_PROPS" ]; then
        JDBC_JAR=$(find "$DEPLOY_DIR/WEB-INF/lib" -name "mysql-connector*" 2>/dev/null | head -1)
        if [ -n "$JDBC_JAR" ]; then
            pass "JDBC driver: $(basename "$JDBC_JAR")"
        else
            fail "db.properties exists but NO JDBC driver in WEB-INF/lib/"
            echo "         JSP database queries will throw ClassNotFoundException for com.mysql.cj.jdbc.Driver"
        fi

        # Check credentials
        if grep -q "db.password=." "$DB_PROPS" 2>/dev/null && ! grep -q "CHANGE_ME\|PLACEHOLDER" "$DB_PROPS" 2>/dev/null; then
            pass "db.properties has credentials"
        else
            fail "db.properties missing or placeholder password"
        fi
    fi

    # 6. Check welcome files exist
    WELCOME_FILES=$(grep -oP '(?<=<welcome-file>)[^<]+' "$WEB_XML" 2>/dev/null)
    for WF in $WELCOME_FILES; do
        if [ -f "$DEPLOY_DIR/$WF" ]; then
            pass "welcome-file: $WF → found"
        else
            fail "welcome-file: $WF → MISSING (causes 404 on /)"
        fi
    done

    # 7. Source vs deployed drift detection
    if [ -d "$SRC_DIR" ]; then
        SRC_JSPS=$(find "$SRC_DIR" -maxdepth 1 -name "*.jsp" 2>/dev/null | wc -l)
        DEPLOY_JSPS=$(find "$DEPLOY_DIR" -maxdepth 1 -name "*.jsp" 2>/dev/null | wc -l)
        if [ "$SRC_JSPS" -ne "$DEPLOY_JSPS" ]; then
            warn "JSP count mismatch: source=$SRC_JSPS deployed=$DEPLOY_JSPS (redeploy needed?)"
        fi

        SRC_WEBXML_HASH=$(sha256sum "$SRC_DIR/WEB-INF/web.xml" 2>/dev/null | cut -d' ' -f1)
        DEPLOY_WEBXML_HASH=$(sha256sum "$WEB_XML" 2>/dev/null | cut -d' ' -f1)
        if [ -n "$SRC_WEBXML_HASH" ] && [ "$SRC_WEBXML_HASH" != "$DEPLOY_WEBXML_HASH" ]; then
            warn "web.xml differs between source and deployed (redeploy needed)"
        fi
    else
        warn "Source webapp not found: $SRC_DIR"
    fi
done

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "╔═══════════════════════════════════════════════════════════════════════════╗"
printf "║  Results: PASS=%-3d  WARN=%-3d  FAIL=%-3d                                  ║\n" "$PASS" "$WARN" "$FAIL"
if [ "$FAIL" -gt 0 ]; then
    echo "║                                                                           ║"
    echo "║  Common fixes:                                                            ║"
    echo "║    Missing .class:  bash scripts/compile-all-modules.sh                   ║"
    echo "║                     bash deploy-all.sh                                    ║"
    echo "║    Missing JDBC:    cp jars/mysql/mysql-connector-j-9.7.0.jar             ║"
    echo "║                     → <webapp>/WEB-INF/lib/                               ║"
    echo "║    db.properties:   bash scripts/populate-db-properties.sh                ║"
    echo "║    Drift detected:  bash deploy-all.sh (redeploys all)                    ║"
fi
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo ""
