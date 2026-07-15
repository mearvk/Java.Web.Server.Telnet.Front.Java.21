#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# NitroWebExpress™ — black-belt Backend Startup
# black-belt is a webapp-only module — no TCP backend server.
# This script exits cleanly so orchestration scripts do not report a failure.
# Usage: bash start-backend.sh
# ═══════════════════════════════════════════════════════════════════════════════
echo ""
echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║  black-belt — Backend Startup                                             ║"
echo "║  Module type: webapp-only (no TCP backend)                                ║"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo ""
echo "  [--] black-belt has no backend TCP server — skipping."
echo "       To start the webapp:  bash start.sh [tomcat_home]"
echo "       System status:        bash ../../scripts/status.sh"
echo ""
exit 0
