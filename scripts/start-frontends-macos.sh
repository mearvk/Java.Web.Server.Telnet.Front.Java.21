#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# NitroWebExpress™ — Start Frontend Modules (macOS)
# Deploys webapps to Tomcat and starts Tomcat via brew services.
# Usage: bash scripts/start-frontends-macos.sh [tomcat_home]
# ═══════════════════════════════════════════════════════════════════════════════
set -uo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# macOS sed
if command -v gsed &>/dev/null; then SED="gsed"; else SED="sed"; fi

# ── Resolve TOMCAT_HOME ───────────────────────────────────────────────────────
TOMCAT_HOME="${1:-}"
NWE_CONFIG="$PROJECT_ROOT/configuration/nwe-config.xml"

if [ -z "$TOMCAT_HOME" ]; then
    if [ -f "$NWE_CONFIG" ]; then
        TOMCAT_HOME=$($SED -n '/<tomcat>/,/<\/tomcat>/p' "$NWE_CONFIG" | grep -o '<install-dir>[^<]*</install-dir>' | $SED 's/<[^>]*>//g' 2>/dev/null)
    fi
fi
if [ -z "$TOMCAT_HOME" ] || [ ! -d "$TOMCAT_HOME/webapps" ]; then
    if command -v brew &>/dev/null && brew list tomcat &>/dev/null 2>&1; then
        TOMCAT_HOME="$(brew --prefix tomcat)/libexec"
    elif [ -d "/opt/homebrew/opt/tomcat/libexec/webapps" ]; then
        TOMCAT_HOME="/opt/homebrew/opt/tomcat/libexec"
    elif [ -d "/usr/local/opt/tomcat/libexec/webapps" ]; then
        TOMCAT_HOME="/usr/local/opt/tomcat/libexec"
    fi
fi
TOMCAT_HOME="${TOMCAT_HOME:-${CATALINA_HOME:-/opt/homebrew/opt/tomcat/libexec}}"

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo " NitroWebExpress™ — Start Frontend Modules (macOS)"
echo " Tomcat: $TOMCAT_HOME"
echo "═══════════════════════════════════════════════════════════════"
echo ""

if [ ! -d "$TOMCAT_HOME/webapps" ]; then
    echo "[FAIL] Tomcat not found at $TOMCAT_HOME"
    echo "       Install: brew install tomcat"
    exit 1
fi

# ── Deploy modules ────────────────────────────────────────────────────────────
echo "[*] Deploying webapps..."
PASS=0; FAIL=0

DEPLOY_SCRIPTS=(
    "modules/black/presidential/Brarner.M.Alete/install/deploy-local.sh"
    "modules/AE6E66/servlets/deploy-local.sh"
    "modules/red/Futures/servlets/deploy-local.sh"
    "modules/Green.Durham.Grass.and.Herb/servlets/deploy-local.sh"
    "modules/black-belt/servlets/deploy-local.sh"
    "modules/gray/servlets/deploy-local.sh"
    "modules/gray.a85/servlets/deploy-local.sh"
    "modules/languages/servlets/deploy-local.sh"
    "modules/fbi/servlets/deploy-local.sh"
    "modules/cia/servlets/deploy-local.sh"
    "modules/nsa/servlets/deploy-local.sh"
    "modules/duke/servlets/deploy-local.sh"
    "modules/library/servlets/deploy-local.sh"
    "source/strernary/servlets/deploy-local.sh"
)

for SCRIPT in "${DEPLOY_SCRIPTS[@]}"; do
    FULL_PATH="$PROJECT_ROOT/$SCRIPT"
    if [ -f "$FULL_PATH" ]; then
        bash "$FULL_PATH" "$TOMCAT_HOME" 2>/dev/null && PASS=$((PASS + 1)) || FAIL=$((FAIL + 1))
    fi
done
echo "[OK] Deployed: $PASS | Failed: $FAIL"

# ── Start Tomcat ──────────────────────────────────────────────────────────────
echo ""
echo "[*] Starting Tomcat..."
brew services start tomcat 2>/dev/null || {
    [ -x "$TOMCAT_HOME/bin/startup.sh" ] && "$TOMCAT_HOME/bin/startup.sh" 2>/dev/null
}
echo "[OK] Tomcat started. http://localhost:8080/"
echo ""
