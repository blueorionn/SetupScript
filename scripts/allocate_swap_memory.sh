#!/bin/bash
set -euo pipefail
# Copyright (c) 2025-present, Swadhin

# A swap file acts as virtual memory, allowing your system to use disk storage when RAM is full.
# E.g. bash allocate_swap_memory.sh

# Check if the script is running with sudo (root privileges)
if [[ $EUID -ne 0 ]]; then
    echo "[ERROR] $(date +"%Y-%m-%d %H:%M:%S") - This script must be run with sudo or as root."
    exit 1
fi

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

# Swap file location
PARENT_FOLDER="/swaps"
FILE_NAME="swapfile"
FILE_PATH="$PARENT_FOLDER/$FILE_NAME"

# Abort if the swap file is already active
echo "[INFO] $(date +"%Y-%m-%d %H:%M:%S") - Checking for existing swap file."
swapon --show
if swapon --show=NAME --noheadings | grep -qxF "$FILE_PATH"; then
    echo "[ERROR] $(date +"%Y-%m-%d %H:%M:%S") - Swap is already active at $FILE_PATH."
    exit 1
fi

# Prompt for swap size and validate it
while true; do
    read -rp "[INPUT] Enter swap size in MB: " SWAP_SIZE_MB
    if [[ "$SWAP_SIZE_MB" =~ ^[0-9]+$ ]] && [[ "10#$SWAP_SIZE_MB" -gt 0 ]]; then
        break
    fi
    echo "[ERROR] $(date +"%Y-%m-%d %H:%M:%S") - Invalid input. Enter digits only (greater than zero)."
done

# Creating swapfile
echo "[INFO] $(date +"%Y-%m-%d %H:%M:%S") - Creating $FILE_NAME of size ${SWAP_SIZE_MB}MB in path $FILE_PATH"
mkdir -p "$PARENT_FOLDER"
fallocate -l "${SWAP_SIZE_MB}M" "$FILE_PATH"

# Set Correct Permissions
echo "[INFO] $(date +"%Y-%m-%d %H:%M:%S") - Setting correct permissions"
chmod 600 "$FILE_PATH"

# Format the file as swap
echo "[INFO] $(date +"%Y-%m-%d %H:%M:%S") - Creating Swap File"
mkswap "$FILE_PATH"

# Enable swap file
echo "[INFO] $(date +"%Y-%m-%d %H:%M:%S") - Enable Swap File"
swapon "$FILE_PATH"

# Make Swap Persistent Across Reboots
if grep -q "^$FILE_PATH[[:space:]]" /etc/fstab; then
    echo "[WARNING] $(date +"%Y-%m-%d %H:%M:%S") - fstab already contains an entry for $FILE_PATH, skipping."
else
    echo "$FILE_PATH none swap sw 0 0" | tee -a /etc/fstab
fi

# Verify swap file
echo "[INFO] $(date +"%Y-%m-%d %H:%M:%S") - Verifying Swapfile"
swapon --show
free -h
