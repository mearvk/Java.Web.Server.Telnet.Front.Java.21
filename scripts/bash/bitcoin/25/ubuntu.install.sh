#!/bin/bash
set -e

# Configuration
VERSION="25.2"
ARCH="x86_64-linux-gnu"
TARBALL="bitcoin-${VERSION}-${ARCH}.tar.gz"
DOWNLOAD_URL="https://bitcoincore.org{VERSION}/${TARBALL}"
CHECKSUM_URL="https://bitcoincore.org{VERSION}/SHA256SUMS"

# 1. Install dependencies
echo "Installing dependencies..."
apt-get update && apt-get install -y wget curl tar gzip gnupg

# 2. Download Bitcoin Core and Checksums
cd /tmp
echo "Downloading Bitcoin Core v${VERSION}..."
wget -q "$DOWNLOAD_URL"
wget -q "$CHECKSUM_URL"

# 3. Verify Checksums
echo "Verifying file integrity..."
# Extract the specific SHA256 for our tarball and verify
EXPECTED_SHA=$(grep "$TARBALL" SHA256SUMS | awk '{print $1}')
ACTUAL_SHA=$(sha256sum "$TARBALL" | awk '{print $1}')

if [ "$EXPECTED_SHA" != "$ACTUAL_SHA" ]; then
    echo "ERROR: Checksum verification failed. Aborting installation."
    exit 1
fi
echo "Checksum verified successfully."

# 4. Extract and Install
echo "Extracting binaries..."
tar -xzf "$TARBALL"

# Move bitcoind and bitcoin-cli to the global path
echo "Installing bitcoind and bitcoin-cli to /usr/local/bin..."
install -m 0755 -o root -g root -t /usr/local/bin "bitcoin-${VERSION}/bin/bitcoind" "bitcoin-${VERSION}/bin/bitcoin-cli"

# 5. Cleanup
echo "Cleaning up..."
rm -rf "/tmp/bitcoin-${VERSION}" "/tmp/$TARBALL" "/tmp/SHA256SUMS"

# 6. Verify Installation
echo "Installation complete!"
bitcoind --version
