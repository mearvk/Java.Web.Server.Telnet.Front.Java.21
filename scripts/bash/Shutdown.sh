#!/usr/bin/env bash
# Shutdown.sh — kill processes on server ports silently (printing handled by ShutdownHooks via CommonRails)

SCRIPT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"

# Noble Registry — save brothers' state before disconcern
bash "${SCRIPT_DIR}/cron/save-noble-state.sh" 2>/dev/null

PORTS=(49152 49155 49166 49177 49188 49199 49200 49201 49202 49203 49204 49144 49133 20000 5512 6682 7743 7744 8888)

for PORT in "${PORTS[@]}"; do
    PIDS=$(lsof -ti TCP:"$PORT" 2>/dev/null)
    [ -n "$PIDS" ] && kill -TERM $PIDS 2>/dev/null
done

sleep 2

for PORT in "${PORTS[@]}"; do
    PIDS=$(lsof -ti TCP:"$PORT" 2>/dev/null)
    [ -n "$PIDS" ] && kill -KILL $PIDS 2>/dev/null
done
