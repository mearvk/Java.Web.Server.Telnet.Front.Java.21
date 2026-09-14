#!/usr/bin/env bash
# receiver-install.sh — Install NWE Receiver-Only Mode
# Credentials are supplied/generated locally; no default passwords are committed.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SECRETS_DIR="$ROOT/data/secrets"
SECRETS_FILE="$SECRETS_DIR/receiver.env"

[[ -d "$ROOT" && -f "$ROOT/configuration/receiver.only.xml" ]] || {
    echo "[FAIL] Unable to resolve receiver project root: $ROOT" >&2
    exit 1
}

as_root() {
    if [[ "$(id -u)" -eq 0 ]]; then
        "$@"
    else
        sudo "$@"
    fi
}

echo "═══════════════════════════════════════════════════════"
echo "  NitroWebExpress™ — Receiver-Only Installer"
echo "  Project: $ROOT"
echo "═══════════════════════════════════════════════════════"

if ! command -v java >/dev/null 2>&1; then
    command -v apt-get >/dev/null 2>&1 || {
        echo "[FAIL] Java 21 is missing and apt-get is unavailable." >&2
        exit 1
    }
    echo "[INSTALL] Java not found. Installing OpenJDK 21..."
    as_root apt-get update
    as_root apt-get install -y openjdk-21-jdk
fi

JAVA_MAJOR="$(java -version 2>&1 | awk -F '[\".]' '/version/ {print $2; exit}')"
[[ "$JAVA_MAJOR" =~ ^[0-9]+$ && "$JAVA_MAJOR" -ge 21 ]] || {
    echo "[FAIL] Java 21+ is required; detected: $(java -version 2>&1 | head -1)" >&2
    exit 1
}
echo "[INSTALL] Java: $(java -version 2>&1 | head -1)"

mkdir -p "$SECRETS_DIR"
chmod 700 "$SECRETS_DIR"

if [[ ! -f "$SECRETS_FILE" ]]; then
    command -v openssl >/dev/null 2>&1 || as_root apt-get install -y openssl
    umask 077
    KEYSTORE_PASSWORD="${NWE_KEYSTORE_PASSWORD:-$(openssl rand -base64 32)}"
    DB_PASSWORD="${NWE_DB_PASSWORD:-$(openssl rand -base64 32)}"
    cat > "$SECRETS_FILE" <<EOF
# Generated locally. Keep mode 0600.
NWE_KEYSTORE_PASSWORD='$KEYSTORE_PASSWORD'
NWE_DB_PASSWORD='$DB_PASSWORD'
EOF
    chmod 600 "$SECRETS_FILE"
else
    # shellcheck disable=SC1090
    source "$SECRETS_FILE"
    : "${NWE_KEYSTORE_PASSWORD:?Missing NWE_KEYSTORE_PASSWORD in $SECRETS_FILE}"
    : "${NWE_DB_PASSWORD:?Missing NWE_DB_PASSWORD in $SECRETS_FILE}"
fi

KEYSTORE="$SECRETS_DIR/receiver.keystore.jks"
if [[ ! -f "$KEYSTORE" ]]; then
    echo "[INSTALL] Generating receiver TLS keystore..."
    keytool -genkeypair \
        -alias receiver \
        -keyalg RSA \
        -keysize 2048 \
        -validity 3650 \
        -keystore "$KEYSTORE" \
        -storepass "$NWE_KEYSTORE_PASSWORD" \
        -dname "CN=NWE Receiver, O=MEARVK, C=US" \
        -noprompt
    chmod 600 "$KEYSTORE"
fi

echo "[INSTALL] Allowing port 443/tcp..."
if command -v ufw >/dev/null 2>&1; then
    as_root ufw allow 443/tcp >/dev/null
elif command -v iptables >/dev/null 2>&1; then
    as_root iptables -C INPUT -p tcp --dport 443 -j ACCEPT 2>/dev/null ||
        as_root iptables -A INPUT -p tcp --dport 443 -j ACCEPT
else
    echo "[WARN] Neither ufw nor iptables is available; configure port 443 manually."
fi

if grep -q '<backend>mysql</backend>' "$ROOT/configuration/receiver.only.xml"; then
    echo "[INSTALL] MySQL backend selected."
    if ! command -v mysql >/dev/null 2>&1; then
        command -v apt-get >/dev/null 2>&1 || {
            echo "[FAIL] MySQL is missing and apt-get is unavailable." >&2
            exit 1
        }
        as_root apt-get install -y mysql-server
    fi

    as_root mysql <<SQL
CREATE DATABASE IF NOT EXISTS nwe_receiver;
CREATE USER IF NOT EXISTS 'nwe'@'localhost' IDENTIFIED BY '${NWE_DB_PASSWORD}';
ALTER USER 'nwe'@'localhost' IDENTIFIED BY '${NWE_DB_PASSWORD}';
GRANT ALL ON nwe_receiver.* TO 'nwe'@'localhost';
FLUSH PRIVILEGES;
SQL
    echo "[INSTALL] MySQL ready; credentials stored in $SECRETS_FILE"
fi

mkdir -p "$ROOT/data"

echo
echo "[INSTALL] Done."
echo "  Secrets: $SECRETS_FILE"
echo "  Keystore: $KEYSTORE"
echo "  Compile: bash \"$ROOT/scripts/receiver/receiver-compile.sh\""
echo "  Run:     sudo bash \"$ROOT/scripts/receiver/receiver-run.sh\""
