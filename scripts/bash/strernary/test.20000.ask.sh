#!/usr/bin/env bash
# Test: Send ASK query to Strernary on port 20000
HOST="${1:-localhost}"
PORT=20000
QUERY="${2:-what is the weather like}"

RESPONSE=$(echo "ASK|${QUERY}" | timeout 5 nc -w 5 "$HOST" "$PORT" 2>/dev/null || true)

if [ -n "$RESPONSE" ]; then
    echo "[PASS] Strernary responded to ASK query."
    echo "$RESPONSE"
else
    echo "[FAIL] No response from $HOST:$PORT."
    exit 1
fi
