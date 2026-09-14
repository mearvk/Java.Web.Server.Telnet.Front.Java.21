#!/usr/bin/env bash
# ai-middle-director.sh — Send commands to Middle Director (port 8888)
HOST="${1:-localhost}"
CMD="${2:-status}"

echo "$CMD" | timeout 5 nc -w 5 "$HOST" 8888 2>/dev/null
