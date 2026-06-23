#!/bin/bash
# Install/Update Bitcoin Core v27.2 on Linux (x86_64)

# Stop on errors
set -e

# Define version and architecture
VERSION="27.2"
ARCH="x86_64-linux-gnu"
FILENAME="bitcoin-${VERSION}-${ARCH}.tar.gz"

# 1. Download the binaries and checksums
echo "Downloading Bitcoin Core v${VERSION}..."
wget -qO "/tmp/${FILENAME}" "https://bitcoincore.org{VERSION}/${FILENAME}"
wget -qO "/tmp/SHA256SUMS" "https://bitcoincore.org{VERSION}/SHA256SUMS"

# 2. Verify file integrity (Security check)
echo "Verifying checksum..."
cd /tmp
sha256sum --ignore-missing --check SHA256SUMS 2>&1 | grep "${FILENAME}" | grep -q "OK"
if [ $? -ne 0 ]; then
    echo "ERROR: Checksum verification failed. The download might be corrupted."
    exit 1
fi
echo "Verification successful!"

# 3. Extract the archive
echo "Extracting files..."
tar -xzf "/tmp/${FILENAME}"

# 4. Install binaries
echo "Installing bitcoind and bitcoin-cli to /usr/local/bin..."
sudo install -m 0755 -o root -g root -t /usr/local/bin "bitcoin-${VERSION}/bin/bitcoind"
sudo install -m 0755 -o root -g root -t /usr/local/bin "bitcoin-${VERSION}/bin/bitcoin-cli"

# 5. Clean up
echo "Cleaning up..."
rm -rf "/tmp/${FILENAME}" "/tmp/SHA256SUMS" "bitcoin-${VERSION}"

echo "Installation complete!"
echo "You can now run: bitcoind -version"
