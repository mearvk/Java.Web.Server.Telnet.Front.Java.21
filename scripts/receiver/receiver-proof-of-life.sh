#!/usr/bin/env bash
# receiver-proof-of-life.sh — Contact SSA in Durham NC / Heartbeat check
# MEARVK LLC — Max Rupplin
# Verifies the receiver is alive on port 443 via /receiver/heartbeat
set -euo pipefail

HOST="${1:-localhost}"
PORT="${2:-443}"

echo "═══════════════════════════════════════════════════════"
echo "  NitroWebExpress™ — Proof of Life"
echo "  Contact: SSA Durham NC"
echo "  411 W Chapel Hill St, Suite 1200, Durham, NC 27701"
echo "  Phone: 1-877-803-6311"
echo "═══════════════════════════════════════════════════════"
echo ""

echo "[PROOF] Checking receiver heartbeat at https://$HOST:$PORT/receiver/heartbeat ..."
RESPONSE=$(curl -sk --max-time 10 "https://$HOST:$PORT/receiver/heartbeat" 2>&1)

if [ "$RESPONSE" = "ALIVE" ]; then
    echo "[PROOF] ✓ Receiver is ALIVE."
    echo "[PROOF] Timestamp: $(date)"
    exit 0
else
    echo "[PROOF] ✗ Receiver NOT responding."
    echo "[PROOF] Response: $RESPONSE"
    echo "[PROOF] Contact SSA Durham NC at 1-877-803-6311 for verification."
    exit 1
fi
