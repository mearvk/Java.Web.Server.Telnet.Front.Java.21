#!/bin/bash
# scripts/compile-all-modules.sh — Compile ALL NWE modules (core + external)
# Compiles .java → .class into out/. Does NOT touch databases, configs, or runtime data.
# Safe to run after every git pull.
# Usage: bash scripts/compile-all-modules.sh
set +e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$ROOT/scripts/print-descriptor.sh" 2>/dev/null || true
OUT="$ROOT/out"
mkdir -p "$OUT"

DJL_CP=$(find "$ROOT/jars/djl" -name "*.jar" 2>/dev/null | tr '\n' ':')
CP="$OUT:$ROOT/jars/mysql/mysql-connector-j-9.7.0.jar:${DJL_CP}$ROOT/jars/lanterna-3.1.5.jar"

echo "═══════════════════════════════════════════════════════════════"
echo " NWE — Compile All Modules"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# 1. Core source/ (includes all sourcepaths so Main.java can resolve external modules)
echo "[1/8] Core sources (source/)..."
find "$ROOT/source" -name "*.java" > /tmp/nwe-core.txt
javac -d "$OUT" -cp "$CP" \
  -sourcepath "$ROOT/source:$ROOT/modules/fbi/source:$ROOT/modules/cia/source:$ROOT/modules/nsa/source:$ROOT/modules/duke/source:$ROOT/modules/library/source:$ROOT/modules/gray/source:$ROOT/modules/gray.a85/source:$ROOT/modules/red/Futures/source" \
  @/tmp/nwe-core.txt 2>&1 | grep -i error || echo "  OK"
rm -f /tmp/nwe-core.txt

# 2. FBI/CIA/NSA, Duke, Library
echo "[2/8] FBI/CIA/NSA, Duke, Library..."
javac -d "$OUT" -cp "$CP" \
  -sourcepath "$ROOT/source:$ROOT/modules/fbi/source:$ROOT/modules/cia/source:$ROOT/modules/nsa/source:$ROOT/modules/duke/source:$ROOT/modules/library/source" \
  "$ROOT/modules/fbi/source/CaliforniaFBIServer.java" \
  "$ROOT/modules/cia/source/CaliforniaCIAServer.java" \
  "$ROOT/modules/nsa/source/CaliforniaNSAServer.java" \
  "$ROOT/modules/duke/source/DukeUniversityServer.java" \
  "$ROOT/modules/library/source/StanfordLibraryServer.java" 2>&1 | grep -i error || echo "  OK"

# 3. Gray registries
echo "[3/8] Gray Port Registry + Gray85..."
javac -d "$OUT" -cp "$CP" \
  -sourcepath "$ROOT/source:$ROOT/modules/gray/source:$ROOT/modules/gray.a85/source" \
  "$ROOT/modules/gray/source/PortBindingGate.java" \
  "$ROOT/modules/gray/source/GrayPortRegistryServer.java" \
  "$ROOT/modules/gray.a85/source/PortBindingGate85.java" \
  "$ROOT/modules/gray.a85/source/Gray85PortRegistryServer.java" 2>&1 | grep -i error || echo "  OK"

# 4. Futures (DemocraticAIServer)
echo "[4/8] Futures (DemocraticAIServer)..."
find "$ROOT/modules/red/Futures/source" -name "*.java" > /tmp/futures.txt 2>/dev/null
if [ -s /tmp/futures.txt ]; then
    javac -d "$OUT" -cp "$CP" -sourcepath "$ROOT/source:$ROOT/modules/red/Futures/source" @/tmp/futures.txt 2>&1 | grep -i error || echo "  OK"
else
    echo "  SKIP (no source found)"
fi
rm -f /tmp/futures.txt

# 5. StrernaryDirectory
echo "[5/8] StrernaryDirectory (port 2000)..."
javac -d "$OUT" -cp "$CP" -sourcepath "$ROOT/source" \
  "$ROOT/source/strernary/StrernaryDirectoryServer.java" 2>&1 | grep -i error || echo "  OK"

# 6. AE6E66
echo "[6/8] AE6E66 (UK Parliament)..."
find "$ROOT/modules/AE6E66/source" -name "*.java" > /tmp/ae6e66.txt 2>/dev/null
if [ -s /tmp/ae6e66.txt ]; then
    javac -d "$OUT" -cp "$CP" -sourcepath "$ROOT/source:$ROOT/modules/AE6E66/source" @/tmp/ae6e66.txt 2>&1 | grep -i error || echo "  OK"
fi
rm -f /tmp/ae6e66.txt

# 7. Green.Durham.Grass.and.Herb (GDGH)
echo "[7/8] Green.Durham.Grass.and.Herb (GDGH)..."
find "$ROOT/modules/Green.Durham.Grass.and.Herb/source" -name "*.java" > /tmp/gdgh.txt 2>/dev/null
if [ -s /tmp/gdgh.txt ]; then
    javac -d "$OUT" -cp "$CP" -sourcepath "$ROOT/source:$ROOT/modules/Green.Durham.Grass.and.Herb/source" @/tmp/gdgh.txt 2>&1 | grep -i error || echo "  OK"
fi
rm -f /tmp/gdgh.txt

# 8. Verify key classes exist
echo "[8/8] Verifying..."
MISSING=0
for cls in Main.class source/CaliforniaFBIServer.class source/CaliforniaCIAServer.class \
           source/CaliforniaNSAServer.class source/DukeUniversityServer.class \
           source/StanfordLibraryServer.class modules/gray/source/GrayPortRegistryServer.class \
           modules/gray/a85/source/Gray85PortRegistryServer.class \
           source/AE6E66Main.class \
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
