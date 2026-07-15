#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# NitroWebExpress™ — Populate db.properties for All Deployed Webapps
# Generates db.properties from .nwe-credentials for every module in Tomcat.
#
# Usage: bash scripts/populate-db-properties.sh [tomcat_home]
# ═══════════════════════════════════════════════════════════════════════════════
set -uo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TOMCAT_HOME="${1:-${CATALINA_HOME:-/opt/apache-tomcat-11.0.2}}"

source "$PROJECT_ROOT/scripts/deploy-functions.sh"

# context → database name
declare -A WEBAPP_DBS=(
    ["california-fbi"]="nwe_california_fbi"
    ["california-cia"]="nwe_california_cia"
    ["california-nsa"]="nwe_california_nsa"
    ["california-duke"]="nwe_duke"
    ["library"]="nwe_library"
    ["ae6e66"]="nwe_ae6e66"
    ["futures"]="nwe_futures"
    ["gdgh"]="nwe_gdgh"
    ["gray-registry"]="nwe_gray_registry"
    ["gray85-registry"]="nwe_gray85_registry"
    ["brarner.m.alete"]="BrarnerScience"
)

echo ""
echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║  NitroWebExpress™ — Populate db.properties                               ║"
echo "║  Tomcat:  $TOMCAT_HOME"
echo "║  Source:  $PROJECT_ROOT/.nwe-credentials"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo ""

# Check .nwe-credentials exists
if [ ! -f "$PROJECT_ROOT/.nwe-credentials" ]; then
    echo "[FAIL] .nwe-credentials not found at $PROJECT_ROOT/.nwe-credentials"
    echo ""
    echo "  Create it:"
    echo "    cat > $PROJECT_ROOT/.nwe-credentials <<EOF"
    echo '    NWE_DB_HOST="127.0.0.1"'
    echo '    NWE_DB_PORT="3306"'
    echo '    NWE_DB_USER="root"'
    echo '    NWE_DB_PASS="yourpassword"'
    echo "    EOF"
    echo "    chmod 600 $PROJECT_ROOT/.nwe-credentials"
    exit 1
fi

GENERATED=0
SKIPPED=0
MISSING=0

for CONTEXT in "${!WEBAPP_DBS[@]}"; do
    DB_NAME="${WEBAPP_DBS[$CONTEXT]}"
    WEBAPP_DIR="$TOMCAT_HOME/webapps/$CONTEXT"

    if [ ! -d "$WEBAPP_DIR" ]; then
        echo "  [SKIP] /$CONTEXT — webapp not deployed"
        MISSING=$((MISSING + 1))
        continue
    fi

    DB_PROPS="$WEBAPP_DIR/WEB-INF/db.properties"

    # Check if already valid
    if [ -f "$DB_PROPS" ] && grep -q "db.password=." "$DB_PROPS" 2>/dev/null && ! grep -q "CHANGE_ME\|PLACEHOLDER" "$DB_PROPS" 2>/dev/null; then
        echo "  [OK]   /$CONTEXT — already configured"
        SKIPPED=$((SKIPPED + 1))
        continue
    fi

    # Generate
    nwe_ensure_db_properties "$WEBAPP_DIR" "$DB_NAME" "$PROJECT_ROOT"
    if [ -f "$DB_PROPS" ] && grep -q "db.password=." "$DB_PROPS" 2>/dev/null; then
        echo "  [✓]   /$CONTEXT → $DB_NAME"
        GENERATED=$((GENERATED + 1))
    else
        echo "  [FAIL] /$CONTEXT — generation failed"
    fi
done

# Also populate source webapp directories (so future deploys carry them)
echo ""
echo "  [*] Also populating source webapp directories..."

declare -A SOURCE_DBS=(
    ["modules/fbi/servlets/servlet/src/main/webapp"]="nwe_california_fbi"
    ["modules/cia/servlets/servlet/src/main/webapp"]="nwe_california_cia"
    ["modules/nsa/servlets/servlet/src/main/webapp"]="nwe_california_nsa"
    ["modules/duke/servlets/servlet/src/main/webapp"]="nwe_duke"
    ["modules/library/servlets/servlet/src/main/webapp"]="nwe_library"
    ["modules/AE6E66/servlets/servlet/src/main/webapp"]="nwe_ae6e66"
    ["modules/red/Futures/servlets/servlet/src/main/webapp"]="nwe_futures"
    ["modules/Green.Durham.Grass.and.Herb/servlets/servlet/src/main/webapp"]="nwe_gdgh"
    ["modules/gray/servlets/servlet/src/main/webapp"]="nwe_gray_registry"
    ["modules/gray.a85/servlets/servlet/src/main/webapp"]="nwe_gray85_registry"
    ["modules/black/presidential/Brarner.M.Alete/servlets/servlet/src/main/webapp"]="BrarnerScience"
)

for SRC_PATH in "${!SOURCE_DBS[@]}"; do
    FULL="$PROJECT_ROOT/$SRC_PATH"
    DB_NAME="${SOURCE_DBS[$SRC_PATH]}"
    if [ -d "$FULL" ]; then
        DB_PROPS="$FULL/WEB-INF/db.properties"
        if [ -f "$DB_PROPS" ] && grep -q "db.password=." "$DB_PROPS" 2>/dev/null && ! grep -q "CHANGE_ME\|PLACEHOLDER" "$DB_PROPS" 2>/dev/null; then
            continue
        fi
        nwe_ensure_db_properties "$FULL" "$DB_NAME" "$PROJECT_ROOT" >/dev/null 2>&1
    fi
done
echo "  [✓] Source directories updated"

echo ""
echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║  Results: $GENERATED generated | $SKIPPED already OK | $MISSING not deployed"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo ""
