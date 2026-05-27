#!/bin/bash
set -e

# Define version and architecture
VERSION="26.0"
ARCH="x86_64-linux-gnu"

# Create a temporary directory and navigate to it
cd /tmp

# Download the Bitcoin Core tarball, checksums, and signature
echo "Downloading Bitcoin Core v${VERSION}..."
wget https://bitcoincore.org{VERSION}/bitcoin-${VERSION}-${ARCH}.tar.gz
wget https://bitcoincore.org{VERSION}/SHA256SUMS

# Verify the download (Optional but recommended)
# (Ensure your system has sha256sum installed)
sha256sum --ignore-missing -c SHA256SUMS || { echo "Checksum verification failed!"; exit 1; }

# Extract the archive
echo "Extracting files..."
tar -xzf bitcoin-${VERSION}-${ARCH}.tar.gz

# Install the binaries to /usr/local/bin
echo "Installing bitcoind and bitcoin-cli to /usr/local/bin..."
sudo install -m 0755 -o root -g root -t /usr/local/bin bitcoin-${VERSION}/bin/bitcoin-cli bitcoin-${VERSION}/bin/bitcoind

# Clean up
echo "Cleaning up temporary files..."
rm -rf bitcoin-${VERSION} bitcoin-${VERSION}-${ARCH}.tar.gz SHA256SUMS

echo "Installation complete!"
bitcoind --version
