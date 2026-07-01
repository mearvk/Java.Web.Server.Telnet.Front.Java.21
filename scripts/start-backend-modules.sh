#!/bin/bash
# NitroWebExpress™ — Start All Backend Modules
# Launches the NWE Main class which internally starts ALL sub-servers.
# Usage: bash scripts/start-backend-modules.sh
# Stop:  bash scripts/start-backend-modules.sh --stop
set -uo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Detect MySQL location (main drive vs block storage)
[ -f "$PROJECT_ROOT/scripts/detect-mysql.sh" ] && source "$PROJECT_ROOT/scripts/detect-mysql.sh"
OUT="$PROJECT_ROOT/out"
JARS="$PROJECT_ROOT/jars"
CP="$OUT:$JARS/mysql/mysql-connector-j-9.7.0.jar:$JARS/lanterna-3.1.5.jar"
DJL_CP=$(find "$JARS/djl" -name "*.jar" 2>/dev/null | tr '\n' ':')
CP="$CP:${DJL_CP}$PROJECT_ROOT/source"
LOG_DIR="$PROJECT_ROOT/logging"
PID_FILE="$PROJECT_ROOT/data/nwe-main.pid"
JVM_OPTS="-Xms256m -Xmx1024m -XX:+UseZGC"

mkdir -p "$LOG_DIR" "$PROJECT_ROOT/data"

# ── Detect log storage location (prefer block storage) ────────────────────────
if mountpoint -q /mnt/blockstorage 2>/dev/null; then
    BLOCK_LOG_DIR="/mnt/blockstorage/nwe/logs"
    mkdir -p "$BLOCK_LOG_DIR"
    LOG_DIR="$BLOCK_LOG_DIR"
    echo "[*] Logging to block storage: $LOG_DIR"
else
    echo "[*] Logging to local: $LOG_DIR"
fi

# ── Stop mode ────────────────────────────────────────────────────────────────
if [[ "${1:-}" == "--stop" ]]; then
    echo "[*] Stopping NitroWebExpress™..."
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if kill -0 "$PID" 2>/dev/null; then
            kill "$PID" 2>/dev/null
            sleep 2
            kill -0 "$PID" 2>/dev/null && kill -9 "$PID" 2>/dev/null
            echo "[OK] NWE Main stopped (PID $PID)"
        else
            echo "[SKIP] PID $PID not running"
        fi
        rm -f "$PID_FILE"
    else
        # Try to find by process name
        pkill -f "java.*Main" 2>/dev/null && echo "[OK] NWE processes killed" || echo "[SKIP] No NWE processes found"
    fi
    exit 0
fi

# ── Check if already running ─────────────────────────────────────────────────
if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    echo "[SKIP] NWE already running (PID $(cat "$PID_FILE")). Use --stop first."
    exit 0
fi

# ── Start ─────────────────────────────────────────────────────────────────────
echo "═══════════════════════════════════════════════════════════════"
echo " NitroWebExpress™ — Start Backend Modules"
echo " JVM: $JVM_OPTS"
echo " Classpath includes: out/, jars/, source/"
echo " Log: $LOG_DIR/nwe-main.log"
echo "═══════════════════════════════════════════════════════════════"
echo ""

cd "$PROJECT_ROOT"
java $JVM_OPTS -cp "$CP" Main >> "$LOG_DIR/nwe-main.log" 2>&1 &
MAIN_PID=$!
echo "$MAIN_PID" > "$PID_FILE"

echo "[*] NWE Main starting (PID $MAIN_PID)..."
echo "[*] Waiting for services to bind..."
sleep 5

# ── Verify ports came up ──────────────────────────────────────────────────────
EXPECTED_PORTS=(49152 49155 49199 5512 6682 20000 2000 49201 49202 49203 49204 49210 49211 49212 49213 49214 5000 9999 10085)
UP=0; DOWN=0

for PORT in "${EXPECTED_PORTS[@]}"; do
    if timeout 1 bash -c "echo >/dev/tcp/localhost/$PORT" 2>/dev/null; then
        UP=$((UP + 1))
    else
        DOWN=$((DOWN + 1))
    fi
done

echo ""
echo "  Ports up: $UP / ${#EXPECTED_PORTS[@]}"

if ! kill -0 "$MAIN_PID" 2>/dev/null; then
    echo "  [FAIL] Main process exited. Check: $LOG_DIR/nwe-main.log"
    echo "  Last 10 lines:"
    tail -10 "$LOG_DIR/nwe-main.log" 2>/dev/null | sed 's/^/    /'
    exit 1
fi

# Show which are up/down
echo ""
declare -A PORT_NAMES=([49152]="NitroWebExpress" [49155]="ConnectionStatus" [49199]="Communicator" [5512]="AES" [6682]="Bitcoin" [20000]="Strernary" [2000]="StrernaryDirectory" [49201]="JapanSignal" [49202]="RussiaSignal" [49203]="MexicoSignal" [49204]="GreeceSignal" [49210]="CaliforniaFBI" [49211]="CaliforniaCIA" [49212]="CaliforniaNSA" [49213]="DukeUniversity" [49214]="StanfordLibrary" [5000]="Futures" [9999]="GrayPortRegistry" [10085]="Gray85Creme")

for PORT in "${EXPECTED_PORTS[@]}"; do
    NAME="${PORT_NAMES[$PORT]:-port-$PORT}"
    if timeout 1 bash -c "echo >/dev/tcp/localhost/$PORT" 2>/dev/null; then
        echo "  [OK] $NAME (port $PORT)"
    else
        echo "  [--] $NAME (port $PORT) — not yet (may need more time or is disabled in nwe-config.xml)"
    fi
done

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo " NWE Main running — PID $MAIN_PID"
echo " Stop: bash scripts/start-backend-modules.sh --stop"
echo " Log:  tail -f $LOG_DIR/nwe-main.log"
echo " Test: bash scripts/test-local.sh"
echo "═══════════════════════════════════════════════════════════════"
