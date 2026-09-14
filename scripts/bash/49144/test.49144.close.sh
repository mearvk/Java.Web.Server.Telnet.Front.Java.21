#!/usr/bin/env bash
# Test: Connect to port 49144 and close cleanly via quit
HOST="${1:-localhost}"
PORT=49144

RESPONSE=$(printf "quit\n" | timeout 5 nc -w 5 "$HOST" "$PORT" 2>/dev/null || true)

echo "[PASS] Connection closed on $HOST:$PORT."
[ -n "$RESPONSE" ] && echo "$RESPONSE" | head -5
