#!/usr/bin/env bash
# ai-directory-list.sh — Connect to Strernary Directory (port 2000) and list servers
HOST="${1:-localhost}"

# Option 1 lists port 20000 servers
echo "1" | timeout 5 nc -w 5 "$HOST" 2000 2>/dev/null
