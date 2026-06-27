#!/bin/bash
# cron/gray-lease-check.sh — Check for expired GrayPortRegistry leases

if echo "LIST" | timeout 5 nc -q1 localhost 9999 >/dev/null 2>&1; then
    echo "$(date -Iseconds) OK GrayPortRegistry port 9999 responding"
else
    echo "$(date -Iseconds) WARN GrayPortRegistry port 9999 not responding"
fi

if echo "LIST" | timeout 5 nc -q1 localhost 10085 >/dev/null 2>&1; then
    echo "$(date -Iseconds) OK Gray85Crème port 10085 responding"
else
    echo "$(date -Iseconds) WARN Gray85Crème port 10085 not responding"
fi
