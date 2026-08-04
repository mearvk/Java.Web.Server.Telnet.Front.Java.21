#!/bin/bash
# install-gateway.sh — Install NWE Gateway (NAT traversal) on home JWSTF instances
#
# Installs:
#   - nwe-gateway daemon (auto-starts, UPnP → relay fallback)
#   - miniupnpc for UPnP/NAT-PMP router configuration
#   - Configuration at /etc/nwe/gateway.conf
#   - Systemd service (auto-start after NWE)
#
# Usage: sudo bash install-gateway.sh
#
# Copyright (C) 2026 MEARVK LLC

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Installing NWE Gateway (NAT Traversal) ==="

# Install dependencies
if command -v apt-get >/dev/null 2>&1; then
    apt-get install -y --no-install-recommends miniupnpc openssh-client socat curl 2>/dev/null || true
fi

# Install gateway binary
install -m 755 "$SCRIPT_DIR/nwe-gateway" /usr/local/bin/nwe-gateway
echo "  ✓ nwe-gateway installed to /usr/local/bin/"

# Install configuration
mkdir -p /etc/nwe
if [ ! -f /etc/nwe/gateway.conf ]; then
    install -m 644 "$SCRIPT_DIR/gateway.conf" /etc/nwe/gateway.conf
    echo "  ✓ Configuration installed to /etc/nwe/gateway.conf"
else
    echo "  • Configuration already exists (preserved)"
fi

# Create state directories
mkdir -p /var/lib/nwe/gateway
mkdir -p /var/log/nwe
echo "  ✓ State directories created"

# Install systemd service
install -m 644 "$SCRIPT_DIR/nwe-gateway.service" /etc/systemd/system/
systemctl daemon-reload 2>/dev/null || true
systemctl enable nwe-gateway.service 2>/dev/null || true
echo "  ✓ Systemd service enabled (starts after NWE)"

echo ""
echo "=== NWE Gateway Installed ==="
echo ""
echo "  The gateway will automatically:"
echo "    1. Try UPnP to open ports on your router (zero-config)"
echo "    2. Fall back to relay tunnel if UPnP unavailable"
echo "    3. Register with the central console"
echo "    4. Health-check every 2 minutes"
echo ""
echo "  Start now:     systemctl start nwe-gateway"
echo "  Check status:  nwe-gateway status"
echo "  View log:      journalctl -u nwe-gateway -f"
echo "  Config:        /etc/nwe/gateway.conf"
echo ""
