#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# NitroWebExpress™ — Remote Linux Server Deploy
# Deploys the full NWE system to a remote server via SSH/SCP.
# Runs post-clone.sh on the remote after transferring the codebase.
#
# Usage: bash scripts/deploy-remote-linux.sh [user@host] [remote_path]
#
# Prerequisites:
#   - SSH key access (run ssh-copy-id first) OR sshpass installed
#   - Remote server: Ubuntu/Debian or RHEL/Fedora
#
# Capitalization reference: configuration/print-method.xml §script-descriptors
# ═══════════════════════════════════════════════════════════════════════════════
set -uo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
source "$PROJECT_ROOT/scripts/print-descriptor.sh" 2>/dev/null || true

# ── Configuration ─────────────────────────────────────────────────────────────
DEFAULT_HOST="45.32.31.139"
DEFAULT_USER="root"
DEFAULT_PATH="/opt/NitroWebExpress"

REMOTE="${1:-${NWE_REMOTE_USER:-$DEFAULT_USER}@${NWE_REMOTE_HOST:-$DEFAULT_HOST}}"
REMOTE_PATH="${2:-$DEFAULT_PATH}"
REMOTE_USER="${REMOTE%%@*}"
REMOTE_HOST="${REMOTE##*@}"

SSH_OPTS="-o ConnectTimeout=10 -o StrictHostKeyChecking=accept-new -o ServerAliveInterval=15 -o ServerAliveCountMax=3"

echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║  NitroWebExpress™ — Remote Linux Server Deploy                          ║"
echo "║  Target:  $REMOTE_USER@$REMOTE_HOST:$REMOTE_PATH                        ║"
echo "║  Source:  $PROJECT_ROOT                                                  ║"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo ""

# ── 1. SSH Connectivity ───────────────────────────────────────────────────────
echo "[1/6] Verifying SSH access..."

# Check port reachable
if ! timeout 5 bash -c "echo >/dev/tcp/$REMOTE_HOST/22" 2>/dev/null; then
    echo "  [!] Port 22 not reachable on $REMOTE_HOST"
    exit 1
fi

# Try key-based auth first
SSH_CMD="ssh $SSH_OPTS"
SCP_CMD="scp -o ConnectTimeout=10"
USE_SSHPASS=false

if ! $SSH_CMD -o BatchMode=yes "$REMOTE" "echo OK" &>/dev/null; then
    echo "  [*] Key-based SSH failed — trying password auth..."
    if ! command -v sshpass &>/dev/null; then
        echo "  [*] Installing sshpass..."
        sudo apt-get install -y -qq sshpass 2>/dev/null || sudo dnf install -y -q sshpass 2>/dev/null || true
    fi
    if command -v sshpass &>/dev/null; then
        read -rsp "  SSH password for $REMOTE: " SSH_PASS
        echo ""
        if sshpass -p "$SSH_PASS" ssh $SSH_OPTS "$REMOTE" "echo OK" &>/dev/null; then
            SSH_CMD="sshpass -p $SSH_PASS ssh $SSH_OPTS"
            SCP_CMD="sshpass -p $SSH_PASS scp -o ConnectTimeout=10"
            USE_SSHPASS=true
            echo "  [✓] Password auth successful"

            # Offer to copy SSH key for future passwordless access
            echo "  [*] Copying SSH key for future passwordless access..."
            if [ ! -f ~/.ssh/id_ed25519 ] && [ ! -f ~/.ssh/id_rsa ]; then
                ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N "" -q
            fi
            sshpass -p "$SSH_PASS" ssh-copy-id -o StrictHostKeyChecking=accept-new "$REMOTE" &>/dev/null && \
                echo "  [✓] SSH key installed — password not needed next time" || true
        else
            echo "  [!] Password auth failed"
            exit 1
        fi
    else
        echo "  [!] Cannot authenticate. Install sshpass or run: ssh-copy-id $REMOTE"
        exit 1
    fi
else
    echo "  [✓] SSH key auth successful"
fi

echo ""

# ── 2. Remote Preparation ────────────────────────────────────────────────────
echo "[2/6] Preparing remote server..."

$SSH_CMD "$REMOTE" bash -s "$REMOTE_PATH" <<'REMOTE_PREP'
    set -e
    REMOTE_PATH="$1"
    
    # Install essentials
    if command -v apt-get &>/dev/null; then
        export DEBIAN_FRONTEND=noninteractive
        apt-get update -qq 2>/dev/null
        apt-get install -y -qq rsync git curl ufw 2>/dev/null
    elif command -v dnf &>/dev/null; then
        dnf install -y -q rsync git curl 2>/dev/null
    fi
    
    # Create target directory
    mkdir -p "$REMOTE_PATH"
    echo "OK"
REMOTE_PREP

echo "  [✓] Remote dependencies installed"
echo ""

# ── 3. Transfer Codebase ─────────────────────────────────────────────────────
echo "[3/6] Transferring codebase to $REMOTE_HOST:$REMOTE_PATH..."
echo "  (excluding .git, out/, target/, node_modules, large binaries)"

# Use rsync if available (faster, incremental), fall back to scp
if command -v rsync &>/dev/null; then
    RSYNC_OPTS="-az --delete --progress --stats"
    RSYNC_EXCLUDE="--exclude=.git --exclude=out --exclude=target --exclude=node_modules --exclude=*.jar --exclude=.djl.ai --exclude='*.MOV' --exclude='*.MP4' --exclude='*.zip'"
    
    if [ "$USE_SSHPASS" = true ]; then
        RSYNC_SSH="sshpass -p $SSH_PASS ssh $SSH_OPTS"
    else
        RSYNC_SSH="ssh $SSH_OPTS"
    fi
    
    rsync $RSYNC_OPTS $RSYNC_EXCLUDE -e "$RSYNC_SSH" \
        "$PROJECT_ROOT/" "$REMOTE:$REMOTE_PATH/" 2>&1 | tail -5
else
    # Fallback: tar + scp
    echo "  [*] rsync not found — using tar+scp (slower)..."
    TARBALL="/tmp/nwe-deploy-$(date +%s).tar.gz"
    tar czf "$TARBALL" -C "$(dirname "$PROJECT_ROOT")" \
        --exclude='.git' --exclude='out' --exclude='target' \
        --exclude='node_modules' --exclude='*.jar' \
        "$(basename "$PROJECT_ROOT")"
    $SCP_CMD "$TARBALL" "$REMOTE:/tmp/"
    $SSH_CMD "$REMOTE" "tar xzf /tmp/$(basename $TARBALL) -C $(dirname $REMOTE_PATH) && rm -f /tmp/$(basename $TARBALL)"
    rm -f "$TARBALL"
fi

echo "  [✓] Codebase transferred"
echo ""

# ── 4. Transfer JARs (separate — large files) ────────────────────────────────
echo "[4/6] Transferring JAR dependencies..."

$SSH_CMD "$REMOTE" "mkdir -p $REMOTE_PATH/jars/mysql $REMOTE_PATH/jars/djl"

# MySQL connector
MYSQL_JAR=$(find "$PROJECT_ROOT/jars/mysql" -name "mysql-connector-j*.jar" -type f 2>/dev/null | head -1)
if [ -n "$MYSQL_JAR" ]; then
    $SCP_CMD "$MYSQL_JAR" "$REMOTE:$REMOTE_PATH/jars/mysql/"
    echo "  [✓] MySQL connector: $(basename "$MYSQL_JAR")"
fi

# Lanterna
LANTERNA_JAR="$PROJECT_ROOT/jars/lanterna-3.1.5.jar"
if [ -f "$LANTERNA_JAR" ]; then
    $SCP_CMD "$LANTERNA_JAR" "$REMOTE:$REMOTE_PATH/jars/"
    echo "  [✓] Lanterna"
fi

# DJL jars (skip native — too large, download on remote)
find "$PROJECT_ROOT/jars/djl" -name "*.jar" ! -name "*native*" -type f 2>/dev/null | while read -r JAR; do
    $SCP_CMD "$JAR" "$REMOTE:$REMOTE_PATH/jars/djl/" 2>/dev/null
done
echo "  [✓] DJL JARs"
echo ""

# ── 5. Transfer Credentials ──────────────────────────────────────────────────
echo "[5/6] Configuring remote credentials..."

if [ -f "$PROJECT_ROOT/.nwe-credentials" ]; then
    $SCP_CMD "$PROJECT_ROOT/.nwe-credentials" "$REMOTE:$REMOTE_PATH/.nwe-credentials"
    $SSH_CMD "$REMOTE" "chmod 600 $REMOTE_PATH/.nwe-credentials"
    echo "  [✓] .nwe-credentials copied (mode 600)"
else
    echo "  [!] No local .nwe-credentials — remote will prompt during post-clone"
fi
echo ""

# ── 6. Run Post-Clone on Remote ──────────────────────────────────────────────
echo "[6/6] Running post-clone setup on remote..."
echo "  (Java 21, MySQL, Tomcat, UFW, databases, deploy, start)"
echo ""

$SSH_CMD -t "$REMOTE" bash -s "$REMOTE_PATH" <<'REMOTE_INSTALL'
    set -e
    REMOTE_PATH="$1"
    cd "$REMOTE_PATH"
    
    # Make scripts executable
    find . -name "*.sh" -exec chmod +x {} \;
    
    # Run post-clone (handles everything)
    bash scripts/web/post-clone.sh
    
    # Compile
    bash scripts/compile-all-modules.sh
    
    # Start everything
    bash scripts/start-all.sh
REMOTE_INSTALL

echo ""
echo "╔═══════════════════════════════════════════════════════════════════════════╗"
echo "║  Remote Deploy Complete                                                 ║"
echo "║                                                                         ║"
echo "║  Server:   $REMOTE_HOST                                                 ║"
echo "║  Path:     $REMOTE_PATH                                                 ║"
echo "║  Tomcat:   http://$REMOTE_HOST:8080                                     ║"
echo "║                                                                         ║"
echo "║  Verify:                                                                ║"
echo "║    ssh $REMOTE 'bash $REMOTE_PATH/scripts/status.sh'                    ║"
echo "║    curl http://$REMOTE_HOST:8080/ae6e66/                                ║"
echo "║                                                                         ║"
echo "║  SSH:      ssh $REMOTE                                                  ║"
echo "║  Logs:     ssh $REMOTE 'tail -f $REMOTE_PATH/logging/nwe-main.log'      ║"
echo "╚═══════════════════════════════════════════════════════════════════════════╝"
echo ""
