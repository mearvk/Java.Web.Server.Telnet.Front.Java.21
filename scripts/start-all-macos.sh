#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# NitroWebExpress™ — Start All Services (macOS)
# Sequence: MySQL → Compile → Backends → Frontends
# Usage: bash scripts/start-all-macos.sh
# ═══════════════════════════════════════════════════════════════════════════════
set -uo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# macOS sed compatibility
if command -v gsed &>/dev/null; then SED="gsed"; else SED="sed"; fi

# ── Resolve TOMCAT_HOME ───────────────────────────────────────────────────────
NWE_CONFIG="$PROJECT_ROOT/configuration/nwe-config.xml"
TOMCAT_HOME=""
if [ -f "$NWE_CONFIG" ]; then
    TOMCAT_HOME=$($SED -n '/<tomcat>/,/<\/tomcat>/p' "$NWE_CONFIG" | grep -o '<install-dir>[^<]*</install-dir>' | $SED 's/<[^>]*>//g' 2>/dev/null)
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
export JAVA_HOME="${JAVA_HOME:-$(/usr/libexec/java_home -v 21 2>/dev/null || echo /opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home)}"

echo ""
echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║                                                                           ║"
echo "║   NitroWebExpress™ — Complete System Startup (macOS)                      ║"
echo "║   Sequence: MySQL → Compile → Backends → Frontends                        ║"
echo "║                                                                           ║"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo ""

# ── Phase 0: Stop existing ────────────────────────────────────────────────────
echo "───────────────────────────────────────────────────────────────────────────────"
echo "Pre-flight: Checking for running services..."
echo "───────────────────────────────────────────────────────────────────────────────"
echo ""

NEED_STOP=0
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/ 2>/dev/null | grep -q "200\|302"; then
    echo "  [*] Tomcat is running — will stop before redeploy"
    NEED_STOP=1
fi
if [ -f "$PROJECT_ROOT/data/nwe-main.pid" ] && kill -0 "$(cat "$PROJECT_ROOT/data/nwe-main.pid" 2>/dev/null)" 2>/dev/null; then
    echo "  [*] NWE Main running — will stop"
    NEED_STOP=1
fi

if [ "$NEED_STOP" -eq 1 ]; then
    echo "  [*] Stopping existing services..."
    [ -f "$PROJECT_ROOT/scripts/shutdown-all-macos.sh" ] && bash "$PROJECT_ROOT/scripts/shutdown-all-macos.sh" 2>/dev/null || true
    sleep 3
    echo "  [OK] Existing services stopped"
else
    echo "  [OK] No running services — clean start"
fi

# ── Phase 1: MySQL ────────────────────────────────────────────────────────────
echo ""
echo "───────────────────────────────────────────────────────────────────────────────"
echo "Phase 1/4: Starting MySQL..."
echo "───────────────────────────────────────────────────────────────────────────────"
echo ""

brew services start mysql 2>/dev/null || true
sleep 2
if mysqladmin ping --silent 2>/dev/null; then
    echo "  [OK] MySQL is running"
else
    echo "  [!] MySQL may not be running — continuing"
fi

# ── Phase 2: Compile ──────────────────────────────────────────────────────────
echo ""
echo "───────────────────────────────────────────────────────────────────────────────"
echo "Phase 2/4: Compiling All Modules..."
echo "───────────────────────────────────────────────────────────────────────────────"
echo ""

if [ -f "$PROJECT_ROOT/scripts/compile-all-modules.sh" ]; then
    bash "$PROJECT_ROOT/scripts/compile-all-modules.sh"
    echo "  [OK] Compilation complete"
else
    echo "  [!] Compile script not found"
fi

# ── Phase 3: Backends ─────────────────────────────────────────────────────────
echo ""
echo "───────────────────────────────────────────────────────────────────────────────"
echo "Phase 3/4: Starting Backend Modules..."
echo "───────────────────────────────────────────────────────────────────────────────"
echo ""

if [ -f "$PROJECT_ROOT/scripts/start-backends.sh" ]; then
    bash "$PROJECT_ROOT/scripts/start-backends.sh"
    echo "  [OK] Backend startup complete"
else
    echo "  [!] Backend start script not found"
fi
sleep 3

# ── Phase 4: Frontends ────────────────────────────────────────────────────────
echo ""
echo "───────────────────────────────────────────────────────────────────────────────"
echo "Phase 4/4: Starting Frontend Modules..."
echo "───────────────────────────────────────────────────────────────────────────────"
echo ""

# Deploy webapps
if [ -f "$PROJECT_ROOT/scripts/start-frontends.sh" ]; then
    bash "$PROJECT_ROOT/scripts/start-frontends.sh" "$TOMCAT_HOME"
fi

# Start Tomcat via brew
brew services start tomcat 2>/dev/null || {
    [ -x "$TOMCAT_HOME/bin/startup.sh" ] && "$TOMCAT_HOME/bin/startup.sh" 2>/dev/null
}
echo "  [OK] Tomcat started"

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║                                                                           ║"
echo "║   ✓ NitroWebExpress™ System Startup Complete! (macOS)                     ║"
echo "║                                                                           ║"
echo "║   Verify:   bash scripts/status-macos.sh                                  ║"
echo "║   Shutdown:  bash scripts/shutdown-all-macos.sh                            ║"
echo "║   Tomcat:    $TOMCAT_HOME"
echo "║                                                                           ║"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo ""
