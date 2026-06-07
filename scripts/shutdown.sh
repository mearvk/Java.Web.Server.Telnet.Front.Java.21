#!/usr/bin/env bash
# shutdown.sh — kill processes on server ports silently (printing handled by ShutdownHooks via CommonRails)

PORTS=(49152 49155 49166 49177 5512 6682)

for PORT in "${PORTS[@]}"; do
    PIDS=$(lsof -ti TCP:"$PORT" 2>/dev/null)
    [ -n "$PIDS" ] && kill -TERM $PIDS 2>/dev/null
done

sleep 2

for PORT in "${PORTS[@]}"; do
    PIDS=$(lsof -ti TCP:"$PORT" 2>/dev/null)
    [ -n "$PIDS" ] && kill -KILL $PIDS 2>/dev/null
done
