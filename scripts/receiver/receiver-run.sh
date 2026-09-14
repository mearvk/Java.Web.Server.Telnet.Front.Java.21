#!/usr/bin/env bash
# receiver-run.sh — Run NWE Receiver-Only Mode (requires sudo for port 443)
# MEARVK LLC — Max Rupplin
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ROOT="$(cd "$ROOT/.." && pwd)"
OUT="$ROOT/out/receiver"
MYSQL_JAR="$ROOT/jars/mysql/mysql-connector-j-9.7.0.jar"
CONFIG="$ROOT/configuration/receiver.only.xml"

CP="$OUT"
[ -f "$MYSQL_JAR" ] && CP="$CP:$MYSQL_JAR"

echo "═══════════════════════════════════════════════════════"
echo "  NitroWebExpress™ — Receiver-Only Mode"
echo "  Port 443 / TLS / No Password"
echo "  Contact SSA Durham NC for proof of life"
echo "═══════════════════════════════════════════════════════"

exec java -cp "$CP" receiver.ReceiverMain "$CONFIG"
