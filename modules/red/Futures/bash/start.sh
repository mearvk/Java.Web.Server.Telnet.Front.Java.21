#!/bin/bash
# ============================================================
# START — Democratic ProFront National 1.0
# Installer ID: MEARVK LLC - Max Rupplin
# ============================================================
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CP="$PROJECT_DIR/output/production/Futures:$(echo "$PROJECT_DIR"/jars/*.jar | tr ' ' ':')"
SILENT=false
[ "$1" = "silent" ] && SILENT=true

# Kill any existing port 5000 process
EXISTING=$(lsof -t -i:5000 2>/dev/null)
if [ -n "$EXISTING" ]; then
    echo "[start] Stopping existing process on port 5000 (PID: $EXISTING)..." | if $SILENT; then cat >> "$PROJECT_DIR/startup.log"; else cat; fi
    kill $EXISTING 2>/dev/null
    sleep 2
fi

if $SILENT; then
    echo "[start] $(date '+%Y-%m-%d %H:%M:%S') Democratic ProFront National 1.0" > "$PROJECT_DIR/startup.log"
    echo "[start] Port 5000 will open after secure random wait (2-3 min)..." >> "$PROJECT_DIR/startup.log"
    java -cp "$CP" ai.server.DemocraticAIServer >> "$PROJECT_DIR/startup.log" 2>&1 &
    echo $! > "$PROJECT_DIR/.server.pid"
    echo "[start] Server PID: $(cat "$PROJECT_DIR/.server.pid")" >> "$PROJECT_DIR/startup.log"
    echo "[start] Server launched (PID: $(cat "$PROJECT_DIR/.server.pid")) — log: startup.log"
else
    echo "[start] Democratic ProFront National 1.0"
    echo "[start] Port 5000 will open after secure random wait (2-3 min)..."
    java -cp "$CP" ai.server.DemocraticAIServer &
    echo $! > "$PROJECT_DIR/.server.pid"
    echo "[start] Server PID: $(cat "$PROJECT_DIR/.server.pid")"
fi
