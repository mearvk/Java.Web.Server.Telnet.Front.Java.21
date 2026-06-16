#!/usr/bin/env bash
# run.sh — Starts the NWE Module Installer standalone JAR on port 8888
# Usage: bash standalone/run.sh

set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
JAR="$DIR/nwe-module-installer.jar"

if [[ ! -f "$JAR" ]]; then
    echo "JAR not found. Building first..."
    bash "$DIR/build.sh"
fi

echo "Starting NWE Module Installer on port 8888..."
java -jar "$JAR"
