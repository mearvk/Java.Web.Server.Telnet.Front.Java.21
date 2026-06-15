#!/usr/bin/env bash
# Test: Check for existing established connections on port 49152
set -e
PORT=49152

echo "[test] Checking established connections on port $PORT..."

ESTABLISHED=$(ss -tn state established "( sport = :$PORT or dport = :$PORT )" 2>/dev/null || \
              netstat -tn 2>/dev/null | grep ":$PORT " | grep ESTABLISHED)

if [ -n "$ESTABLISHED" ]; then
    COUNT=$(echo "$ESTABLISHED" | grep -c "" || true)
    echo "[PASS] Found $COUNT established connection(s) on port $PORT:"
    echo "$ESTABLISHED"
    exit 0
else
    echo "[INFO] No established connections on port $PORT."
    exit 0
fi
