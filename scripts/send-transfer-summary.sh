#!/usr/bin/env bash
# send-transfer-summary.sh — Sends the Transfer of Summary to all contacts
# Usage: bash scripts/send-transfer-summary.sh
#
# Requires: sendmail or mailx installed on the server.
# Install: sudo apt-get install -y mailutils postfix
#          (select 'Internet Site' when prompted for postfix config)

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/out"
JAR="$ROOT/jars/mysql/mysql-connector-j-9.7.0.jar"

echo "=== Transfer of Summary — Email Dispatcher ==="
echo ""

# Check for mail capability
if command -v sendmail &>/dev/null; then
    echo "  ✔  sendmail found: $(which sendmail)"
elif command -v mail &>/dev/null; then
    echo "  ✔  mailx found: $(which mail)"
else
    echo "  ✗  No mail agent found. Installing mailutils + postfix..."
    if command -v apt-get &>/dev/null; then
        sudo DEBIAN_FRONTEND=noninteractive apt-get install -y mailutils postfix
        echo "  ✔  mailutils + postfix installed."
    else
        echo "  ✗  Cannot install mail agent. Install sendmail or mailutils manually."
        exit 1
    fi
fi

echo ""
echo "  Compiling TransferSummaryMailer..."

# Compile if needed
find "$ROOT/source" -name "*.java" ! -path "*/lanterna/*" > /tmp/tsm_files.txt
javac -d "$OUT" --release 25 -cp "$OUT:$JAR" -sourcepath "$ROOT/source" \
    "$ROOT/source/communicator/TransferSummaryMailer.java" 2>/dev/null || true

echo "  Running mailer..."
echo ""

# Run the mailer
java -cp "$OUT:$JAR" communicator.TransferSummaryMailer 2>&1

echo ""
echo "=== Transfer of Summary dispatch complete ==="
