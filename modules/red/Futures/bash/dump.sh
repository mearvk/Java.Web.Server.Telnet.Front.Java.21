#!/bin/bash
# ============================================================
# MySQL DUMP — Democratic ProFront National 1.0
# Dumps all data from democratic_d500 database
# Installer ID: MEARVK LLC - Max Rupplin
# ============================================================
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DUMP_DIR="$PROJECT_DIR/dumps"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DUMP_FILE="$DUMP_DIR/democratic_d500_$TIMESTAMP.sql"

mkdir -p "$DUMP_DIR"

echo "[dump] Dumping democratic_d500 database..."

mysqldump --databases democratic_d500 \
    --add-drop-table \
    --routines \
    --triggers \
    --single-transaction \
    --result-file="$DUMP_FILE" \
    2>&1

if [ $? -eq 0 ]; then
    SIZE=$(du -h "$DUMP_FILE" | cut -f1)
    echo "[dump] Success: $DUMP_FILE ($SIZE)"
else
    echo "[dump] Failed — trying with sudo..."
    sudo mysqldump --databases democratic_d500 \
        --add-drop-table \
        --routines \
        --triggers \
        --single-transaction \
        --result-file="$DUMP_FILE" \
        2>&1
    if [ $? -eq 0 ]; then
        SIZE=$(du -h "$DUMP_FILE" | cut -f1)
        echo "[dump] Success: $DUMP_FILE ($SIZE)"
    else
        echo "[dump] FAILED — check MySQL credentials."
        exit 1
    fi
fi

echo "[dump] Installer ID: MEARVK LLC - Max Rupplin"
