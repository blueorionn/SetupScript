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
