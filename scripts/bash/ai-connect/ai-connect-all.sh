#!/usr/bin/env bash
# ai-connect-all.sh — Basic connection check to all AI listener ports
HOST="${1:-localhost}"

PORTS=(
    "2000:Strernary Directory"
    "8888:Middle Director (StrategicGoals)"
    "20000:Strernary DJL Inference"
    "49111:AIProctorModule"
    "49201:Japan Signal Server"
    "49202:Russia Signal Server"
    "49203:Mexico Signal Server"
    "49204:Greece International Signal"
    "49205:Italy International Signal"
)

echo "=== NWE AI Port Connectivity Check ==="
echo "Host: $HOST"
echo ""

PASS=0; FAIL=0
for entry in "${PORTS[@]}"; do
    PORT="${entry%%:*}"
    NAME="${entry#*:}"
    if timeout 3 bash -c "echo >/dev/tcp/$HOST/$PORT" 2>/dev/null; then
        echo "[PASS] $PORT — $NAME"
        ((PASS++))
    else
        echo "[FAIL] $PORT — $NAME"
        ((FAIL++))
    fi
done

echo ""
echo "Results: $PASS passed, $FAIL failed (of ${#PORTS[@]} AI ports)"
