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
DEFAULT_PACKAGES="sudo curl wget tree htop net-tools git build-essential"
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

# Check if the system is a supported Debian or Ubuntu release
echo "[LOG] $(date +"%Y-%m-%d %H:%M:%S") - Checking system os"

if [[ ! -r /etc/os-release ]]; then
    echo "[ERROR] $(date +"%Y-%m-%d %H:%M:%S") - Cannot detect OS: /etc/os-release not found."
    exit 1
fi

. /etc/os-release

case "${ID:-}" in
    debian)
        case "${VERSION_ID:-}" in
            9|10|11|12|13) OS_INFO="Debian $VERSION_ID" ;;
            *)
                echo "[ERROR] $(date +"%Y-%m-%d %H:%M:%S") - Debian ${VERSION_ID:-unknown} is not supported. Supported: 9-13."
                exit 1
                ;;
        esac
        ;;
    ubuntu)
        case "${VERSION_ID:-}" in
            16.04|18.04|20.04|22.04|24.04|26.04) OS_INFO="Ubuntu $VERSION_ID" ;;
            *)
                echo "[ERROR] $(date +"%Y-%m-%d %H:%M:%S") - Ubuntu ${VERSION_ID:-unknown} is not supported. Supported LTS: 16.04-26.04."
                exit 1
                ;;
        esac
        ;;
    *)
        echo "[ERROR] $(date +"%Y-%m-%d %H:%M:%S") - Unsupported distribution '${ID:-unknown}'. Only Debian and Ubuntu are supported."
        exit 1
        ;;
esac

echo "[INFO] $(date +"%Y-%m-%d %H:%M:%S") - $OS_INFO detected executing script."

# Update and upgrade the system
echo "[INFO] $(date +"%Y-%m-%d %H:%M:%S") - Updating and Upgrading the system."
apt-get update && apt-get upgrade -y

# Install packages (before user setup so sudo is available on minimal installs)
echo "[INFO] $(date +"%Y-%m-%d %H:%M:%S") - Installing packages."
apt-get install -y $PACKAGES_TO_INSTALL

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
    if getent group "$USER_TO_CHECK" >/dev/null; then
        # A group with this name already exists, reuse it
        useradd -m -s /bin/bash -g "$USER_TO_CHECK" "$USER_TO_CHECK"
    else
        useradd -m -s /bin/bash "$USER_TO_CHECK"
    fi
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

echo "[INFO] $(date +"%Y-%m-%d %H:%M:%S") - Setup complete."