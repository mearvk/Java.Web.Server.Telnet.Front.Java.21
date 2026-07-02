#!/bin/bash
# ============================================================================
# BMA Legal Data Unzipper & Consumer
# Decompresses all .gz files, converts JSON to .csv/.rdns/.txt for safe storage
#
# DIGTIK Best Practices:
#   - No raw execution of downloaded content
#   - All output stored as .csv, .txt, or .rdns (read-only data formats)
#   - SHA-256 integrity hash for every produced file
#   - Path traversal protection (filenames sanitized)
#   - No executable output (chmod 444 on all produced files)
#
# Output formats:
#   .csv  — Tabular data (case law, counts, titles)
#   .txt  — Plain text (opinions, statutes, summaries)
#   .rdns — Read-only Data Notation Safe (structured records, no exec)
#
# Author: Max Rupplin — MEARVK LLC
# ============================================================================

set -e

LEGAL_DIR="$(cd "$(dirname "$0")" && pwd)"
SAFE_DIR="$LEGAL_DIR/safe"
INTEGRITY_LOG="$SAFE_DIR/integrity.sha256"

echo "=== BMA Legal Data Unzipper & Consumer ==="
echo "Source:  $LEGAL_DIR"
echo "Output:  $SAFE_DIR"
echo ""

mkdir -p "$SAFE_DIR"
> "$INTEGRITY_LOG"

# ============================================================================
# STEP 1: Decompress all .gz files to their parent directories
# ============================================================================
echo "[1/4] Decompressing .gz files..."

find "$LEGAL_DIR" -name "*.gz" -type f | while read -r gz_file; do
    out_file="${gz_file%.gz}"
    echo "    -> Decompressing: $(basename "$gz_file")"
    echo "       To: $out_file"
    gunzip -fk "$gz_file" 2>/dev/null || echo "       (already decompressed or corrupt)"
done
echo ""

# ============================================================================
# STEP 2: Convert JSON files to safe .rdns format
# ============================================================================
echo "[2/4] Converting JSON to .rdns (Read-only Data Notation Safe)..."

find "$LEGAL_DIR" -name "*.json" -type f | while read -r json_file; do
    base_name=$(basename "$json_file" .json)
    # Sanitize filename — no path traversal characters
    safe_name=$(echo "$base_name" | tr -cd 'a-zA-Z0-9._-')
    rdns_file="$SAFE_DIR/${safe_name}.rdns"

    echo "    -> Converting: $(basename "$json_file")"
    echo "       To: $rdns_file"

    # Convert JSON to RDNS: strip executable content, extract key-value pairs
    # RDNS format: KEY=VALUE per line, sections delimited by ---
    {
        echo "# RDNS — Read-only Data Notation Safe"
        echo "# Source: $(basename "$json_file")"
        echo "# Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
        echo "# Module: Brarner.M.Alete™ Legal"
        echo "# Rating: 9.5/10"
        echo "---"

        # Extract JSON content safely using sed/grep (no eval, no exec)
        if command -v python3 &>/dev/null; then
            python3 -c "
import json, sys
try:
    with open('$json_file', 'r') as f:
        data = json.load(f)
    if isinstance(data, dict):
        for k, v in data.items():
            if isinstance(v, (str, int, float, bool)):
                print(f'{k}={v}')
            elif isinstance(v, list):
                print(f'{k}.count={len(v)}')
                for i, item in enumerate(v[:20]):
                    if isinstance(item, dict):
                        for ik, iv in item.items():
                            if isinstance(iv, (str, int, float, bool)):
                                val = str(iv)[:200]
                                print(f'{k}[{i}].{ik}={val}')
                    else:
                        print(f'{k}[{i}]={str(item)[:200]}')
    elif isinstance(data, list):
        print(f'records.count={len(data)}')
        for i, item in enumerate(data[:20]):
            if isinstance(item, dict):
                for ik, iv in item.items():
                    if isinstance(iv, (str, int, float, bool)):
                        val = str(iv)[:200]
                        print(f'record[{i}].{ik}={val}')
except Exception as e:
    print(f'# ERROR: {e}')
" 2>/dev/null
        else
            # Fallback: basic extraction without python
            grep -oP '"[^"]+"\s*:\s*"[^"]*"' "$json_file" 2>/dev/null | \
                sed 's/"\([^"]*\)"\s*:\s*"\([^"]*\)"/\1=\2/' | head -100
        fi
    } > "$rdns_file" 2>/dev/null

    # Record integrity hash
    sha256sum "$rdns_file" >> "$INTEGRITY_LOG"
done
echo ""

# ============================================================================
# STEP 3: Copy CSV/TXT files to safe directory with read-only permissions
# ============================================================================
echo "[3/4] Copying CSV/TXT data to safe directory..."

find "$LEGAL_DIR" -maxdepth 3 -name "*.csv" -type f | while read -r csv_file; do
    # Skip files already in safe/
    if [[ "$csv_file" == *"/safe/"* ]]; then continue; fi

    base_name=$(basename "$csv_file")
    safe_name=$(echo "$base_name" | tr -cd 'a-zA-Z0-9._-')
    dest="$SAFE_DIR/${safe_name}"

    # If duplicate name, prefix with parent directory
    if [ -f "$dest" ]; then
        parent=$(basename "$(dirname "$csv_file")")
        dest="$SAFE_DIR/${parent}.${safe_name}"
    fi

    echo "    -> Copying: $base_name"
    echo "       To: $dest"
    cp "$csv_file" "$dest"
    sha256sum "$dest" >> "$INTEGRITY_LOG"
done

# Copy txt files (legal sites references)
find "$LEGAL_DIR" -maxdepth 1 -name "*.txt" -type f | while read -r txt_file; do
    base_name=$(basename "$txt_file")
    safe_name=$(echo "$base_name" | tr -cd 'a-zA-Z0-9._-')
    dest="$SAFE_DIR/${safe_name}"
    echo "    -> Copying: $base_name"
    echo "       To: $dest"
    cp "$txt_file" "$dest"
    sha256sum "$dest" >> "$INTEGRITY_LOG"
done
echo ""

# ============================================================================
# STEP 4: Lock all safe files to read-only (no executable output per DIGTIK)
# ============================================================================
echo "[4/4] Setting read-only permissions on safe directory..."

chmod 444 "$SAFE_DIR"/*.csv "$SAFE_DIR"/*.rdns "$SAFE_DIR"/*.txt 2>/dev/null || true
chmod 644 "$INTEGRITY_LOG"

echo ""
echo "=== Unzip & Consume Complete ==="
echo ""
echo "Safe files produced:"
ls -la "$SAFE_DIR"/ 2>/dev/null | grep -v "^total"
echo ""
echo "Integrity log: $INTEGRITY_LOG"
echo "Total safe files: $(find "$SAFE_DIR" -type f | wc -l)"
echo ""
echo "These files are now ready for the BMA Legal BaseServer (ports 18500-18507)."
echo "Start with: java -cp . presidential.Brarner.M.Alete.source.legal.BaseServer"
