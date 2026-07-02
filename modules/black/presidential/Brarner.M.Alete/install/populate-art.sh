#!/bin/bash
# Brarner.M.Alete™ — Populate Art Museum Data (Linux/macOS)
# Inserts museum and artwork records into BrarnerScience.art_works
# Usage: bash install/populate-art.sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BMA_ROOT="$(dirname "$SCRIPT_DIR")"
DB_PROPS="$BMA_ROOT/servlets/servlet/src/main/webapp/WEB-INF/db.properties"

echo "═══════════════════════════════════════════════════════════════"
echo " Brarner.M.Alete™ — Populate Art Database"
echo "═══════════════════════════════════════════════════════════════"

if [ ! -f "$DB_PROPS" ]; then echo "[!] db.properties not found."; exit 1; fi

DB_USER=$(grep '^db.user=' "$DB_PROPS" | cut -d= -f2-)
DB_PASS=$(grep '^db.password=' "$DB_PROPS" | cut -d= -f2-)
MYSQL_CMD="mysql -u${DB_USER}"
[ -n "$DB_PASS" ] && MYSQL_CMD="$MYSQL_CMD -p${DB_PASS}"

DATA_CSV="$BMA_ROOT/data/art/art-works.csv"
mkdir -p "$BMA_ROOT/data/art"

if [ -f "$DATA_CSV" ] && [ -s "$DATA_CSV" ]; then
    echo "[*] Loading art data from CSV..."
    $MYSQL_CMD BrarnerScience <<'SQL'
DROP TABLE IF EXISTS art_works;
CREATE TABLE art_works (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    museum_name VARCHAR(255),
    collection VARCHAR(100),
    title VARCHAR(500),
    artist VARCHAR(255),
    year_created VARCHAR(20),
    medium VARCHAR(255),
    INDEX idx_museum (museum_name)
);
SQL
    TMP_SQL="/tmp/bma-art.sql"
    echo "USE BrarnerScience;" > "$TMP_SQL"
    tail -n +2 "$DATA_CSV" | while IFS=',' read -r museum title artist year medium collection; do
        museum="${museum//\'/\\\'}" title="${title//\'/\\\'}" artist="${artist//\'/\\\'}" medium="${medium//\'/\\\'}" collection="${collection//\'/\\\'}"
        echo "INSERT INTO art_works(museum_name,title,artist,year_created,medium,collection) VALUES('$museum','$title','$artist','$year','$medium','$collection');" >> "$TMP_SQL"
    done
    $MYSQL_CMD < "$TMP_SQL"
    rm -f "$TMP_SQL"
    ROWS=$($MYSQL_CMD -N -e "SELECT COUNT(*) FROM BrarnerScience.art_works;")
    echo "[OK] art_works table: $ROWS rows"
else
    # Seed with sample data
    echo "[*] No CSV found — seeding with sample museum data..."
    $MYSQL_CMD BrarnerScience <<'SQL'
INSERT IGNORE INTO art_works (museum_name, title, artist, year_created, medium) VALUES
('Metropolitan Museum of Art','Water Lilies','Claude Monet','1906','Oil on canvas'),
('Metropolitan Museum of Art','Washington Crossing the Delaware','Emanuel Leutze','1851','Oil on canvas'),
('National Gallery of Art','Ginevra de Benci','Leonardo da Vinci','1474','Oil on panel'),
('National Gallery of Art','Girl with a Pearl Earring (copy)','After Vermeer','1665','Oil on canvas'),
('Smithsonian American Art Museum','Among the Sierra Nevada','Albert Bierstadt','1868','Oil on canvas'),
('Smithsonian American Art Museum','Niagara','Frederic Edwin Church','1857','Oil on canvas'),
('Art Institute of Chicago','A Sunday on La Grande Jatte','Georges Seurat','1886','Oil on canvas'),
('Art Institute of Chicago','American Gothic','Grant Wood','1930','Oil on beaverboard'),
('Museum of Modern Art','The Starry Night','Vincent van Gogh','1889','Oil on canvas'),
('Museum of Modern Art','Les Demoiselles d Avignon','Pablo Picasso','1907','Oil on canvas'),
('NC Museum of Art','St. Jerome in His Study','Albrecht Durer','1514','Engraving'),
('NC Museum of Art','Wheatfields','Jacob van Ruisdael','1670','Oil on canvas');
SQL
    ROWS=$($MYSQL_CMD -N -e "SELECT COUNT(*) FROM BrarnerScience.art_works;")
    echo "[OK] art_works seeded: $ROWS rows"
    echo "     Add full data to: $DATA_CSV"
    echo "     Format: museum_name,title,artist,year_created,medium,collection"
fi

echo "═══════════════════════════════════════════════════════════════"
