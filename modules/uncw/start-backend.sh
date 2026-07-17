#!/bin/bash
set -uo pipefail
MOD_ROOT="$(cd "$(dirname "$0")" && pwd)"; PROJECT_ROOT="$(cd "$MOD_ROOT/../.." && pwd)"
PID_DIR="$MOD_ROOT/data/pids"; LOG_DIR="$MOD_ROOT/logging"; JVM_OPTS="-Xms128m -Xmx512m"
mkdir -p "$PID_DIR" "$LOG_DIR"
echo ""; echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║  UNCW™ Backend Server — Startup (Port 49231)                            ║"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"; echo ""
CP="$PROJECT_ROOT/out:$PROJECT_ROOT/jars/mysql/mysql-connector-j-9.7.0.jar:$PROJECT_ROOT/jars/lanterna-3.1.5.jar"
DJL_CP=$(find "$PROJECT_ROOT/jars/djl" -name "*.jar" 2>/dev/null | tr '\n' ':'); CP="$CP:${DJL_CP}"
MODULE_CLASS="source.UNCWServer"; PID_FILE="$PID_DIR/backend.pid"
if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then echo "  [✓] Already running (PID $(cat "$PID_FILE"))"; exit 0; fi
echo -n "  [*] Starting $MODULE_CLASS... "
cd "$PROJECT_ROOT"; java $JVM_OPTS -cp "$CP" "$MODULE_CLASS" >> "$LOG_DIR/backend.log" 2>&1 &
PID=$!; echo "$PID" > "$PID_FILE"
DEADLINE=$((SECONDS + 10)); READY=0
while [ $SECONDS -lt $DEADLINE ]; do if timeout 1 bash -c "echo >/dev/tcp/localhost/49231" 2>/dev/null; then READY=1; break; fi; sleep 1; done
if [ $READY -eq 1 ]; then echo "✓ (PID $PID, port 49231 UP)"; elif kill -0 "$PID" 2>/dev/null; then echo "~ (timeout)"; else echo "✗ (FAILED)"; rm -f "$PID_FILE"; exit 1; fi
echo ""
