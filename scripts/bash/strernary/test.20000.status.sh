#!/usr/bin/env bash
# Test: Send STATUS command to Strernary on port 20000
HOST="${1:-localhost}"
PORT=20000

RESPONSE=$(echo "STATUS" | timeout 5 nc -w 5 "$HOST" "$PORT" 2>/dev/null || true)

if echo "$RESPONSE" | grep -q "ALIVE"; then
    echo "[PASS] Strernary ALIVE on $HOST:$PORT."
    echo "$RESPONSE"
else
    echo "[FAIL] No ALIVE response from $HOST:$PORT."
    exit 1
fi
