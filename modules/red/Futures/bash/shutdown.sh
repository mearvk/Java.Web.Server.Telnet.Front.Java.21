#!/bin/bash
# ============================================================
# SHUTDOWN — Democratic ProFront National 1.0
# Stops any existing port 5000 process
# Installer ID: MEARVK LLC - Max Rupplin
# ============================================================
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# Method 1: Kill by PID file
if [ -f "$PROJECT_DIR/.server.pid" ]; then
    PID=$(cat "$PROJECT_DIR/.server.pid")
    if kill -0 $PID 2>/dev/null; then
        echo "[shutdown] Stopping server PID $PID..."
        kill $PID
        sleep 2
        kill -0 $PID 2>/dev/null && kill -9 $PID
    fi
    rm -f "$PROJECT_DIR/.server.pid"
fi

# Method 2: Kill anything on port 5000
PIDS=$(lsof -t -i:5000 2>/dev/null)
if [ -n "$PIDS" ]; then
    echo "[shutdown] Killing port 5000 processes: $PIDS"
    kill $PIDS 2>/dev/null
    sleep 1
    kill -9 $(lsof -t -i:5000 2>/dev/null) 2>/dev/null
fi

echo "[shutdown] Democratic ProFront National 1.0 stopped."
