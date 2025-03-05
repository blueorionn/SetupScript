#!/bin/bash

# A swap file acts as virtual memory, allowing your system to use disk storage when RAM is full. 
# It helps prevent crashes and keeps your system running smoothly, even when RAM is exhausted.
# This script can be used to generate such a swap file.

# Check if the script is running with sudo (root privileges)
if [[ $EUID -ne 0 ]]; then
    echo "[ERROR] $(date +"%Y-%m-%d %H:%M:%S") - This script must be run with sudo or as root."
    exit 1
fi

# Check if the system is running Debian
echo "[LOG] $(date +"%Y-%m-%d %H:%M:%S") - Checking system os"

if ! grep -qi 'ubuntu' /etc/os-release; then
    echo "[ERROR] $(date +"%Y-%m-%d %H:%M:%S") - This system is not running Ubuntu."
    exit 1
else
    echo "[INFO] $(date +"%Y-%m-%d %H:%M:%S") - System is running Ubuntu."
fi

# Update and upgrade Debian
echo "[INFO] $(date +"%Y-%m-%d %H:%M:%S") - Updating and Upgrading Debian."
sudo apt-get update && sudo apt-get upgrade -y

# Check for existing swapfile
echo "[INFO] $(date +"%Y-%m-%d %H:%M:%S") - Checking for existing swap file."
sudo swapon --show

# Getting memory size and checking it's validity
if [ -z "$1" ]; then
  echo "[ERROR] $(date +"%Y-%m-%d %H:%M:%S") - No memory size provided."
  exit 1
fi

if ! [[ "$1" =~ ^[0-9]+$ ]]; then
  echo "[ERROR] $(date +"%Y-%m-%d %H:%M:%S") - Argument is not a valid number."
  exit 1
fi

if [ "$1" -le 0 ]; then
  echo "[ERROR] $(date +"%Y-%m-%d %H:%M:%S") - Argument must be greater than zero."
  exit 1
fi

# Creating swapfile
PARENT_FOLDER="/swaps"
FILE_NAME="swapfile"
FILE_PATH="/swaps/$FILE_NAME"
FILE_SIZE=$1

echo "[INFO] $(date +"%Y-%m-%d %H:%M:%S") - Creating $FILE_NAME in path $FILE_PATH"
sudo mkdir -p "$PARENT_FOLDER"
sudo fallocate -l "$FILE_SIZE"G "$FILE_PATH"

# Set Correct Permissions
echo "[INFO] $(date +"%Y-%m-%d %H:%M:%S") - Setting correct permissions"
sudo chmod 600 "$FILE_PATH"

# Format the file as swap
echo "[INFO] $(date +"%Y-%m-%d %H:%M:%S") - Creating Swap File"
sudo mkswap "$FILE_PATH"

# Enable swap file
echo "[INFO] $(date +"%Y-%m-%d %H:%M:%S") - Enable Swap File"
sudo swapon "$FILE_PATH"

# Make Swap Persistent Across Reboots
echo "\"$FILE_PATH\" none swap sw 0 0" | sudo tee -a /etc/fstab

# verifying swapfile
echo "[INFO] $(date +"%Y-%m-%d %H:%M:%S") - Verifying Swapfile"
sudo swapon --show
sudo free -h