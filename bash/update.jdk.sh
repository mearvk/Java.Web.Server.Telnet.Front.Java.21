#!/usr/bin/env bash
set -e

REQUIRED_MAJOR=25
INSTALL_DIR="/usr/local/java25"

check_java_version() {
    if ! command -v java &> /dev/null; then
        return 1
    fi

    local version_str
    version_str=$(java -version 2>&1 | head -n 1 | cut -d '"' -f 2)

    local major_version
    major_version=$(echo "$version_str" | cut -d '.' -f 1)

    if [ "$major_version" -ge "$REQUIRED_MAJOR" ]; then
        echo "Found Java version $version_str (Matches requirement JDK $REQUIRED_MAJOR+)."
        return 0
    else
        echo "Found older Java version: $version_str."
        return 1
    fi
}

install_jdk25() {
    echo "Downloading and installing JDK 25..."

    # Detect Architecture
    local arch
    arch=$(uname -m)
    if [ "$arch" = "x86_64" ]; then
        local url="https://oracle.com"
    elif [ "$arch" = "aarch64" ]; then
        local url="https://oracle.com"
    else
        echo "Unsupported architecture: $arch" >&2
        exit 1
    fi

    # Download and extract
    sudo mkdir -p "$INSTALL_DIR"
    curl -sSL "$url" | sudo tar -xzf - -C "$INSTALL_DIR" --strip-components=1

    # Update system alternatives
    sudo update-alternatives --install /usr/bin/java java "$INSTALL_DIR/bin/java" 2000
    sudo update-alternatives --install /usr/bin/javac javac "$INSTALL_DIR/bin/javac" 2000
    sudo update-alternatives --set java "$INSTALL_DIR/bin/java"
    sudo update-alternatives --set javac "$INSTALL_DIR/bin/javac"

    echo "JDK 25 installed and activated successfully."
}

# Main execution flow
if check_java_version; then
    echo "Environment verified. Ready to run."
else
    if [ "$EUID" -ne 0 ]; then
        echo "Please re-run this script with 'sudo' or as root to update Java."
        exit 1
    fi
    install_jdk25
fi
