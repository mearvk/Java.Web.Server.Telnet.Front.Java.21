#!/usr/bin/env bash
set -e

# Ensure the script is run with root privileges
if [ "$EUID" -ne 0 ]; then
    echo "Error: Please run this script with sudo or as root." >&2
    exit 1
fi

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "Error: Cannot detect operating system." >&2
    exit 1
fi

echo "Detected OS: $OS"

case "$OS" in
    ubuntu|debian|pop|mint)
        echo "Updating package lists..."
        apt-get update -y

        echo "Installing ClamAV packages..."
        apt-get install -y clamav clamav-daemon

        # Stop freshclam service to unlock the database directory for a manual update
        echo "Stopping freshclam daemon for initial manual sync..."
        systemctl stop clamav-freshclam || true
        ;;

    rhel|centos|rocky|almalinux|amzn)
        echo "Installing EPEL repository and ClamAV packages..."
        dnf install -y epel-release || yum install -y epel-release
        dnf install -y clamav clamd clamav-update || yum install -y clamav clamd clamav-update
        ;;

    *)
        echo "Error: Unsupported operating system: $OS" >&2
        exit 1
    ;;
esac

# Execute the database signature update
echo "Updating virus signature database via freshclam..."
if freshclam; then
    echo "Database successfully updated."
else
    echo "Warning: freshclam encountered an issue. Mirror might be rate-limiting. Checking configuration..."
fi

# Enable and start the background daemons for real-time protection and auto-updates
echo "Enabling and starting ClamAV background services..."
if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ] || [ "$OS" = "pop" ] || [ "$OS" = "mint" ]; then
    systemctl enable clamav-freshclam
    systemctl start clamav-freshclam
    systemctl enable clamav-daemon
    systemctl start clamav-daemon
else
    # RedHat-based path configurations
    systemctl enable clamav-freshclam
    systemctl start clamav-freshclam
    systemctl enable clamd@scan
    systemctl start clamd@scan
fi

echo "=================================================="
echo " ClamAV installation and database sync completed! "
echo "=================================================="
clamscan --version
