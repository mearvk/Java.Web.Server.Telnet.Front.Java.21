#!/usr/bin/env bash
# nwe-install.sh — NitroWebExpress installer
# Compiles source (if needed), stages classes to out/, chmod's scripts.
# Usage: bash bash/nwe-install.sh [--force]   (--force recompiles even if up-to-date)

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/source"
OUT="$ROOT/out"
JAR="$ROOT/jars/mysql/mysql-connector-j-9.7.0.jar"
FORCE=0
[[ "${1:-}" == "--force" ]] && FORCE=1

echo "=== NitroWebExpress Installer ==="
echo "ROOT : $ROOT"
echo "SRC  : $SRC"
echo "OUT  : $OUT"
echo ""

# ── 1. chmod all scripts ──────────────────────────────────────────────────────
echo "[1/3] Setting executable permissions on scripts..."
find "$ROOT/bash"    -name "*.sh" -exec chmod +x {} \;
find "$ROOT/scripts" -name "*.sh" -exec chmod +x {} \;
echo "      Done."

# ── 2. Compile if needed ──────────────────────────────────────────────────────
echo "[2/3] Checking compilation status..."

# Collect all .java source files
mapfile -t SOURCES < <(find "$SRC" -name "*.java" | sort)

if [[ ${#SOURCES[@]} -eq 0 ]]; then
    echo "      No .java files found under $SRC — nothing to compile."
else
    NEEDS_COMPILE=$FORCE

    if [[ $NEEDS_COMPILE -eq 0 ]]; then
        # Check if any .java is newer than its corresponding .class in out/
        for java_file in "${SOURCES[@]}"; do
            rel="${java_file#$SRC/}"
            class_file="$OUT/${rel%.java}.class"
            if [[ ! -f "$class_file" || "$java_file" -nt "$class_file" ]]; then
                NEEDS_COMPILE=1
                break
            fi
        done
    fi

    if [[ $NEEDS_COMPILE -eq 1 ]]; then
        echo "      Compiling ${#SOURCES[@]} source files..."
        mkdir -p "$OUT"

        # Build source-path list for javac
        SOURCE_LIST=$(mktemp)
        printf '%s\n' "${SOURCES[@]}" > "$SOURCE_LIST"

        javac \
            --release 21 \
            -cp "$OUT:$JAR" \
            -sourcepath "$SRC" \
            -d "$OUT" \
            "@$SOURCE_LIST"

        rm -f "$SOURCE_LIST"
        echo "      Compilation successful."
    else
        echo "      All classes are up-to-date — skipping compilation. (use --force to recompile)"
    fi
fi

# ── 3. Move any .class files left in source/ into out/ ────────────────────────
echo "[3/3] Staging any stray .class files from source/ to out/..."
MOVED=0
while IFS= read -r -d '' class_file; do
    rel="${class_file#$SRC/}"
    dest="$OUT/$rel"
    mkdir -p "$(dirname "$dest")"
    mv "$class_file" "$dest"
    MOVED=$((MOVED + 1))
done < <(find "$SRC" -name "*.class" -print0)
echo "      Moved $MOVED file(s)."

# ── 4. ClamAV install (Linux only) ───────────────────────────────────────────
if [[ "$(uname -s)" == "Linux" ]]; then
    echo "[4/4] Checking ClamAV..."
    if command -v clamscan &>/dev/null; then
        echo "      ClamAV already installed: $(clamscan --version 2>&1 | head -1)"
    else
        if command -v apt-get &>/dev/null; then
            echo "      Installing ClamAV via apt-get (requires sudo)..."
            sudo apt-get install -y clamav clamav-daemon
            sudo systemctl enable clamav-freshclam || true
            sudo systemctl start  clamav-freshclam || true
            echo "      ClamAV installed and freshclam service started."
        elif command -v yum &>/dev/null; then
            echo "      Installing ClamAV via yum (requires sudo)..."
            sudo yum install -y clamav clamav-update
            sudo freshclam || true
            echo "      ClamAV installed."
        else
            echo "      WARN: Cannot detect package manager — install ClamAV manually."
        fi
    fi
else
    echo "[4/4] Non-Linux system detected — skipping ClamAV install."
fi

echo ""
echo "=== Install complete. Run: bash scripts/startup.sh ==="
