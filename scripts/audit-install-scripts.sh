#!/usr/bin/env bash
# audit-install-scripts.sh — Static quality gate for installation/startup scripts.
# Run from anywhere: bash scripts/audit-install-scripts.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ERRORS=0
WARNINGS=0

fail() { printf '[FAIL] %s\n' "$*" >&2; ERRORS=$((ERRORS + 1)); }
warn() { printf '[WARN] %s\n' "$*" >&2; WARNINGS=$((WARNINGS + 1)); }

printf '=== NWE installation/startup script audit ===\n'
printf 'Repository: %s\n\n' "$ROOT"

while IFS= read -r -d '' file; do
    rel="${file#"$ROOT/"}"

    if ! head -n 1 "$file" | grep -Eq '^#!.*(ba)?sh([[:space:]]|$)'; then
        warn "$rel: missing bash-compatible shebang"
    fi

    if ! bash -n "$file"; then
        fail "$rel: shell syntax error"
        continue
    fi

    # Installation scripts should be independent of the caller's cwd.
    if grep -Eq '(^|[[:space:]])cd[[:space:]]+([./]|\.\.)' "$file"; then
        warn "$rel: contains a relative cd; prefer script-derived absolute paths"
    fi

    # Flag common committed/default credentials for manual remediation.
    if grep -EInq "(storepass[[:space:]]+(changeit|password)|IDENTIFIED BY[[:space:]]+'[^']+'|MYSQL_PASS[[:space:]]*=[[:space:]]*['\"])" "$file"; then
        fail "$rel: possible hard-coded/default credential"
    fi

    # Avoid hiding operational failures in installers.
    if grep -Eq '\|\|[[:space:]]*(true|echo)' "$file" && [[ "$rel" == *install* || "$rel" == *deploy* ]]; then
        warn "$rel: installer/deployer suppresses a command failure"
    fi

done < <(find "$ROOT" -type f \( -name '*.sh' -o -name '*.bash' \) -print0 \
    ! -path '*/.git/*' \
    ! -path '*/node_modules/*')

printf '\n=== Audit summary ===\n'
printf 'Warnings: %d\n' "$WARNINGS"
printf 'Errors:   %d\n' "$ERRORS"

if (( ERRORS > 0 )); then
    printf 'Audit FAILED. Fix errors before release/install.\n' >&2
    exit 1
fi

printf 'Audit passed; warnings are review items.\n'
