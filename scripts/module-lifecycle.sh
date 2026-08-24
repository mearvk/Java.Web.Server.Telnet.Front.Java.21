#!/usr/bin/env bash
# Uniform lifecycle controller for modules in Java.Web.Server.Telnet.Front.Java.21.
# Source trees are never deleted by "remove"; only installed/build artifacts are removed.
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODULES_DIR="$ROOT/modules"
ACTION="${1:-status}"
TARGET="${2:-all}"

usage() {
  cat <<'EOF'
Usage: scripts/module-lifecycle.sh <install|update|verify|remove|status> [module|all]

install  Build/prepare a module and deploy when its supported lifecycle exists.
update   Rebuild/redeploy a module using repository-local build mechanisms.
verify   Check source/build/deployment state without changing it.
remove   Stop/undeploy and remove generated artifacts; NEVER removes source.
status   Report lifecycle capabilities and current state.
EOF
}

[[ -d "$MODULES_DIR" ]] || { echo "Missing modules directory: $MODULES_DIR" >&2; exit 1; }

module_dirs() {
  if [[ "$TARGET" == "all" ]]; then
    find "$MODULES_DIR" -mindepth 1 -maxdepth 2 -type d -name source -printf '%h\n' 2>/dev/null | sort -u
    find "$MODULES_DIR" -mindepth 1 -maxdepth 1 -type d -printf '%p\n' | sort -u
  else
    [[ -d "$MODULES_DIR/$TARGET" ]] || { echo "Unknown module: $TARGET" >&2; exit 2; }
    printf '%s\n' "$MODULES_DIR/$TARGET"
  fi
}

run_optional() {
  local script="$1"; shift
  if [[ -x "$script" ]]; then
    "$script" "$@"
  elif [[ -f "$script" ]]; then
    bash "$script" "$@"
  else
    return 127
  fi
}

install_one() {
  local m="$1"
  echo "==> INSTALL $m"
  if [[ -f "$m/install.sh" ]]; then run_optional "$m/install.sh"; return; fi
  if [[ -f "$m/source/Makefile" ]]; then make -C "$m/source"; return; fi
  if [[ -f "$m/Makefile" ]]; then make -C "$m"; return; fi
  if [[ -f "$m/pom.xml" ]] && command -v mvn >/dev/null; then mvn -f "$m/pom.xml" package; return; fi
  if [[ -f "$m/gradlew" ]]; then (cd "$m" && ./gradlew build); return; fi
  echo "No install/build hook for $(basename "$m"); source retained."
}

update_one() {
  local m="$1"
  echo "==> UPDATE $m"
  if [[ -f "$m/update.sh" ]]; then run_optional "$m/update.sh"; return; fi
  install_one "$m"
}

verify_one() {
  local m="$1"
  echo "==> VERIFY $m"
  if [[ -f "$m/verify.sh" ]]; then run_optional "$m/verify.sh"; return; fi
  if [[ -x "$m/start-backend.sh" || -f "$m/start-backend.sh" ]]; then echo "backend lifecycle: present"; else echo "backend lifecycle: absent"; fi
  if [[ -x "$m/shutdown-backend.sh" || -f "$m/shutdown-backend.sh" ]]; then echo "backend removal/stop hook: present"; else echo "backend removal/stop hook: absent"; fi
  if [[ -f "$m/source/Makefile" || -f "$m/Makefile" || -f "$m/pom.xml" || -f "$m/gradlew" ]]; then echo "build mechanism: present"; else echo "build mechanism: not detected"; fi
}

remove_one() {
  local m="$1"
  echo "==> REMOVE GENERATED ARTIFACTS $m"
  # Stop running services first when the module supplies the repository's hook.
  if [[ -f "$m/shutdown-backend.sh" ]]; then run_optional "$m/shutdown-backend.sh" || true; fi
  if [[ -f "$m/shutdown-frontend.sh" ]]; then run_optional "$m/shutdown-frontend.sh" || true; fi
  # Prefer a repository-defined uninstall hook.
  if [[ -f "$m/uninstall.sh" ]]; then run_optional "$m/uninstall.sh"; return; fi
  # Safe generated-output cleanup only. Never rm -rf the module/source tree.
  rm -rf "$m/out" "$m/build" "$m/target" 2>/dev/null || true
  find "$m" -maxdepth 2 -type f \( -name '*.class' -o -name '*.jar' \) -print -delete 2>/dev/null || true
  echo "Source preserved. Generated artifacts removed where recognized."
}

case "$ACTION" in
  install|update|verify|remove|status) ;;
  *) usage; exit 2;;
esac

while IFS= read -r module; do
  [[ -d "$module" ]] || continue
  case "$ACTION" in
    install) install_one "$module" ;;
    update) update_one "$module" ;;
    verify) verify_one "$module" ;;
    remove) remove_one "$module" ;;
    status) verify_one "$module" ;;
  esac
done < <(module_dirs | awk '!seen[$0]++')
