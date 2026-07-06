#!/bin/bash
# Fetch only newer files from github.com/mearvk base repo without merge/rebase.
# Compares remote file timestamps against local and pulls only what's changed.
#
# Usage: bash scripts/github/pull-newer-only.sh

set -e

REPO="mearvk/Java.Web.Server.Telnet.Front.Java.21"
BRANCH="main"
API="https://api.github.com/repos/${REPO}"
RAW="https://raw.githubusercontent.com/${REPO}/${BRANCH}"
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
UPDATED=0
SKIPPED=0

echo "-- : [pull-newer-only] Checking ${REPO}@${BRANCH} for newer files..."

# Get the tree recursively from GitHub API
TREE=$(curl -s "${API}/git/trees/${BRANCH}?recursive=1")

# Extract file paths from the tree
PATHS=$(echo "$TREE" | grep -oP '"path"\s*:\s*"\K[^"]+' | grep -v '^\.git')

for filepath in $PATHS; do
    local_file="${ROOT}/${filepath}"

    # Skip directories and non-existent remote entries
    [ -d "$local_file" ] && continue

    if [ -f "$local_file" ]; then
        # Get remote last commit date for this file
        remote_date=$(curl -s "${API}/commits?path=${filepath}&per_page=1" | grep -oP '"date"\s*:\s*"\K[^"]+' | head -1)
        [ -z "$remote_date" ] && continue

        local_epoch=$(stat -c %Y "$local_file" 2>/dev/null || stat -f %m "$local_file" 2>/dev/null)
        remote_epoch=$(date -d "$remote_date" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%SZ" "$remote_date" +%s 2>/dev/null)

        # Skip if local is same age or newer
        if [ "$local_epoch" -ge "$remote_epoch" ] 2>/dev/null; then
            SKIPPED=$((SKIPPED + 1))
            continue
        fi
    fi

    # Download newer file
    mkdir -p "$(dirname "$local_file")"
    if curl -sf "${RAW}/${filepath}" -o "$local_file"; then
        echo "  UPDATED: ${filepath}"
        UPDATED=$((UPDATED + 1))
    fi
done

echo "-- : [pull-newer-only] Done. Updated: ${UPDATED} | Skipped (local newer): ${SKIPPED}"
