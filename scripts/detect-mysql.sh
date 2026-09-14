#!/bin/bash
# scripts/detect-mysql.sh — Detect MySQL datadir (main drive or block storage)
# Source from other scripts: source "$(dirname "$0")/../scripts/detect-mysql.sh"
#
# Sets: MYSQL_DATADIR, MYSQL_ON_BLOCK, MYSQL_HOST, MYSQL_PORT, BLOCK_MOUNT

BLOCK_MOUNT="/mnt/blockstorage"
MYSQL_HOST="localhost"
MYSQL_PORT="3306"
MYSQL_ON_BLOCK="false"

# Detect from config
if [ -f /etc/mysql/mysql.conf.d/mysqld.cnf ]; then
    MYSQL_DATADIR=$(grep -E "^datadir" /etc/mysql/mysql.conf.d/mysqld.cnf 2>/dev/null | awk -F= '{print $2}' | tr -d ' ')
fi

# Fallback: symlink check
if [ -z "$MYSQL_DATADIR" ]; then
    if [ -L /var/lib/mysql ]; then
        MYSQL_DATADIR=$(readlink -f /var/lib/mysql)
    else
        MYSQL_DATADIR="/var/lib/mysql"
    fi
fi

# Is it on block storage?
case "$MYSQL_DATADIR" in
    /mnt/blockstorage*) MYSQL_ON_BLOCK="true" ;;
esac

export MYSQL_DATADIR MYSQL_ON_BLOCK MYSQL_HOST MYSQL_PORT BLOCK_MOUNT

# If run directly (not sourced), print info
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    echo "MySQL datadir:    $MYSQL_DATADIR"
    echo "On block storage: $MYSQL_ON_BLOCK"
    echo "Block mounted:    $(mountpoint -q $BLOCK_MOUNT 2>/dev/null && echo yes || echo no)"
    echo "MySQL running:    $(mysqladmin ping 2>/dev/null && echo yes || echo no)"
    df -h / | tail -1 | awk '{print "Main drive:      ", $3, "used /", $2, "("$5")"}'
    mountpoint -q "$BLOCK_MOUNT" 2>/dev/null && df -h "$BLOCK_MOUNT" | tail -1 | awk '{print "Block storage:   ", $3, "used /", $2, "("$5")"}'
fi
