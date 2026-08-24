#!/usr/bin/env bash
set -euo pipefail

# Launch the JavaFX Aptitude UI when the GUI artifact exists; otherwise use a
# clean terminal fallback. The module descriptor remains the integration point.
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
UI_JAR="${JWSTF_APTITUDE_UI_JAR:-$ROOT/installer/build/jwstf-aptitude-ui.jar}"

if [[ -f "$UI_JAR" ]] && command -v java >/dev/null 2>&1; then
  exec java -jar "$UI_JAR"
fi

cat <<'EOF'
JWSTF Aptitude Installer

GUI artifact not built. Running the safe terminal installer instead.

Choose an operation:
  1) install
  2) update
  3) verify
  4) remove
  5) search

The JavaFX release build provides the graphical interface. This fallback
preserves the same lifecycle and confirmation semantics.
EOF

read -r -p "Operation [1-5]: " choice
case "$choice" in
  1) exec "$ROOT/modules/aptitude/aptitude-module.sh" install "${PACKAGE:-jwstf}" ;;
  2) exec "$ROOT/modules/aptitude/aptitude-module.sh" update ;;
  3) exec "$ROOT/modules/aptitude/aptitude-module.sh" verify "${PACKAGE:-jwstf}" ;;
  4) exec "$ROOT/modules/aptitude/aptitude-module.sh" remove "${PACKAGE:-jwstf}" ;;
  5) exec "$ROOT/modules/aptitude/aptitude-module.sh" search "${PACKAGE:-jwstf}" ;;
  *) echo "Cancelled."; exit 2 ;;
esac
