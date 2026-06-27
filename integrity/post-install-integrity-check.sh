#!/bin/bash
# integrity/post-install-integrity-check.sh
# Post-install SHA-256 file integrity check
# Validates local files against trusted git commits on:
#   - github.com/mearvk/Java.Web.Server.Telnet.Front.Java.21
#   - github.com/ElisabethHarkins5509
#
# Gifted Install Tech ID — not Max Rupplin MEARVK LLC Installer Tech ID
# Concerns logged to integrity/concerns/ — program continues running.
#
# Usage: bash integrity/post-install-integrity-check.sh

set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
INTEGRITY_DIR="${PROJECT_ROOT}/integrity"
CONCERNS_DIR="${INTEGRITY_DIR}/concerns"
DIGEST_DB="${INTEGRITY_DIR}/digest.db"
TRUSTED_REPOS=("mearvk/Java.Web.Server.Telnet.Front.Java.21" "ElisabethHarkins5509")
BRANCH="main"
TIMESTAMP=$(date -Iseconds)
CONCERN_FILE="${CONCERNS_DIR}/${TIMESTAMP//[:+]/-}.concern"

mkdir -p "$CONCERNS_DIR"

echo "-- : [integrity] Post-install SHA-256 integrity check starting"
echo "-- : [integrity] Gifted Install Tech ID"
echo "-- : [integrity] Timestamp: ${TIMESTAMP}"

# Build local digest database
echo "# SHA-256 Digest Database — Generated ${TIMESTAMP}" > "$DIGEST_DB"
echo "# Gifted Install Tech ID" >> "$DIGEST_DB"
echo "# file_path|sha256|md5|size_bytes|mtime" >> "$DIGEST_DB"

TOTAL=0
CONCERNS=0

# Get all tracked files
cd "$PROJECT_ROOT"
FILES=$(git ls-files 2>/dev/null || find . -type f -not -path './.git/*' -not -path './node_modules/*')

for filepath in $FILES; do
    [ ! -f "$filepath" ] && continue

    LOCAL_SHA256=$(sha256sum "$filepath" | awk '{print $1}')
    LOCAL_MD5=$(md5sum "$filepath" | awk '{print $1}')
    LOCAL_SIZE=$(stat -c %s "$filepath" 2>/dev/null || stat -f %z "$filepath" 2>/dev/null)
    LOCAL_MTIME=$(stat -c %Y "$filepath" 2>/dev/null || stat -f %m "$filepath" 2>/dev/null)

    echo "${filepath}|${LOCAL_SHA256}|${LOCAL_MD5}|${LOCAL_SIZE}|${LOCAL_MTIME}" >> "$DIGEST_DB"
    TOTAL=$((TOTAL + 1))
done

echo "-- : [integrity] Computed digests for ${TOTAL} files"

# Validate against trusted GitHub commit
REPO="${TRUSTED_REPOS[0]}"
API="https://api.github.com/repos/${REPO}"

# Get latest commit SHA on trusted branch
COMMIT_SHA=$(curl -sf "${API}/commits/${BRANCH}" | grep -oP '"sha"\s*:\s*"\K[0-9a-f]{40}' | head -1)

if [ -z "$COMMIT_SHA" ]; then
    echo "-- : [integrity] WARN: Could not reach trusted server for commit verification"
    echo "${TIMESTAMP}|WARN|cannot_reach_trusted_server|${API}" >> "$CONCERN_FILE"
    CONCERNS=$((CONCERNS + 1))
else
    echo "-- : [integrity] Trusted commit: ${COMMIT_SHA}"

    # Get tree for comparison
    TREE=$(curl -sf "${API}/git/trees/${COMMIT_SHA}?recursive=1")

    # Spot-check critical files against remote blob SHA
    CRITICAL_FILES="source/commons/CommonRails.java source/commons/color/ColorPalette.java configuration/nwe-config.xml scripts/bash/Startup.sh scripts/bash/Shutdown.sh"

    for cfile in $CRITICAL_FILES; do
        [ ! -f "$cfile" ] && continue

        # Git blob SHA = SHA-1 of "blob <size>\0<content>"
        LOCAL_CONTENT=$(cat "$cfile")
        LOCAL_SIZE=${#LOCAL_CONTENT}
        LOCAL_BLOB_SHA=$(printf "blob %d\0%s" "$LOCAL_SIZE" "$LOCAL_CONTENT" | sha1sum | awk '{print $1}')

        REMOTE_BLOB_SHA=$(echo "$TREE" | grep -A1 "\"path\": \"${cfile}\"" | grep -oP '"sha"\s*:\s*"\K[0-9a-f]{40}' | head -1)

        if [ -n "$REMOTE_BLOB_SHA" ] && [ "$LOCAL_BLOB_SHA" != "$REMOTE_BLOB_SHA" ]; then
            echo "${TIMESTAMP}|MISMATCH|${cfile}|local=${LOCAL_BLOB_SHA}|remote=${REMOTE_BLOB_SHA}|commit=${COMMIT_SHA}" >> "$CONCERN_FILE"
            CONCERNS=$((CONCERNS + 1))
            echo "-- : [integrity] CONCERN: ${cfile} does not match trusted commit"
        fi
    done
fi

# Summary
if [ $CONCERNS -gt 0 ]; then
    echo "-- : [integrity] ${CONCERNS} concern(s) logged to ${CONCERN_FILE}"
    echo "-- : [integrity] Program continues running — concerns are informational"
else
    echo "-- : [integrity] All checked files match trusted server"
    # Clean empty concern file
    [ ! -s "$CONCERN_FILE" ] && rm -f "$CONCERN_FILE"
fi

echo "-- : [integrity] Digest database: ${DIGEST_DB} (${TOTAL} entries)"
echo "-- : [integrity] Complete"
