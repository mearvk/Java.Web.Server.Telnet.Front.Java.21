#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════════
# FiduciaryServices™ — Start Backend (TCP Server + ACH Transfer Service)
# Port: 49240
# Installer Tech ID: Max Rupplin
# ═══════════════════════════════════════════════════════════════════════════════════
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NWE_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
CLASS_DIR="$NWE_ROOT/classes"
MODULE_SRC="$SCRIPT_DIR/source"

echo "[*] FiduciaryServices™ — Starting backend..."

# Compile if needed
if [ ! -f "$CLASS_DIR/fiduciary/FiduciaryServicesServer.class" ]; then
    echo "    Compiling FiduciaryServicesServer..."
    mkdir -p "$CLASS_DIR"
    SOURCEPATH="$MODULE_SRC:$NWE_ROOT/source"
    CLASSPATH="$NWE_ROOT/jars/mysql/mysql-connector-j-8.3.0.jar"
    javac -d "$CLASS_DIR" -sourcepath "$SOURCEPATH" -cp "$CLASSPATH" \
        "$MODULE_SRC/FiduciaryServicesServer.java" 2>/dev/null || {
        echo "    [WARN] Compilation skipped (source not yet available)"
    }
fi

# Start server
if [ -f "$CLASS_DIR/fiduciary/FiduciaryServicesServer.class" ]; then
    CLASSPATH="$CLASS_DIR:$NWE_ROOT/jars/mysql/mysql-connector-j-8.3.0.jar"
    java -cp "$CLASSPATH" fiduciary.FiduciaryServicesServer &
    FIDUCIARY_PID=$!
    echo "    PID: $FIDUCIARY_PID"
    echo "    Port: 49240"
    echo "[OK] FiduciaryServices™ backend running."
else
    echo "    [INFO] Backend class not found — webapp-only mode."
    echo "    Run: fiduciary (CLI tool at /usr/local/bin/fiduciary)"
    echo "    Run: ach_transfer --list-platforms"
fi
