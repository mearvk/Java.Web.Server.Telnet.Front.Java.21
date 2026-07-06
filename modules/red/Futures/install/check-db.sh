#!/usr/bin/env bash
# Futures — Database Population Check
# Usage: bash install/check-db.sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MOD_ROOT="$(dirname "$SCRIPT_DIR")"
DB_PROPS="$MOD_ROOT/servlets/servlet/src/main/webapp/WEB-INF/db.properties"

if [ -f "$DB_PROPS" ]; then
    DB_USER=$(grep '^db.user=' "$DB_PROPS" | cut -d= -f2-)
    DB_PASS=$(grep '^db.password=' "$DB_PROPS" | cut -d= -f2-)
    DB_HOST=$(grep '^db.url=' "$DB_PROPS" | sed -n 's|.*://\([^:/]*\).*|\1|p')
    DB_HOST="${DB_HOST:-127.0.0.1}"
else
    DB_USER="root"; DB_PASS='$$Ironman1'; DB_HOST="127.0.0.1"
fi
DB_NAME="nwe_futures"
MYSQL="mysql -u$DB_USER -p$DB_PASS -h$DB_HOST $DB_NAME -N -B"

echo "═══════════════════════════════════════════════════════════════"
echo " Futures — Database Population Check"
echo " Database: $DB_NAME @ $DB_HOST (user=$DB_USER)"
echo " Time:     $(date '+%Y-%m-%d %H:%M:%S %Z')"
echo "═══════════════════════════════════════════════════════════════"
echo ""

if ! mysql -u$DB_USER -p$DB_PASS -h$DB_HOST -e "USE $DB_NAME" 2>/dev/null; then
    echo "[FAIL] Cannot connect to '$DB_NAME'  user=$DB_USER  host=$DB_HOST"
    [ ! -f "$DB_PROPS" ] && echo "       db.properties NOT FOUND: $DB_PROPS"
    exit 1
fi

TABLES=$($MYSQL -e "SHOW TABLES;" 2>/dev/null)
TABLE_COUNT=$(echo "$TABLES" | grep -c . || true)
echo "Tables found: $TABLE_COUNT"; echo ""
printf "  %-30s %10s %s\n" "TABLE" "ROWS" "STATUS"
printf "  %-30s %10s %s\n" "-----" "----" "------"

POPULATED=0; EMPTY=0
for TABLE in $TABLES; do
    COUNT=$($MYSQL -e "SELECT COUNT(*) FROM \`$TABLE\`;" 2>/dev/null)
    if [ "$COUNT" -gt 0 ] 2>/dev/null; then
        STATUS="✓ populated"; POPULATED=$((POPULATED + 1))
    else
        STATUS="✗ EMPTY"; EMPTY=$((EMPTY + 1))
    fi
    printf "  %-30s %10s %s\n" "$TABLE" "$COUNT" "$STATUS"
done

echo ""
echo "───────────────────────────────────────────────────────────────"
echo " Summary: $TABLE_COUNT tables | $POPULATED populated | $EMPTY empty"
[ $EMPTY -eq 0 ] && echo " Result:  ALL TABLES POPULATED ✓" || echo " Result:  $EMPTY TABLE(S) NEED DATA ✗"
echo "═══════════════════════════════════════════════════════════════"
