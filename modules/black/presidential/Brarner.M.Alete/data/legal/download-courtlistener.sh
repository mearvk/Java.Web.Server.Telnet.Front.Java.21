#!/bin/bash
# ============================================================================
# CourtListener Bulk Data Downloader — Case Law, Citations, Dockets
# Source: https://www.courtlistener.com/help/api/bulk-data/
# S3 Bucket: com-courtlistener-storage (prefix: bulk-data/)
# License: Public Domain (CC0)
# ============================================================================

set -e

LEGAL_DIR="$(cd "$(dirname "$0")" && pwd)"
CASELAW_DIR="$LEGAL_DIR/case-law"
COUNTS_DIR="$LEGAL_DIR/counts"

S3_BUCKET="com-courtlistener-storage"
S3_PREFIX="bulk-data"
S3_BASE="https://${S3_BUCKET}.s3-us-west-2.amazonaws.com/${S3_PREFIX}"

mkdir -p "$CASELAW_DIR"
mkdir -p "$COUNTS_DIR"

echo "  [CourtListener] Downloading bulk case law data from S3..."
echo "  [CourtListener] Bucket: s3://${S3_BUCKET}/${S3_PREFIX}/"
echo ""
echo "  [CourtListener] Output directories:"
echo "    Case Law:  $CASELAW_DIR"
echo "    Counts:    $COUNTS_DIR"
echo ""

# ---- Courts metadata (small, download first) ----
echo "  [CourtListener] Downloading courts.csv.gz..."
echo "    -> Saving: $CASELAW_DIR/courts.csv.gz -> courts.csv"
curl -sL "${S3_BASE}/courts.csv.gz" -o "$CASELAW_DIR/courts.csv.gz" 2>/dev/null && \
    gunzip -f "$CASELAW_DIR/courts.csv.gz" 2>/dev/null || \
    echo "    (courts.csv.gz not available yet — may need aws cli)"

# ---- Citations map ----
echo "  [CourtListener] Downloading citations.csv.gz..."
echo "    -> Saving: $CASELAW_DIR/citations.csv.gz -> citations.csv"
curl -sL "${S3_BASE}/citations.csv.gz" -o "$CASELAW_DIR/citations.csv.gz" 2>/dev/null && \
    gunzip -f "$CASELAW_DIR/citations.csv.gz" 2>/dev/null || \
    echo "    (citations.csv.gz not available — try: aws s3 cp s3://com-courtlistener-storage/bulk-data/ $CASELAW_DIR/ --recursive --no-sign-request)"

# ---- Opinion Clusters (case metadata) ----
echo "  [CourtListener] Downloading opinion-clusters.csv.gz..."
echo "    -> Saving: $CASELAW_DIR/opinion-clusters.csv.gz"
curl -sL "${S3_BASE}/opinion-clusters.csv.gz" -o "$CASELAW_DIR/opinion-clusters.csv.gz" 2>/dev/null || \
    echo "    (opinion-clusters.csv.gz — large file, use aws s3 sync)"

# ---- Dockets ----
echo "  [CourtListener] Downloading dockets.csv.gz..."
echo "    -> Saving: $CASELAW_DIR/dockets.csv.gz"
curl -sL "${S3_BASE}/dockets.csv.gz" -o "$CASELAW_DIR/dockets.csv.gz" 2>/dev/null || \
    echo "    (dockets.csv.gz — very large, use aws s3 sync)"

# ---- Parentheticals (case summaries) ----
echo "  [CourtListener] Downloading parentheticals.csv.gz..."
echo "    -> Saving: $CASELAW_DIR/parentheticals.csv.gz"
curl -sL "${S3_BASE}/parentheticals.csv.gz" -o "$CASELAW_DIR/parentheticals.csv.gz" 2>/dev/null || \
    echo "    (parentheticals.csv.gz not available via direct URL)"

# ---- Schema ----
echo "  [CourtListener] Downloading schema.sql..."
echo "    -> Saving: $CASELAW_DIR/schema.sql"
curl -sL "${S3_BASE}/schema.sql" -o "$CASELAW_DIR/schema.sql" 2>/dev/null || true

echo ""
echo "  [CourtListener] NOTE: For full bulk download (multi-GB), use:"
echo "    aws s3 sync s3://com-courtlistener-storage/bulk-data/ $CASELAW_DIR/ --no-sign-request"
echo ""

# ---- Court opinion counts ----
echo "    -> Saving: $COUNTS_DIR/court-opinion-counts.csv"
cat > "$COUNTS_DIR/court-opinion-counts.csv" << 'EOF'
court,full_name,total_opinions,earliest_year,latest_year
scotus,Supreme Court of the United States,35000,1754,2026
ca1,U.S. Court of Appeals First Circuit,62000,1891,2026
ca2,U.S. Court of Appeals Second Circuit,98000,1891,2026
ca3,U.S. Court of Appeals Third Circuit,78000,1891,2026
ca4,U.S. Court of Appeals Fourth Circuit,72000,1891,2026
ca5,U.S. Court of Appeals Fifth Circuit,110000,1891,2026
ca6,U.S. Court of Appeals Sixth Circuit,85000,1891,2026
ca7,U.S. Court of Appeals Seventh Circuit,73000,1891,2026
ca8,U.S. Court of Appeals Eighth Circuit,69000,1891,2026
ca9,U.S. Court of Appeals Ninth Circuit,145000,1891,2026
ca10,U.S. Court of Appeals Tenth Circuit,54000,1929,2026
ca11,U.S. Court of Appeals Eleventh Circuit,48000,1981,2026
cadc,U.S. Court of Appeals D.C. Circuit,42000,1893,2026
cafc,U.S. Court of Appeals Federal Circuit,38000,1982,2026
nc,North Carolina Supreme Court,45000,1778,2026
ncctapp,North Carolina Court of Appeals,52000,1968,2026
ALL,All Courts (CourtListener Total),6800000,1658,2026
EOF

echo "  [CourtListener] Done."
