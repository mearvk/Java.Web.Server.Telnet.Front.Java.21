#!/bin/bash
set -euo pipefail

ACTION="${1:-status}"
VENDOR="${2:-all}"
PACKAGE="${3:-}"

command -v brew >/dev/null 2>&1 || {
  echo "ERROR: Homebrew is required. Install it from https://brew.sh/" >&2
  exit 1
}

microsoft=(
  "edge|--cask microsoft-edge"
  "vscode|--cask visual-studio-code"
  "powershell|--cask powershell"
  "dotnet|dotnet"
  "teams|--cask microsoft-teams"
  "onedrive|--cask onedrive"
)
apple=(
  "apple-music|--cask apple-music"
)

resolve() {
  local vendor="$1" package="$2" entry name args
  local -n catalog="$vendor"
  for entry in "${catalog[@]}"; do
    name="${entry%%|*}"; args="${entry#*|}"
    if [[ "$name" == "$package" ]]; then
      printf '%s\n' "$args"
      return 0
    fi
  done
  return 1
}

list_catalog() {
  printf '%s\n' '[microsoft]' edge vscode powershell dotnet teams onedrive
  printf '%s\n' '[apple]' apple-music
}

if [[ "$ACTION" == "list" ]]; then list_catalog; exit 0; fi

if [[ "$VENDOR" == "all" ]]; then vendors=(microsoft apple); else vendors=("$VENDOR"); fi

run_one() {
  local spec="$1"
  # shellcheck disable=SC2206
  local args=( $spec )
  case "$ACTION" in
    install) brew install "${args[@]}" ;;
    update) brew upgrade "${args[@]}" ;;
    remove) brew uninstall "${args[@]}" ;;
    status) brew list --versions "${args[@]}" || true ;;
    repair) brew reinstall "${args[@]}" ;;
    *) echo "ERROR: unsupported action: $ACTION" >&2; exit 2 ;;
  esac
}

if [[ "$ACTION" == "upgrade-all" ]]; then
  brew update
  brew upgrade
  exit 0
fi

for vendor in "${vendors[@]}"; do
  if [[ -n "$PACKAGE" ]]; then
    spec="$(resolve "$vendor" "$PACKAGE")" || continue
    run_one "$spec"
  else
    echo "No package specified. Use 'list' or provide a package alias." >&2
    exit 2
  fi
done

echo "US House macOS software operation complete."
