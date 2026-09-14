#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# NitroWebExpress™ — Shutdown Frontend Modules (macOS)
# Stops Tomcat and removes deployed webapps.
# Usage: bash scripts/shutdown-frontends-macos.sh
# ═══════════════════════════════════════════════════════════════════════════════

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# macOS sed
if command -v gsed &>/dev/null; then SED="gsed"; else SED="sed"; fi

# Resolve TOMCAT_HOME
TOMCAT_HOME=""
NWE_CONFIG="$PROJECT_ROOT/configuration/nwe-config.xml"
if [ -f "$NWE_CONFIG" ]; then
    TOMCAT_HOME=$($SED -n '/<tomcat>/,/<\/tomcat>/p' "$NWE_CONFIG" | grep -o '<install-dir>[^<]*</install-dir>' | $SED 's/<[^>]*>//g' 2>/dev/null)
fi
if [ -z "$TOMCAT_HOME" ] || [ ! -d "$TOMCAT_HOME/webapps" ]; then
    if command -v brew &>/dev/null && brew list tomcat &>/dev/null 2>&1; then
        TOMCAT_HOME="$(brew --prefix tomcat)/libexec"
    elif [ -d "/opt/homebrew/opt/tomcat/libexec" ]; then
        TOMCAT_HOME="/opt/homebrew/opt/tomcat/libexec"
    elif [ -d "/usr/local/opt/tomcat/libexec" ]; then
        TOMCAT_HOME="/usr/local/opt/tomcat/libexec"
    fi
fi

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo " NitroWebExpress™ — Shutdown Frontend Modules (macOS)"
echo " Tomcat: ${TOMCAT_HOME:-unknown}"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# ── Stop Tomcat ───────────────────────────────────────────────────────────────
echo "[*] Stopping Tomcat..."
brew services stop tomcat 2>/dev/null && echo "[OK] Tomcat stopped via brew" || {
    if [ -n "$TOMCAT_HOME" ] && [ -x "$TOMCAT_HOME/bin/shutdown.sh" ]; then
        "$TOMCAT_HOME/bin/shutdown.sh" 2>/dev/null
        echo "[OK] Tomcat stopped via shutdown.sh"
    else
        echo "[--] Tomcat not running or not found"
    fi
}

# ── Undeploy webapps ──────────────────────────────────────────────────────────
if [ -n "$TOMCAT_HOME" ] && [ -d "$TOMCAT_HOME/webapps" ]; then
    echo ""
    echo "[*] Removing deployed webapps..."
    for CONTEXT in ae6e66 blackbelt california-cia california-duke california-fbi gray-registry gray85-registry gdgh languages library california-nsa futures brarner.m.alete strernary; do
        if [ -d "$TOMCAT_HOME/webapps/$CONTEXT" ]; then
            rm -rf "$TOMCAT_HOME/webapps/$CONTEXT"
            echo "  [OK] Removed /$CONTEXT"
        fi
    done
fi

echo ""
echo "[OK] Frontend shutdown complete"
