#!/bin/bash
set -euo pipefail

SCRIPT="$(cd "$(dirname "$0")" && pwd)/US-House-Apps.sh"

if [[ ! -x "$SCRIPT" ]]; then
  chmod +x "$SCRIPT"
fi

if [[ "${1:-menu}" != "menu" ]]; then
  exec "$SCRIPT" "$@"
fi

cat <<'MENU'
US HOUSE — macOS SOFTWARE CONVENIENCE
1. List catalog
2. Install
3. Update
4. Remove
5. Status
6. Upgrade all
7. Repair
8. Exit
MENU

read -r -p 'Select: ' choice
case "$choice" in
  1) exec "$SCRIPT" list ;;
  2) action=install ;;
  3) action=update ;;
  4) action=remove ;;
  5) action=status ;;
  6) exec "$SCRIPT" upgrade-all ;;
  7) action=repair ;;
  8) exit 0 ;;
  *) echo 'Invalid selection.'; exit 2 ;;
esac

read -r -p 'Vendor (microsoft/apple): ' vendor
read -r -p 'Package alias: ' package
exec "$SCRIPT" "$action" "$vendor" "$package"
