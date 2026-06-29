#!/usr/bin/env bash
# strernary-client.sh — Interactive client for Strernary port 20000
# Usage: ./strernary-client.sh [host] [national_id]
#   If national_id is provided, it is sent automatically at the ID prompt.
#   Otherwise you'll be prompted interactively.

HOST="${1:-localhost}"
NID="${2:-}"
PORT=20000

if ! command -v nc &>/dev/null; then
    echo "[ERROR] netcat (nc) not found. Install ncat or netcat." >&2
    exit 1
fi

if [ -n "$NID" ]; then
    # Send NationalID then drop into interactive mode
    (echo "$NID"; cat) | nc "$HOST" "$PORT"
else
    # Fully interactive — user enters NationalID (or presses Enter to skip)
    nc "$HOST" "$PORT"
fi
