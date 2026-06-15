#!/usr/bin/env bash
# Test: Connect to port 49152 and attempt to change basic settings (lang, color)
set -e
HOST="${1:-localhost}"
PORT=49152
TIMEOUT=5

echo "[test] Connecting to $HOST:$PORT to test settings commands..."

RESPONSE=$(printf "lang ja\nlang en\ncolor off\ncolor on\nquit\n" | timeout "$TIMEOUT" nc -w "$TIMEOUT" "$HOST" "$PORT" 2>/dev/null || true)

if [ -n "$RESPONSE" ]; then
    echo "[PASS] Settings commands sent. Server response:"
    echo "$RESPONSE"
    exit 0
else
    echo "[FAIL] No response from $HOST:$PORT."
    exit 1
fi
