#!/bin/bash

# Check if the system is running Debian
echo "[INFO] $(date +"%Y-%m-%d %H:%M:%S") - Checking system os"

if [[ ! -f /etc/debian_version ]]; then
    echo "[ERROR] $(date +"%Y-%m-%d %H:%M:%S") - This system is not running Debian."
    exit 1
else
    echo "[INFO] $(date +"%Y-%m-%d %H:%M:%S") - System is running Debian."
fi
