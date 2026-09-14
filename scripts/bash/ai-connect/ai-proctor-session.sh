#!/usr/bin/env bash
# ai-proctor-session.sh — Connect to AIProctorModule (port 49111) with identify + ask
HOST="${1:-localhost}"
NATIONAL_ID="${2:-00000000}"
QUERY="${3:-What is integrity?}"

{
    echo "identify $NATIONAL_ID"
    sleep 1
    echo "ask $QUERY"
    sleep 2
    echo "quit"
} | timeout 10 nc -w 10 "$HOST" 49111 2>/dev/null
