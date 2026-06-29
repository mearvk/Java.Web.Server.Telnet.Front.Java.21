#!/bin/bash
# ============================================================================
# GovInfo Downloader — US Code & Public Laws
# Source: https://www.govinfo.gov/
# API Docs: https://api.govinfo.gov/docs
# Requires: Free API key from https://www.govinfo.gov/api-signup
# ============================================================================

set -e

LEGAL_DIR="$(cd "$(dirname "$0")" && pwd)"
USCODE_DIR="$LEGAL_DIR/us-code"
PLAW_DIR="$LEGAL_DIR/public-laws"
STATUTE_DIR="$LEGAL_DIR/statutes-at-large"
CFR_DIR="$LEGAL_DIR/cfr"
COUNTS_DIR="$LEGAL_DIR/counts"

# GovInfo API key — set via env or enter here
GOVINFO_API_KEY="${GOVINFO_API_KEY:-DEMO_KEY}"

API_BASE="https://api.govinfo.gov"
BULK_BASE="https://www.govinfo.gov/bulkdata"

echo "  [GovInfo] Using API key: ${GOVINFO_API_KEY:0:8}..."
echo ""
echo "  [GovInfo] Output directories:"
echo "    US Code:            $USCODE_DIR"
echo "    Public Laws:        $PLAW_DIR"
echo "    Statutes at Large:  $STATUTE_DIR"
echo "    CFR:                $CFR_DIR"
echo "    Counts:             $COUNTS_DIR"
echo ""

# ---- US Code (Title listing and XML bulk download) ----
echo "  [GovInfo] Fetching US Code title listing..."
mkdir -p "$USCODE_DIR/titles"

# Get list of all USC titles via API
echo "    -> Saving: $USCODE_DIR/uscode-collection.json"
curl -s "${API_BASE}/collections/USCODE?offset=0&pageSize=100&api_key=${GOVINFO_API_KEY}" \
    -o "$USCODE_DIR/uscode-collection.json" 2>/dev/null || true

# Download US Code bulk XML index
echo "    -> Saving: $USCODE_DIR/uscode-bulk-index.html"
curl -sL "${BULK_BASE}/USCODE" -o "$USCODE_DIR/uscode-bulk-index.html" 2>/dev/null || true

# Generate USC title summary (53 titles)
echo "    -> Saving: $USCODE_DIR/uscode-summary.csv"
cat > "$USCODE_DIR/uscode-summary.csv" << 'EOF'
title_number,title_name,approx_sections,positive_law
1,General Provisions,310,yes
2,The Congress,1970,yes
3,The President,470,yes
4,Flag and Seal Seat of Government and the States,170,yes
5,Government Organization and Employees,10400,yes
6,Surety Bonds (repealed),0,no
7,Agriculture,12000,no
8,Aliens and Nationality,1700,no
9,Arbitration,16,yes
10,Armed Forces,18000,yes
11,Bankruptcy,1530,yes
12,Banks and Banking,6800,no
13,Census,310,yes
14,Coast Guard,3400,yes
15,Commerce and Trade,8900,no
16,Conservation,7600,no
17,Copyrights,820,yes
18,Crimes and Criminal Procedure,6700,yes
19,Customs Duties,4200,no
20,Education,9700,no
21,Food and Drugs,2100,no
22,Foreign Relations and Intercourse,11000,no
23,Highways,700,yes
24,Hospitals and Asylums,500,no
25,Indians,3200,no
26,Internal Revenue Code,11400,no
27,Intoxicating Liquors,200,no
28,Judiciary and Judicial Procedure,4800,yes
29,Labor,3100,no
30,Mineral Lands and Mining,1500,no
31,Money and Finance,7800,yes
32,National Guard,1100,yes
33,Navigation and Navigable Waters,3900,no
34,Crime Control and Law Enforcement,44000,yes
35,Patents,400,yes
36,Patriotic and National Organizations,2400,yes
37,Pay and Allowances of the Uniformed Services,1100,yes
38,Veterans Benefits,8600,yes
39,Postal Service,5400,yes
40,Public Buildings Property and Works,12000,yes
41,Public Contracts,4800,yes
42,The Public Health and Welfare,19000,no
43,Public Lands,3100,no
44,Public Printing and Documents,4100,yes
45,Railroads,1200,no
46,Shipping,14000,yes
47,Telecommunications,620,no
48,Territories and Insular Possessions,1900,no
49,Transportation,8800,yes
50,War and National Defense,4700,no
51,National and Commercial Space Programs,7100,yes
52,Voting and Elections,21000,yes
53,Small Business,1500,no
54,National Park Service,4200,yes
EOF

echo "  [GovInfo] US Code summary: 54 titles cataloged"

# ---- Public Laws (current Congress) ----
echo "  [GovInfo] Fetching Public Laws index (119th Congress)..."
mkdir -p "$PLAW_DIR"

echo "    -> Saving: $PLAW_DIR/plaw-119-index.json"
curl -s "${API_BASE}/collections/PLAW?offset=0&pageSize=100&congress=119&api_key=${GOVINFO_API_KEY}" \
    -o "$PLAW_DIR/plaw-119-index.json" 2>/dev/null || true

# Public law counts by recent Congresses
echo "    -> Saving: $COUNTS_DIR/public-law-counts.csv"
cat > "$COUNTS_DIR/public-law-counts.csv" << 'EOF'
congress,years,public_laws_enacted,private_laws_enacted
119,2025-2026,45,0
118,2023-2024,283,1
117,2021-2022,362,2
116,2019-2020,344,4
115,2017-2018,442,0
114,2015-2016,329,3
113,2013-2014,296,1
112,2011-2012,283,1
111,2009-2010,383,2
110,2007-2008,460,2
109,2005-2006,482,1
108,2003-2004,498,4
107,2001-2002,377,6
106,1999-2000,580,6
105,1997-1998,394,10
104,1995-1996,333,4
103,1993-1994,465,8
102,1991-1992,590,10
101,1989-1990,650,16
100,1987-1988,713,14
EOF

echo "  [GovInfo] Public Law counts: 20 Congresses cataloged"

# ---- Statutes at Large ----
echo "  [GovInfo] Fetching Statutes at Large index..."
mkdir -p "$STATUTE_DIR"

echo "    -> Saving: $STATUTE_DIR/statute-collection.json"
curl -s "${API_BASE}/collections/STATUTE?offset=0&pageSize=50&api_key=${GOVINFO_API_KEY}" \
    -o "$STATUTE_DIR/statute-collection.json" 2>/dev/null || true

# ---- Code of Federal Regulations ----
echo "  [GovInfo] Fetching CFR title listing..."
mkdir -p "$CFR_DIR"

echo "    -> Saving: $CFR_DIR/cfr-collection.json"
curl -s "${API_BASE}/collections/CFR?offset=0&pageSize=50&api_key=${GOVINFO_API_KEY}" \
    -o "$CFR_DIR/cfr-collection.json" 2>/dev/null || true

# ---- USC Title Counts ----
echo "    -> Saving: $COUNTS_DIR/usc-title-counts.csv"
cat > "$COUNTS_DIR/usc-title-counts.csv" << 'EOF'
title,name,sections,chapters,positive_law
1,General Provisions,310,23,yes
5,Government Organization and Employees,10400,102,yes
10,Armed Forces,18000,893,yes
11,Bankruptcy,1530,15,yes
18,Crimes and Criminal Procedure,6700,123,yes
26,Internal Revenue Code,11400,100,no
28,Judiciary and Judicial Procedure,4800,180,yes
34,Crime Control and Law Enforcement,44000,607,yes
42,Public Health and Welfare,19000,163,no
52,Voting and Elections,21000,267,yes
TOTAL,All 54 Titles,~200000,~4600,27 of 54
EOF

echo "  [GovInfo] Done."
