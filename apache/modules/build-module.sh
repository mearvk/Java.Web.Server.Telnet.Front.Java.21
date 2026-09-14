#!/usr/bin/env bash
# build-module.sh — Builds and installs the NWE Apache module
# Requires: apache2-dev, libcurl4-openssl-dev, libssl-dev
# Usage: sudo bash apache/modules/build-module.sh

set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== Building mod_nwe_key Apache Module ==="

# Install deps if missing
if ! command -v apxs &>/dev/null && ! command -v apxs2 &>/dev/null; then
    echo "[1/4] Installing apache2-dev..."
    apt-get install -y apache2-dev libcurl4-openssl-dev libssl-dev
fi

APXS=$(command -v apxs2 2>/dev/null || command -v apxs)

echo "[2/4] Compiling module..."
$APXS -i -a -c "$DIR/mod_nwe_key.c" -lcurl -lcrypto

echo "[3/4] Adding handler configuration..."
cat > /etc/apache2/conf-available/nwe-key.conf << 'EOF'
<Location /nwe-key-listener>
    SetHandler nwe-key-handler
</Location>
EOF
a2enconf nwe-key 2>/dev/null || true

echo "[4/4] Restarting Apache..."
systemctl restart apache2

echo ""
echo "  ✔  mod_nwe_key installed and active."
echo "  Endpoints:"
echo "    POST /nwe-key-listener/handshake  — send public.key"
echo "    POST /nwe-key-listener/install    — send JAR (after handshake)"
echo ""
echo "=== Done ==="
