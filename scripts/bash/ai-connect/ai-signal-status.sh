#!/usr/bin/env bash
# ai-signal-status.sh — Send STATUS to international signal servers (49201-49205)
HOST="${1:-localhost}"

PORTS=(
    "49201:Japan"
    "49202:Russia"
    "49203:Mexico"
    "49204:Greece"
    "49205:Italy"
)

for entry in "${PORTS[@]}"; do
    PORT="${entry%%:*}"
    NAME="${entry#*:}"
    RESP=$(echo "STATUS" | timeout 5 nc -w 5 "$HOST" "$PORT" 2>/dev/null)
    if [ -n "$RESP" ]; then
        echo "[$NAME:$PORT] $RESP"
    else
        echo "[$NAME:$PORT] No response"
    fi
done
