#!/usr/bin/env bash
# Test: Check if port 49202 (RussiaSignalServer) is open
HOST="${1:-localhost}"
PORT=49202

if timeout 3 bash -c "echo >/dev/tcp/$HOST/$PORT" 2>/dev/null; then
    echo "[PASS] Port $PORT is open on $HOST."
else
    echo "[FAIL] Port $PORT not reachable on $HOST."
    exit 1
fi
