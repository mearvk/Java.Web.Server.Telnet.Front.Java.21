#!/usr/bin/env bash
# Test: Send STATUS command to MexicoSignalServer on port 49203
HOST="${1:-localhost}"
PORT=49203

RESPONSE=$(echo "STATUS" | timeout 5 nc -w 5 "$HOST" "$PORT" 2>/dev/null || true)

if echo "$RESPONSE" | grep -q "ALIVE"; then
    echo "[PASS] MexicoSignalServer ALIVE on $HOST:$PORT."
    echo "$RESPONSE"
else
    echo "[FAIL] No ALIVE response from $HOST:$PORT."
    exit 1
fi
