#!/usr/bin/env bash
set -e

# Define variables for Bitcoin Core v29.2
BITCOIN_VERSION="29.2"
ARCH="x86_64-linux-gnu"
BITCOIN_TAR="bitcoin-${BITCOIN_VERSION}-${ARCH}.tar.gz"
DOWNLOAD_URL="https://bitcoincore.org{BITCOIN_VERSION}/${BITCOIN_TAR}"
CHECKSUM_URL="https://bitcoincore.org{BITCOIN_VERSION}/SHA256SUMS"

echo "=== Installing Bitcoin Core ${BITCOIN_VERSION} ==="

# 1. Install required tools
sudo apt-get update
sudo apt-get install -y wget curl gnupg

# 2. Download Bitcoin Core binaries and the official checksums
cd /tmp
echo "Downloading Bitcoin binaries..."
wget -qO "${BITCOIN_TAR}" "${DOWNLOAD_URL}"
wget -qO "SHA256SUMS" "${CHECKSUM_URL}"

# 3. Verify file integrity using SHA256SUMS
echo "Verifying checksums..."
sha256sum --ignore-missing --check SHA256SUMS > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "ERROR: Checksum verification failed!"
    exit 1
fi
echo "Checksum verification OK."

# 4. Extract and Install
echo "Extracting files..."
tar -xzf "${BITCOIN_TAR}"
cd "bitcoin-${BITCOIN_VERSION}"

echo "Installing bitcoind and bitcoin-cli to /usr/local/bin..."
sudo install -m 0755 bin/bitcoind /usr/local/bin/bitcoind
sudo install -m 0755 bin/bitcoin-cli /usr/local/bin/bitcoin-cli
sudo install -m 0755 bin/bitcoin-tx /usr/local/bin/bitcoin-tx

# 5. Clean up
cd /tmp
rm -rf "${BITCOIN_TAR}" SHA256SUMS "bitcoin-${BITCOIN_VERSION}"

echo "=== Installation Successful ==="
echo "You can now run: bitcoind -version"
