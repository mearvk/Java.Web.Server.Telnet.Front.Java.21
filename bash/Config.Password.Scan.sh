#!/usr/bin/env bash
#
# Config.Password.Scan.sh
# =========================
# MEARVK LLC — NitroWebExpress™
#
# Scans all configuration-style files in the project (*.xml, *.properties,
# *.conf, *.cfg, *.ini, *.yml, *.yaml, *.json, *.env) for password / secret /
# credential fields that contain a *non-default* value — i.e. a real,
# hardcoded secret rather than a placeholder, empty value, or an indirection
# (password-env, credentials-file, etc.) that points elsewhere for the
# real secret.
#
# Usage:
#   bash/Config.Password.Scan.sh                 # scan and print report only
#   bash/Config.Password.Scan.sh --update-gitignore   # also add flagged files
#                                                      to .gitignore
#
# Exit codes:
#   0 = no non-default passwords found
#   1 = one or more non-default passwords found (see report)
#
set -uo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT" || exit 2

GITIGNORE="$PROJECT_ROOT/.gitignore"
UPDATE_GITIGNORE=false
[[ "${1:-}" == "--update-gitignore" ]] && UPDATE_GITIGNORE=true

# ─────────────────────────────────────────────────────────────────────────
# Directories to skip entirely (build output, VCS internals, IDE metadata)
# ─────────────────────────────────────────────────────────────────────────
PRUNE_DIRS=(
    "*/target/*"
    "*/build/*"
    "*/out/*"
    "*/.git/*"
    "*/.idea/*"
    "*/.vscode/*"
    "*/node_modules/*"
)

# ─────────────────────────────────────────────────────────────────────────
# File extensions considered "configuration" files
# ─────────────────────────────────────────────────────────────────────────
CONFIG_GLOBS=(
    "*.xml" "*.properties" "*.conf" "*.cfg" "*.ini"
    "*.yml" "*.yaml" "*.json" "*.env"
)

# ─────────────────────────────────────────────────────────────────────────
# Keys that indicate a credential field
# ─────────────────────────────────────────────────────────────────────────
KEY_PATTERN='(password|passwd|pwd|secret|api[_-]?key|access[_-]?key|private[_-]?key|auth[_-]?token|client[_-]?secret)'

# ─────────────────────────────────────────────────────────────────────────
# Values considered "default" / safe / not a real leaked secret.
# Matched case-insensitively against the captured value.
# ─────────────────────────────────────────────────────────────────────────
DEFAULT_VALUE_PATTERN='^(|changeit|change_me|changeme|replace_me|your_api_key_here|your_cx_here|xxxxx*|password|secret|todo|n\/a|none)$'

# Keys that are *indirections* to a real secret stored elsewhere
# (env var name, path to a credentials file, etc.) — not the secret itself.
INDIRECTION_KEY_PATTERN='(password-env|credentials-file|secret-file|password-file)'

echo "══════════════════════════════════════════════════════════════════════"
echo " Config Password Scan — MEARVK LLC NitroWebExpress™"
echo " Root: $PROJECT_ROOT"
echo "══════════════════════════════════════════════════════════════════════"

# Build the prune expression for `find`
find_prune_expr=()
for d in "${PRUNE_DIRS[@]}"; do
    find_prune_expr+=( -path "$d" -o )
done
unset 'find_prune_expr[${#find_prune_expr[@]}-1]'  # drop trailing -o

# Build the name expression for `find`
find_name_expr=()
for g in "${CONFIG_GLOBS[@]}"; do
    find_name_expr+=( -name "$g" -o )
done
unset 'find_name_expr[${#find_name_expr[@]}-1]'  # drop trailing -o

mapfile -d '' -t FILES < <(
    find "$PROJECT_ROOT" \
        \( "${find_prune_expr[@]}" \) -prune -o \
        \( "${find_name_expr[@]}" \) -type f -print0 2>/dev/null
)

declare -a FLAGGED_FILES=()
TOTAL_HITS=0

for f in "${FILES[@]}"; do
    rel="${f#"$PROJECT_ROOT"/}"

    # Read line by line looking for key/value pairs in XML, properties, JSON, etc.
    while IFS= read -r line_no_and_content; do
        line_no="${line_no_and_content%%:*}"
        content="${line_no_and_content#*:}"

        # Skip indirection keys (password-env, credentials-file, ...)
        if echo "$content" | grep -qiE "$INDIRECTION_KEY_PATTERN"; then
            continue
        fi

        # Extract candidate value depending on format:
        #   XML:        <password>VALUE</password>
        #   properties:  key.password=VALUE
        #   JSON/YAML:   "password": "VALUE"   or   password: VALUE
        value=""

        if [[ "$content" =~ \<[A-Za-z0-9_-]*($KEY_PATTERN)[A-Za-z0-9_-]*\>([^\<]*)\< ]]; then
            value="${BASH_REMATCH[3]}"
        elif [[ "$content" =~ [\"\']?[A-Za-z0-9_.-]*($KEY_PATTERN)[A-Za-z0-9_.-]*[\"\']?[[:space:]]*[:=][[:space:]]*[\"\']?([^\"\',}]*) ]]; then
            value="${BASH_REMATCH[3]}"
        else
            continue
        fi

        # Trim whitespace
        value="$(echo -n "$value" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

        # Skip if value matches a known default/placeholder pattern
        if echo "$value" | grep -qiE "$DEFAULT_VALUE_PATTERN"; then
            continue
        fi

        # Skip empty values (already covered above but double-guard)
        [[ -z "$value" ]] && continue

        echo "  [FOUND] $rel:$line_no  ->  ${content#"${content%%[![:space:]]*}"}"
        FLAGGED_FILES+=("$rel")
        TOTAL_HITS=$((TOTAL_HITS + 1))

    done < <(grep -nEi "$KEY_PATTERN" "$f" 2>/dev/null)
done

echo "──────────────────────────────────────────────────────────────────────"
echo " Total non-default password/secret hits: $TOTAL_HITS"
echo " Distinct files flagged: $(printf '%s\n' "${FLAGGED_FILES[@]}" | sort -u | wc -l)"
echo "══════════════════════════════════════════════════════════════════════"

if [[ "$TOTAL_HITS" -eq 0 ]]; then
    echo "No non-default passwords found. Nothing to do."
    exit 0
fi

# De-duplicate flagged files
mapfile -t UNIQUE_FLAGGED < <(printf '%s\n' "${FLAGGED_FILES[@]}" | sort -u)

if [[ "$UPDATE_GITIGNORE" == true ]]; then
    echo
    echo "Updating .gitignore with flagged files..."

    {
        echo ""
        echo "### Config files with non-default passwords (auto-detected by bash/Config.Password.Scan.sh) ###"
        for rel in "${UNIQUE_FLAGGED[@]}"; do
            if ! grep -qxF "$rel" "$GITIGNORE" 2>/dev/null; then
                echo "$rel"
            fi
        done
    } >> "$GITIGNORE"

    echo "Done. .gitignore updated with $(echo "${#UNIQUE_FLAGGED[@]}") candidate file(s)."
    echo "NOTE: Files already tracked by git must also be removed from the index:"
    echo "      git rm --cached <file>"
else
    echo
    echo "Flagged files (not yet added to .gitignore — rerun with --update-gitignore):"
    for rel in "${UNIQUE_FLAGGED[@]}"; do
        echo "  $rel"
    done
fi

exit 1
