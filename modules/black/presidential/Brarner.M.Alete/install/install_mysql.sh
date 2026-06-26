#!/bin/bash
echo "--- MySQL Install Check ---"

if command -v mysql &>/dev/null; then
    echo "MySQL client found."
    mysql --version
else
    echo "MySQL not found."
    echo
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macOS detected. Installing via Homebrew..."
        if command -v brew &>/dev/null; then
            brew install mysql
        else
            echo "Homebrew not found. Install from: https://brew.sh"
            echo "Then run: brew install mysql"
        fi
    else
        echo "Linux detected."
        if command -v apt-get &>/dev/null; then
            echo "Installing via apt..."
            sudo apt-get update && sudo apt-get install -y mysql-server mysql-client
        elif command -v yum &>/dev/null; then
            echo "Installing via yum..."
            sudo yum install -y mysql-server mysql
        elif command -v dnf &>/dev/null; then
            echo "Installing via dnf..."
            sudo dnf install -y mysql-server mysql
        else
            echo "Download from: https://dev.mysql.com/downloads/mysql/"
        fi
    fi
fi

echo
echo "--- MySQL Service Status ---"
if [[ "$OSTYPE" == "darwin"* ]]; then
    brew services list 2>/dev/null | grep mysql || echo "MySQL service not registered with brew services."
else
    systemctl status mysql 2>/dev/null || systemctl status mysqld 2>/dev/null || echo "MySQL service not found."
fi
