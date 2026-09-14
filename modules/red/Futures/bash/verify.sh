#!/bin/bash
# ============================================================
# VERIFY — Democratic ProFront National 1.0
# Reaches out to the Futures GitHub repo with the local commit
# hash (the key it's indexed with) to verify authenticity/grade.
#
# All verification attempts are logged carefully — connections
# may be hostile by the time we discover it.
#
# Installer ID: MEARVK LLC - Max Rupplin
# ============================================================
set -u

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
LOG_FILE="$PROJECT_DIR/logging/verification.log"
ATTEMPTS_FILE="$PROJECT_DIR/logging/verification.attempts.csv"
REPO_API="https://api.github.com/repos/mearvk/Futures"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S %Z')
EPOCH=$(date +%s)

mkdir -p "$PROJECT_DIR/logging"

echo "============================================================"
echo " VERIFY AUTHENTICITY — Democratic ProFront National 1.0"
echo " $TIMESTAMP"
echo "============================================================"
echo ""

# Get local commit hash (the key this project is indexed with)
LOCAL_COMMIT=$(cd "$PROJECT_DIR" && git rev-parse HEAD 2>/dev/null)
LOCAL_SHORT=$(cd "$PROJECT_DIR" && git rev-parse --short HEAD 2>/dev/null)
LOCAL_BRANCH=$(cd "$PROJECT_DIR" && git branch --show-current 2>/dev/null)

if [ -z "$LOCAL_COMMIT" ]; then
    echo "  ✗ FATAL: Not a git repository or no commits."
    echo "[$TIMESTAMP] FATAL no_commit" >> "$LOG_FILE"
    exit 1
fi

echo "  Local commit: $LOCAL_COMMIT"
echo "  Branch: $LOCAL_BRANCH"
echo ""

# Record this attempt BEFORE making network call
# Format: timestamp,epoch,local_commit,branch,result,remote_commit,grade
# Store carefully — these attempts may be hostile probes
ATTEMPT_LINE="$TIMESTAMP,$EPOCH,$LOCAL_COMMIT,$LOCAL_BRANCH"

# Reach out to GitHub API for remote HEAD
echo "  Reaching out to: $REPO_API ..."
RESPONSE=$(curl -s -w "\n%{http_code}" --connect-timeout 10 --max-time 15 \
    -H "Accept: application/vnd.github.v3+json" \
    "$REPO_API/commits/$LOCAL_BRANCH" 2>/dev/null)

HTTP_CODE=$(echo "$RESPONSE" | tail -1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" != "200" ]; then
    echo "  ⚠ GitHub returned HTTP $HTTP_CODE"
    echo "[$TIMESTAMP] ATTEMPT http=$HTTP_CODE commit=$LOCAL_SHORT branch=$LOCAL_BRANCH" >> "$LOG_FILE"
    echo "$ATTEMPT_LINE,FAILED_HTTP_$HTTP_CODE,,UNGRADED" >> "$ATTEMPTS_FILE"
    exit 1
fi

# Extract remote commit SHA
REMOTE_COMMIT=$(echo "$BODY" | grep -m1 '"sha"' | awk -F'"' '{print $4}')
REMOTE_SHORT="${REMOTE_COMMIT:0:7}"

echo "  Remote HEAD:  $REMOTE_COMMIT"
echo ""

# Grade the verification
if [ "$LOCAL_COMMIT" = "$REMOTE_COMMIT" ]; then
    GRADE="AUTHENTIC"
    echo "  ✓ GRADE: AUTHENTIC — local matches remote HEAD exactly"
elif echo "$BODY" | grep -q "$LOCAL_COMMIT"; then
    GRADE="VALID_ANCESTOR"
    echo "  ✓ GRADE: VALID ANCESTOR — local commit exists in remote history"
else
    # Check if our commit exists on remote at all
    VERIFY_RESP=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 10 \
        "$REPO_API/commits/$LOCAL_COMMIT" 2>/dev/null)
    if [ "$VERIFY_RESP" = "200" ]; then
        GRADE="VALID_BEHIND"
        echo "  ~ GRADE: VALID (BEHIND) — commit exists but not at HEAD"
    else
        GRADE="UNVERIFIED"
        echo "  ✗ GRADE: UNVERIFIED — local commit not found on remote"
    fi
fi

echo ""
echo "  Grade: $GRADE"
echo "  Local:  $LOCAL_SHORT ($LOCAL_BRANCH)"
echo "  Remote: $REMOTE_SHORT"

# Log carefully
echo "[$TIMESTAMP] VERIFY commit=$LOCAL_SHORT remote=$REMOTE_SHORT grade=$GRADE branch=$LOCAL_BRANCH" >> "$LOG_FILE"
echo "$ATTEMPT_LINE,$GRADE,$REMOTE_COMMIT,$GRADE" >> "$ATTEMPTS_FILE"

# Track as potential hostile probe analysis
echo ""
echo "  Attempts logged to: logging/verification.attempts.csv"
echo "  Audit log: logging/verification.log"
echo ""
echo "============================================================"
echo "  NOTE: All verification attempts are stored for analysis."
echo "  US long-term middle/inside players may be hostile by the"
echo "  time discovery occurs. Treat all attempts with suspicion."
echo "============================================================"
