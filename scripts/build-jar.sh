#!/usr/bin/env bash
# build-jar.sh — Build a runnable fat JAR for NitroWebExpress quick deployment.
# The script is location-independent: it may be invoked from any working directory.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd -P)"
SRC="$ROOT/source"
OUT="$ROOT/out"
JAR_OUT="$ROOT/nwe.jar"
MYSQL_JAR="$ROOT/jars/mysql/mysql-connector-j-9.7.0.jar"
LANTERNA_JAR="$ROOT/jars/lanterna-3.1.5.jar"
DJL_DIR="$ROOT/jars/djl"
JPCAP_DIR="$ROOT/jars/jpcap"

require_command() {
    command -v "$1" >/dev/null 2>&1 || {
        echo "[FAIL] Required command not found: $1" >&2
        exit 1
    }
}

require_command javac
require_command jar
require_command unzip

[[ -d "$SRC" ]] || { echo "[FAIL] Source directory missing: $SRC" >&2; exit 1; }
[[ -f "$MYSQL_JAR" ]] || { echo "[FAIL] Missing dependency: $MYSQL_JAR" >&2; exit 1; }
[[ -f "$LANTERNA_JAR" ]] || { echo "[FAIL] Missing dependency: $LANTERNA_JAR" >&2; exit 1; }

if [[ -n "${JAVA_HOME:-}" && -x "$JAVA_HOME/bin/javac" ]]; then
    export PATH="$JAVA_HOME/bin:$PATH"
fi

CP="$OUT:$MYSQL_JAR:$LANTERNA_JAR"
if [[ -d "$DJL_DIR" ]]; then
    while IFS= read -r -d '' dep; do CP+="${CP:+:}$dep"; done < <(find "$DJL_DIR" -type f -name '*.jar' -print0)
fi
if [[ -d "$JPCAP_DIR" ]]; then
    while IFS= read -r -d '' dep; do CP+="${CP:+:}$dep"; done < <(find "$JPCAP_DIR" -type f -name '*.jar' -print0)
fi

TMP_ROOT="${TMPDIR:-/tmp}"
SOURCE_LIST="$(mktemp "$TMP_ROOT/nwe-sources.XXXXXX")"
STAGING="$(mktemp -d "$TMP_ROOT/nwe-jar-staging.XXXXXX")"
cleanup() { rm -f "$SOURCE_LIST"; rm -rf "$STAGING"; }
trap cleanup EXIT

echo "=== NitroWebExpress — JAR Builder ==="
echo "ROOT: $ROOT"

echo "[1/3] Compiling sources..."
mkdir -p "$OUT"
find "$SRC" -type f -name '*.java' -print > "$SOURCE_LIST"
[[ -s "$SOURCE_LIST" ]] || { echo "[FAIL] No Java sources found under $SRC" >&2; exit 1; }
javac --release 21 -cp "$CP" -sourcepath "$SRC" -d "$OUT" "@$SOURCE_LIST"
echo "      Compiled."

echo "[2/3] Assembling fat JAR..."
cp -a "$OUT"/. "$STAGING/"

extract_jar() {
    local dep="$1"
    [[ -f "$dep" ]] || return 0
    unzip -qo "$dep" -d "$STAGING" \
        -x 'META-INF/MANIFEST.MF' 'META-INF/*.SF' 'META-INF/*.RSA' 'META-INF/*.DSA'
}

extract_jar "$MYSQL_JAR"
extract_jar "$LANTERNA_JAR"
if [[ -d "$DJL_DIR" ]]; then
    while IFS= read -r -d '' dep; do
        [[ "$dep" == *native* ]] && continue
        extract_jar "$dep"
    done < <(find "$DJL_DIR" -type f -name '*.jar' -print0)
fi
if [[ -d "$JPCAP_DIR" ]]; then
    while IFS= read -r -d '' dep; do extract_jar "$dep"; done < <(find "$JPCAP_DIR" -type f -name '*.jar' -print0)
fi

mkdir -p "$STAGING/META-INF"
cat > "$STAGING/META-INF/MANIFEST.MF" <<'EOF'
Manifest-Version: 1.0
Main-Class: Main
Class-Path: jars/djl/pytorch-native-cpu-2.5.1-linux-x86_64.jar
EOF

echo "[3/3] Creating $JAR_OUT..."
jar cfm "$JAR_OUT" "$STAGING/META-INF/MANIFEST.MF" -C "$STAGING" .
echo "      Done. Size: $(du -h "$JAR_OUT" | cut -f1)"
echo "=== Run with: java -jar nwe.jar ==="
