#!/usr/bin/env bash
# remote-deploy-script.sh — Deploy NWE to remote server via SSH/SCP
# Prompts for remote user and root password before deploying.
# Usage: bash scripts/remote-deploy-script.sh

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/out"
CONFIG="$ROOT/configuration/nwe-config.xml"
SCRIPTS="$ROOT/scripts"
BASH_DIR="$ROOT/bash"

# ── Remote defaults (from nwe-config.xml) ─────────────────────────────────────
DEFAULT_USER="root"
DEFAULT_HOST="45.32.31.139"
DEFAULT_REMOTE_DIR="/opt/nwe"

echo "=============================================="
echo "  NitroWebExpress — Remote Deployment Script"
echo "=============================================="
echo ""

# ── Prompt: Remote user ───────────────────────────────────────────────────────
read -rp "Remote user [$DEFAULT_USER]: " REMOTE_USER
REMOTE_USER="${REMOTE_USER:-$DEFAULT_USER}"

# ── Prompt: Remote host ───────────────────────────────────────────────────────
read -rp "Remote host [$DEFAULT_HOST]: " REMOTE_HOST
REMOTE_HOST="${REMOTE_HOST:-$DEFAULT_HOST}"

# ── Prompt: Remote directory ──────────────────────────────────────────────────
read -rp "Remote deploy directory [$DEFAULT_REMOTE_DIR]: " REMOTE_DIR
REMOTE_DIR="${REMOTE_DIR:-$DEFAULT_REMOTE_DIR}"

# ── Prompt: Root password ─────────────────────────────────────────────────────
echo ""
read -rsp "Enter root password for $REMOTE_USER@$REMOTE_HOST: " ROOT_PASSWORD
echo ""
echo ""

# ── Validate local build ──────────────────────────────────────────────────────
if [[ ! -d "$OUT" ]] || [[ -z "$(ls -A "$OUT" 2>/dev/null)" ]]; then
    echo "[ERROR] No compiled classes found in $OUT"
    echo "        Run 'bash bash/NWE.install.sh' first to compile."
    exit 1
fi

echo "[1/5] Deploying to $REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR"
echo ""

# ── Helper: run remote command via sshpass ────────────────────────────────────
remote_exec() {
    sshpass -p "$ROOT_PASSWORD" ssh -o StrictHostKeyChecking=no "$REMOTE_USER@$REMOTE_HOST" "$@"
}

remote_copy() {
    sshpass -p "$ROOT_PASSWORD" scp -o StrictHostKeyChecking=no -r "$@"
}

# ── Check sshpass is available ────────────────────────────────────────────────
if ! command -v sshpass &>/dev/null; then
    echo "[WARN] sshpass not found. Installing..."
    if command -v apt-get &>/dev/null; then
        sudo apt-get install -y sshpass
    elif command -v yum &>/dev/null; then
        sudo yum install -y sshpass
    else
        echo "[ERROR] Cannot install sshpass automatically."
        echo "        Install it manually: sudo apt-get install sshpass"
        exit 1
    fi
fi

# ── 2. Create remote directory structure ──────────────────────────────────────
echo "[2/5] Creating remote directory structure..."
remote_exec "mkdir -p $REMOTE_DIR/{out,configuration,scripts,bash,jars,logging}"
echo "      Done."

# ── 3. Upload compiled classes ────────────────────────────────────────────────
echo "[3/5] Uploading compiled classes (out/)..."
remote_copy "$OUT/" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR/out/"
echo "      Done."

# ── 4. Upload configuration, scripts, jars ───────────────────────────────────
echo "[4/5] Uploading configuration and scripts..."
remote_copy "$CONFIG" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR/configuration/nwe-config.xml"
remote_copy "$SCRIPTS/startup.sh" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR/scripts/startup.sh"
remote_copy "$BASH_DIR/NWE.install.sh" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR/bash/NWE.install.sh"

# Upload jars (MySQL connector, Lanterna)
if [[ -d "$ROOT/jars" ]]; then
    remote_copy "$ROOT/jars/" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR/jars/"
fi
echo "      Done."

# ── 5. Set permissions and verify ────────────────────────────────────────────
echo "[5/5] Setting permissions and verifying deployment..."
remote_exec "chmod +x $REMOTE_DIR/scripts/*.sh $REMOTE_DIR/bash/*.sh 2>/dev/null || true"
remote_exec "ls -la $REMOTE_DIR/out/ | head -20"
echo ""

# ── Summary ───────────────────────────────────────────────────────────────────
echo "=============================================="
echo "  Deployment complete!"
echo "  Host: $REMOTE_USER@$REMOTE_HOST"
echo "  Path: $REMOTE_DIR"
echo ""
echo "  To start NWE on the remote server:"
echo "    ssh $REMOTE_USER@$REMOTE_HOST"
echo "    cd $REMOTE_DIR && bash scripts/startup.sh"
echo "=============================================="
