#!/usr/bin/env bash
# Test: Check if port 49152 is open and accepting TCP connections
#
# REQUIREMENT: Server must be running (see scripts/bash/Startup.sh)
#
set -e
HOST="${1:-localhost}"
PORT=49152
TIMEOUT=5

echo "[test] Checking port $PORT on $HOST..."

if timeout "$TIMEOUT" bash -c "echo >/dev/tcp/$HOST/$PORT" 2>/dev/null; then
    echo "[PASS] Port $PORT is open and accepting connections."
    exit 0
else
    echo "[FAIL] Port $PORT is not reachable on $HOST."
    exit 1
fi
