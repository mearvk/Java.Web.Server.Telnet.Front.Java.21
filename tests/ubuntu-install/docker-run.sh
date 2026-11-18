#!/usr/bin/env bash
# Run run-tests.sh inside a throw-away systemd Ubuntu container.
#   bash tests/ubuntu-install/docker-run.sh [22.04|24.04]
set -euo pipefail
UBUNTU="${1:-24.04}"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
IMG="jwstf-install-test:$UBUNTU"
NAME="jwstf-install-test-$UBUNTU"
docker build -q --build-arg UBUNTU="$UBUNTU" -t "$IMG" "$HERE" >/dev/null
docker rm -f "$NAME" >/dev/null 2>&1 || true
docker run -d --name "$NAME" --privileged --cgroupns=host \
    -v /sys/fs/cgroup:/sys/fs/cgroup:rw -v "$REPO":/repo:ro --tmpfs /run --tmpfs /run/lock "$IMG" >/dev/null
trap 'docker rm -f "$NAME" >/dev/null 2>&1 || true' EXIT
for _ in $(seq 1 30); do
    docker exec "$NAME" systemctl is-system-running 2>/dev/null | grep -qE 'running|degraded' && break; sleep 1
done
# the repo is mounted read-only; the installer only reads it, but give it a writable copy for out.rebuilt-style temp files
docker exec "$NAME" bash -c 'cp -a /repo /work'
docker exec "$NAME" bash /work/tests/ubuntu-install/run-tests.sh
