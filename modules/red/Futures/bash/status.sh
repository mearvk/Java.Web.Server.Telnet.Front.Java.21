#!/bin/bash
# ============================================================
# Status Script — Democratic ProFront National 1.0
# D500 Democratic President — Max Rupplin — MEARVK LLC
# Checks: uptime, connections, visitors, hostile activity,
#          question categories (money, voting, presidents, etc.)
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DB_NAME="democratic_d500"
DB_USER="mearvk_admin"
PORT=5000

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

header() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}  Democratic ProFront National 1.0 — STATUS REPORT${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "  Report Time: $(date '+%Y-%m-%d %H:%M:%S %Z')"
    echo -e "${CYAN}───────────────────────────────────────────────────────────────${NC}"
}

# ── Section 1: Server Uptime ──────────────────────────────────

section_uptime() {
    echo ""
    echo -e "${BOLD}[1] SERVER UPTIME${NC}"
    echo -e "${CYAN}───────────────────────────────────────────────────────────────${NC}"

    # Check if server process is running on port 5000
    PID=$(lsof -ti :$PORT 2>/dev/null)
    if [ -n "$PID" ]; then
        echo -e "  Server Status:    ${GREEN}RUNNING${NC} (PID: $PID, Port: $PORT)"
        # Process uptime
        PROC_START=$(ps -o lstart= -p "$PID" 2>/dev/null)
        if [ -n "$PROC_START" ]; then
            echo -e "  Process Started:  $PROC_START"
        fi
    else
        echo -e "  Server Status:    ${RED}NOT RUNNING${NC} (Port $PORT not active)"
    fi

    # Accumulated uptime from data file
    UPTIME_FILE="$SCRIPT_DIR/data/uptime.accumulator"
    if [ -f "$UPTIME_FILE" ]; then
        ACCUM_HOURS=$(cat "$UPTIME_FILE" | tr -d '[:space:]')
        echo -e "  Accumulated Time: ${ACCUM_HOURS} hours"
        # Calculate days
        if command -v bc &>/dev/null; then
            DAYS=$(echo "scale=2; $ACCUM_HOURS / 24" | bc 2>/dev/null)
            MONTHS=$(echo "scale=2; $ACCUM_HOURS / 720" | bc 2>/dev/null)
            echo -e "  Equivalent:       ${DAYS} days / ${MONTHS} months"
            # 6-month Hardware & Strikes check
            THRESHOLD=4320
            if (( $(echo "$ACCUM_HOURS >= $THRESHOLD" | bc -l 2>/dev/null) )); then
                echo -e "  Hardware Module:  ${GREEN}ELIGIBLE (≥6 months)${NC}"
            else
                REMAINING=$(echo "scale=1; $THRESHOLD - $ACCUM_HOURS" | bc 2>/dev/null)
                echo -e "  Hardware Module:  ${YELLOW}NOT YET (${REMAINING} hours remaining)${NC}"
            fi
        fi
    fi

    # System uptime
    echo -e "  System Uptime:    $(uptime -p 2>/dev/null || uptime)"
}

# ── Section 2: Current & Total Connections ────────────────────

section_connections() {
    echo ""
    echo -e "${BOLD}[2] CONNECTIONS${NC}"
    echo -e "${CYAN}───────────────────────────────────────────────────────────────${NC}"

    # Current connections on port 5000
    CURRENT=$(ss -tn sport = :$PORT 2>/dev/null | grep -c ESTAB)
    echo -e "  Current Active:   ${GREEN}${CURRENT}${NC} connections on port $PORT"

    # From database
    if command -v mysql &>/dev/null; then
        TOTAL=$(mysql -u "$DB_USER" -N -e "SELECT COUNT(*) FROM connection_log;" "$DB_NAME" 2>/dev/null)
        ACCEPTED=$(mysql -u "$DB_USER" -N -e "SELECT COUNT(*) FROM connection_log WHERE outcome='ACCEPTED';" "$DB_NAME" 2>/dev/null)
        DISMISSED=$(mysql -u "$DB_USER" -N -e "SELECT COUNT(*) FROM connection_log WHERE outcome LIKE 'DISMISSED%';" "$DB_NAME" 2>/dev/null)
        REJECTED=$(mysql -u "$DB_USER" -N -e "SELECT COUNT(*) FROM connection_log WHERE outcome LIKE 'REJECTED%';" "$DB_NAME" 2>/dev/null)

        if [ -n "$TOTAL" ]; then
            echo -e "  Total Historical: ${TOTAL} connections"
            echo -e "  Accepted:         ${GREEN}${ACCEPTED}${NC}"
            echo -e "  Dismissed:        ${RED}${DISMISSED}${NC}"
            echo -e "  Rejected:         ${YELLOW}${REJECTED}${NC}"
        else
            echo -e "  Database:         ${YELLOW}Unavailable (check credentials)${NC}"
        fi
    fi

    # From safety ledger file
    LEDGER="$SCRIPT_DIR/data/safety.ledger.csv"
    if [ -f "$LEDGER" ]; then
        LEDGER_ENTRIES=$(wc -l < "$LEDGER")
        UNIQUE_IPS=$(awk -F',' '{print $4}' "$LEDGER" | sort -u | wc -l)
        echo -e "  Safety Ledger:    ${LEDGER_ENTRIES} entries, ${UNIQUE_IPS} unique IPs"
    fi
}

# ── Section 3: Geographic Visitors ────────────────────────────

section_geography() {
    echo ""
    echo -e "${BOLD}[3] GEOGRAPHIC VISITORS${NC}"
    echo -e "${CYAN}───────────────────────────────────────────────────────────────${NC}"

    if command -v mysql &>/dev/null; then
        # Countries from person profiles (geo-location data)
        echo -e "  ${BOLD}Countries:${NC}"
        COUNTRIES=$(mysql -u "$DB_USER" -N -e "
            SELECT SUBSTRING_INDEX(classification, ':', 1) AS country, COUNT(*) AS cnt
            FROM person_profiles
            WHERE classification IS NOT NULL AND classification LIKE '%:%'
            GROUP BY country ORDER BY cnt DESC LIMIT 15;" "$DB_NAME" 2>/dev/null)

        if [ -n "$COUNTRIES" ]; then
            echo "$COUNTRIES" | while IFS=$'\t' read -r country cnt; do
                printf "    %-25s %s connections\n" "$country" "$cnt"
            done
        fi

        # Try IP-based geo from connection_log
        echo ""
        echo -e "  ${BOLD}Unique IPs (top 15):${NC}"
        TOP_IPS=$(mysql -u "$DB_USER" -N -e "
            SELECT ip_address, COUNT(*) AS cnt
            FROM connection_log
            GROUP BY ip_address ORDER BY cnt DESC LIMIT 15;" "$DB_NAME" 2>/dev/null)

        if [ -n "$TOP_IPS" ]; then
            echo "$TOP_IPS" | while IFS=$'\t' read -r ip cnt; do
                printf "    %-20s %s visits\n" "$ip" "$cnt"
            done
        else
            echo -e "    ${YELLOW}No connection log data available${NC}"
        fi
    fi

    # Fallback: extract unique IPs from safety ledger
    LEDGER="$SCRIPT_DIR/data/safety.ledger.csv"
    if [ -f "$LEDGER" ]; then
        echo ""
        echo -e "  ${BOLD}IPs from Safety Ledger (top 10):${NC}"
        awk -F',' '{print $4}' "$LEDGER" | sort | uniq -c | sort -rn | head -10 | while read cnt ip; do
            printf "    %-20s %s entries\n" "$ip" "$cnt"
        done
    fi
}

# ── Section 4: Hostile Visitors ───────────────────────────────

section_hostile() {
    echo ""
    echo -e "${BOLD}[4] HOSTILE VISITORS${NC}"
    echo -e "${CYAN}───────────────────────────────────────────────────────────────${NC}"

    if command -v mysql &>/dev/null; then
        HOSTILE_COUNT=$(mysql -u "$DB_USER" -N -e "SELECT COUNT(*) FROM person_profiles WHERE hostile=TRUE;" "$DB_NAME" 2>/dev/null)
        UNFUNNY_COUNT=$(mysql -u "$DB_USER" -N -e "SELECT COUNT(*) FROM person_profiles WHERE unfunny=TRUE;" "$DB_NAME" 2>/dev/null)
        DISMISSAL_COUNT=$(mysql -u "$DB_USER" -N -e "SELECT COUNT(*) FROM dismissals;" "$DB_NAME" 2>/dev/null)

        if [ -n "$HOSTILE_COUNT" ]; then
            echo -e "  Hostile Profiles:  ${RED}${HOSTILE_COUNT}${NC}"
            echo -e "  Unfunny Profiles:  ${YELLOW}${UNFUNNY_COUNT}${NC}"
            echo -e "  Total Dismissals:  ${DISMISSAL_COUNT}"
            echo ""

            # Recent hostiles
            echo -e "  ${BOLD}Recent Hostile Connections:${NC}"
            mysql -u "$DB_USER" -N -e "
                SELECT ip_address, reason, profiled_ts
                FROM person_profiles
                WHERE hostile=TRUE
                ORDER BY profiled_ts DESC LIMIT 5;" "$DB_NAME" 2>/dev/null | while IFS=$'\t' read -r ip reason ts; do
                echo -e "    ${RED}$ip${NC} — $reason ($ts)"
            done
        else
            echo -e "    ${YELLOW}Database unavailable${NC}"
        fi
    fi

    # From safety ledger — high scores indicate hostility
    LEDGER="$SCRIPT_DIR/data/safety.ledger.csv"
    if [ -f "$LEDGER" ]; then
        echo ""
        echo -e "  ${BOLD}High-Risk Entries (score > 0.5 from ledger):${NC}"
        awk -F',' '$1 > 0.5 {printf "    Score: %-8s IP: %-16s Time: %s\n", $1, $4, $2}' "$LEDGER" | head -10
        HIGH_RISK=$(awk -F',' '$1 > 0.5' "$LEDGER" | wc -l)
        echo -e "  Total High-Risk:   ${RED}${HIGH_RISK}${NC} entries"
    fi

    # Verification hostile attempts
    VERIFY_LOG="$SCRIPT_DIR/logging/verification.attempts.csv"
    if [ -f "$VERIFY_LOG" ]; then
        HOSTILE_ATTEMPTS=$(wc -l < "$VERIFY_LOG")
        echo -e "  Verification Attempts: ${HOSTILE_ATTEMPTS} logged"
    fi
}

# ── Section 5: Question Categories ────────────────────────────

section_questions() {
    echo ""
    echo -e "${BOLD}[5] QUESTION CATEGORIES${NC}"
    echo -e "${CYAN}───────────────────────────────────────────────────────────────${NC}"

    if command -v mysql &>/dev/null; then
        TOTAL_Q=$(mysql -u "$DB_USER" -N -e "SELECT COUNT(*) FROM questions;" "$DB_NAME" 2>/dev/null)
        if [ -n "$TOTAL_Q" ]; then
            echo -e "  Total Questions:   $TOTAL_Q"
            echo ""

            # Money/tax questions
            MONEY_Q=$(mysql -u "$DB_USER" -N -e "
                SELECT COUNT(*) FROM questions
                WHERE question_text REGEXP 'money|tax|capital gains|dividend|income|wealth|budget|fiscal|IRS|revenue|financial';" "$DB_NAME" 2>/dev/null)
            echo -e "  💰 Money/Tax:      ${MONEY_Q}"

            # Democratic voting questions
            VOTING_Q=$(mysql -u "$DB_USER" -N -e "
                SELECT COUNT(*) FROM questions
                WHERE question_text REGEXP 'vot|election|ballot|poll|democratic|democracy|primary|caucus|referendum';" "$DB_NAME" 2>/dev/null)
            echo -e "  🗳️  Voting:         ${VOTING_Q}"

            # US Presidents questions
            PRES_Q=$(mysql -u "$DB_USER" -N -e "
                SELECT COUNT(*) FROM questions
                WHERE question_text REGEXP 'president|Biden|Trump|Obama|Bush|Clinton|Reagan|Lincoln|Washington|Kennedy|Roosevelt';" "$DB_NAME" 2>/dev/null)
            echo -e "  🏛️  Presidents:     ${PRES_Q}"

            # Law/legal questions
            LAW_Q=$(mysql -u "$DB_USER" -N -e "
                SELECT COUNT(*) FROM questions
                WHERE question_text REGEXP 'law|legal|court|supreme|amendment|constitution|rights|legislation|statute';" "$DB_NAME" 2>/dev/null)
            echo -e "  ⚖️  Law/Legal:      ${LAW_Q}"

            # Defense/military questions
            DEF_Q=$(mysql -u "$DB_USER" -N -e "
                SELECT COUNT(*) FROM questions
                WHERE question_text REGEXP 'defense|military|security|national|army|navy|pentagon|UCMJ';" "$DB_NAME" 2>/dev/null)
            echo -e "  🛡️  Defense:        ${DEF_Q}"

            # Heuristics/AI questions
            AI_Q=$(mysql -u "$DB_USER" -N -e "
                SELECT COUNT(*) FROM questions
                WHERE question_text REGEXP 'heuristic|cognitive|AI|artificial|neural|reasoning|bias|synthesis';" "$DB_NAME" 2>/dev/null)
            echo -e "  🧠 AI/Heuristics:  ${AI_Q}"

            # Breakdown by status
            echo ""
            echo -e "  ${BOLD}Status Breakdown:${NC}"
            mysql -u "$DB_USER" -N -e "
                SELECT status, COUNT(*) FROM questions GROUP BY status;" "$DB_NAME" 2>/dev/null | while IFS=$'\t' read -r status cnt; do
                printf "    %-12s %s\n" "$status" "$cnt"
            done
        else
            echo -e "    ${YELLOW}Database unavailable${NC}"
        fi
    fi

    # From QA test results file
    QA_FILE="$SCRIPT_DIR/logging/qa-test-results.csv"
    if [ -f "$QA_FILE" ]; then
        echo ""
        echo -e "  ${BOLD}QA Test Results (from test log):${NC}"
        TOTAL_QA=$(wc -l < "$QA_FILE")
        PASS_QA=$(grep -c ",PASS," "$QA_FILE" 2>/dev/null)
        FAIL_QA=$(grep -c ",FAIL," "$QA_FILE" 2>/dev/null)
        echo -e "    Total: $TOTAL_QA | ${GREEN}Pass: $PASS_QA${NC} | ${RED}Fail: $FAIL_QA${NC}"
    fi
}

# ── Section 6: AI Module Status ───────────────────────────────

section_ai() {
    echo ""
    echo -e "${BOLD}[6] AI MODULE${NC}"
    echo -e "${CYAN}───────────────────────────────────────────────────────────────${NC}"

    if command -v mysql &>/dev/null; then
        SESSIONS=$(mysql -u "$DB_USER" -N -e "SELECT COUNT(*) FROM training_sessions;" "$DB_NAME" 2>/dev/null)
        SPEC_REQ=$(mysql -u "$DB_USER" -N -e "SELECT COUNT(*) FROM speculation_requests;" "$DB_NAME" 2>/dev/null)
        SPEC_DONE=$(mysql -u "$DB_USER" -N -e "SELECT COUNT(*) FROM speculation_results;" "$DB_NAME" 2>/dev/null)

        if [ -n "$SESSIONS" ]; then
            echo -e "  Training Sessions: $SESSIONS"
            echo -e "  Speculation Reqs:  $SPEC_REQ"
            echo -e "  Results Computed:  $SPEC_DONE"
        fi
    fi

    # Check model files
    AI_DIR="$SCRIPT_DIR/source/ai"
    if [ -d "$AI_DIR" ]; then
        AI_FILES=$(find "$AI_DIR" -name "*.java" | wc -l)
        echo -e "  AI Source Files:   $AI_FILES"
    fi
}

# ── Section 7: Integrity & Security ──────────────────────────

section_security() {
    echo ""
    echo -e "${BOLD}[7] INTEGRITY & SECURITY${NC}"
    echo -e "${CYAN}───────────────────────────────────────────────────────────────${NC}"

    # SHA-256 integrity
    INTEGRITY_FILE="$SCRIPT_DIR/.integrity.sha256"
    if [ -f "$INTEGRITY_FILE" ]; then
        TRACKED=$(wc -l < "$INTEGRITY_FILE")
        echo -e "  Tracked Files:     $TRACKED (SHA-256 baseline)"

        # Quick integrity check
        TAMPERED=0
        while IFS='  ' read -r hash file; do
            if [ -f "$SCRIPT_DIR/$file" ]; then
                CURRENT=$(sha256sum "$SCRIPT_DIR/$file" 2>/dev/null | awk '{print $1}')
                if [ "$CURRENT" != "$hash" ]; then
                    TAMPERED=$((TAMPERED + 1))
                fi
            fi
        done < "$INTEGRITY_FILE"

        if [ "$TAMPERED" -eq 0 ]; then
            echo -e "  Integrity:         ${GREEN}ALL FILES CLEAN${NC}"
        else
            echo -e "  Integrity:         ${RED}${TAMPERED} FILE(S) MODIFIED${NC}"
        fi
    fi

    # Certs and cookies
    CERT_DIR="$SCRIPT_DIR/data/certs"
    COOKIE_DIR="$SCRIPT_DIR/data/cookies"
    [ -d "$CERT_DIR" ] && echo -e "  Stored Certs:      $(ls "$CERT_DIR" 2>/dev/null | wc -l)"
    [ -d "$COOKIE_DIR" ] && echo -e "  Stored Cookies:    $(ls "$COOKIE_DIR" 2>/dev/null | wc -l)"

    # Hardware & Strikes log
    HW_LOG="$SCRIPT_DIR/logging/hardware-and-strikes.log"
    if [ -f "$HW_LOG" ]; then
        HW_ENTRIES=$(wc -l < "$HW_LOG")
        echo -e "  H&S Log Entries:   $HW_ENTRIES"
    fi
}

# ── Section 8: Agreements ─────────────────────────────────────

section_agreements() {
    echo ""
    echo -e "${BOLD}[8] AGREEMENTS & PROFILES${NC}"
    echo -e "${CYAN}───────────────────────────────────────────────────────────────${NC}"

    if command -v mysql &>/dev/null; then
        PROFILES=$(mysql -u "$DB_USER" -N -e "SELECT COUNT(*) FROM person_profiles;" "$DB_NAME" 2>/dev/null)
        SANE=$(mysql -u "$DB_USER" -N -e "SELECT COUNT(*) FROM person_profiles WHERE sane=TRUE;" "$DB_NAME" 2>/dev/null)
        LIBERAL=$(mysql -u "$DB_USER" -N -e "SELECT COUNT(*) FROM person_profiles WHERE liberal=TRUE;" "$DB_NAME" 2>/dev/null)
        AGREEMENTS=$(mysql -u "$DB_USER" -N -e "SELECT COUNT(*) FROM agreements;" "$DB_NAME" 2>/dev/null)
        ACTIVE_AGR=$(mysql -u "$DB_USER" -N -e "SELECT COUNT(*) FROM agreements WHERE status='ACTIVE';" "$DB_NAME" 2>/dev/null)
        PARAS_USED=$(mysql -u "$DB_USER" -N -e "SELECT COALESCE(SUM(paragraphs_used),0) FROM agreements;" "$DB_NAME" 2>/dev/null)

        if [ -n "$PROFILES" ]; then
            echo -e "  Total Profiles:    $PROFILES"
            echo -e "  Sane:              ${GREEN}$SANE${NC}"
            echo -e "  Liberal:           ${GREEN}$LIBERAL${NC}"
            echo -e "  Agreements:        $AGREEMENTS (${GREEN}$ACTIVE_AGR active${NC})"
            echo -e "  Paragraphs Served: $PARAS_USED"
        else
            echo -e "    ${YELLOW}Database unavailable${NC}"
        fi
    fi
}

# ── Footer ────────────────────────────────────────────────────

footer() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "  D500 Democratic President — MEARVK LLC — A9000 Clear"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
}

# ── Main ──────────────────────────────────────────────────────

header
section_uptime
section_connections
section_geography
section_hostile
section_questions
section_ai
section_security
section_agreements
footer
