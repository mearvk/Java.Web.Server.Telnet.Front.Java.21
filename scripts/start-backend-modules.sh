#!/bin/bash
# NitroWebExpress™ — Start All Backend Modules
# Launches all TCP server modules as background processes.
# Usage: bash scripts/start-backend-modules.sh
# Stop:  bash scripts/start-backend-modules.sh --stop
set -uo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$PROJECT_ROOT/out"
JARS="$PROJECT_ROOT/jars"
CP="$OUT:$JARS/mysql/mysql-connector-j-9.7.0.jar:$JARS/lanterna-3.1.5.jar"
DJL_CP=$(find "$JARS/djl" -name "*.jar" 2>/dev/null | tr '\n' ':')
CP="$CP:${DJL_CP}"
LOG_DIR="$PROJECT_ROOT/logging"
PID_DIR="$PROJECT_ROOT/data/pids"
JVM_OPTS="-Xms256m -Xmx1024m -XX:+UseZGC"

mkdir -p "$LOG_DIR" "$PID_DIR"

# ── Stop mode ────────────────────────────────────────────────────────────────
if [[ "${1:-}" == "--stop" ]]; then
    echo "[*] Stopping all NWE backend modules..."
    for PID_FILE in "$PID_DIR"/*.pid; do
        [ -f "$PID_FILE" ] || continue
        PID=$(cat "$PID_FILE")
        NAME=$(basename "$PID_FILE" .pid)
        if kill -0 "$PID" 2>/dev/null; then
            kill "$PID" 2>/dev/null
            echo "  [STOP] $NAME (PID $PID)"
        fi
        rm -f "$PID_FILE"
    done
    echo "[OK] All modules stopped."
    exit 0
fi

# ── Start function ────────────────────────────────────────────────────────────
start_module() {
    local NAME="$1" CLASS="$2" PORT="$3" EXTRA_CP="${4:-}"
    local FULL_CP="$CP:$EXTRA_CP"

    # Skip if already running
    if timeout 1 bash -c "echo >/dev/tcp/localhost/$PORT" 2>/dev/null; then
        echo "  [SKIP] $NAME (port $PORT) — already running"
        return
    fi

    cd "$PROJECT_ROOT"
    java $JVM_OPTS -cp "$FULL_CP" "$CLASS" >> "$LOG_DIR/$NAME.log" 2>&1 &
    local PID=$!
    echo "$PID" > "$PID_DIR/$NAME.pid"

    # Wait briefly and check it started
    sleep 1
    if kill -0 "$PID" 2>/dev/null; then
        echo "  [OK] $NAME (port $PORT) — PID $PID"
    else
        echo "  [FAIL] $NAME (port $PORT) — exited immediately (check $LOG_DIR/$NAME.log)"
    fi
}

# ── Launch ────────────────────────────────────────────────────────────────────
echo "═══════════════════════════════════════════════════════════════"
echo " NitroWebExpress™ — Start Backend Modules"
echo " JVM: $JVM_OPTS"
echo " Logs: $LOG_DIR/"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# Core
start_module "NitroWebExpress"     "server.nitro.NitroWebExpress"          49152
start_module "ConnectionStatus"    "server.nitro.modules.ConnectionStatusServer" 49155
start_module "Communicator"        "communicator.Communicator"             49199

# Encryption
start_module "AES"                 "server.nitro.NitroWebExpress\$AESCompliant" 5512
start_module "Bitcoin"             "server.nitro.modules.BitcoinCompliant" 6682

# Strernary
start_module "Strernary"           "strernary.StrernaryServer"             20000  "$PROJECT_ROOT/source/strernary"
start_module "StrernaryDirectory"  "strernary.StrernaryDirectoryServer"    2000   "$PROJECT_ROOT/source/strernary"

# Signal Servers
start_module "JapanSignal"         "international.radio.japan.JapanSignalServer"   49201 "$PROJECT_ROOT/source/international/radio/japan"
start_module "RussiaSignal"        "international.radio.russia.RussiaSignalServer" 49202 "$PROJECT_ROOT/source/international/radio/russia"
start_module "MexicoSignal"        "international.radio.mexico.MexicoSignalServer" 49203 "$PROJECT_ROOT/source/international/radio/mexico"
start_module "GreeceSignal"        "greece.international.GreeceInternationalSignalServer" 49204 "$PROJECT_ROOT/source/greece/international"

# California Federal
start_module "CaliforniaFBI"       "source.CaliforniaFBIServer"            49210  "$PROJECT_ROOT/california/fbi/source"
start_module "CaliforniaCIA"       "source.CaliforniaCIAServer"            49211  "$PROJECT_ROOT/california/cia/source"
start_module "CaliforniaNSA"       "source.CaliforniaNSAServer"            49212  "$PROJECT_ROOT/california/nsa/source"

# NC Academic
start_module "DukeUniversity"      "source.DukeUniversityServer"           49213  "$PROJECT_ROOT/north/carolina/duke/source"
start_module "StanfordLibrary"     "source.StanfordLibraryServer"          49214  "$PROJECT_ROOT/north/carolina/library/source"

# Futures
start_module "Futures"             "ai.server.DemocraticAIServer"          5000   "$PROJECT_ROOT/modules/black/red/Futures/source"

# Gray Registries
start_module "GrayPortRegistry"    "modules.gray.GrayPortRegistryServer"   9999   "$PROJECT_ROOT/modules/gray/source"
start_module "Gray85Creme"         "modules.gray85.Gray85PortRegistryServer" 10085 "$PROJECT_ROOT/modules/gray.a85/source"

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo " All modules launched. Verify: bash scripts/test-local.sh"
echo " Stop: bash scripts/start-backend-modules.sh --stop"
echo " Logs: $LOG_DIR/*.log"
echo " PIDs: $PID_DIR/*.pid"
echo "═══════════════════════════════════════════════════════════════"
