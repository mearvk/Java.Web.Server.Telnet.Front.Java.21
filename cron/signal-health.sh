#!/bin/bash
# cron/signal-health.sh — Check International Signal Servers are alive
# Ports: 49201 (Japan), 49202 (Russia), 49203 (Mexico), 49204 (Greece)

PORTS="49201 49202 49203 49204"
NAMES="Japan Russia Mexico Greece"

i=0
for port in $PORTS; do
    name=$(echo $NAMES | cut -d' ' -f$((i+1)))
    if echo "STATUS" | timeout 5 nc -q1 localhost "$port" >/dev/null 2>&1; then
        echo "$(date -Iseconds) OK ${name}SignalServer port ${port}"
    else
        echo "$(date -Iseconds) FAIL ${name}SignalServer port ${port}"
    fi
    i=$((i+1))
done
