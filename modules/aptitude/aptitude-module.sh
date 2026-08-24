#!/usr/bin/env bash
set -euo pipefail

# JWSTF Aptitude adapter.
# Usage: aptitude-module.sh {search|install|update|verify|remove} [package...]

usage() {
  echo "Usage: $0 {search|install|update|verify|remove} [package ...]" >&2
  exit 2
}

command -v aptitude >/dev/null 2>&1 || {
  echo "aptitude is not installed on this Debian/Ubuntu host." >&2
  exit 127
}

[[ $# -ge 1 ]] || usage
op="$1"
shift

case "$op" in
  search)
    [[ $# -ge 1 ]] || usage
    aptitude search "$@"
    ;;
  install)
    [[ $# -ge 1 ]] || usage
    echo "Planned installation: $*"
    aptitude -s install "$@"
    read -r -p "Apply this installation? [y/N] " answer
    [[ "$answer" =~ ^[Yy]$ ]] || { echo "Cancelled."; exit 0; }
    sudo aptitude install "$@"
    ;;
  update)
    sudo aptitude update
    if [[ $# -gt 0 ]]; then
      sudo aptitude safe-upgrade "$@"
    else
      sudo aptitude safe-upgrade
    fi
    ;;
  verify)
    [[ $# -ge 1 ]] || usage
    for package in "$@"; do
      aptitude show "$package"
    done
    ;;
  remove)
    [[ $# -ge 1 ]] || usage
    echo "Planned removal: $*"
    aptitude -s remove "$@"
    read -r -p "Apply this removal? [y/N] " answer
    [[ "$answer" =~ ^[Yy]$ ]] || { echo "Cancelled."; exit 0; }
    sudo aptitude remove "$@"
    ;;
  *)
    usage
    ;;
esac
