#!/bin/bash
# ============================================================================
# Brarner.M.Alete™ — Setup Analysis Storage Directories
# Creates the upload, results, and quarantine directories for file analysis.
# ============================================================================

echo "═══════════════════════════════════════════════════════════════"
echo " Brarner.M.Alete™ — Setup Analysis Storage"
echo "═══════════════════════════════════════════════════════════════"

DIRS=(
    "/opt/bma/analysis/uploads"
    "/opt/bma/analysis/results"
    "/opt/bma/analysis/quarantine"
)

for dir in "${DIRS[@]}"; do
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        echo "  [+] Created: $dir"
    else
        echo "  [✓] Exists:  $dir"
    fi
done

# Set permissions (Tomcat user typically tomcat or www-data)
TOMCAT_USER="${1:-tomcat}"
if id "$TOMCAT_USER" &>/dev/null; then
    chown -R "$TOMCAT_USER":"$TOMCAT_USER" /opt/bma/analysis
    chmod -R 750 /opt/bma/analysis
    echo ""
    echo "  [✓] Ownership set to: $TOMCAT_USER"
else
    chmod -R 777 /opt/bma/analysis
    echo ""
    echo "  [!] User '$TOMCAT_USER' not found — using chmod 777"
    echo "      Re-run with: sudo bash setup-analysis-storage.sh <tomcat-user>"
fi

# Verify ClamAV is installed
echo ""
if command -v clamscan &>/dev/null; then
    CLAM_VER=$(clamscan --version 2>/dev/null | head -1)
    echo "  [✓] ClamAV: $CLAM_VER"
else
    echo "  [!] ClamAV not found. Install with:"
    echo "      sudo apt install clamav clamav-daemon"
    echo "      sudo freshclam"
    echo ""
    echo "      Analysis will still work without ClamAV (files allowed through)"
    echo "      but production deployments MUST have ClamAV installed."
fi

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo " [✓] Analysis storage ready"
echo "═══════════════════════════════════════════════════════════════"
