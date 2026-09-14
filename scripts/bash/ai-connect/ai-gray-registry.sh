#!/usr/bin/env bash
# ai-gray-registry.sh — Connect to Installer ID Tech™ Port Registry (port 9999)
HOST="${1:-localhost}"
CMD="${2:-LIST}"

echo "$CMD" | timeout 5 nc -w 5 "$HOST" 9999 2>/dev/null
