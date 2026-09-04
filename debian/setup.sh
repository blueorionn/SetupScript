#!/bin/bash
set -euo pipefail
# Copyright (c) 2025-present, Swadhin
# E.g. bash setup.sh
# E.g. bash setup.sh -u USERNAME -i PACKAGE-1 PACKAGE-2

# Check if the script is running with sudo (root privileges)
if [[ $EUID -ne 0 ]]; then
    echo "[ERROR] $(date +"%Y-%m-%d %H:%M:%S") - This script must be run with sudo or as root."
    exit 1
fi

# Default values
USER_TO_CHECK="admin"
DEFAULT_PACKAGES="curl wget tree htop net-tools git build-essential"
PACKAGES_TO_INSTALL="$DEFAULT_PACKAGES"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -u|--user)
            if [[ -z "${2:-}" ]]; then
                echo "[ERROR] $(date +"%Y-%m-%d %H:%M:%S") - Option -u requires a username."
                exit 1
            fi
            if ! [[ "$2" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
                echo "[ERROR] $(date +"%Y-%m-%d %H:%M:%S") - Invalid username: $2"
                exit 1
            fi
            USER_TO_CHECK="$2"
            shift 2
            ;;
        -i|--install)
            if [[ $# -lt 2 || "${2:-}" == -* ]]; then
                echo "[ERROR] $(date +"%Y-%m-%d %H:%M:%S") - Option -i requires at least one package name."
                exit 1
            fi
            shift
            # Consume packages until the next flag, so flags can come in any order
            while [[ $# -gt 0 && "$1" != -* ]]; do
                PACKAGES_TO_INSTALL="$PACKAGES_TO_INSTALL ${1//,/ }"
                shift
            done
            ;;
        *)
            echo "[ERROR] $(date +"%Y-%m-%d %H:%M:%S") - Unknown argument: $1"
            echo "[INFO] Usage: bash setup.sh [-u USERNAME] [-i PACKAGE-1 PACKAGE-2 ...]"
            exit 1
            ;;
    esac
done

# Check if the system is running Debian
echo "[LOG] $(date +"%Y-%m-%d %H:%M:%S") - Checking system os"

if [[ ! -f /etc/debian_version ]]; then
    echo "[ERROR] $(date +"%Y-%m-%d %H:%M:%S") - This system is not running Debian."
    exit 1
fi

echo "[INFO] $(date +"%Y-%m-%d %H:%M:%S") - System is running Debian."

# This script is only intented to run on debian v12.
echo "[LOG] $(date +"%Y-%m-%d %H:%M:%S") - Checking debian version..."
DEBIAN_VERSION=$(cat /etc/debian_version)

if [[ "$DEBIAN_VERSION" != 12.* ]]; then
    echo "[ERROR] $(date +"%Y-%m-%d %H:%M:%S") - This script is only intended for running in Debian 12.x."
    exit 1
fi

echo "[INFO] $(date +"%Y-%m-%d %H:%M:%S") - Debian version $DEBIAN_VERSION detected executing script."

# Update and upgrade Debian
echo "[INFO] $(date +"%Y-%m-%d %H:%M:%S") - Updating and Upgrading Debian."
apt-get update && apt-get upgrade -y

# Checking if user exist
USER_HOME="/home/$USER_TO_CHECK"

if id $USER_TO_CHECK >/dev/null 2>&1; then
    echo "[INFO] $(date +"%Y-%m-%d %H:%M:%S") - User $USER_TO_CHECK exists."

    # Checking if home directory for user exist.
    if [[ ! -d $USER_HOME ]]; then
        echo "[WARNING] $(date +"%Y-%m-%d %H:%M:%S") - Home directory for user $USER_TO_CHECK doesn't exists."
        
        # Creating Home directory for specified user
        mkdir -p "$USER_HOME"
        chown -R "$USER_TO_CHECK":"$USER_TO_CHECK" "$USER_HOME"
        chmod 700 "$USER_HOME"

        echo "[INFO] $(date +"%Y-%m-%d %H:%M:%S") - Home directory for '$USER_TO_CHECK' has been created and configured."
        
    else
        echo "[INFO] $(date +"%Y-%m-%d %H:%M:%S") - Home directory for user $USER_TO_CHECK exists."
    fi

else
    echo "[WARNING] $(date +"%Y-%m-%d %H:%M:%S") - User $USER_TO_CHECK doesn't exists."

    # Creating specified user with home directory and bash shell
    echo "[INFO] $(date +"%Y-%m-%d %H:%M:%S") - Creating $USER_TO_CHECK user."
    useradd -m -s /bin/bash $USER_TO_CHECK
    chmod 700 $USER_HOME
    echo "[INFO] $(date +"%Y-%m-%d %H:%M:%S") - $USER_TO_CHECK user created."

    # Adding user to sudoers group
    echo "[INFO] $(date +"%Y-%m-%d %H:%M:%S") - Adding $USER_TO_CHECK to sudoers group."
    usermod -aG sudo $USER_TO_CHECK

    # Specify user password
    echo "[INFO] $(date +"%Y-%m-%d %H:%M:%S") - Specify $USER_TO_CHECK passwd."
    passwd "$USER_TO_CHECK" || echo "[WARNING] $(date +"%Y-%m-%d %H:%M:%S") - Password not set for $USER_TO_CHECK."
fi

# SSH Configuration
if [[ -f /root/.ssh/authorized_keys ]]; then

    # Copying authorized_keys (mkdir -p is a no-op if .ssh already exists)
    mkdir -p "$USER_HOME/.ssh"
    cp /root/.ssh/authorized_keys "$USER_HOME/.ssh/authorized_keys"
    chown -R $USER_TO_CHECK:$USER_TO_CHECK "$USER_HOME/.ssh"
    chmod 700 "$USER_HOME/.ssh"
    chmod 600 "$USER_HOME/.ssh/authorized_keys"
    echo "[INFO] $(date +"%Y-%m-%d %H:%M:%S") - Copied authorized_keys to specified user."
else
    echo "[WARNING] $(date +"%Y-%m-%d %H:%M:%S") - Root doesn't have authorized_keys."
fi

# Install packages
echo "[INFO] $(date +"%Y-%m-%d %H:%M:%S") - Installing packages."

apt-get install -y $PACKAGES_TO_INSTALL

echo "[INFO] $(date +"%Y-%m-%d %H:%M:%S") - Installation complete."