#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# duke — Backend Startup Script
# Starts the TCP backend server(s).
# Usage: bash start-backend.sh
# ═══════════════════════════════════════════════════════════════
set -uo pipefail

MOD_ROOT="$(cd "$(dirname "$0")" && pwd)"
PID_DIR="$MOD_ROOT/data/pids"
LOG_DIR="$MOD_ROOT/logging"
SOURCE="$MOD_ROOT/source"
LIB="$MOD_ROOT/lib"
JARS="$MOD_ROOT/jars"
JVM_OPTS="-Xms64m -Xmx256m"

mkdir -p "$PID_DIR" "$LOG_DIR"

echo "═══════════════════════════════════════════════════════════════"
echo " duke — Backend Server"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# Build classpath
CP="$SOURCE"
if [ -d "$LIB" ]; then CP="$CP:$LIB/*"; fi
if [ -d "$JARS" ]; then CP="$CP:$JARS/*"; fi

# ── Module definition ─────────────────────────────────────────────────────
MODULE_CLASS="DukeUniversityServer"
PID_FILE="$PID_DIR/backend.pid"

# Check if already running
if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    echo "  [SKIP] Backend — already running (PID $(cat "$PID_FILE"))"
else
    echo -n "  [*] Starting $MODULE_CLASS..."
    cd "$MOD_ROOT"
    java $JVM_OPTS -cp "$CP" "$MODULE_CLASS" >> "$LOG_DIR/backend.log" 2>&1 &
    PID=$!
    echo "$PID" > "$PID_FILE"
    sleep 1

    if kill -0 "$PID" 2>/dev/null; then
        echo " OK (PID $PID)"
    else
        echo " FAILED (check $LOG_DIR/backend.log)"
        rm -f "$PID_FILE"
    fi
fi

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo " Stop: bash shutdown-backend.sh"
echo " Logs: $LOG_DIR/"
echo "═══════════════════════════════════════════════════════════════"
