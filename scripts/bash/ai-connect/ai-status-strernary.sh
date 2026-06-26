#!/usr/bin/env bash
# ai-status-strernary.sh — Send STATUS command to Strernary (port 20000)
HOST="${1:-localhost}"

echo "STATUS" | timeout 5 nc -w 5 "$HOST" 20000 2>/dev/null
