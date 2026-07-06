#!/bin/bash
# Quick UFW allow for all NWE ports
# Usage: sudo bash scripts/ufw-allow-all.sh
for PORT in 2000 5000 5512 6682 7743 7744 8080 8888 9999 10085 20000 \
            49111 49133 49144 49152 49155 49166 49177 49188 49199 49200 \
            49201 49202 49203 49204 49210 49211 49212 49213 49214; do
    ufw allow "$PORT/tcp" >/dev/null 2>&1 && echo "OK $PORT" || echo "FAIL $PORT"
done
ufw --force enable
ufw status numbered | grep -c ALLOW | xargs -I{} echo "Done: {} rules active"
