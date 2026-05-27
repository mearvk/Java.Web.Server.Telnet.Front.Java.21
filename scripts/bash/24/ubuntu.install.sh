#!/usr/bin/env bash
set -e

# Define version and architecture
VERSION="24.0.1"
ARCH="x86_64-linux-gnu"
TARBALL="bitcoin-${VERSION}-${ARCH}.tar.gz"

# 1. Navigate to /tmp to download files
cd /tmp

# 2. Download Bitcoin Core binaries, checksums, and signatures
echo "Downloading Bitcoin Core v${VERSION}..."
wget https://bitcoincore.org/bin/bitcoin-core-${VERSION}/${TARBALL}
wget https://bitcoincore.org/bin/bitcoin-core-${VERSION}/SHA256SUMS
wget https://bitcoincore.org/bin/bitcoin-core-${VERSION}/SHA256SUMS.asc

# 3. Verify file integrity (Optional but recommended)
echo "Verifying checksums..."
sha256sum --ignore-missing --check SHA256SUMS

# 4. Extract the tarball
echo "Extracting files..."
tar -xzf ${TARBALL}

# 5. Install binaries to /usr/local/bin
echo "Installing bitcoind and bitcoin-cli..."
sudo install -m 0755 -o root -g root -t /usr/local/bin bitcoin-${VERSION}/bin/bitcoind bitcoin-${VERSION}/bin/bitcoin-cli

# 6. Clean up
echo "Cleaning up installation files..."
rm -rf bitcoin-${VERSION} ${TARBALL} SHA256SUMS SHA256SUMS.asc

echo "Installation complete!"
bitcoind --version