#!/usr/bin/env bash
# shutdown.sh — gracefully stop the WebExpress server and all related connections

PORTS=(49152 49155 5512 6682)

echo "[shutdown] Closing server ports: ${PORTS[*]}"

for PORT in "${PORTS[@]}"; do
    # collect every PID listening on this port
    PIDS=$(lsof -ti TCP:"$PORT" 2>/dev/null)
    if [ -n "$PIDS" ]; then
        echo "[shutdown] Sending SIGTERM to PIDs on port $PORT: $PIDS"
        kill -TERM $PIDS 2>/dev/null
    fi
done

# allow a brief grace period for clean shutdown
sleep 2

for PORT in "${PORTS[@]}"; do
    PIDS=$(lsof -ti TCP:"$PORT" 2>/dev/null)
    if [ -n "$PIDS" ]; then
        echo "[shutdown] Sending SIGKILL to remaining PIDs on port $PORT: $PIDS"
        kill -KILL $PIDS 2>/dev/null
    fi
done

echo "[shutdown] Done."
