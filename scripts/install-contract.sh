#!/usr/bin/env bash
# NWE Unified Installation Contract
# Shared primitives for every installer/module.
# Contract: resolve root -> validate -> plan -> change -> verify -> accurate exit.
set -euo pipefail

NWE_INSTALL_CONTRACT_VERSION="1.0"

nwe_contract_root() {
    local source_file="${1:-${BASH_SOURCE[1]}}"
    cd "$(dirname "$source_file")/.." && pwd
}

nwe_require_command() {
    command -v "$1" >/dev/null 2>&1 || {
        echo "[FAIL] Required command not found: $1" >&2
        return 1
    }
}

nwe_is_root() { [[ "$(id -u)" -eq 0 ]]; }

nwe_run_privileged() {
    if nwe_is_root; then
        "$@"
    else
        command -v sudo >/dev/null 2>&1 || { echo "[FAIL] sudo is required: $*" >&2; return 1; }
        sudo "$@"
    fi
}

nwe_step() { echo "[NWE] $*"; }
nwe_warn() { echo "[WARN] $*" >&2; }
nwe_fail() { echo "[FAIL] $*" >&2; return 1; }

nwe_require_linux() {
    [[ "$(uname -s)" == "Linux" ]] || nwe_fail "This operation requires Linux."
}

nwe_verify_path() {
    [[ -e "$1" ]] || nwe_fail "Expected path does not exist: $1"
}

nwe_source_optional() {
    local file="$1"
    if [[ -f "$file" ]]; then
        # shellcheck source=/dev/null
        source "$file"
        return 0
    fi
    return 1
}

nwe_module_root() {
    local install_dir="$1"
    cd "$install_dir/.." && pwd
}

nwe_repo_root_from_module() {
    local module_root="$1"
    cd "$module_root/../.." && pwd
}

nwe_verify_module() {
    local module_root="$1"
    nwe_verify_path "$module_root"
    [[ -d "$module_root/source" || -d "$module_root/servlets" ]] || \
        nwe_fail "Module does not contain expected source/servlets directories: $module_root"
}

nwe_install_contract_banner() {
    echo "NWE Unified Installation Contract v$NWE_INSTALL_CONTRACT_VERSION"
    echo "  root: ${NWE_ROOT:-unknown}"
}
