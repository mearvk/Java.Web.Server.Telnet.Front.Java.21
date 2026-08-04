#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════════
# FiduciaryServices™ — Shutdown Backend
# Installer Tech ID: Max Rupplin
# ═══════════════════════════════════════════════════════════════════════════════════
echo "[*] FiduciaryServices™ — Shutting down backend..."
PIDS=$(pgrep -f "FiduciaryServicesServer" 2>/dev/null)
if [ -n "$PIDS" ]; then
    kill $PIDS 2>/dev/null
    echo "    Stopped PID(s): $PIDS"
else
    echo "    No running backend found."
fi
echo "[OK] FiduciaryServices™ backend shutdown complete."
