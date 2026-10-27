#!/bin/bash
# ════════════════════════════════════════════════════════════════════════════════
# NitroWebExpress™ — Shutdown All Frontend Modules
# Undeploys all module webapps from Tomcat.
# Usage: bash scripts/shutdown-frontends.sh [tomcat_home] [--stop-tomcat]
# ════════════════════════════════════════════════════════════════════════════════
set -uo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

resolve_tomcat_home() {
    local requested="${1:-${CATALINA_HOME:-}}"
    if [ -n "$requested" ] && [ -d "$requested/webapps" ]; then
        printf '%s\n' "$requested"
        return 0
    fi

    if uname -s | grep -qi 'darwin'; then
        for candidate in \
            "/opt/homebrew/opt/tomcat/libexec" \
            "/usr/local/opt/tomcat/libexec" \
            "/Applications/Tomcat/apache-tomcat-11.0.2"; do
            if [ -d "$candidate/webapps" ]; then
                printf '%s\n' "$candidate"
                return 0
            fi
        done
    else
        for candidate in \
            "/opt/apache-tomcat-11.0.2" \
            "/opt/tomcat" \
            "/var/lib/tomcat9" \
            "/usr/share/tomcat"; do
            if [ -d "$candidate/webapps" ]; then
                printf '%s\n' "$candidate"
                return 0
            fi
        done
    fi

    printf '%s\n' "${requested:-${CATALINA_HOME:-/opt/apache-tomcat-11.0.2}}"
}

TOMCAT_HOME="$(resolve_tomcat_home "${1:-}")"
source "$PROJECT_ROOT/scripts/print-descriptor.sh" 2>/dev/null || true
STOP_TOMCAT=false

# Check for --stop-tomcat flag
for arg in "$@"; do
    if [ "$arg" = "--stop-tomcat" ]; then
        STOP_TOMCAT=true
    fi
done

MODULES=(
    "AE6E66:ae6e66"
    "black-belt:blackbelt"
    "cia:california-cia"
    "duke:california-duke"
    "fbi:california-fbi"
    "gray:gray-registry"
    "gray.a85:gray85-registry"
    "Green.Durham.Grass.and.Herb:gdgh"
    "languages:languages"
    "library:library"
    "nsa:california-nsa"
)

FUTURES_SHUTDOWN="red/Futures/shutdown-frontend.sh"

echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║  NitroWebExpress™ — Shutdown All Frontend Modules                      ║"
echo "║  Tomcat: $TOMCAT_HOME                                                 ║"
if [ "$STOP_TOMCAT" = true ]; then
    echo "║  Will STOP Tomcat after undeploying modules                            ║"
fi
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo ""

SUCCESS=()
FAILED=()

# Undeploy standard modules
for MODULE_SPEC in "${MODULES[@]}"; do
    IFS=':' read -r MOD_DIR CONTEXT <<< "$MODULE_SPEC"
    MOD_PATH="$PROJECT_ROOT/modules/$MOD_DIR"

    if [ ! -d "$MOD_PATH" ]; then
        continue
    fi

    if [ ! -f "$MOD_PATH/shutdown.sh" ]; then
        continue
    fi

    echo -n "  [*] Undeploying $MOD_DIR ($CONTEXT)... "

    if cd "$MOD_PATH" && bash shutdown.sh "$TOMCAT_HOME" > /dev/null 2>&1; then
        echo "✓"
        SUCCESS+=("$MOD_DIR:$CONTEXT")
    else
        echo "✗"
        FAILED+=("$MOD_DIR:$CONTEXT")
    fi
done

# Undeploy Futures frontend (special convention: -frontend)
if [ -f "$PROJECT_ROOT/modules/$FUTURES_SHUTDOWN" ]; then
    echo -n "  [*] Undeploying Futures (frontend)... "
    if cd "$PROJECT_ROOT/modules/red/Futures" && bash shutdown-frontend.sh "$TOMCAT_HOME" > /dev/null 2>&1; then
        echo "✓"
        SUCCESS+=("Futures:frontend")
    else
        echo "✗"
        FAILED+=("Futures:frontend")
    fi
fi

echo ""

# Optionally stop Tomcat
if [ "$STOP_TOMCAT" = true ]; then
    echo "  [*] Stopping Tomcat..."
    if [ -x "$TOMCAT_HOME/bin/shutdown.sh" ]; then
        "$TOMCAT_HOME/bin/shutdown.sh" > /dev/null 2>&1 || true
        sleep 2
        echo "  [✓] Tomcat stopped"
    elif uname -s | grep -qi 'darwin'; then
        if command -v brew >/dev/null 2>&1; then
            brew services stop tomcat 2>/dev/null || true
            sleep 2
            echo "  [✓] Tomcat stopped"
        else
            echo "  [!] Tomcat stop script unavailable on this host"
        fi
    elif command -v systemctl >/dev/null 2>&1; then
        sudo systemctl stop tomcat 2>/dev/null || true
        sleep 2
        echo "  [✓] Tomcat stopped"
    else
        echo "  [!] Tomcat stop script unavailable on this host"
    fi
fi

echo ""
echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║  Frontend Shutdown Summary                                            ║"
echo "║  Undeployed: ${#SUCCESS[@]} / $(( ${#MODULES[@]} + 1 ))                  ║"
if [ ${#FAILED[@]} -gt 0 ]; then
    echo "║  Failed:     ${#FAILED[@]}                                            ║"
fi
echo "╚═══════════════════════════════════════════════════════════════════════════╝"

[ ${#FAILED[@]} -eq 0 ]




























































































































