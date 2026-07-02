#!/bin/bash
# ============================================================================
# BMA Legal Data Downloader — Main Entry Point
# Downloads US statutory law, case law, precedent, and law counts
# Sources: GovInfo.gov, CourtListener, Caselaw Access Project (Harvard)
# ============================================================================

set -e

LEGAL_DIR="$(cd "$(dirname "$0")" && pwd)"
echo "=== BMA Legal Data Downloader ==="
echo "Target directory: $LEGAL_DIR"
echo ""
echo "Documents will be saved to:"
echo "  US Code (statutory law):     $LEGAL_DIR/us-code/"
echo "    - uscode-collection.json     (GovInfo API USC collection index)"
echo "    - uscode-bulk-index.html     (Bulk XML download page)"
echo "    - uscode-summary.csv         (All 54 titles with section counts)"
echo "  Public Laws:                 $LEGAL_DIR/public-laws/"
echo "    - plaw-119-index.json        (119th Congress public laws)"
echo "  Statutes at Large:           $LEGAL_DIR/statutes-at-large/"
echo "    - statute-collection.json    (Statutes collection index)"
echo "  CFR:                         $LEGAL_DIR/cfr/"
echo "    - cfr-collection.json        (Code of Federal Regulations index)"
echo "  Case Law:                    $LEGAL_DIR/case-law/"
echo "    - courts.csv                 (Court metadata)"
echo "    - citations.csv              (Citation map — what cites what)"
echo "    - opinion-clusters.csv.gz    (Case opinions & metadata)"
echo "    - dockets.csv.gz             (Docket/case information)"
echo "    - parentheticals.csv.gz      (Court-written case summaries)"
echo "    - schema.sql                 (Database schema for import)"
echo "  Precedent:                   $LEGAL_DIR/precedent/"
echo "    - landmark-cases.csv         (24 landmark SCOTUS cases)"
echo "    - marbury-v-madison.json     (Opinion JSON)"
echo "    - brown-v-board.json         (Opinion JSON)"
echo "    - miranda-v-arizona.json     (Opinion JSON)"
echo "  Counts:                      $LEGAL_DIR/counts/"
echo "    - usc-title-counts.csv       (Sections per USC title)"
echo "    - public-law-counts.csv      (Laws enacted per Congress)"
echo "    - court-opinion-counts.csv   (Opinions per court/year)"
echo ""

# ---- Step 1: Download GovInfo data (US Code, Public Laws) ----
echo "[1/3] Downloading GovInfo data (US Code, Public Laws, Statutes)..."
bash "$LEGAL_DIR/download-govinfo.sh"

# ---- Step 2: Download CourtListener bulk case law ----
echo "[2/3] Downloading CourtListener case law data..."
bash "$LEGAL_DIR/download-courtlistener.sh"

# ---- Step 3: Generate law counts and precedent index ----
echo "[3/3] Generating law counts and precedent data..."
bash "$LEGAL_DIR/download-precedent.sh"

echo ""
echo "=== All legal data downloads complete ==="
echo "Directory contents:"
du -sh "$LEGAL_DIR"/*/ 2>/dev/null || true
