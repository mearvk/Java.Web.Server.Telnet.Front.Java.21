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

# db.properties: deployed location is canonical on remote
DB_PROPS="$DEPLOY_DIR/WEB-INF/db.properties"
# If not present in deploy, copy from source
if [ ! -f "$DB_PROPS" ] && [ -f "$WEBAPP_SRC/WEB-INF/db.properties" ]; then
    mkdir -p "$DEPLOY_DIR/WEB-INF"
    cp "$WEBAPP_SRC/WEB-INF/db.properties" "$DB_PROPS"
fi

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
    echo "  [*] Deploy dir not found — creating and deploying..."
    mkdir -p "$DEPLOY_DIR/WEB-INF/lib"
    cp -r "$WEBAPP_SRC/"* "$DEPLOY_DIR/"
    mark_fix "Initial deploy to $DEPLOY_DIR"
fi
mark_ok "Deploy directory: $DEPLOY_DIR"

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
DIFF=$(rsync -rcn --out-format="%n" "$WEBAPP_SRC/" "$DEPLOY_DIR/" 2>/dev/null || true)

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
    rsync -rc "$WEBAPP_SRC/" "$DEPLOY_DIR/"

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

# ─── JDBC driver check ───
echo ""
echo "[4b] JDBC driver verification..."

# Ensure JDBC JAR is in jars/ (source of truth for all deploys)
JDBC_IN_JARS=$(find "$BMA_ROOT/jars/" -name "mysql-connector-j*" 2>/dev/null | head -1)
if [ -n "$JDBC_IN_JARS" ]; then
    mark_ok "JDBC driver in jars/: $(basename "$JDBC_IN_JARS")"
else
    # Try to find elsewhere and copy into jars/
    JDBC_ELSEWHERE=$(find "$BMA_ROOT/lib" /opt/tomcat/lib 2>/dev/null -name "mysql-connector-j*" | head -1)
    if [ -n "$JDBC_ELSEWHERE" ]; then
        cp "$JDBC_ELSEWHERE" "$BMA_ROOT/jars/"
        mark_fix "JDBC driver copied to jars/ from $(dirname "$JDBC_ELSEWHERE")"
        JDBC_IN_JARS="$BMA_ROOT/jars/$(basename "$JDBC_ELSEWHERE")"
    else
        mark_fail "MySQL JDBC driver NOT FOUND anywhere"
        echo "         Run: bash install/download-jars.sh"
    fi
fi

# Ensure JDBC JAR is also in lib/ (embedded Tomcat classpath: -cp out:lib/*)
JDBC_IN_LIB=$(find "$BMA_ROOT/lib/" -name "mysql-connector-j*" 2>/dev/null | head -1)
if [ -z "$JDBC_IN_LIB" ] && [ -n "$JDBC_IN_JARS" ]; then
    cp "$JDBC_IN_JARS" "$BMA_ROOT/lib/"
    mark_fix "JDBC driver copied to lib/ (embedded Tomcat classpath)"
elif [ -n "$JDBC_IN_LIB" ]; then
    mark_ok "JDBC driver in lib/: $(basename "$JDBC_IN_LIB")"
fi

# Ensure JDBC JAR is in deploy WEB-INF/lib/ (standard Tomcat)
mkdir -p "$DEPLOY_DIR/WEB-INF/lib" 2>/dev/null || true
JDBC_IN_DEPLOY=$(find "$DEPLOY_DIR/WEB-INF/lib/" -name "mysql-connector-j*" 2>/dev/null | head -1)
if [ -z "$JDBC_IN_DEPLOY" ] && [ -n "$JDBC_IN_JARS" ]; then
    cp "$JDBC_IN_JARS" "$DEPLOY_DIR/WEB-INF/lib/"
    mark_fix "JDBC driver copied to $DEPLOY_DIR/WEB-INF/lib/"
    NEEDS_TOMCAT_RESTART=1
elif [ -n "$JDBC_IN_DEPLOY" ]; then
    mark_ok "JDBC driver in WEB-INF/lib/: $(basename "$JDBC_IN_DEPLOY")"
else
    mark_fail "JDBC driver missing from $DEPLOY_DIR/WEB-INF/lib/ and no source found"
fi

# ─── Ownership & symlinks ───
chown -R tomcat:tomcat "$DEPLOY_DIR" 2>/dev/null || true
ln -sfn "$DEPLOY_DIR" "$BMA_ROOT/www" 2>/dev/null || true
ln -sfn "$DEPLOY_DIR" "$BMA_ROOT/web" 2>/dev/null || true

# ─── DB connectivity ───
echo ""
echo "[5] Database connectivity (using $DB_PROPS)..."

if [ -f "$DB_PROPS" ]; then
    DB_USER=$(grep '^db.user=' "$DB_PROPS" | cut -d= -f2-)
    DB_PASS=$(grep '^db.password=' "$DB_PROPS" | cut -d= -f2-)
    DB_URL=$(grep '^db.url=' "$DB_PROPS" | cut -d= -f2-)
    DB_HOST=$(echo "$DB_URL" | sed -n 's|.*://\([^:/]*\).*|\1|p')
    DB_PORT=$(echo "$DB_URL" | sed -n 's|.*:\([0-9]*\)/.*|\1|p')
    DB_NAME=$(echo "$DB_URL" | sed -n 's|.*/\([^?]*\).*|\1|p')
    DB_HOST="${DB_HOST:-localhost}"
    DB_PORT="${DB_PORT:-3306}"

    mark_ok "db.properties: user=$DB_USER host=$DB_HOST:$DB_PORT db=$DB_NAME"

    # Test connection exactly as JSP pages would (same credentials)
    if mysql -u"$DB_USER" -p"$DB_PASS" -h"$DB_HOST" -P"$DB_PORT" "$DB_NAME" -e "SELECT 1" &>/dev/null; then
        mark_ok "MySQL connection OK (verified with db.properties credentials)"

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
        mark_fail "MySQL connection FAILED with db.properties credentials"
        echo "         File:     $DB_PROPS"
        echo "         User:     $DB_USER"
        echo "         Host:     $DB_HOST:$DB_PORT"
        echo "         Database: $DB_NAME"
        echo "         Password: $([ -n "$DB_PASS" ] && echo "set (${#DB_PASS} chars)" || echo "EMPTY")"
        echo ""
        echo "         Troubleshoot:"
        if ! timeout 2 bash -c "echo >/dev/tcp/$DB_HOST/$DB_PORT" 2>/dev/null; then
            echo "           [!] Port $DB_HOST:$DB_PORT not reachable — MySQL not running?"
        else
            echo "           [OK] Port $DB_HOST:$DB_PORT is open"
            echo "           [!] Credentials rejected — check user/password"
        fi
        echo "         Fix: bash install/set-db-credentials.sh"
    fi
else
    mark_fail "db.properties not found"
    echo "         Checked: $DEPLOY_DIR/WEB-INF/db.properties"
    echo "         Checked: $WEBAPP_SRC/WEB-INF/db.properties"
    echo "         Fix: bash install/set-db-credentials.sh"
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

# ─── Legal data integrity ───
echo ""
echo "[6b] Legal module data..."

LEGAL_SAFE="$BMA_ROOT/data/legal/safe"
if [ -d "$LEGAL_SAFE" ]; then
    SAFE_COUNT=$(find "$LEGAL_SAFE" -type f \( -name "*.csv" -o -name "*.rdns" -o -name "*.txt" \) | wc -l)
    if [ "$SAFE_COUNT" -ge 10 ]; then
        mark_ok "Legal safe data: $SAFE_COUNT files"
    else
        mark_fail "Legal safe data incomplete ($SAFE_COUNT files, expected 10+)"
        echo "         Fix: bash data/legal/download-legal-data.sh && bash data/legal/unzip-and-consume.sh"
    fi
    # Verify SHA-256 integrity
    INTEGRITY="$LEGAL_SAFE/integrity.sha256"
    if [ -f "$INTEGRITY" ]; then
        if cd "$LEGAL_SAFE" && sha256sum -c "$INTEGRITY" &>/dev/null; then
            mark_ok "Legal data integrity: SHA-256 verified"
        else
            mark_fail "Legal data integrity: SHA-256 mismatch — rerun unzip-and-consume.sh"
        fi
        cd "$BMA_ROOT" 2>/dev/null || true
    else
        mark_skip "No integrity.sha256 found — rerun unzip-and-consume.sh"
    fi
    # Check legal.jsp deployed
    if [ -f "$DEPLOY_DIR/legal.jsp" ]; then
        mark_ok "legal.jsp deployed"
    else
        mark_fail "legal.jsp missing from $DEPLOY_DIR — webapp needs redeploy"
    fi
    # Deploy legal safe data to webapp if missing
    if [ ! -d "$DEPLOY_DIR/data/legal" ] || [ "$(find "$DEPLOY_DIR/data/legal" -type f 2>/dev/null | wc -l)" -lt "$SAFE_COUNT" ]; then
        mkdir -p "$DEPLOY_DIR/data/legal"
        cp "$LEGAL_SAFE"/*.csv "$DEPLOY_DIR/data/legal/" 2>/dev/null || true
        cp "$LEGAL_SAFE"/*.rdns "$DEPLOY_DIR/data/legal/" 2>/dev/null || true
        cp "$LEGAL_SAFE"/*.txt "$DEPLOY_DIR/data/legal/" 2>/dev/null || true
        chmod 444 "$DEPLOY_DIR/data/legal/"* 2>/dev/null || true
        mark_fix "Legal data synced to $DEPLOY_DIR/data/legal/"
    else
        mark_ok "Legal data in webapp is current"
    fi
else
    mark_fail "Legal safe directory not found: $LEGAL_SAFE"
    echo "         Fix: bash data/legal/download-legal-data.sh && bash data/legal/unzip-and-consume.sh"
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
