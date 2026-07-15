#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# NitroWebExpress™ — Deploy All Web Modules (macOS)
# Reads configuration from nwe-config.xml and web-deploy-config.xml.
# Usage: bash scripts/web/deploy-all-macos.sh
# ═══════════════════════════════════════════════════════════════════════════════
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
CONFIG="$SCRIPT_DIR/web-deploy-config.xml"
NWE_CONFIG="$PROJECT_ROOT/configuration/nwe-config.xml"

# macOS sed compatibility
if command -v gsed &>/dev/null; then SED="gsed"; else SED="sed"; fi
sed_inplace() { if command -v gsed &>/dev/null; then gsed -i "$@"; else sed -i '' "$@"; fi; }

# ── Resolve TOMCAT_HOME ───────────────────────────────────────────────────────
TOMCAT_HOME=""

# Priority 1: nwe-config.xml
if [ -f "$NWE_CONFIG" ]; then
    TOMCAT_HOME=$($SED -n '/<tomcat>/,/<\/tomcat>/p' "$NWE_CONFIG" | grep -o '<install-dir>[^<]*</install-dir>' | $SED 's/<[^>]*>//g' 2>/dev/null)
    TOMCAT_VERSION=$($SED -n '/<tomcat>/,/<\/tomcat>/p' "$NWE_CONFIG" | grep -o '<version>[^<]*</version>' | $SED 's/<[^>]*>//g' 2>/dev/null)
fi

# Priority 2: brew detection
if [ -z "$TOMCAT_HOME" ] || [ ! -d "$TOMCAT_HOME/webapps" ]; then
    if command -v brew &>/dev/null && brew list tomcat &>/dev/null 2>&1; then
        TOMCAT_HOME="$(brew --prefix tomcat)/libexec"
    fi
fi

# Priority 3: Standard Homebrew paths
if [ -z "$TOMCAT_HOME" ] || [ ! -d "$TOMCAT_HOME/webapps" ]; then
    if [ -d "/opt/homebrew/opt/tomcat/libexec/webapps" ]; then
        TOMCAT_HOME="/opt/homebrew/opt/tomcat/libexec"
    elif [ -d "/usr/local/opt/tomcat/libexec/webapps" ]; then
        TOMCAT_HOME="/usr/local/opt/tomcat/libexec"
    fi
fi

# Priority 4: CATALINA_HOME
if [ -z "$TOMCAT_HOME" ] || [ ! -d "$TOMCAT_HOME/webapps" ]; then
    TOMCAT_HOME="${CATALINA_HOME:-/opt/homebrew/opt/tomcat/libexec}"
fi

TOMCAT_VERSION="${TOMCAT_VERSION:-11.0.2}"

echo "═══════════════════════════════════════════════════════════════"
echo " NitroWebExpress™ — Deploy All Web Modules (macOS)"
echo " Tomcat ${TOMCAT_VERSION}: $TOMCAT_HOME"
echo "═══════════════════════════════════════════════════════════════"
echo ""

if [ ! -f "$CONFIG" ]; then echo "[FAIL] Config not found: $CONFIG"; exit 1; fi
if [ ! -d "$TOMCAT_HOME/webapps" ]; then
    echo "[FAIL] Tomcat not found. Install: brew install tomcat"
    exit 1
fi

# ── Setup databases ───────────────────────────────────────────────────────────
echo "[*] Setting up module databases..."
[ -f "$PROJECT_ROOT/scripts/web/setup-all-databases.sh" ] && bash "$PROJECT_ROOT/scripts/web/setup-all-databases.sh" 2>/dev/null || true

# ── Deploy modules ────────────────────────────────────────────────────────────
echo ""
# Extract deploy scripts from config (macOS compatible grep)
ENABLED=$($SED -n 's/.*<deploy-script>\(.*\)<\/deploy-script>.*/\1/p' "$CONFIG")

PASS=0; FAIL=0
for SCRIPT in $ENABLED; do
    FULL_PATH="$PROJECT_ROOT/$SCRIPT"
    SETUP_DB="$(dirname "$FULL_PATH")/setup-db.sh"
    [ -f "$SETUP_DB" ] && bash "$SETUP_DB" 2>/dev/null || true
    if [ -f "$FULL_PATH" ]; then
        echo "[*] Deploying: $SCRIPT"
        bash "$FULL_PATH" "$TOMCAT_HOME" 2>&1 | tail -2 && PASS=$((PASS + 1)) || FAIL=$((FAIL + 1))
    else
        echo "[--] Not found: $SCRIPT"; FAIL=$((FAIL + 1))
    fi
done

# ── Sync config ───────────────────────────────────────────────────────────────
sed_inplace "s|<tomcat-home>[^<]*</tomcat-home>|<tomcat-home>${TOMCAT_HOME}</tomcat-home>|" "$CONFIG"

# ── Start Tomcat ──────────────────────────────────────────────────────────────
echo ""
if command -v brew &>/dev/null; then
    brew services start tomcat 2>/dev/null || true
    echo "[OK] Tomcat started via brew services"
elif [ -x "$TOMCAT_HOME/bin/catalina.sh" ]; then
    "$TOMCAT_HOME/bin/startup.sh" 2>/dev/null
    echo "[OK] Tomcat started via startup.sh"
fi

# ── Start backends ────────────────────────────────────────────────────────────
echo ""
echo "[*] Ensuring backend modules are running..."
BACKEND_SCRIPT="$PROJECT_ROOT/scripts/start-backends.sh"
PID_FILE="$PROJECT_ROOT/data/nwe-main.pid"

if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    echo "    Backend already running (PID $(cat "$PID_FILE"))"
else
    if [ -f "$BACKEND_SCRIPT" ]; then
        bash "$BACKEND_SCRIPT" &
        sleep 8
        if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
            echo "    [OK] Backend started (PID $(cat "$PID_FILE"))"
        else
            echo "    [!] Backend may have failed — check: $PROJECT_ROOT/logging/nwe-main.log"
        fi
    fi
fi

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo " Results: $PASS deployed | $FAIL failed"
echo " Tomcat: $TOMCAT_HOME"
echo " URL: http://localhost:8080/"
echo "═══════════════════════════════════════════════════════════════"
