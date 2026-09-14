#!/bin/bash
# NitroWebExpress™ — Generate TLS Keystore
# Creates a self-signed PKCS12 keystore for TLS on all TCP services.
# On next startup, TlsContextProvider will load this and enable TLS.
#
# For production, replace with a Let's Encrypt or CA-signed certificate:
#   openssl pkcs12 -export -in fullchain.pem -inkey privkey.pem -out psychiatry/secrets/server.p12
#
# Usage: bash scripts/generate-tls-keystore.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
KEYSTORE="$PROJECT_ROOT/psychiatry/secrets/server.p12"
PASS="${NWE_KEYSTORE_PASS:-changeit}"

if [ -f "$KEYSTORE" ]; then
    echo "[*] Keystore already exists: $KEYSTORE"
    keytool -list -keystore "$KEYSTORE" -storepass "$PASS" -storetype PKCS12 2>/dev/null | head -7
    echo ""
    read -rp "    Regenerate? (y/N): " REGEN
    if [ "$REGEN" != "y" ] && [ "$REGEN" != "Y" ]; then
        echo "    Keeping existing keystore."
        exit 0
    fi
fi

mkdir -p "$(dirname "$KEYSTORE")"

echo "[*] Generating TLS keystore (EC secp256r1, TLSv1.3)..."
echo "    Output: $KEYSTORE"
echo ""

keytool -genkeypair \
    -alias nwe-server \
    -keyalg EC \
    -groupname secp256r1 \
    -sigalg SHA384withECDSA \
    -validity 365 \
    -storetype PKCS12 \
    -keystore "$KEYSTORE" \
    -storepass "$PASS" \
    -dname "CN=NitroWebExpress, OU=MEARVK LLC, O=MEARVK, L=Durham, ST=NC, C=US"

chmod 600 "$KEYSTORE"

echo ""
echo "[✓] TLS keystore generated successfully"
echo "    Algorithm:  EC secp256r1 (256-bit)"
echo "    Signature:  SHA384withECDSA"
echo "    Validity:   365 days"
echo "    Keystore:   $KEYSTORE (mode 600)"
echo ""
echo "    TLS will activate on next backend startup."
echo "    To set a custom password: export NWE_KEYSTORE_PASS=yourpassword"
echo ""
echo "    For production (Let's Encrypt / CA-signed):"
echo "      openssl pkcs12 -export -in fullchain.pem -inkey privkey.pem \\"
echo "        -out $KEYSTORE -passout pass:\$NWE_KEYSTORE_PASS"
echo ""
