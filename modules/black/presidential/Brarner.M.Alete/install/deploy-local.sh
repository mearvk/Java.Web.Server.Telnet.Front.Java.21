#!/bin/bash
# Brarner.M.Alete™ — Quick Local Deploy (exploded, no WAR)
# Copies webapp directly to Tomcat webapps for immediate serving.
# Usage: sudo bash install/deploy-local.sh [tomcat_home]
set -e

# Detect MySQL location and check disk space
_NWE="$(cd "$(dirname "$0")/../../../.." 2>/dev/null && pwd)"
[ -f "$_NWE/scripts/detect-mysql.sh" ] && source "$_NWE/scripts/detect-mysql.sh"
MAIN_AVAIL=$(df --output=avail / 2>/dev/null | tail -1 | tr -d " ")
if [ "${MAIN_AVAIL:-999999}" -lt 524288 ]; then
    echo "[!] WARNING: Main drive has less than 512MB free. Deploy may fail."
    echo "    If MySQL is not on block storage, run: sudo bash scripts/migrate-mysql-to-blockstorage.sh"
    df -h / | tail -1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BMA_ROOT="$(dirname "$SCRIPT_DIR")"
WEBAPP_SRC="$BMA_ROOT/servlets/servlet/src/main/webapp"
TOMCAT_HOME="${1:-${CATALINA_HOME:-/home/mearvk/tomcat}}"
CONTEXT="brarner.m.alete"
DEPLOY_DIR="$TOMCAT_HOME/webapps/$CONTEXT"

echo "═══════════════════════════════════════════════════════════════"
echo " Brarner.M.Alete™ — Quick Local Deploy"
echo " Source:  $WEBAPP_SRC"
echo " Target:  $DEPLOY_DIR"
echo "═══════════════════════════════════════════════════════════════"

if [ ! -d "$WEBAPP_SRC" ]; then
    echo "[!] Webapp source not found: $WEBAPP_SRC"
    exit 1
fi

if [ ! -d "$TOMCAT_HOME/webapps" ]; then
    echo "[!] Tomcat not found at: $TOMCAT_HOME"
    echo "    Set CATALINA_HOME or pass path: sudo bash install/deploy-local.sh /path/to/tomcat"
    exit 1
fi

# Deploy exploded webapp (rsync for speed — only copies changed files)
echo "[*] Deploying exploded webapp..."
mkdir -p "$DEPLOY_DIR/WEB-INF/classes" "$DEPLOY_DIR/WEB-INF/lib"
TOTAL_FILES=$(find "$WEBAPP_SRC" -type f 2>/dev/null | wc -l)
echo "    Source: $TOTAL_FILES files ($(du -sh "$WEBAPP_SRC" | cut -f1))"
if command -v rsync &>/dev/null; then
    rsync -a --delete --info=progress2 --exclude='db.properties' "$WEBAPP_SRC/" "$DEPLOY_DIR/"
    echo "    [✓] rsync complete"
else
    rm -rf "$DEPLOY_DIR"
    mkdir -p "$DEPLOY_DIR/WEB-INF/classes" "$DEPLOY_DIR/WEB-INF/lib"
    echo -n "    Copying... "
    cp -r "$WEBAPP_SRC/"* "$DEPLOY_DIR/"
    echo "✓"
fi

# Copy JARs from jars/ directory (preferred) or lib/
if ls "$BMA_ROOT/jars/"*.jar &>/dev/null; then
    cp "$BMA_ROOT/jars/"*.jar "$DEPLOY_DIR/WEB-INF/lib/"
    echo "[*] JARs copied from jars/ to WEB-INF/lib/"
elif ls "$BMA_ROOT/lib/"*.jar &>/dev/null; then
    cp "$BMA_ROOT/lib/"*.jar "$DEPLOY_DIR/WEB-INF/lib/"
    echo "[*] JARs copied from lib/ to WEB-INF/lib/"
fi

# Ensure db.properties exists — use .nwe-credentials or prompt if interactive
DB_PROPS="$DEPLOY_DIR/WEB-INF/db.properties"
if [ ! -f "$DB_PROPS" ] || ! grep -q "db.password=." "$DB_PROPS" 2>/dev/null || grep -q "CHANGE_ME" "$DB_PROPS" 2>/dev/null; then
    # Try .nwe-credentials first (non-interactive safe)
    NWE_ROOT="$(cd "$SCRIPT_DIR/../../../.." 2>/dev/null && pwd)"
    if [ -f "$NWE_ROOT/.nwe-credentials" ]; then
        source "$NWE_ROOT/.nwe-credentials"
        mkdir -p "$DEPLOY_DIR/WEB-INF"
        cat > "$DB_PROPS" <<EOF
# BMA Database Configuration — auto-generated from .nwe-credentials
db.driver=com.mysql.cj.jdbc.Driver
db.url=jdbc:mysql://${NWE_DB_HOST:-127.0.0.1}:${NWE_DB_PORT:-3306}/BrarnerScience
db.user=${NWE_DB_USER:-root}
db.password=${NWE_DB_PASS}
EOF
        chmod 600 "$DB_PROPS"
        echo "[*] db.properties generated from .nwe-credentials"
    elif [ -t 0 ]; then
        # Interactive terminal — prompt for credentials
        echo ""
        echo "[*] db.properties needs MySQL credentials for JSP pages."
        read -rp "    MySQL user [root]: " DB_USER
        DB_USER="${DB_USER:-root}"
        read -rsp "    MySQL password: " DB_PASS
        echo ""
        read -rp "    MySQL host [localhost]: " DB_HOST
        DB_HOST="${DB_HOST:-localhost}"
        read -rp "    MySQL port [3306]: " DB_PORT
        DB_PORT="${DB_PORT:-3306}"
        mkdir -p "$DEPLOY_DIR/WEB-INF"
        cat > "$DB_PROPS" <<EOF
# BMA Database Configuration — written by deploy-local.sh
db.driver=com.mysql.cj.jdbc.Driver
db.url=jdbc:mysql://${DB_HOST}:${DB_PORT}/BrarnerScience
db.user=${DB_USER}
db.password=${DB_PASS}
EOF
        chmod 600 "$DB_PROPS"
        echo "[*] db.properties written"
    else
        # Non-interactive and no credentials file — skip (don't hang)
        echo "[!] db.properties missing and no .nwe-credentials found (non-interactive)"
        echo "    JSP database pages will fail. Create .nwe-credentials and redeploy."
    fi
else
    echo "[*] db.properties present (user=$(grep '^db.user=' "$DB_PROPS" | cut -d= -f2-))"
fi

# Compile servlets if javac available and sources exist
SERVLET_SRC="$BMA_ROOT/servlets/servlet/src/main/java"
if [ -d "$SERVLET_SRC" ] && command -v javac &>/dev/null; then
    echo "[*] Compiling servlet classes..."
    find "$SERVLET_SRC" -name "*.java" > /tmp/bma-sources.txt
    if [ -s /tmp/bma-sources.txt ]; then
        CP="$DEPLOY_DIR/WEB-INF/lib/*"
        javac -d "$DEPLOY_DIR/WEB-INF/classes" -cp "$CP" @/tmp/bma-sources.txt 2>/dev/null && \
            echo "[*] Servlets compiled" || \
            echo "[!] Servlet compilation failed (JSP pages still work without servlets)"
        rm -f /tmp/bma-sources.txt
    fi
fi

# Fix ownership
chown -R tomcat:tomcat "$DEPLOY_DIR" 2>/dev/null || true

# Deploy legal data to webapp data directory (for direct JSP access if needed)
LEGAL_SAFE="$BMA_ROOT/data/legal/safe"
if [ -d "$LEGAL_SAFE" ]; then
    mkdir -p "$DEPLOY_DIR/data/legal"
    cp "$LEGAL_SAFE"/*.csv "$DEPLOY_DIR/data/legal/" 2>/dev/null || true
    cp "$LEGAL_SAFE"/*.rdns "$DEPLOY_DIR/data/legal/" 2>/dev/null || true
    cp "$LEGAL_SAFE"/*.txt "$DEPLOY_DIR/data/legal/" 2>/dev/null || true
    chmod 444 "$DEPLOY_DIR/data/legal/"* 2>/dev/null || true
    echo "[*] Legal data deployed to $DEPLOY_DIR/data/legal/ (read-only)"
else
    echo "[!] Legal safe data not found — run: bash data/legal/download-legal-data.sh && bash data/legal/unzip-and-consume.sh"
fi

# Deploy smartphone edition
SMARTPHONE_SRC="$BMA_ROOT/smartphone"
if [ -d "$SMARTPHONE_SRC" ]; then
    rm -rf "$DEPLOY_DIR/smartphone"
    cp -r "$SMARTPHONE_SRC" "$DEPLOY_DIR/smartphone/"
    echo "[*] Smartphone edition deployed to $DEPLOY_DIR/smartphone/"
else
    echo "[!] Smartphone edition not found at $SMARTPHONE_SRC"
fi

# Create www and web symlinks in BMA project root → canonical deploy dir
ln -sfn "$DEPLOY_DIR" "$BMA_ROOT/www"
ln -sfn "$DEPLOY_DIR" "$BMA_ROOT/web"
echo "[*] Symlinks: www → $DEPLOY_DIR, web → $DEPLOY_DIR"

echo ""
echo "[✓] Deployed to: $DEPLOY_DIR"
echo ""
JSP_LIST=$(find "$WEBAPP_SRC" -maxdepth 1 -name "*.jsp" -printf "%f " 2>/dev/null | sort)
echo "    JSP:  ${JSP_LIST}"
echo "    DB:   WEB-INF/db.properties"
echo "    URL:  http://localhost:8080/$CONTEXT/"
echo ""

# ─── Backend note (deploy does NOT start backends — use start-all.sh) ────────
NWE_ROOT="$(cd "$BMA_ROOT/../../../.." 2>/dev/null && pwd)"
PID_FILE="$NWE_ROOT/data/nwe-main.pid"

if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    echo "[*] Backend already running (PID $(cat "$PID_FILE"))"
else
    echo "[*] Backend not running. Start separately with:"
    echo "    bash scripts/start-all.sh"
    echo "    — or —"
    echo "    bash scripts/start-backend-modules.sh"
fi

echo ""
echo "═══════════════════════════════════════════════════════════════"
