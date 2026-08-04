#!/bin/bash
# ─────────────────────────────────────────────────────────────────────────────
# fetch-jpcap.sh — Download and build Jpcap from source
# Part of NitroWebExpress — Galactic Cherry Marvell Edition 98
#
# Jpcap: Java packet capture library wrapping libpcap
# Source: https://github.com/jpcap/jpcap (LGPL-2.1)
#
# Prerequisites:
#   - libpcap-dev (apt install libpcap-dev)
#   - JDK 21+ with JAVA_HOME set
#   - Maven (or use the included mvnw wrapper)
#
# Output:
#   jpcap-<version>.jar in this directory
#   jpcap-src/ — full source tree
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC_DIR="${SCRIPT_DIR}/jpcap-src"
REPO_URL="https://github.com/jpcap/jpcap.git"
CLONE_DEPTH=10

echo "╔══════════════════════════════════════════════════╗"
echo "║  Jpcap — Java Packet Capture Library Fetch      ║"
echo "║  NitroWebExpress / Galactic Cherry Marvell 98   ║"
echo "╚══════════════════════════════════════════════════╝"
echo

# Check prerequisites
if ! command -v git &>/dev/null; then
    echo "ERROR: git not found. Install git first."
    exit 1
fi

if [ -z "${JAVA_HOME:-}" ]; then
    echo "WARNING: JAVA_HOME not set. Will attempt to find JDK."
    if command -v javac &>/dev/null; then
        JAVA_HOME="$(dirname "$(dirname "$(readlink -f "$(which javac)")")")"
        echo "  Found: ${JAVA_HOME}"
    else
        echo "ERROR: No JDK found. Set JAVA_HOME or install JDK 21+."
        exit 1
    fi
fi

if ! dpkg -l libpcap-dev &>/dev/null 2>&1; then
    echo "NOTE: libpcap-dev may not be installed."
    echo "  Install with: sudo apt install libpcap-dev"
    echo "  Continuing anyway (JAR build may succeed without native)..."
fi

# Clone source
if [ -d "${SRC_DIR}" ]; then
    echo "Source directory exists. Updating..."
    cd "${SRC_DIR}"
    git pull --rebase 2>/dev/null || true
else
    echo "Cloning Jpcap source (depth ${CLONE_DEPTH})..."
    git clone --depth "${CLONE_DEPTH}" "${REPO_URL}" "${SRC_DIR}"
    cd "${SRC_DIR}"
fi

# Build
echo
echo "Building Jpcap..."
if [ -f "./mvnw" ]; then
    chmod +x ./mvnw
    ./mvnw package -DskipTests -q
elif command -v mvn &>/dev/null; then
    mvn package -DskipTests -q
else
    echo "No Maven found. Attempting manual javac compilation..."
    mkdir -p target/classes
    find src/main/java -name "*.java" > /tmp/jpcap-sources.txt
    javac -d target/classes @/tmp/jpcap-sources.txt 2>/dev/null || true
    cd target/classes
    jar cf "${SCRIPT_DIR}/jpcap-manual.jar" .
    cd "${SCRIPT_DIR}"
    echo "Built jpcap-manual.jar (pure-Java classes only, no native)"
    exit 0
fi

# Copy JAR
JAR_FILE=$(find target -name "jpcap-*.jar" -not -name "*sources*" -not -name "*javadoc*" | head -1)
if [ -n "${JAR_FILE}" ]; then
    cp "${JAR_FILE}" "${SCRIPT_DIR}/"
    echo
    echo "SUCCESS: $(basename "${JAR_FILE}") copied to ${SCRIPT_DIR}/"
    echo "  Source: ${SRC_DIR}/"
else
    echo "WARNING: No JAR produced. Check build output."
    exit 1
fi

echo
echo "Done. Add to classpath: jars/jpcap/$(basename "${JAR_FILE}")"
