#!/bin/bash
# integrity/post-install-integrity-check.sh
# Post-install SHA-256 file integrity check with auto-restore on failure.
#
# On integrity fail: git checkout the file from the same commit on trusted repo.
# On software update: update digests but preserve originals in history.
# Self-integrity: SHA-256 of integrity scripts stored in DB.
#
# Gifted Install Tech ID — not Max Rupplin MEARVK LLC Installer Tech ID
# Non-blocking — concerns logged to integrity/concerns/. Program continues.

set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
INTEGRITY_DIR="${PROJECT_ROOT}/integrity"
CONCERNS_DIR="${INTEGRITY_DIR}/concerns"
DIGEST_DB="${INTEGRITY_DIR}/digest.db"
SELF_DB="${INTEGRITY_DIR}/self.sha256"
TIMESTAMP=$(date -Iseconds)
CONCERN_FILE="${CONCERNS_DIR}/${TIMESTAMP//[:+]/-}.concern"

REPO="mearvk/Java.Web.Server.Telnet.Front.Java.21"
BRANCH="main"
API="https://api.github.com/repos/${REPO}"
RAW="https://raw.githubusercontent.com/${REPO}/${BRANCH}"

mkdir -p "$CONCERNS_DIR"

echo "-- : [integrity] Post-install SHA-256 check — Gifted Install Tech ID"

# ─── Step 1: Verify self-integrity (integrity scripts themselves) ───
SELF_FILES="integrity/post-install-integrity-check.sh integrity/integrity-schema.sql"
SELF_OK=true

if [ -f "$SELF_DB" ]; then
    for sf in $SELF_FILES; do
        [ ! -f "${PROJECT_ROOT}/${sf}" ] && continue
        EXPECTED=$(grep "^${sf}|" "$SELF_DB" | cut -d'|' -f2)
        ACTUAL=$(sha256sum "${PROJECT_ROOT}/${sf}" | awk '{print $1}')
        if [ -n "$EXPECTED" ] && [ "$ACTUAL" != "$EXPECTED" ]; then
            echo "-- : [integrity] SELF-INTEGRITY FAIL: ${sf}"
            echo "${TIMESTAMP}|SELF_FAIL|${sf}|expected=${EXPECTED}|actual=${ACTUAL}" >> "$CONCERN_FILE"
            # Attempt restore from trusted repo — but require approval if interactive
            if curl -sf "${RAW}/${sf}" -o "${PROJECT_ROOT}/${sf}.restored"; then
                if [ -t 0 ]; then
                    # Interactive: ask for confirmation before overwriting
                    echo "-- : [integrity] File differs from trusted source: ${sf}"
                    printf "-- : [integrity] Restore from GitHub? [y/N]: "
                    read -r CONFIRM
                    if [ "$CONFIRM" = "y" ] || [ "$CONFIRM" = "Y" ]; then
                        mv "${PROJECT_ROOT}/${sf}.restored" "${PROJECT_ROOT}/${sf}"
                        echo "-- : [integrity] RESTORED: ${sf} from trusted repo"
                    else
                        rm -f "${PROJECT_ROOT}/${sf}.restored"
                        echo "-- : [integrity] SKIPPED restore of ${sf} (user declined)"
                        echo "${TIMESTAMP}|RESTORE_DECLINED|${sf}" >> "$CONCERN_FILE"
                        SELF_OK=false
                    fi
                else
                    # Non-interactive: do NOT auto-restore. Log what would be restored.
                    rm -f "${PROJECT_ROOT}/${sf}.restored"
                    echo "-- : [integrity] NON-INTERACTIVE: Would restore ${sf} — logging only (no auto-restore)"
                    echo "${TIMESTAMP}|RESTORE_PENDING|${sf}|expected=${EXPECTED}|actual=${ACTUAL}|action=none_non_interactive" >> "$CONCERN_FILE"
                    SELF_OK=false
                fi
            else
                SELF_OK=false
            fi
        fi
    done
fi

# ─── Step 2: Get trusted commit SHA ───
COMMIT_SHA=$(curl -sf "${API}/commits/${BRANCH}" | grep -oP '"sha"\s*:\s*"\K[0-9a-f]{40}' | head -1)
if [ -z "$COMMIT_SHA" ]; then
    echo "-- : [integrity] WARN: Cannot reach trusted server"
    echo "${TIMESTAMP}|WARN|cannot_reach_trusted_server" >> "$CONCERN_FILE"
    exit 0
fi
echo "-- : [integrity] Trusted commit: ${COMMIT_SHA}"

# ─── Step 3: Build/verify digest database ───
TOTAL=0
CONCERNS=0
RESTORED=0

cd "$PROJECT_ROOT"
FILES=$(git ls-files 2>/dev/null || find . -type f -not -path './.git/*')

# New digest DB for this scan
DIGEST_DB_NEW="${DIGEST_DB}.new"
echo "# SHA-256 Digest Database — ${TIMESTAMP} — commit ${COMMIT_SHA}" > "$DIGEST_DB_NEW"
echo "# Gifted Install Tech ID" >> "$DIGEST_DB_NEW"
echo "# file_path|sha256|md5|size|commit" >> "$DIGEST_DB_NEW"

for filepath in $FILES; do
    [ ! -f "$filepath" ] && continue
    TOTAL=$((TOTAL + 1))

    CURRENT_SHA=$(sha256sum "$filepath" | awk '{print $1}')
    CURRENT_MD5=$(md5sum "$filepath" | awk '{print $1}')
    CURRENT_SIZE=$(stat -c %s "$filepath" 2>/dev/null || stat -f %z "$filepath" 2>/dev/null)

    echo "${filepath}|${CURRENT_SHA}|${CURRENT_MD5}|${CURRENT_SIZE}|${COMMIT_SHA}" >> "$DIGEST_DB_NEW"

    # Check against existing digest DB
    if [ -f "$DIGEST_DB" ]; then
        EXPECTED_SHA=$(grep "^${filepath}|" "$DIGEST_DB" | cut -d'|' -f2)
        EXPECTED_COMMIT=$(grep "^${filepath}|" "$DIGEST_DB" | cut -d'|' -f5)

        if [ -n "$EXPECTED_SHA" ] && [ "$CURRENT_SHA" != "$EXPECTED_SHA" ]; then
            # File changed — is this an update (new commit) or corruption (same commit)?
            if [ "$EXPECTED_COMMIT" = "$COMMIT_SHA" ]; then
                # Same commit, different hash = corruption. Restore.
                echo "-- : [integrity] MISMATCH (corruption): ${filepath}"
                echo "${TIMESTAMP}|MISMATCH|${filepath}|expected=${EXPECTED_SHA}|actual=${CURRENT_SHA}|commit=${COMMIT_SHA}" >> "$CONCERN_FILE"
                CONCERNS=$((CONCERNS + 1))

                # Attempt restore from same commit on trusted repo
                if curl -sf "${RAW}/${filepath}" -o "${filepath}.restore.tmp"; then
                    RESTORE_SHA=$(sha256sum "${filepath}.restore.tmp" | awk '{print $1}')
                    if [ "$RESTORE_SHA" = "$EXPECTED_SHA" ]; then
                        if [ -t 0 ]; then
                            # Interactive: ask for confirmation before overwriting
                            echo "-- : [integrity] Corruption detected in: ${filepath}"
                            printf "-- : [integrity] Restore from GitHub (commit ${COMMIT_SHA})? [y/N]: "
                            read -r CONFIRM
                            if [ "$CONFIRM" = "y" ] || [ "$CONFIRM" = "Y" ]; then
                                cp "$filepath" "${filepath}.corrupted.bak"
                                mv "${filepath}.restore.tmp" "$filepath"
                                echo "-- : [integrity] RESTORED: ${filepath}"
                                echo "${TIMESTAMP}|RESTORED|${filepath}|sha256=${EXPECTED_SHA}" >> "$CONCERN_FILE"
                                RESTORED=$((RESTORED + 1))
                            else
                                rm -f "${filepath}.restore.tmp"
                                echo "-- : [integrity] SKIPPED restore of ${filepath} (user declined)"
                                echo "${TIMESTAMP}|RESTORE_DECLINED|${filepath}" >> "$CONCERN_FILE"
                            fi
                        else
                            # Non-interactive: do NOT auto-restore. Log what would be restored.
                            rm -f "${filepath}.restore.tmp"
                            echo "-- : [integrity] NON-INTERACTIVE: Would restore ${filepath} — logging only (no auto-restore)"
                            echo "${TIMESTAMP}|RESTORE_PENDING|${filepath}|expected=${EXPECTED_SHA}|actual=${CURRENT_SHA}|action=none_non_interactive" >> "$CONCERN_FILE"
                        fi
                    else
                        rm -f "${filepath}.restore.tmp"
                        echo "-- : [integrity] WARN: Remote also differs for ${filepath}"
                    fi
                else
                    echo "-- : [integrity] FAIL: Cannot restore ${filepath}"
                    echo "${TIMESTAMP}|FAILED_RESTORE|${filepath}" >> "$CONCERN_FILE"
                fi
            else
                # Different commit = software update. Preserve original in history.
                echo "-- : [integrity] UPDATE detected: ${filepath} (new commit)"
            fi
        fi
    fi
done

# ─── Step 4: Preserve originals on update ───
if [ -f "$DIGEST_DB" ]; then
    HISTORY_FILE="${INTEGRITY_DIR}/history/$(date +%Y%m%d-%H%M%S).digest.db"
    mkdir -p "${INTEGRITY_DIR}/history"
    cp "$DIGEST_DB" "$HISTORY_FILE"
fi

# Install new digest DB
mv "$DIGEST_DB_NEW" "$DIGEST_DB"

# ─── Step 5: Update self-integrity (hash the integrity scripts) ───
echo "# Self-integrity — ${TIMESTAMP}" > "$SELF_DB"
for sf in $SELF_FILES; do
    [ ! -f "${PROJECT_ROOT}/${sf}" ] && continue
    HASH=$(sha256sum "${PROJECT_ROOT}/${sf}" | awk '{print $1}')
    echo "${sf}|${HASH}|${COMMIT_SHA}" >> "$SELF_DB"
done

# ─── Summary ───
[ ! -s "$CONCERN_FILE" ] && rm -f "$CONCERN_FILE"
echo "-- : [integrity] Total: ${TOTAL} | Concerns: ${CONCERNS} | Restored: ${RESTORED}"
echo "-- : [integrity] Digest DB updated. Originals preserved in history/."
echo "-- : [integrity] Complete — program continues running"
