#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# Brarner.M.Alete™ — Backend Startup Script
# Starts the TCP backend servers (Postal, SSA, Art, Legal).
# These are the signal-processing servers the webapp connects to.
# Usage: bash start-backend.sh
# ═══════════════════════════════════════════════════════════════
set -uo pipefail

BMA_ROOT="$(cd "$(dirname "$0")" && pwd)"
PID_DIR="$BMA_ROOT/data/pids"
LOG_DIR="$BMA_ROOT/logging"
SOURCE="$BMA_ROOT/source"
LIB="$BMA_ROOT/lib"
JARS="$BMA_ROOT/jars"
JVM_OPTS="-Xms64m -Xmx256m"

mkdir -p "$PID_DIR" "$LOG_DIR"

echo "═══════════════════════════════════════════════════════════════"
echo " Brarner.M.Alete™ — Backend Servers"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# Build classpath
CP="$SOURCE"
if [ -d "$LIB" ]; then CP="$CP:$LIB/*"; fi
if [ -d "$JARS" ]; then CP="$CP:$JARS/*"; fi

# ── Module definitions ────────────────────────────────────────────────────────
declare -A MODULES=(
    [postal]="presidential.Brarner.M.Alete.source.postal.BaseServer"
    [ssa]="presidential.Brarner.M.Alete.source.ssa.BaseServer"
    [art]="presidential.Brarner.M.Alete.source.art.BaseServer"
    [legal]="presidential.Brarner.M.Alete.source.legal.BaseServer"
)

# ── Start each module ─────────────────────────────────────────────────────────
for MODULE in postal ssa art legal; do
    CLASS="${MODULES[$MODULE]}"
    PID_FILE="$PID_DIR/$MODULE.pid"

    # Check if already running
    if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
        echo "  [SKIP] $MODULE — already running (PID $(cat "$PID_FILE"))"
        continue
    fi

    echo -n "  [*] Starting $MODULE..."
    cd "$BMA_ROOT"
    java $JVM_OPTS -cp "$CP" "$CLASS" >> "$LOG_DIR/$MODULE.log" 2>&1 &
    PID=$!
    echo "$PID" > "$PID_FILE"
    sleep 1

    if kill -0 "$PID" 2>/dev/null; then
        echo " OK (PID $PID)"
    else
        echo " FAILED (check $LOG_DIR/$MODULE.log)"
        rm -f "$PID_FILE"
    fi
done

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo " Stop: bash shutdown-backend.sh"
echo " Logs: $LOG_DIR/"
echo "═══════════════════════════════════════════════════════════════"
