#!/usr/bin/env bash
# Test: Start a connection to port 49111 and verify banner/response
HOST="${1:-localhost}"
PORT=49111

RESPONSE=$(echo "" | timeout 5 nc -w 5 "$HOST" "$PORT" 2>/dev/null || true)

if [ -n "$RESPONSE" ]; then
    echo "[PASS] Connected to $HOST:$PORT. Response:"
    echo "$RESPONSE" | head -10
else
    echo "[FAIL] No response from $HOST:$PORT."
    exit 1
fi
