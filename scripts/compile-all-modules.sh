#!/usr/bin/env bash
# scripts/compile-all-modules.sh — Compile all NWE modules.
# Location-independent: safe to invoke from any working directory.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd -P)"
OUT="$ROOT/out"
TMP_ROOT="${TMPDIR:-/tmp}"

[[ -f "$ROOT/scripts/print-descriptor.sh" ]] && source "$ROOT/scripts/print-descriptor.sh" || true
command -v javac >/dev/null 2>&1 || { echo "[FAIL] javac not found. Install/use Java 21." >&2; exit 1; }

mkdir -p "$OUT"

CP="$OUT:$ROOT/jars/mysql/mysql-connector-j-9.7.0.jar:$ROOT/jars/lanterna-3.1.5.jar"
if [[ -d "$ROOT/jars/djl" ]]; then
    while IFS= read -r -d '' jar; do CP+="${CP:+:}$jar"; done < <(find "$ROOT/jars/djl" -type f -name '*.jar' -print0)
fi
if [[ -d "$ROOT/jars/jpcap" ]]; then
    while IFS= read -r -d '' jar; do CP+="${CP:+:}$jar"; done < <(find "$ROOT/jars/jpcap" -type f -name '*.jar' -print0)
fi

SOURCE_PATHS="$ROOT/source"
for module in \
    "$ROOT/modules/fbi/source" "$ROOT/modules/cia/source" "$ROOT/modules/nsa/source" \
    "$ROOT/modules/duke/source" "$ROOT/modules/library/source" "$ROOT/modules/gray/source" \
    "$ROOT/modules/gray.a85/source" "$ROOT/modules/red/Futures/source" "$ROOT/modules/vietnam/source" \
    "$ROOT/modules/emeter/source" "$ROOT/modules/spectrum-tandem/source" "$ROOT/modules/chat/source" \
    "$ROOT/modules/uncw/source"; do
    [[ -d "$module" ]] && SOURCE_PATHS="$SOURCE_PATHS:$module"
done

compile_list() {
    local label="$1" list_file="$2" source_path="$3"
    if [[ ! -s "$list_file" ]]; then
        echo "  SKIP (no source found)"
        rm -f "$list_file"
        return 0
    fi
    javac --release 21 -d "$OUT" -cp "$CP" -sourcepath "$source_path" "@$list_file"
    rm -f "$list_file"
    echo "  OK"
}

echo "═══════════════════════════════════════════════════════════════"
echo " NWE — Compile All Modules"
echo "═══════════════════════════════════════════════════════════════"
echo "ROOT: $ROOT"
echo ""

list="$TMP_ROOT/nwe-core.$$.txt"
find "$ROOT/source" -type f -name '*.java' -print > "$list"
echo "[1/8] Core sources (source/)..."
compile_list core "$list" "$SOURCE_PATHS"

echo "[2/8] FBI/CIA/NSA, Duke, Library, Vietnam, Emeter, SpectrumTandem, Chat, UNCW..."
for entry in \
    "$ROOT/modules/fbi/source/CaliforniaFBIServer.java" \
    "$ROOT/modules/cia/source/CaliforniaCIAServer.java" \
    "$ROOT/modules/nsa/source/CaliforniaNSAServer.java" \
    "$ROOT/modules/duke/source/DukeUniversityServer.java" \
    "$ROOT/modules/library/source/StanfordLibraryServer.java" \
    "$ROOT/modules/vietnam/source/VietnamServer.java" \
    "$ROOT/modules/emeter/source/EmeterServer.java" \
    "$ROOT/modules/spectrum-tandem/source/SpectrumTandemServer.java" \
    "$ROOT/modules/spectrum-tandem/source/SpectrumTandemProtocolHandler.java" \
    "$ROOT/modules/chat/source/ChatServer.java" \
    "$ROOT/modules/chat/source/ChatProtocolHandler.java" \
    "$ROOT/modules/uncw/source/UNCWServer.java"; do
    [[ -f "$entry" ]] || { echo "  [SKIP] $entry"; continue; }
    javac --release 21 -d "$OUT" -cp "$CP" -sourcepath "$SOURCE_PATHS" "$entry"
done
echo "  OK"

echo "[3/8] Gray Port Registry + Gray85..."
for entry in \
    "$ROOT/modules/gray/source/PortBindingGate.java" \
    "$ROOT/modules/gray/source/GrayPortRegistryServer.java" \
    "$ROOT/modules/gray.a85/source/PortBindingGate85.java" \
    "$ROOT/modules/gray.a85/source/Gray85PortRegistryServer.java"; do
    [[ -f "$entry" ]] && javac --release 21 -d "$OUT" -cp "$CP" -sourcepath "$SOURCE_PATHS" "$entry"
done
echo "  OK"

echo "[4/8] Futures (DemocraticAIServer)..."
list="$TMP_ROOT/nwe-futures.$$.txt"
find "$ROOT/modules/red/Futures/source" -type f -name '*.java' -print > "$list" 2>/dev/null || true
compile_list futures "$list" "$SOURCE_PATHS:$ROOT/modules/red/Futures/source"

echo "[5/8] StrernaryDirectory (port 2000)..."
if [[ -f "$ROOT/source/strernary/StrernaryDirectoryServer.java" ]]; then
    javac --release 21 -d "$OUT" -cp "$CP" -sourcepath "$SOURCE_PATHS" "$ROOT/source/strernary/StrernaryDirectoryServer.java"
    echo "  OK"
else
    echo "  SKIP (source not found)"
fi

echo "[6/8] AE6E66 (UK Parliament)..."
list="$TMP_ROOT/nwe-ae6e66.$$.txt"
find "$ROOT/modules/AE6E66/source" -type f -name '*.java' -print > "$list" 2>/dev/null || true
compile_list ae6e66 "$list" "$SOURCE_PATHS:$ROOT/modules/AE6E66/source"

echo "[7/8] Green.Durham.Grass.and.Herb (GDGH)..."
list="$TMP_ROOT/nwe-gdgh.$$.txt"
find "$ROOT/modules/Green.Durham.Grass.and.Herb/source" -type f -name '*.java' -print > "$list" 2>/dev/null || true
compile_list gdgh "$list" "$SOURCE_PATHS:$ROOT/modules/Green.Durham.Grass.and.Herb/source"

echo "[8/8] Verifying key classes..."
MISSING=0
for cls in \
    Main.class source/CaliforniaFBIServer.class source/CaliforniaCIAServer.class \
    source/CaliforniaNSAServer.class source/DukeUniversityServer.class \
    source/StanfordLibraryServer.class modules/gray/source/GrayPortRegistryServer.class \
    modules/gray/a85/source/Gray85PortRegistryServer.class source/AE6E66Main.class \
    strernary/StrernaryDirectoryServer.class; do
    if [[ ! -f "$OUT/$cls" ]]; then
        echo "  [MISSING] $cls"
        MISSING=$((MISSING + 1))
    fi
done

if (( MISSING != 0 )); then
    echo "[FAIL] $MISSING key compiled classes are missing." >&2
    exit 1
fi

echo "  All key classes present."
echo ""
echo "═══════════════════════════════════════════════════════════════"
echo " Compilation complete."
echo "═══════════════════════════════════════════════════════════════"
