#!/usr/bin/env bash
set -e
REPO_URL="https://github.com/mearvk/Java.Web.Server.Telnet.Front.Java.21"
TARGET_DIR="Java.Web.Server.Telnet.Front.Java.21"
BIN_DIR="bin"

if ! command -v git &> /dev/null || ! command -v javac &> /dev/null; then
    echo "Error: git and javac must be installed." >&2
    exit 1
fi

if [ ! -d "$TARGET_DIR" ]; then
    git clone "$REPO_URL"
fi
cd "$TARGET_DIR"
mkdir -p "$BIN_DIR"

find . -name "*.java" > java_files.txt
javac -d "$BIN_DIR" --release 21 @java_files.txt
rm -f java_files.txt
echo "Compilation successful."
