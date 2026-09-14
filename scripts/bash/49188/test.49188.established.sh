#!/usr/bin/env bash
# Test: Check for existing established connections on port 49188
PORT=49188

ESTABLISHED=$(ss -tn state established "( sport = :$PORT or dport = :$PORT )" 2>/dev/null || \
              netstat -tn 2>/dev/null | grep ":$PORT " | grep ESTABLISHED)

if [ -n "$ESTABLISHED" ]; then
    COUNT=$(echo "$ESTABLISHED" | wc -l)
    echo "[PASS] $COUNT established connection(s) on port $PORT:"
    echo "$ESTABLISHED"
else
    echo "[INFO] No established connections on port $PORT."
fi
