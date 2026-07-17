#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════════
# NitroWebExpress™ — Chat Backend Startup
# Starts the TCP backend server on port 49230.
# Usage: bash start-backend.sh
# ═══════════════════════════════════════════════════════════════════════════════════
set -uo pipefail

MOD_ROOT="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$MOD_ROOT/../.." && pwd)"
PID_DIR="$MOD_ROOT/data/pids"
LOG_DIR="$MOD_ROOT/logging"
JVM_OPTS="-Xms128m -Xmx512m"

mkdir -p "$PID_DIR" "$LOG_DIR"

echo ""
echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║  NWE Chat™ Backend Server — Startup                                     ║"
echo "║  JVM: $JVM_OPTS                                                         ║"
echo "║  Encryption: DH-2048 + RSA-2048 + AES-256-GCM                           ║"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo ""

CP="$PROJECT_ROOT/out:$PROJECT_ROOT/jars/mysql/mysql-connector-j-9.7.0.jar:$PROJECT_ROOT/jars/lanterna-3.1.5.jar"
DJL_CP=$(find "$PROJECT_ROOT/jars/djl" -name "*.jar" 2>/dev/null | tr '\n' ':')
CP="$CP:${DJL_CP}"

MODULE_CLASS="source.ChatServer"
PID_FILE="$PID_DIR/backend.pid"

if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    echo "  [✓] Backend already running (PID $(cat "$PID_FILE"))"
    exit 0
fi

echo -n "  [*] Starting $MODULE_CLASS... "

cd "$PROJECT_ROOT"
java $JVM_OPTS -cp "$CP" "$MODULE_CLASS" >> "$LOG_DIR/backend.log" 2>&1 &
PID=$!
echo "$PID" > "$PID_FILE"

DEADLINE=$((SECONDS + 10))
READY=0
while [ $SECONDS -lt $DEADLINE ]; do
    if timeout 1 bash -c "echo >/dev/tcp/localhost/49230" 2>/dev/null; then
        READY=1; break
    fi
    sleep 1
done

if [ $READY -eq 1 ]; then
    echo "✓ (PID $PID, port 49230 UP)"
elif kill -0 "$PID" 2>/dev/null; then
    echo "~ (PID $PID alive, port 49230 not yet bound — timeout)"
else
    echo "✗ (FAILED)"
    rm -f "$PID_FILE"
    echo "  Check logs: tail -f $LOG_DIR/backend.log"
    exit 1
fi

echo ""
echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║  Chat Backend Running — PID: $PID                                       ║"
echo "║  Logs: $LOG_DIR/backend.log                                              ║"
echo "║  Stop: bash shutdown-backend.sh                                           ║"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo ""
