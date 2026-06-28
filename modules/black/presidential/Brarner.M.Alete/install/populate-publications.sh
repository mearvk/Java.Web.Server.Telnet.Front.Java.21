#!/bin/bash
# Brarner.M.Alete™ — Populate Publications Data (Linux/macOS)
# Inserts scientific publication records into BrarnerScience.publications
# Usage: bash install/populate-publications.sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BMA_ROOT="$(dirname "$SCRIPT_DIR")"
DB_PROPS="$BMA_ROOT/servlets/servlet/src/main/webapp/WEB-INF/db.properties"

echo "═══════════════════════════════════════════════════════════════"
echo " Brarner.M.Alete™ — Populate Publications Database"
echo "═══════════════════════════════════════════════════════════════"

if [ ! -f "$DB_PROPS" ]; then echo "[!] db.properties not found."; exit 1; fi

DB_USER=$(grep '^db.user=' "$DB_PROPS" | cut -d= -f2-)
DB_PASS=$(grep '^db.password=' "$DB_PROPS" | cut -d= -f2-)
MYSQL_CMD="mysql -u${DB_USER}"
[ -n "$DB_PASS" ] && MYSQL_CMD="$MYSQL_CMD -p${DB_PASS}"

DATA_CSV="$BMA_ROOT/data/publications/publications.csv"
mkdir -p "$BMA_ROOT/data/publications"

if [ -f "$DATA_CSV" ] && [ -s "$DATA_CSV" ]; then
    echo "[*] Loading publications from CSV..."
    $MYSQL_CMD BrarnerScience -e "ALTER TABLE publications ADD COLUMN IF NOT EXISTS abstract_text TEXT AFTER year_published;" 2>/dev/null || true
    $MYSQL_CMD BrarnerScience -e "TRUNCATE TABLE publications;"
    TMP_SQL="/tmp/bma-pubs.sql"
    echo "USE BrarnerScience;" > "$TMP_SQL"
    tail -n +2 "$DATA_CSV" | while IFS=',' read -r source title authors doi year abstract; do
        source="${source//\'/\\\'}" title="${title//\'/\\\'}" authors="${authors//\'/\\\'}" doi="${doi//\'/\\\'}" abstract="${abstract//\'/\\\'}"
        echo "INSERT INTO publications(source_name,title,authors,doi,year_published,abstract_text) VALUES('$source','$title','$authors','$doi','$year','$abstract');" >> "$TMP_SQL"
    done
    $MYSQL_CMD < "$TMP_SQL"
    rm -f "$TMP_SQL"
    ROWS=$($MYSQL_CMD -N -e "SELECT COUNT(*) FROM BrarnerScience.publications;")
    echo "[OK] publications table: $ROWS rows"
else
    echo "[*] No CSV found — seeding with sample publication data..."
    $MYSQL_CMD BrarnerScience <<'SQL'
INSERT IGNORE INTO publications (source_name, title, authors, doi, year_published) VALUES
('Nature','The structure of DNA','Watson JD, Crick FHC','10.1038/171737a0','1953'),
('Nature','CRISPR-Cas9 gene editing','Doudna JA, Charpentier E','10.1038/nature17946','2012'),
('Science','Human Genome Project completion','International HGP Consortium','10.1126/science.1058040','2001'),
('Science','Gravitational waves detected','LIGO Collaboration','10.1126/science.aaf2133','2016'),
('PNAS','Deep learning for protein folding','AlphaFold Team','10.1073/pnas.2024', '2020'),
('Physical Review Letters','Higgs boson discovery','ATLAS Collaboration','10.1103/PhysRevLett.108.111803','2012'),
('The Lancet','mRNA vaccine efficacy','Polack FP et al.','10.1016/S0140-6736(20)32661-1','2020'),
('NCSU Journal','Eigenvalue methods in signal processing','Rupplin M','10.ncsu/eigen.2026','2026'),
('NCSU Journal','Neural network convergence in finite fields','Rupplin M','10.ncsu/nn.2026','2026'),
('arxiv','Quantum computing error correction','Preskill J','10.48550/arXiv.1207.6131','2012');
SQL
    ROWS=$($MYSQL_CMD -N -e "SELECT COUNT(*) FROM BrarnerScience.publications;")
    echo "[OK] publications seeded: $ROWS rows"
    echo "     Add full data to: $DATA_CSV"
    echo "     Format: source_name,title,authors,doi,year_published,abstract_text"
fi

echo "═══════════════════════════════════════════════════════════════"
