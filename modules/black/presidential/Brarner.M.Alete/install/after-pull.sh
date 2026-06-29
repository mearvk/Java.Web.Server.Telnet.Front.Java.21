#!/bin/bash
# Brarner.M.Alete™ — After-Pull Deploy & Health Check
# Syncs only changed resources, verifies DB, checks services, restarts only what's needed.
# Usage: sudo bash install/after-pull.sh [tomcat_home]
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BMA_ROOT="$(dirname "$SCRIPT_DIR")"
WEBAPP_SRC="$BMA_ROOT/servlets/servlet/src/main/webapp"
TOMCAT_HOME="${1:-${CATALINA_HOME:-/opt/tomcat}}"
CONTEXT="brarner.m.alete"
DEPLOY_DIR="$TOMCAT_HOME/webapps/$CONTEXT"
DB_PROPS="$DEPLOY_DIR/WEB-INF/db.properties"

OK=0; SKIP=0; FIX=0; FAIL=0

mark_ok()   { echo "  [OK]   $1"; OK=$((OK + 1)); }
mark_skip() { echo "  [SKIP] $1"; SKIP=$((SKIP + 1)); }
mark_fix()  { echo "  [FIX]  $1"; FIX=$((FIX + 1)); }
mark_fail() { echo "  [FAIL] $1"; FAIL=$((FAIL + 1)); }

echo "═══════════════════════════════════════════════════════════════"
echo " Brarner.M.Alete™ — After-Pull Deploy & Health Check"
echo " Source:  $WEBAPP_SRC"
echo " Deploy:  $DEPLOY_DIR"
echo " Time:    $(date '+%Y-%m-%d %H:%M:%S %Z')"
echo "═══════════════════════════════════════════════════════════════"

# ─── Pre-flight ───
echo ""
echo "[1] Pre-flight checks..."

if [ ! -d "$WEBAPP_SRC" ]; then
    mark_fail "Webapp source not found: $WEBAPP_SRC"; exit 1
fi
mark_ok "Webapp source exists"

if [ ! -d "$DEPLOY_DIR" ]; then
    mark_fail "Deploy dir not found — run install/deploy-local.sh first"; exit 1
fi
mark_ok "Deploy directory exists"

if [ ! -f "$WEBAPP_SRC/WEB-INF/web.xml" ]; then
    mark_fail "web.xml missing from source"
else
    mark_ok "web.xml present"
fi

# ─── Service status ───
echo ""
echo "[2] Service status..."

TOMCAT_RUNNING=0
if systemctl is-active tomcat &>/dev/null; then
    mark_ok "Tomcat is running"
    TOMCAT_RUNNING=1
elif "$TOMCAT_HOME/bin/catalina.sh" status &>/dev/null 2>&1; then
    mark_ok "Tomcat is running (non-systemd)"
    TOMCAT_RUNNING=1
else
    mark_fail "Tomcat is NOT running"
fi

APACHE_RUNNING=0
if systemctl is-active apache2 &>/dev/null || systemctl is-active httpd &>/dev/null; then
    mark_ok "Apache2 is running"
    APACHE_RUNNING=1
else
    mark_skip "Apache2 not running (may not be needed locally)"
fi

# ─── File sync ───
echo ""
echo "[3] Syncing resources (only changed files)..."

NEEDS_TOMCAT_RESTART=0
NEEDS_APACHE_RELOAD=0

# Check what would change
DIFF=$(rsync -rcn --out-format="%n" "$WEBAPP_SRC/" "$DEPLOY_DIR/" \
    --exclude="WEB-INF/db.properties" 2>/dev/null || true)

if [ -z "$DIFF" ]; then
    mark_ok "All webapp files are current — nothing to sync"
else
    # Categorize changes
    JSP_CHANGES=$(echo "$DIFF" | grep -c '\.jsp$' || true)
    XHTML_CHANGES=$(echo "$DIFF" | grep -c '\.xhtml$' || true)
    CSS_CHANGES=$(echo "$DIFF" | grep -c '\.css$' || true)
    IMG_CHANGES=$(echo "$DIFF" | grep -c 'images/' || true)
    XML_CHANGES=$(echo "$DIFF" | grep -c '\.xml$' || true)
    OTHER_CHANGES=$(echo "$DIFF" | grep -vcE '\.(jsp|xhtml|css|xml)$|images/' || true)

    # Apply sync
    rsync -rc "$WEBAPP_SRC/" "$DEPLOY_DIR/" --exclude="WEB-INF/db.properties"

    [ "$JSP_CHANGES" -gt 0 ] && mark_fix "$JSP_CHANGES JSP file(s) updated"
    [ "$XHTML_CHANGES" -gt 0 ] && mark_fix "$XHTML_CHANGES XHTML file(s) updated"
    [ "$CSS_CHANGES" -gt 0 ] && mark_fix "$CSS_CHANGES CSS file(s) updated" && NEEDS_APACHE_RELOAD=1
    [ "$IMG_CHANGES" -gt 0 ] && mark_fix "$IMG_CHANGES image(s) updated" && NEEDS_APACHE_RELOAD=1
    [ "$XML_CHANGES" -gt 0 ] && mark_fix "$XML_CHANGES XML config(s) updated"
    [ "$OTHER_CHANGES" -gt 0 ] && mark_fix "$OTHER_CHANGES other file(s) updated"

    # web.xml change requires restart
    if echo "$DIFF" | grep -q "WEB-INF/web.xml"; then
        NEEDS_TOMCAT_RESTART=1
    fi
fi

# ─── JAR sync ───
echo ""
echo "[4] Checking JARs..."

if ls "$BMA_ROOT/jars/"*.jar &>/dev/null; then
    JAR_DIFF=$(rsync -rcn --out-format="%n" "$BMA_ROOT/jars/" "$DEPLOY_DIR/WEB-INF/lib/" 2>/dev/null || true)
    if [ -z "$JAR_DIFF" ]; then
        mark_ok "All JARs are current"
    else
        JAR_COUNT=$(echo "$JAR_DIFF" | wc -l)
        rsync -rc "$BMA_ROOT/jars/" "$DEPLOY_DIR/WEB-INF/lib/"
        mark_fix "$JAR_COUNT JAR(s) updated in WEB-INF/lib/"
        NEEDS_TOMCAT_RESTART=1
    fi
else
    mark_skip "No jars/ directory — skipping JAR sync"
fi

# ─── Ownership ───
chown -R tomcat:tomcat "$DEPLOY_DIR" 2>/dev/null || true

# ─── DB connectivity ───
echo ""
echo "[5] Database connectivity..."

if [ -f "$DB_PROPS" ]; then
    DB_USER=$(grep '^db.user=' "$DB_PROPS" | cut -d= -f2-)
    DB_PASS=$(grep '^db.password=' "$DB_PROPS" | cut -d= -f2-)
    DB_URL=$(grep '^db.url=' "$DB_PROPS" | cut -d= -f2-)
    DB_HOST=$(echo "$DB_URL" | sed -n 's|.*://\([^:/]*\).*|\1|p')
    DB_PORT=$(echo "$DB_URL" | sed -n 's|.*:\([0-9]*\)/.*|\1|p')
    DB_NAME=$(echo "$DB_URL" | sed -n 's|.*/\([^?]*\).*|\1|p')
    DB_HOST="${DB_HOST:-localhost}"
    DB_PORT="${DB_PORT:-3306}"

    mark_ok "db.properties present (user=$DB_USER, db=$DB_NAME)"

    if mysql -u"$DB_USER" -p"$DB_PASS" -h"$DB_HOST" -P"$DB_PORT" "$DB_NAME" -e "SELECT 1" &>/dev/null; then
        mark_ok "MySQL connection OK ($DB_USER@$DB_HOST:$DB_PORT/$DB_NAME)"

        # Quick table check
        TABLES=$(mysql -u"$DB_USER" -p"$DB_PASS" -h"$DB_HOST" -P"$DB_PORT" "$DB_NAME" -N -B -e "SHOW TABLES;" 2>/dev/null)
        TABLE_COUNT=$(echo "$TABLES" | wc -w)
        EMPTY_TABLES=0
        for T in $TABLES; do
            COUNT=$(mysql -u"$DB_USER" -p"$DB_PASS" -h"$DB_HOST" -P"$DB_PORT" "$DB_NAME" -N -B -e "SELECT COUNT(*) FROM \`$T\`;" 2>/dev/null)
            [ "$COUNT" -eq 0 ] 2>/dev/null && EMPTY_TABLES=$((EMPTY_TABLES + 1))
        done
        if [ "$EMPTY_TABLES" -eq 0 ]; then
            mark_ok "All $TABLE_COUNT tables populated"
        else
            mark_fail "$EMPTY_TABLES/$TABLE_COUNT table(s) empty — run: bash install/populate-all.sh"
        fi
    else
        mark_fail "MySQL connection FAILED — check credentials in $DB_PROPS"
    fi
else
    mark_fail "db.properties missing from deploy — run: bash install/set-db-credentials.sh"
fi

# ─── JSP page health (if Tomcat running) ───
echo ""
echo "[6] JSP page health..."

if [ "$TOMCAT_RUNNING" -eq 1 ]; then
    BASE="http://localhost:8080/$CONTEXT"
    for jsp in $(find "$WEBAPP_SRC" -maxdepth 1 -name "*.jsp" -printf "%f\n" 2>/dev/null | sort); do
        STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "${BASE}/${jsp}" 2>/dev/null)
        if [ "$STATUS" -ge 200 ] && [ "$STATUS" -lt 400 ] 2>/dev/null; then
            mark_ok "$jsp → $STATUS"
        else
            mark_fail "$jsp → $STATUS"
        fi
    done
else
    mark_skip "Tomcat not running — cannot check pages"
fi

# ─── Restart decisions ───
echo ""
echo "[7] Service restart decisions..."

if [ "$NEEDS_TOMCAT_RESTART" -eq 1 ] && [ "$TOMCAT_RUNNING" -eq 1 ]; then
    echo "  [*] Restarting Tomcat (JARs or web.xml changed)..."
    systemctl restart tomcat 2>/dev/null || { "$TOMCAT_HOME/bin/shutdown.sh" && "$TOMCAT_HOME/bin/startup.sh"; }
    mark_fix "Tomcat restarted"
elif [ "$NEEDS_TOMCAT_RESTART" -eq 0 ]; then
    mark_ok "Tomcat restart not needed (JSP hot-reloads)"
fi

if [ "$NEEDS_APACHE_RELOAD" -eq 1 ] && [ "$APACHE_RUNNING" -eq 1 ]; then
    echo "  [*] Reloading Apache2 (static assets changed)..."
    systemctl reload apache2 2>/dev/null || systemctl reload httpd 2>/dev/null || true
    mark_fix "Apache2 reloaded"
elif [ "$APACHE_RUNNING" -eq 1 ]; then
    mark_ok "Apache2 reload not needed"
fi

# ─── Summary ───
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo " Results: $OK ok | $FIX fixed | $SKIP skipped | $FAIL failed"
if [ "$FAIL" -eq 0 ]; then
    echo " Status:  ALL GOOD ✓"
else
    echo " Status:  $FAIL ISSUE(S) NEED ATTENTION"
fi
echo "═══════════════════════════════════════════════════════════════"
