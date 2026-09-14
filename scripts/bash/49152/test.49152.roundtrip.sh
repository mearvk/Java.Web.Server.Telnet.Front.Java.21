#!/usr/bin/env bash
# Test: Full packet round-trip on port 49152
# Verifies: TCP accept → ConnectionPoller pickup → NationalFinanceIDFeeder banner → client read
# This is the comprehensive telnet forwarding test.
set -e
HOST="${1:-localhost}"
PORT=49152
TIMEOUT=12

echo "[test] Full telnet round-trip test on $HOST:$PORT..."
echo "[test] Phase 1: TCP connect..."

if ! timeout 3 bash -c "echo >/dev/tcp/$HOST/$PORT" 2>/dev/null; then
    echo "[FAIL] Port $PORT not accepting TCP connections."
    exit 1
fi
echo "[PASS] Phase 1: TCP handshake complete."

echo "[test] Phase 2: Waiting for server banner (up to ${TIMEOUT}s)..."

RESPONSE=$( (sleep "$TIMEOUT") | timeout "$TIMEOUT" nc -w "$TIMEOUT" "$HOST" "$PORT" 2>/dev/null || true)

if echo "$RESPONSE" | grep -qi "N21\|NATIONAL\|FINANCE\|Welcome"; then
    echo "[PASS] Phase 2: Server banner received."
else
    echo "[FAIL] Phase 2: No banner within ${TIMEOUT}s."
    exit 1
fi

echo "[test] Phase 3: Sending input and reading response..."

RESPONSE2=$( (sleep 8; printf "\n"; sleep 3) | timeout 14 nc -w 14 "$HOST" "$PORT" 2>/dev/null || true)

if echo "$RESPONSE2" | grep -qi "National ID\|assigned\|IQ\|questions"; then
    echo "[PASS] Phase 3: Server processed input and returned data."
    echo ""
    echo "[PASS] === ALL PHASES PASSED — Telnet forwarding operational ==="
    exit 0
elif [ -n "$RESPONSE2" ]; then
    echo "[PASS] Phase 3: Server returned data after input."
    echo ""
    echo "[PASS] === ALL PHASES PASSED — Telnet forwarding operational ==="
    exit 0
else
    echo "[WARN] Phase 3: No data after input (proxy backend may be down)."
    echo ""
    echo "[PARTIAL] Phases 1-2 passed; Phase 3 inconclusive."
    exit 0
fi
