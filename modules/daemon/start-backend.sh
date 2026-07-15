#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# NitroWebExpress™ — daemon Backend Startup
# Starts the ModuleLoaderDaemon TCP server (port 49188).
# Usage: bash start-backend.sh
# ═══════════════════════════════════════════════════════════════════════════════
set -uo pipefail

MOD_ROOT="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$MOD_ROOT/../.." && pwd)"
PID_DIR="$MOD_ROOT/data/pids"
LOG_DIR="$MOD_ROOT/logging"
JVM_OPTS="-Xms64m -Xmx256m"

mkdir -p "$PID_DIR" "$LOG_DIR"

echo ""
echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║  daemon — ModuleLoaderDaemon Backend Startup                              ║"
echo "║  Port:  49188                                                              ║"
echo "║  JVM:   $JVM_OPTS                                                          ║"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo ""

CP="$PROJECT_ROOT/out:$PROJECT_ROOT/jars/mysql/mysql-connector-j-9.7.0.jar:$PROJECT_ROOT/jars/lanterna-3.1.5.jar"
DJL_CP=$(find "$PROJECT_ROOT/jars/djl" -name "*.jar" 2>/dev/null | tr '\n' ':')
CP="$CP:${DJL_CP}"

MODULE_CLASS="ModuleLoaderDaemon"
PID_FILE="$PID_DIR/backend.pid"

if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    echo "  [✓] ModuleLoaderDaemon already running (PID $(cat "$PID_FILE"))"
    echo ""
    exit 0
fi

echo -n "  [*] Starting $MODULE_CLASS... "

cd "$PROJECT_ROOT"
java $JVM_OPTS -Dnwe.root="$PROJECT_ROOT" -cp "$CP" "$MODULE_CLASS" >> "$LOG_DIR/backend.log" 2>&1 &
PID=$!
echo "$PID" > "$PID_FILE"

DEADLINE=$((SECONDS + 10))
READY=0
while [ $SECONDS -lt $DEADLINE ]; do
    if timeout 1 bash -c "echo >/dev/tcp/localhost/49188" 2>/dev/null; then
        READY=1; break
    fi
    sleep 1
done

if [ $READY -eq 1 ]; then
    echo "✓ (PID $PID, port 49188 UP)"
elif kill -0 "$PID" 2>/dev/null; then
    echo "~ (PID $PID alive, port 49188 not yet bound — timeout)"
else
    echo "✗ (FAILED)"
    rm -f "$PID_FILE"
    echo "  Check logs: tail -f $LOG_DIR/backend.log"
    exit 1
fi

echo ""
echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║  ModuleLoaderDaemon Running                                               ║"
echo "║  PID:  $PID                                                                ║"
echo "║  Port: 49188                                                               ║"
echo "║  Logs: $LOG_DIR/backend.log                                               ║"
echo "║  Stop: bash shutdown-backend.sh                                            ║"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo ""
