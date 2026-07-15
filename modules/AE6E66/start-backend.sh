#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════════
# NitroWebExpress™ — AE6E66 Backend Startup
# Starts the TCP backend server.
# Usage: bash start-backend.sh
# ═══════════════════════════════════════════════════════════════════════════════════
set -uo pipefail

MOD_ROOT="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$MOD_ROOT/../.." && pwd)"
PID_DIR="$MOD_ROOT/data/pids"
LOG_DIR="$MOD_ROOT/logging"
SOURCE="$MOD_ROOT/source"
LIB="$MOD_ROOT/lib"
JARS="$MOD_ROOT/jars"
JVM_OPTS="-Xms64m -Xmx256m"

mkdir -p "$PID_DIR" "$LOG_DIR"

echo ""
echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║  AE6E66 Backend Server — Startup                                          ║"
echo "║  JVM: $JVM_OPTS                                                            ║"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo ""

# Build classpath
CP="$SOURCE"
if [ -d "$LIB" ]; then CP="$CP:$LIB/*"; fi
if [ -d "$JARS" ]; then CP="$CP:$JARS/*"; fi

# ── Module definition ─────────────────────────────────────────────────────────
MODULE_CLASS="source.AE6E66Main"
PID_FILE="$PID_DIR/backend.pid"

# Check if already running
if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    echo "  [✓] Backend already running (PID $(cat "$PID_FILE"))"
    echo ""
    echo "╔═══════════════════════════════════════════════════════════════════════════╗"
    echo "║  To stop:    bash shutdown-backend.sh                                     ║"
    echo "║  To restart: bash shutdown-backend.sh && bash start-backend.sh            ║"
    echo "║  System:     bash ../../scripts/status.sh                                 ║"
    echo "╚═══════════════════════════════════════════════════════════════════════════╝"
    echo ""
    exit 0
fi

echo -n "  [*] Starting $MODULE_CLASS... "

cd "$MOD_ROOT"
java $JVM_OPTS -cp "$CP" "$MODULE_CLASS" >> "$LOG_DIR/backend.log" 2>&1 &
PID=$!
echo "$PID" > "$PID_FILE"

# ── Liveness callback (10s timeout — no TCP port for this module) ────────────
DEADLINE=$((SECONDS + 10))
ALIVE=0
while [ $SECONDS -lt $DEADLINE ]; do
    if kill -0 "$PID" 2>/dev/null; then
        ALIVE=1; break
    fi
    sleep 1
done

if [ $ALIVE -eq 1 ]; then
    echo "✓ (PID $PID alive)"
else
    echo "✗ (FAILED — exited within 10s)"
    rm -f "$PID_FILE"
    echo ""
    echo "  Check logs: tail -f $LOG_DIR/backend.log"
    exit 1
fi

echo ""
echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║  Backend Running                                                          ║"
echo "║  PID: $PID                                                                 ║"
echo "║  Logs: $LOG_DIR/backend.log                                                ║"
echo "║                                                                            ║"
echo "║  Management:                                                               ║"
echo "║  Stop backend:     bash shutdown-backend.sh                               ║"
echo "║  Start frontend:   bash start.sh                                           ║"
echo "║  Start all:        bash ../../scripts/start-all.sh                         ║"
echo "║  System status:    bash ../../scripts/status.sh                            ║"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo ""
