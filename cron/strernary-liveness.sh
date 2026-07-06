#!/bin/bash
# cron/strernary-liveness.sh — Probe Strernary™ on port 20000

if echo "STATUS" | timeout 5 nc -q1 localhost 20000 >/dev/null 2>&1; then
    echo "$(date -Iseconds) OK Strernary port 20000"
else
    echo "$(date -Iseconds) FAIL Strernary port 20000 — not responding"
fi
