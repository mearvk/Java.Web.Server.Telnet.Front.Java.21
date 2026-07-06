#!/usr/bin/env bash
# NWE.firewall.sh — Open all NitroWebExpress ports via ufw (preferred) or iptables.
# Usage: sudo bash bash/NWE.firewall.sh [--remove]
#   --remove: closes all NWE ports instead of opening them.

set -euo pipefail

ACTION="${1:-allow}"
[[ "$ACTION" == "--remove" ]] && ACTION="deny"

# All NWE ports
PORTS=(
    49152   # NitroWebExpress (main Telnet proxy)
    49155   # ConnectionStatusServer
    49166   # ModuleInstallationService
    49177   # ASCIICreatorServer
    49188   # ModuleLoaderDaemon
    49199   # Communicator
    49200   # CalendarD44Server
    49201   # JapanSignalServer
    49202   # RussiaSignalServer
    49203   # MexicoSignalServer
    49204   # GreeceInternationalSignalServer
    49210   # CaliforniaFBI
    49211   # CaliforniaCIA
    49212   # CaliforniaNSA
    49213   # DukeUniversity
    49214   # StanfordLibrary
    49144   # BinaryHttpServer
    49133   # WeatherServer
    49111   # AIProctorModule
    20000   # Strernary (best-guess inference)
    2000    # Strernary Directory
    5000    # Futures (Democratic AI)
    5512    # AES 2.0 Compliant
    6682    # Bitcoin Compliant
    7743    # RSA Compliant
    7744    # DSA Compliant
    9999    # GrayPortRegistry
    10085   # Gray85 Crème Registry
    8888    # MiddleDirectorServer / NWE Module Installer
)

echo "=== NWE Firewall Configuration ==="
echo "Action: $ACTION"
echo ""

if command -v ufw &>/dev/null; then
    echo "[ufw] Using ufw..."
    for PORT in "${PORTS[@]}"; do
        if [[ "$ACTION" == "allow" ]]; then
            sudo ufw allow "$PORT/tcp" comment "NWE port $PORT" 2>/dev/null || \
            sudo ufw allow "$PORT/tcp" 2>/dev/null
            echo "  [OK] ufw allow $PORT/tcp"
        else
            sudo ufw delete allow "$PORT/tcp" 2>/dev/null || true
            echo "  [OK] ufw deny $PORT/tcp (removed)"
        fi
    done
    sudo ufw --force enable 2>/dev/null || true
    echo ""
    echo "[ufw] Firewall rules applied. Status:"
    sudo ufw status numbered | grep -E "(49|20000|5512|6682|7743|7744|8888)" || echo "  (no NWE rules visible — check 'sudo ufw status')"

elif command -v iptables &>/dev/null; then
    echo "[iptables] Using iptables..."
    for PORT in "${PORTS[@]}"; do
        if [[ "$ACTION" == "allow" ]]; then
            sudo iptables -A INPUT -p tcp --dport "$PORT" -j ACCEPT 2>/dev/null
            echo "  [OK] iptables ACCEPT $PORT/tcp"
        else
            sudo iptables -D INPUT -p tcp --dport "$PORT" -j ACCEPT 2>/dev/null || true
            echo "  [OK] iptables removed $PORT/tcp"
        fi
    done
    echo ""
    echo "[iptables] Rules applied. Saving..."
    if command -v netfilter-persistent &>/dev/null; then
        sudo netfilter-persistent save 2>/dev/null
    elif command -v iptables-save &>/dev/null; then
        sudo iptables-save > /etc/iptables/rules.v4 2>/dev/null || \
        sudo iptables-save > /etc/iptables.rules 2>/dev/null || true
    fi

else
    echo "[ERROR] Neither ufw nor iptables found."
    echo "        Install ufw: sudo apt install ufw"
    echo "        Or manually open ports: ${PORTS[*]}"
    exit 1
fi

echo ""
echo "=== NWE Firewall $ACTION complete ==="
