#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════════════
# migrate-mysql-to-blockstorage.sh
# Moves MySQL data from /var/lib/mysql to /mnt/blockstorage/mysql
# to free main drive space for web deployment.
#
# Target: Production server (45.32.31.139 / lauradei.us)
# Author: Max Rupplin — MEARVK LLC
# Date:   July 1 2026
#
# Usage: sudo bash scripts/migrate-mysql-to-blockstorage.sh
# Rollback: sudo bash scripts/migrate-mysql-to-blockstorage.sh --rollback
# ═══════════════════════════════════════════════════════════════════════════════
set -euo pipefail

BLOCK_MOUNT="/mnt/blockstorage"
NEW_DATADIR="$BLOCK_MOUNT/mysql"
OLD_DATADIR="/var/lib/mysql"
MYSQL_CONF="/etc/mysql/mysql.conf.d/mysqld.cnf"
BACKUP_CONF="${MYSQL_CONF}.bak.$(date +%Y%m%d%H%M%S)"

log()  { echo "[*] $1"; }
warn() { echo "[!] $1"; }
fail() { echo "[FAIL] $1"; exit 1; }

[ "$(id -u)" -ne 0 ] && fail "Must run as root: sudo bash $0"

# ── Rollback ──────────────────────────────────────────────────────────────────
if [ "${1:-}" = "--rollback" ]; then
    echo "═══ MySQL Migration Rollback ═══"
    systemctl stop mysql 2>/dev/null || systemctl stop mysqld 2>/dev/null || true
    sleep 2
    if [ -L "$OLD_DATADIR" ]; then
        rm -f "$OLD_DATADIR"
        if [ -d "${OLD_DATADIR}.original" ]; then
            mv "${OLD_DATADIR}.original" "$OLD_DATADIR"
        else
            rsync -aAX "$NEW_DATADIR/" "$OLD_DATADIR/"
        fi
    fi
    LATEST_BAK=$(ls -t /etc/mysql/mysql.conf.d/mysqld.cnf.bak.* 2>/dev/null | head -1)
    [ -n "$LATEST_BAK" ] && cp "$LATEST_BAK" "$MYSQL_CONF"
    if [ -f /etc/apparmor.d/usr.sbin.mysqld ]; then
        sed -i "\|$BLOCK_MOUNT/mysql|d" /etc/apparmor.d/usr.sbin.mysqld
        apparmor_parser -r /etc/apparmor.d/usr.sbin.mysqld 2>/dev/null || true
    fi
    systemctl start mysql 2>/dev/null || systemctl start mysqld 2>/dev/null
    sleep 3
    mysqladmin ping &>/dev/null && log "Rollback complete. MySQL running." || fail "MySQL failed after rollback."
    exit 0
fi

# ── Pre-flight ────────────────────────────────────────────────────────────────
echo "═══════════════════════════════════════════════════════════════"
echo " MySQL → Block Storage Migration"
echo " Source: $OLD_DATADIR"
echo " Target: $NEW_DATADIR"
echo "═══════════════════════════════════════════════════════════════"
echo ""

mountpoint -q "$BLOCK_MOUNT" 2>/dev/null || fail "$BLOCK_MOUNT not mounted. Mount block storage first."

AVAIL_KB=$(df --output=avail "$BLOCK_MOUNT" | tail -1 | tr -d ' ')
MYSQL_KB=$(du -sk "$OLD_DATADIR" 2>/dev/null | awk '{print $1}')
log "Block storage free: $((AVAIL_KB/1024)) MB | MySQL size: $((MYSQL_KB/1024)) MB"
[ "$AVAIL_KB" -lt "$((MYSQL_KB + 524288))" ] && fail "Not enough space on block storage."

MAIN_BEFORE=$(df --output=avail / | tail -1 | tr -d ' ')

# ── Step 1: Stop MySQL ────────────────────────────────────────────────────────
log "Stopping MySQL..."
systemctl stop mysql 2>/dev/null || systemctl stop mysqld 2>/dev/null
sleep 3
pgrep -x mysqld &>/dev/null && fail "MySQL still running."
log "MySQL stopped."

# ── Step 2: Copy data ─────────────────────────────────────────────────────────
log "Copying data to $NEW_DATADIR..."
mkdir -p "$NEW_DATADIR"
rsync -aAX "$OLD_DATADIR/" "$NEW_DATADIR/"
OLD_COUNT=$(find "$OLD_DATADIR" -type f | wc -l)
NEW_COUNT=$(find "$NEW_DATADIR" -type f | wc -l)
[ "$NEW_COUNT" -lt "$OLD_COUNT" ] && fail "Copy incomplete: $OLD_COUNT → $NEW_COUNT"
log "Copied $NEW_COUNT files."

# ── Step 3: Update config ─────────────────────────────────────────────────────
cp "$MYSQL_CONF" "$BACKUP_CONF"
if grep -q "^datadir" "$MYSQL_CONF"; then
    sed -i "s|^datadir.*|datadir = $NEW_DATADIR|" "$MYSQL_CONF"
elif grep -q "^# datadir" "$MYSQL_CONF"; then
    sed -i "s|^# datadir.*|datadir = $NEW_DATADIR|" "$MYSQL_CONF"
else
    echo "datadir = $NEW_DATADIR" >> "$MYSQL_CONF"
fi
log "Config updated: datadir = $NEW_DATADIR"

# ── Step 4: AppArmor ─────────────────────────────────────────────────────────
if [ -f /etc/apparmor.d/usr.sbin.mysqld ]; then
    if ! grep -q "$NEW_DATADIR" /etc/apparmor.d/usr.sbin.mysqld; then
        sed -i "/\/var\/lib\/mysql\/ r,/a\\  $NEW_DATADIR/ r,\n  $NEW_DATADIR/** rwk," /etc/apparmor.d/usr.sbin.mysqld
    fi
    apparmor_parser -r /etc/apparmor.d/usr.sbin.mysqld 2>/dev/null || true
    log "AppArmor updated."
fi

# ── Step 5: Symlink ──────────────────────────────────────────────────────────
mv "$OLD_DATADIR" "${OLD_DATADIR}.original"
ln -s "$NEW_DATADIR" "$OLD_DATADIR"
log "Symlink: $OLD_DATADIR → $NEW_DATADIR"

# ── Step 6: Start MySQL ──────────────────────────────────────────────────────
log "Starting MySQL..."
systemctl start mysql 2>/dev/null || systemctl start mysqld 2>/dev/null
sleep 5

if ! mysqladmin ping &>/dev/null; then
    warn "MySQL failed to start. Rolling back..."
    bash "$0" --rollback
    exit 1
fi

DB_COUNT=$(mysql -N -e "SELECT COUNT(*) FROM information_schema.SCHEMATA;" 2>/dev/null || echo "?")
log "MySQL running. Databases: $DB_COUNT"

# ── Step 7: Free space ───────────────────────────────────────────────────────
rm -rf "${OLD_DATADIR}.original"
MAIN_AFTER=$(df --output=avail / | tail -1 | tr -d ' ')
FREED_MB=$(( (MAIN_AFTER - MAIN_BEFORE) / 1024 ))

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo " Migration Complete"
echo "  New datadir: $NEW_DATADIR"
echo "  Space freed: ${FREED_MB} MB"
echo "  MySQL: running ($DB_COUNT databases)"
echo "  Config backup: $BACKUP_CONF"
echo "  Rollback: sudo bash $0 --rollback"
echo "═══════════════════════════════════════════════════════════════"
df -h / | awk 'NR==2{print "  Main drive:  Used:", $3, " Avail:", $4, " ("$5")"}'
df -h "$BLOCK_MOUNT" | awk 'NR==2{print "  Block store: Used:", $3, " Avail:", $4, " ("$5")"}'
echo "═══════════════════════════════════════════════════════════════"
