#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# NitroWebExpress™ — black-belt Backend Shutdown
# black-belt is a webapp-only module — no TCP backend server.
# This script exits cleanly so orchestration scripts do not report a failure.
# Usage: bash shutdown-backend.sh
# ═══════════════════════════════════════════════════════════════════════════════
echo ""
echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║  black-belt — Backend Shutdown                                            ║"
echo "║  Module type: webapp-only (no TCP backend)                                ║"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo ""
echo "  [--] black-belt has no backend TCP server — nothing to stop."
echo "       To stop the webapp:  bash shutdown.sh [tomcat_home]"
echo ""
exit 0
