#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# NitroWebExpress™ — Start All Frontend Modules
# Deploys all module webapps to Tomcat and verifies HTTP endpoints.
# Skips modules already deployed (fast re-run after git pull).
# Usage: bash scripts/start-frontends.sh [tomcat_home]
# ═══════════════════════════════════════════════════════════════════════════════
set -uo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TOMCAT_HOME="${1:-${CATALINA_HOME:-/opt/apache-tomcat-11.0.2}}"

source "$PROJECT_ROOT/scripts/print-descriptor.sh" 2>/dev/null || true

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

echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║  NitroWebExpress™ — Start All Frontend Modules                          ║"
echo "║  Tomcat:  $TOMCAT_HOME                                                  ║"
echo "║  Modules: ${#MODULES[@]}                                                         ║"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo ""

# ── Validate Tomcat ───────────────────────────────────────────────────────────
if [ ! -d "$TOMCAT_HOME/webapps" ]; then
    echo "  [ERROR] Tomcat not found at: $TOMCAT_HOME"
    echo "          Set CATALINA_HOME or pass as argument."
    exit 1
fi

# ── Start Tomcat (once) ───────────────────────────────────────────────────────
echo -n "  [*] Tomcat: "
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/ 2>/dev/null | grep -q "200\|302\|401\|403"; then
    echo "already running"
else
    echo -n "starting... "
    if [ -x "$TOMCAT_HOME/bin/startup.sh" ]; then
        "$TOMCAT_HOME/bin/startup.sh" > /dev/null 2>&1
    else
        sudo systemctl start tomcat 2>/dev/null || true
    fi
    sleep 3
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/ 2>/dev/null | grep -q "200\|302\|401\|403"; then
        echo "up"
    else
        echo "waiting..."
        sleep 5
    fi
fi
echo ""

# ── Check which modules are already deployed ─────────────────────────────────
echo "  [*] Checking deployed webapps..."
DEPLOYED=()
MISSING=()
for MODULE_SPEC in "${MODULES[@]}"; do
    IFS=':' read -r MOD_DIR CONTEXT <<< "$MODULE_SPEC"
    if [ -d "$TOMCAT_HOME/webapps/$CONTEXT" ] && [ -f "$TOMCAT_HOME/webapps/$CONTEXT/WEB-INF/web.xml" ]; then
        DEPLOYED+=("$MOD_DIR:$CONTEXT")
    else
        MISSING+=("$MOD_DIR:$CONTEXT")
    fi
done

# Check Futures
if [ -d "$TOMCAT_HOME/webapps/futures" ] && [ -f "$TOMCAT_HOME/webapps/futures/WEB-INF/web.xml" ]; then
    DEPLOYED+=("Futures:futures")
else
    MISSING+=("Futures:futures")
fi

echo "      Already deployed: ${#DEPLOYED[@]}"
echo "      Need deployment:  ${#MISSING[@]}"
echo ""

# ── Deploy only missing modules ──────────────────────────────────────────────
SUCCESS=()
FAILED=()

if [ ${#MISSING[@]} -eq 0 ]; then
    echo "  [✓] All modules already deployed — nothing to do"
    SUCCESS=("${DEPLOYED[@]}")
else
    echo "  [*] Deploying ${#MISSING[@]} module(s)..."
    echo ""

    for MODULE_SPEC in "${MISSING[@]}"; do
        IFS=':' read -r MOD_DIR CONTEXT <<< "$MODULE_SPEC"

        # Find the deploy script
        DEPLOY_SCRIPT=""
        if [ "$MOD_DIR" = "Futures" ]; then
            DEPLOY_SCRIPT="$PROJECT_ROOT/modules/red/Futures/servlets/deploy-local.sh"
        elif [ -f "$PROJECT_ROOT/modules/$MOD_DIR/servlets/deploy-local.sh" ]; then
            DEPLOY_SCRIPT="$PROJECT_ROOT/modules/$MOD_DIR/servlets/deploy-local.sh"
        fi

        if [ -z "$DEPLOY_SCRIPT" ] || [ ! -f "$DEPLOY_SCRIPT" ]; then
            echo "  [SKIP] $MOD_DIR — no deploy-local.sh found"
            continue
        fi

        echo -n "  [*] Deploying $MOD_DIR ($CONTEXT)... "
        if bash "$DEPLOY_SCRIPT" "$TOMCAT_HOME" > /dev/null 2>&1; then
            echo "✓"
            SUCCESS+=("$MOD_DIR:$CONTEXT")
        else
            echo "✗"
            FAILED+=("$MOD_DIR:$CONTEXT")
        fi
    done

    # Count already-deployed as successes too
    for SPEC in "${DEPLOYED[@]}"; do
        SUCCESS+=("$SPEC")
    done
fi

# ── Quick stabilization (only if we deployed something) ──────────────────────
if [ ${#MISSING[@]} -gt 0 ]; then
    echo ""
    echo "  [*] Waiting for webapps to stabilize (3s)..."
    sleep 3
fi

# ── Force Tomcat to reload all contexts if any show 404 ──────────────────────
echo ""
echo "  [*] Checking Tomcat webapp loading..."
NEEDS_RELOAD=0
for MODULE_SPEC in "${MODULES[@]}"; do
    IFS=':' read -r MOD_DIR CONTEXT <<< "$MODULE_SPEC"
    HC=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 2 "http://localhost:8080/$CONTEXT/" 2>/dev/null || echo "000")
    if [ "$HC" = "404" ] || [ "$HC" = "000" ]; then
        NEEDS_RELOAD=1
        break
    fi
done

if [ "$NEEDS_RELOAD" -eq 1 ]; then
    echo "  [*] Some webapps returning 404 — restarting Tomcat to force reload..."
    if [ -x "$TOMCAT_HOME/bin/shutdown.sh" ]; then
        "$TOMCAT_HOME/bin/shutdown.sh" >/dev/null 2>&1 || true
        sleep 3
        "$TOMCAT_HOME/bin/startup.sh" >/dev/null 2>&1
    else
        sudo systemctl restart tomcat 2>/dev/null || true
    fi
    echo "  [*] Waiting for Tomcat to load webapps (8s)..."
    sleep 8
else
    echo "  [✓] All webapps loaded — no restart needed"
fi

# ── Verify HTTP endpoints ─────────────────────────────────────────────────────
echo ""
echo "  [*] Verifying HTTP endpoints..."
echo ""

for MODULE_SPEC in "${MODULES[@]}"; do
    IFS=':' read -r MOD_DIR CONTEXT <<< "$MODULE_SPEC"
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 2 "http://localhost:8080/$CONTEXT/" 2>/dev/null || echo "000")

    if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "302" ]; then
        echo "  [✓] /$CONTEXT (HTTP $HTTP_CODE)"
    else
        echo "  [--] /$CONTEXT (HTTP $HTTP_CODE)"
    fi
done

# Futures
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 2 "http://localhost:8080/futures/" 2>/dev/null || echo "000")
if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "302" ]; then
    echo "  [✓] /futures (HTTP $HTTP_CODE)"
else
    echo "  [--] /futures (HTTP $HTTP_CODE)"
fi

# ── Summary ───────────────────────────────────────────────────────────────────
TOTAL=$(( ${#MODULES[@]} + 1 ))
echo ""
echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║  Frontend Deployment Summary                                            ║"
echo "║  Deployed: ${#SUCCESS[@]} / $TOTAL                                                      ║"
if [ ${#FAILED[@]} -gt 0 ]; then
    echo "║  Failed:   ${#FAILED[@]}                                                       ║"
fi
if [ ${#MISSING[@]} -eq 0 ]; then
    echo "║  Status:   All already deployed (fast path)                             ║"
fi
echo "║  Tomcat:   http://localhost:8080                                        ║"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"

[ ${#FAILED[@]} -eq 0 ]
