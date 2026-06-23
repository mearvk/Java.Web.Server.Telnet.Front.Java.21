#!/usr/bin/env bash
# Test: Connect to port 49144 and send settings/status commands
HOST="${1:-localhost}"
PORT=49144

RESPONSE=$(printf "status\nlang en\nquit\n" | timeout 5 nc -w 5 "$HOST" "$PORT" 2>/dev/null || true)

if [ -n "$RESPONSE" ]; then
    echo "[PASS] Settings commands accepted. Response:"
    echo "$RESPONSE"
else
    echo "[FAIL] No response from $HOST:$PORT."
    exit 1
fi
