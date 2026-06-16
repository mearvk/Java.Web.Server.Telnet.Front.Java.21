#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# NWE Pre-Install Check
# Run BEFORE NWE.install.sh to verify system readiness.
# Exit code 0 = all checks pass, non-zero = issues found.
# ─────────────────────────────────────────────────────────────────────────────

set -uo pipefail

PASS=0
FAIL=0
WARN=0

ok()   { echo "  [PASS] $1"; PASS=$((PASS + 1)); }
fail() { echo "  [FAIL] $1"; FAIL=$((FAIL + 1)); }
warn() { echo "  [WARN] $1"; WARN=$((WARN + 1)); }

echo "=== NWE Pre-Install System Check ==="
echo ""

# ── 1. Disk space (require at least 1 GB free on /) ──────────────────────────
echo "[1/7] Disk space..."
AVAIL_KB=$(df / --output=avail 2>/dev/null | tail -1 | tr -d ' ')
if [[ -z "$AVAIL_KB" ]]; then
    warn "Could not determine disk space."
else
    AVAIL_MB=$((AVAIL_KB / 1024))
    if [[ $AVAIL_MB -ge 1024 ]]; then
        ok "Available disk: ${AVAIL_MB} MB (>= 1024 MB required)"
    else
        fail "Insufficient disk space: ${AVAIL_MB} MB (need >= 1024 MB)"
    fi
fi

# ── 2. Required ports available ───────────────────────────────────────────────
echo "[2/7] Port availability..."
PORTS=(49152 49155 49166 49177 49188 49199 49144 49133 49200)
for PORT in "${PORTS[@]}"; do
    if ss -tlnp 2>/dev/null | grep -q ":${PORT} " ; then
        fail "Port $PORT already in use"
    else
        ok "Port $PORT available"
    fi
done

# ── 3. sudo access ───────────────────────────────────────────────────────────
echo "[3/7] sudo access..."
if sudo -n true 2>/dev/null; then
    ok "sudo available (passwordless)"
elif sudo -v 2>/dev/null; then
    ok "sudo available (with password)"
else
    fail "sudo not available — installer requires sudo for Apache, MySQL, etc."
fi

# ── 4. Java installation ─────────────────────────────────────────────────────
echo "[4/7] Java..."
if command -v java &>/dev/null; then
    JAVA_VER=$(java -version 2>&1 | head -1)
    MAJOR=$(java -version 2>&1 | head -1 | grep -oP '(?<=version ")(\d+)' || echo "0")
    if [[ "$MAJOR" -ge 21 ]]; then
        ok "Java installed: $JAVA_VER (>= 21 required)"
    else
        fail "Java version too old: $JAVA_VER (need >= 21)"
        echo "        Install: sudo apt install openjdk-21-jdk"
    fi
else
    fail "Java not installed"
    echo "        Install: sudo apt install openjdk-21-jdk"
fi

# ── 5. javac (JDK, not just JRE) ─────────────────────────────────────────────
echo "[5/7] javac (JDK)..."
if command -v javac &>/dev/null; then
    ok "javac found: $(javac -version 2>&1)"
else
    fail "javac not found — full JDK required (not just JRE)"
    echo "        Install: sudo apt install openjdk-21-jdk"
fi

# ── 6. Java license acceptance ────────────────────────────────────────────────
echo "[6/7] Java license..."
echo ""
echo "  NitroWebExpress requires OpenJDK 21+."
echo "  OpenJDK is licensed under the GNU General Public License v2 with Classpath Exception."
echo ""
read -rp "  Do you accept the Java OpenJDK license? [y/N]: " ACCEPT
if [[ "${ACCEPT,,}" == "y" || "${ACCEPT,,}" == "yes" ]]; then
    ok "Java license accepted"
else
    fail "Java license not accepted — cannot proceed"
fi

# ── 7. Other dependencies ────────────────────────────────────────────────────
echo "[7/7] Optional dependencies..."
if command -v mysql &>/dev/null; then
    ok "MySQL client found"
else
    warn "MySQL client not found — will use XML fallback until installed"
fi

if command -v apache2 &>/dev/null || command -v httpd &>/dev/null; then
    ok "Apache2 found"
else
    warn "Apache2 not found — BinaryHttpServer will use local fallback"
fi

if command -v python3 &>/dev/null; then
    ok "python3 found (used by XML wellness check)"
else
    warn "python3 not found — XML wellness check script will not work"
fi

if command -v sendmail &>/dev/null || command -v mail &>/dev/null; then
    ok "Mail agent found (sendmail/mailx)"
else
    warn "No mail agent — TransferSummaryMailer requires: sudo apt install mailutils postfix"
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "=== Pre-Install Summary ==="
echo "  PASS: $PASS   WARN: $WARN   FAIL: $FAIL"
echo ""

if [[ $FAIL -gt 0 ]]; then
    echo "  ✗  $FAIL check(s) failed. Resolve before running NWE.install.sh."
    exit 1
else
    echo "  ✔  System ready. Run: bash bash/NWE.install.sh"
    exit 0
fi
