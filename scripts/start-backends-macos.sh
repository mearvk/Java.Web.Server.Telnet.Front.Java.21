#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# NitroWebExpress™ — Start Backend Modules (macOS)
# Starts Main.java with G1GC, 4GB heap.
# Usage: bash scripts/start-backends-macos.sh
# ═══════════════════════════════════════════════════════════════════════════════
set -uo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

export JAVA_HOME="${JAVA_HOME:-$(/usr/libexec/java_home -v 21 2>/dev/null || echo /opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home)}"
export PATH="$JAVA_HOME/bin:$PATH"

OUT="$PROJECT_ROOT/out"
PID_DIR="$PROJECT_ROOT/data"
PID_FILE="$PID_DIR/nwe-main.pid"
LOG_FILE="$PROJECT_ROOT/logging/nwe-main.log"

mkdir -p "$PID_DIR" "$PROJECT_ROOT/logging"

# ── Check if already running ──────────────────────────────────────────────────
if [ -f "$PID_FILE" ]; then
    OLD_PID=$(cat "$PID_FILE")
    if kill -0 "$OLD_PID" 2>/dev/null; then
        echo "[*] NWE Main already running (PID $OLD_PID)"
        echo "    Stop first: bash scripts/shutdown-backends.sh"
        exit 0
    fi
    rm -f "$PID_FILE"
fi

# ── Build classpath ───────────────────────────────────────────────────────────
MYSQL_JAR="$PROJECT_ROOT/jars/mysql/mysql-connector-j-9.7.0.jar"
LANTERNA_JAR="$PROJECT_ROOT/jars/lanterna-3.1.5.jar"
DJL_CP=$(find "$PROJECT_ROOT/jars/djl" -name "*.jar" 2>/dev/null | tr '\n' ':')
CP="$OUT:$MYSQL_JAR:${DJL_CP}$LANTERNA_JAR"

echo "[*] Starting NitroWebExpress™ backends..."
echo "    JAVA_HOME: $JAVA_HOME"
echo "    JVM: G1GC, 4GB heap"
echo ""

# ── Start in background ───────────────────────────────────────────────────────
cd "$PROJECT_ROOT"
nohup java -server -XX:+UseG1GC -Xmx4g -Xms1g \
    -Duser.dir="$PROJECT_ROOT" \
    -cp "$CP" Main > "$LOG_FILE" 2>&1 &

JAVA_PID=$!
echo "$JAVA_PID" > "$PID_FILE"

echo "[OK] NWE Main started (PID $JAVA_PID)"
echo "    PID file: $PID_FILE"
echo "    Log: $LOG_FILE"
echo ""

# ── Verify ports ──────────────────────────────────────────────────────────────
echo "[*] Verifying ports (waiting 5 seconds)..."
sleep 5

PORTS_UP=0
for PORT in 49152 20000 2000 5512 6682; do
    if nc -z localhost "$PORT" 2>/dev/null; then
        echo "  [OK] Port $PORT listening"
        PORTS_UP=$((PORTS_UP + 1))
    else
        echo "  [--] Port $PORT not yet listening"
    fi
done
echo "  Ports up: $PORTS_UP / 5"
echo ""
