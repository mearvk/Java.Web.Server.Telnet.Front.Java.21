#!/usr/bin/env bash
# ai-xml-route.sh — Send NWE XML route packet to port 2000 for NIO masquerade forwarding
HOST="${1:-localhost}"
TARGET_PORT="${2:-20000}"
PAYLOAD="${3:-ASK|What is life?}"

echo "<nwe-route><port>$TARGET_PORT</port><payload>$PAYLOAD</payload></nwe-route>" | timeout 5 nc -w 5 "$HOST" 2000 2>/dev/null
