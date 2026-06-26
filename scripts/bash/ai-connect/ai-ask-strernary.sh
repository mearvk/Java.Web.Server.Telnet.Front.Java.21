#!/usr/bin/env bash
# ai-ask-strernary.sh — Send ASK command to Strernary DJL (port 20000)
HOST="${1:-localhost}"
QUERY="${2:-What is life?}"

echo "ASK|$QUERY" | timeout 10 nc -w 10 "$HOST" 20000 2>/dev/null
