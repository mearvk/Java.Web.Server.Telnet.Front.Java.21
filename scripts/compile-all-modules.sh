#!/bin/bash
# scripts/compile-all-modules.sh — Compile ALL NWE modules (core + external)
# Usage: bash scripts/compile-all-modules.sh
set -e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/out"
mkdir -p "$OUT"

DJL_CP=$(find "$ROOT/jars/djl" -name "*.jar" 2>/dev/null | tr '\n' ':')
CP="$OUT:$ROOT/jars/mysql/mysql-connector-j-9.7.0.jar:${DJL_CP}$ROOT/jars/lanterna-3.1.5.jar"

echo "═══════════════════════════════════════════════════════════════"
echo " NWE — Compile All Modules"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# 1. Core source/
echo "[1/6] Core sources (source/)..."
find "$ROOT/source" -name "*.java" > /tmp/nwe-core.txt
javac -d "$OUT" -cp "$CP" -sourcepath "$ROOT/source" @/tmp/nwe-core.txt 2>&1 | grep -i error || echo "  OK"
rm -f /tmp/nwe-core.txt

# 2. California/Duke/Stanford
echo "[2/6] California FBI/CIA/NSA, Duke, Stanford..."
javac -d "$OUT" -cp "$CP" \
  -sourcepath "$ROOT/source:$ROOT/california/fbi/source:$ROOT/california/cia/source:$ROOT/california/nsa/source:$ROOT/north/carolina/duke/source:$ROOT/north/carolina/library/source" \
  "$ROOT/california/fbi/source/CaliforniaFBIServer.java" \
  "$ROOT/california/cia/source/CaliforniaCIAServer.java" \
  "$ROOT/california/nsa/source/CaliforniaNSAServer.java" \
  "$ROOT/north/carolina/duke/source/DukeUniversityServer.java" \
  "$ROOT/north/carolina/library/source/StanfordLibraryServer.java" 2>&1 | grep -i error || echo "  OK"

# 3. Gray registries
echo "[3/6] Gray Port Registry + Gray85..."
javac -d "$OUT" -cp "$CP" \
  -sourcepath "$ROOT/source:$ROOT/modules/gray/source:$ROOT/modules/gray.a85/source" \
  "$ROOT/modules/gray/source/PortBindingGate.java" \
  "$ROOT/modules/gray/source/GrayPortRegistryServer.java" \
  "$ROOT/modules/gray.a85/source/PortBindingGate85.java" \
  "$ROOT/modules/gray.a85/source/Gray85PortRegistryServer.java" 2>&1 | grep -i error || echo "  OK"

# 4. Futures (DemocraticAIServer)
echo "[4/6] Futures (DemocraticAIServer)..."
find "$ROOT/modules/black/red/Futures/source" -name "*.java" > /tmp/futures.txt 2>/dev/null
if [ -s /tmp/futures.txt ]; then
    javac -d "$OUT" -cp "$CP" -sourcepath "$ROOT/source:$ROOT/modules/black/red/Futures/source" @/tmp/futures.txt 2>&1 | grep -i error || echo "  OK"
else
    echo "  SKIP (no source found)"
fi
rm -f /tmp/futures.txt

# 5. StrernaryDirectory
echo "[5/6] StrernaryDirectory (port 2000)..."
javac -d "$OUT" -cp "$CP" -sourcepath "$ROOT/source" \
  "$ROOT/source/strernary/StrernaryDirectoryServer.java" 2>&1 | grep -i error || echo "  OK"

# 6. Verify key classes exist
echo "[6/6] Verifying..."
MISSING=0
for cls in Main.class source/CaliforniaFBIServer.class source/CaliforniaCIAServer.class \
           source/CaliforniaNSAServer.class source/DukeUniversityServer.class \
           source/StanfordLibraryServer.class modules/gray/source/GrayPortRegistryServer.class \
           modules/gray/a85/source/Gray85PortRegistryServer.class \
           strernary/StrernaryDirectoryServer.class; do
    if [ ! -f "$OUT/$cls" ]; then
        echo "  [MISSING] $cls"
        MISSING=$((MISSING + 1))
    fi
done
if [ $MISSING -eq 0 ]; then
    echo "  All key classes present."
fi

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo " Compilation complete. Restart with:"
echo "   bash scripts/start-backend-modules.sh --stop"
echo "   bash scripts/start-backend-modules.sh"
echo "═══════════════════════════════════════════════════════════════"
