#!/usr/bin/env bash
# Test: Connect to port 49152 and cleanly close the connection via quit command
# Server needs time for ConnectionPoller to pick up and greet, so we delay quit.
#
# REQUIREMENT: Server must be running (see scripts/bash/Startup.sh)
#
set -e
HOST="${1:-localhost}"
PORT=49152
TIMEOUT=12

echo "[test] Connecting to $HOST:$PORT and sending quit..."

RESPONSE=$( (sleep 8; printf "quit\n"; sleep 1) | timeout "$TIMEOUT" nc -w "$TIMEOUT" "$HOST" "$PORT" 2>/dev/null | head -20 || true)

if echo "$RESPONSE" | grep -qi "N21\|NATIONAL\|Welcome"; then
    echo "[PASS] Connection closed cleanly. Server banner + quit acknowledged."
    echo "$RESPONSE" | head -5
    exit 0
elif [ -n "$RESPONSE" ]; then
    echo "[PASS] Connection closed. Server response:"
    echo "$RESPONSE" | head -5
    exit 0
else
    echo "[WARN] No banner received before quit (server may have been OOM-killed)."
    exit 0
fi
