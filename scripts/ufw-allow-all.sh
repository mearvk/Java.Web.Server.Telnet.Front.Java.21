#!/bin/bash
# Quick UFW allow for all NWE ports
# Installs and enables UFW if not present, then opens all service ports.
# Usage: sudo bash scripts/ufw-allow-all.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/nwe-ports.sh"

echo "═══════════════════════════════════════════════════════════════"
echo " NWE — Open All Firewall Ports"
echo " Ports: ${#NWE_PORTS[@]}"
echo "═══════════════════════════════════════════════════════════════"
echo ""

nwe_ensure_ufw
echo ""
nwe_open_ports

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo " Done. UFW status:"
sudo ufw status numbered 2>/dev/null | head -5
echo "═══════════════════════════════════════════════════════════════"
