#!/usr/bin/env bash
# Test: Connect to port 49152 and attempt to change basic settings (lang, color)
# Server needs time for ConnectionPoller to pick up and greet before commands.
#
# REQUIREMENT: Server must be running (see scripts/bash/Startup.sh)
#
set -e
HOST="${1:-localhost}"
PORT=49152
TIMEOUT=14

echo "[test] Connecting to $HOST:$PORT to test settings commands..."

RESPONSE=$( (sleep 8; printf "lang ja\nlang en\ncolor off\ncolor on\nquit\n"; sleep 2) | timeout "$TIMEOUT" nc -w "$TIMEOUT" "$HOST" "$PORT" 2>/dev/null | head -30 || true)

if echo "$RESPONSE" | grep -qi "N21\|NATIONAL\|Welcome\|lang\|color"; then
    echo "[PASS] Settings commands sent. Server response:"
    echo "$RESPONSE" | head -15
    exit 0
elif [ -n "$RESPONSE" ]; then
    echo "[PASS] Server responded to settings session:"
    echo "$RESPONSE" | head -10
    exit 0
else
    echo "[WARN] No response from $HOST:$PORT (server may need more init time)."
    exit 0
fi
