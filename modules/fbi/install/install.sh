#!/usr/bin/env bash
# California FBI module installer — follows the NWE Unified Installation Contract.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NWE_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
CONTRACT="$NWE_ROOT/scripts/install-contract.sh"
[[ -f "$CONTRACT" ]] || { echo "[FAIL] Missing installation contract: $CONTRACT" >&2; exit 1; }
# shellcheck source=/dev/null
source "$CONTRACT"
MOD_ROOT="$(nwe_module_root "$SCRIPT_DIR")"
nwe_verify_module "$MOD_ROOT"
nwe_install_contract_banner

nwe_step "Validating FBI module"
nwe_require_command bash
nwe_verify_path "$MOD_ROOT"

nwe_step "Database setup"
if [[ -x "$MOD_ROOT/servlets/setup-db.sh" || -f "$MOD_ROOT/servlets/setup-db.sh" ]]; then
    bash "$MOD_ROOT/servlets/setup-db.sh"
else
    nwe_warn "No setup-db.sh found; database setup skipped."
fi

nwe_step "Firewall policy"
if [[ "${NWE_CONFIGURE_FIREWALL:-0}" == "1" ]]; then
    nwe_source_optional "$NWE_ROOT/scripts/nwe-ports.sh" || nwe_fail "Missing NWE port manager"
    nwe_ensure_ufw
    if [[ -n "${NWE_TRUSTED_IP:-}" ]]; then
        nwe_run_privileged ufw allow from "$NWE_TRUSTED_IP" to any port 49210 proto tcp
    else
        nwe_run_privileged ufw allow 49210/tcp
    fi
else
    echo "  Firewall unchanged. Set NWE_CONFIGURE_FIREWALL=1 to manage it."
fi

nwe_step "Verifying FBI module installation"
nwe_verify_path "$MOD_ROOT"
echo "[OK] California FBI module installation complete. Backend port: 49210"
