#!/usr/bin/env bash
# Test: Send STATUS command to GreeceInternationalSignalServer on port 49204
HOST="${1:-localhost}"
PORT=49204

RESPONSE=$(echo "STATUS" | timeout 5 nc -w 5 "$HOST" "$PORT" 2>/dev/null || true)

if echo "$RESPONSE" | grep -q "ALIVE"; then
    echo "[PASS] GreeceInternationalSignalServer ALIVE on $HOST:$PORT."
    echo "$RESPONSE"
else
    echo "[FAIL] No ALIVE response from $HOST:$PORT."
    exit 1
fi
