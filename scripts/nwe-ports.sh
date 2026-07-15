#!/bin/bash
# scripts/nwe-ports.sh — NWE Port Open/Close Functions
# Source from start/shutdown scripts:
#   source "$PROJECT_ROOT/scripts/nwe-ports.sh"
#
# Functions:
#   nwe_open_ports   — Opens all NWE service ports in the firewall
#   nwe_close_ports  — Closes all NWE service ports in the firewall
#   nwe_port_status  — Shows which NWE ports are currently allowed/denied
#
# Capitalization reference: configuration/print-method.xml §script-descriptors

# ═══════════════════════════════════════════════════════════════════════════════
# nwe_ensure_ufw — Install and enable UFW if not present (Linux only)
# Called before open/close operations to guarantee firewall availability.
# ═══════════════════════════════════════════════════════════════════════════════
nwe_ensure_ufw() {
    if command -v ufw &>/dev/null; then
        # UFW installed — ensure it's enabled
        if ! sudo ufw status 2>/dev/null | grep -q "Status: active"; then
            echo "  [*] UFW installed but inactive — enabling..."
            sudo ufw --force enable >/dev/null 2>&1
            echo "  [✓] UFW enabled"
        fi
        return 0
    fi

    # Not installed — try to install
    echo "  [*] UFW not found — installing..."
    if command -v apt-get &>/dev/null; then
        sudo apt-get update -qq >/dev/null 2>&1
        sudo apt-get install -y -qq ufw >/dev/null 2>&1
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y -q ufw >/dev/null 2>&1
    elif command -v yum &>/dev/null; then
        sudo yum install -y -q ufw >/dev/null 2>&1
    elif command -v pacman &>/dev/null; then
        sudo pacman -S --noconfirm ufw >/dev/null 2>&1
    else
        echo "  [!] Cannot install UFW — no supported package manager found"
        echo "      Install manually: apt install ufw / dnf install ufw"
        return 1
    fi

    if command -v ufw &>/dev/null; then
        # Allow SSH first to avoid lockout
        sudo ufw allow 22/tcp >/dev/null 2>&1
        sudo ufw --force enable >/dev/null 2>&1
        echo "  [✓] UFW installed and enabled (SSH port 22 pre-allowed)"
        return 0
    else
        echo "  [!] UFW installation failed"
        return 1
    fi
}

# ── Port List (authoritative — matches ufw-allow-all.sh and nwe-config.xml) ──
NWE_PORTS=(
    2000    # StrernaryDirectory
    5000    # Futures (DemocraticAI)
    5512    # AES Encryption
    6682    # Bitcoin
    7743    # RSA Encryption
    7744    # DSA Encryption
    8080    # Tomcat (all web frontends)
    8888    # Reserved
    9999    # Gray Port Registry
    10085   # Gray85 Crème Registry
    20000   # Strernary AI Inference
    49111   # Reserved
    49133   # WeatherServer
    49144   # BinaryHttp
    49152   # NitroWebExpress Main
    49155   # ConnectionStatus
    49166   # ModuleInstallation
    49177   # AsciiCreator
    49188   # ModuleLoaderDaemon
    49199   # Communicator
    49200   # CalendarD44
    49201   # JapanSignal
    49202   # RussiaSignal
    49203   # MexicoSignal
    49204   # GreeceInternational
    49210   # California FBI
    49211   # California CIA
    49212   # California NSA
    49213   # Duke University
    49214   # Stanford Library
)

# ═══════════════════════════════════════════════════════════════════════════════
# nwe_open_ports — Open all NWE ports in the system firewall
# Called by: start-all.sh, start-backends.sh, post-clone.sh
# ═══════════════════════════════════════════════════════════════════════════════
nwe_open_ports() {
    local OPENED=0 FAILED=0 SKIPPED=0

    # SECURITY: Set NWE_TRUSTED_IP to restrict access to a specific IP.
    # Without it, ports are open to ALL sources (0.0.0.0).
    if [ -z "$NWE_TRUSTED_IP" ]; then
        echo "[WARN] NWE_TRUSTED_IP not set — opening ports to ALL sources. Set NWE_TRUSTED_IP for production."
    fi

    echo "  [*] Opening NWE service ports..."

    # Ensure UFW is installed and active
    nwe_ensure_ufw

    if command -v ufw &>/dev/null; then
        for PORT in "${NWE_PORTS[@]}"; do
            if ufw status | grep -q "$PORT/tcp.*ALLOW" 2>/dev/null; then
                SKIPPED=$((SKIPPED + 1))
            elif [ -n "$NWE_TRUSTED_IP" ]; then
                if sudo ufw allow from "$NWE_TRUSTED_IP" to any port "$PORT" proto tcp comment "NWE: $PORT" 2>/dev/null; then
                    OPENED=$((OPENED + 1))
                else
                    FAILED=$((FAILED + 1))
                fi
            else
                if sudo ufw allow "$PORT/tcp" comment "NWE: $PORT" 2>/dev/null; then
                    OPENED=$((OPENED + 1))
                else
                    FAILED=$((FAILED + 1))
                fi
            fi
        done
        sudo ufw --force enable >/dev/null 2>&1
        echo "  [✓] UFW: $OPENED opened, $SKIPPED already open, $FAILED failed"

    elif command -v firewall-cmd &>/dev/null; then
        for PORT in "${NWE_PORTS[@]}"; do
            if firewall-cmd --query-port="$PORT/tcp" >/dev/null 2>&1; then
                SKIPPED=$((SKIPPED + 1))
            elif sudo firewall-cmd --permanent --add-port="$PORT/tcp" >/dev/null 2>&1; then
                OPENED=$((OPENED + 1))
            else
                FAILED=$((FAILED + 1))
            fi
        done
        sudo firewall-cmd --reload >/dev/null 2>&1
        echo "  [✓] firewalld: $OPENED opened, $SKIPPED already open, $FAILED failed"

    elif command -v iptables &>/dev/null; then
        for PORT in "${NWE_PORTS[@]}"; do
            if sudo iptables -C INPUT -p tcp --dport "$PORT" -j ACCEPT 2>/dev/null; then
                SKIPPED=$((SKIPPED + 1))
            elif sudo iptables -A INPUT -p tcp --dport "$PORT" -j ACCEPT 2>/dev/null; then
                OPENED=$((OPENED + 1))
            else
                FAILED=$((FAILED + 1))
            fi
        done
        echo "  [✓] iptables: $OPENED opened, $SKIPPED already open, $FAILED failed"

    else
        echo "  [--] No firewall tool found (ufw, firewalld, iptables) — ports not managed"
        return 1
    fi

    return 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# nwe_close_ports — Close all NWE ports in the system firewall
# Called by: shutdown-all.sh, shutdown-backends.sh
# ═══════════════════════════════════════════════════════════════════════════════
nwe_close_ports() {
    local CLOSED=0 SKIPPED=0 FAILED=0

    echo "  [*] Closing NWE service ports..."

    # Ensure UFW is available before attempting close
    nwe_ensure_ufw

    if command -v ufw &>/dev/null; then
        for PORT in "${NWE_PORTS[@]}"; do
            if ! ufw status | grep -q "$PORT/tcp.*ALLOW" 2>/dev/null; then
                SKIPPED=$((SKIPPED + 1))
            elif sudo ufw delete allow "$PORT/tcp" >/dev/null 2>&1; then
                CLOSED=$((CLOSED + 1))
            else
                FAILED=$((FAILED + 1))
            fi
        done
        echo "  [✓] UFW: $CLOSED closed, $SKIPPED already closed, $FAILED failed"

    elif command -v firewall-cmd &>/dev/null; then
        for PORT in "${NWE_PORTS[@]}"; do
            if ! firewall-cmd --query-port="$PORT/tcp" >/dev/null 2>&1; then
                SKIPPED=$((SKIPPED + 1))
            elif sudo firewall-cmd --permanent --remove-port="$PORT/tcp" >/dev/null 2>&1; then
                CLOSED=$((CLOSED + 1))
            else
                FAILED=$((FAILED + 1))
            fi
        done
        sudo firewall-cmd --reload >/dev/null 2>&1
        echo "  [✓] firewalld: $CLOSED closed, $SKIPPED already closed, $FAILED failed"

    elif command -v iptables &>/dev/null; then
        for PORT in "${NWE_PORTS[@]}"; do
            if ! sudo iptables -C INPUT -p tcp --dport "$PORT" -j ACCEPT 2>/dev/null; then
                SKIPPED=$((SKIPPED + 1))
            elif sudo iptables -D INPUT -p tcp --dport "$PORT" -j ACCEPT 2>/dev/null; then
                CLOSED=$((CLOSED + 1))
            else
                FAILED=$((FAILED + 1))
            fi
        done
        echo "  [✓] iptables: $CLOSED closed, $SKIPPED already closed, $FAILED failed"

    else
        echo "  [--] No firewall tool found (ufw, firewalld, iptables) — ports not managed"
        return 1
    fi

    return 0
}

# ═══════════════════════════════════════════════════════════════════════════════
# nwe_port_status — Show which NWE ports are currently open/closed
# Called by: status.sh
# ═══════════════════════════════════════════════════════════════════════════════
nwe_port_status() {
    local OPEN=0 CLOSED=0

    echo "  Firewall Port Status:"

    if command -v ufw &>/dev/null; then
        for PORT in "${NWE_PORTS[@]}"; do
            if ufw status | grep -q "$PORT/tcp.*ALLOW" 2>/dev/null; then
                OPEN=$((OPEN + 1))
            else
                CLOSED=$((CLOSED + 1))
            fi
        done
    elif command -v firewall-cmd &>/dev/null; then
        for PORT in "${NWE_PORTS[@]}"; do
            if firewall-cmd --query-port="$PORT/tcp" >/dev/null 2>&1; then
                OPEN=$((OPEN + 1))
            else
                CLOSED=$((CLOSED + 1))
            fi
        done
    else
        echo "    No firewall tool detected"
        return 1
    fi

    echo "    Open: $OPEN / ${#NWE_PORTS[@]}"
    if [ $CLOSED -gt 0 ]; then
        echo "    Closed: $CLOSED"
    fi
    return 0
}

# If run directly (not sourced), show usage
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    case "${1:-}" in
        open)   nwe_open_ports ;;
        close)  nwe_close_ports ;;
        status) nwe_port_status ;;
        *)
            echo "NWE Port Manager — ${#NWE_PORTS[@]} service ports"
            echo ""
            echo "Usage:"
            echo "  bash scripts/nwe-ports.sh open     Open all NWE ports"
            echo "  bash scripts/nwe-ports.sh close    Close all NWE ports"
            echo "  bash scripts/nwe-ports.sh status   Show port firewall status"
            echo ""
            echo "Or source from another script:"
            echo "  source \"\$PROJECT_ROOT/scripts/nwe-ports.sh\""
            echo "  nwe_open_ports"
            echo "  nwe_close_ports"
            ;;
    esac
fi
