#!/bin/bash
# Analytics™ — Start Backend (DB-only module, no TCP server)
cd "$(dirname "$0")" || exit 1
echo "[*] Analytics™ — Starting backend (DB initialization)..."
bash servlets/setup-db.sh 2>/dev/null || echo "[WARN] DB setup skipped."
echo "[OK] Analytics™ backend ready (passive tracking via JSP includes)."
