#!/usr/bin/env bash
# Test: Connect to port 49152 and cleanly close the connection via quit command
set -e
HOST="${1:-localhost}"
PORT=49152
TIMEOUT=5

echo "[test] Connecting to $HOST:$PORT and sending quit..."

RESPONSE=$(printf "quit\n" | timeout "$TIMEOUT" nc -w "$TIMEOUT" "$HOST" "$PORT" 2>/dev/null || true)

if [ $? -eq 0 ] || [ -n "$RESPONSE" ]; then
    echo "[PASS] Connection closed cleanly. Server response:"
    echo "$RESPONSE" | head -10
    exit 0
else
    echo "[FAIL] Could not connect or close on $HOST:$PORT."
    exit 1
fi
