#!/usr/bin/env bash
# Test: Start a telnet connection to port 49152 and verify banner response
set -e
HOST="${1:-localhost}"
PORT=49152
TIMEOUT=5

echo "[test] Connecting to $HOST:$PORT..."

RESPONSE=$(echo "" | timeout "$TIMEOUT" nc -w "$TIMEOUT" "$HOST" "$PORT" 2>/dev/null || true)

if [ -n "$RESPONSE" ]; then
    echo "[PASS] Connection established. Server response:"
    echo "$RESPONSE" | head -10
    exit 0
else
    echo "[FAIL] No response from $HOST:$PORT within ${TIMEOUT}s."
    exit 1
fi
