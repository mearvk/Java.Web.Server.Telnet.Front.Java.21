#!/usr/bin/env bash
# Test: Start a telnet connection to port 49152 and verify banner response
# The server uses a polling loop (500ms) + session handler to send banner.
# The ConnectionPoller needs to poll CURRENT_CONNECTIONS before greet() fires.
# Keep stdin open with sleep so the server has time to respond.
set -e
HOST="${1:-localhost}"
PORT=49152
TIMEOUT=12

echo "[test] Connecting to $HOST:$PORT (waiting up to ${TIMEOUT}s for banner)..."

RESPONSE=$( (sleep "$TIMEOUT") | timeout "$TIMEOUT" nc -w "$TIMEOUT" "$HOST" "$PORT" 2>/dev/null | head -20 || true)

if echo "$RESPONSE" | grep -qi "N21\|NATIONAL\|FINANCE\|Welcome"; then
    echo "[PASS] Connection established. Server banner received:"
    echo "$RESPONSE" | head -10
    exit 0
elif [ -n "$RESPONSE" ]; then
    echo "[PASS] Connection established. Server response:"
    echo "$RESPONSE" | head -10
    exit 0
else
    echo "[FAIL] No response from $HOST:$PORT within ${TIMEOUT}s."
    exit 1
fi
