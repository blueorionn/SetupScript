#!/bin/bash

# Check if the system is running Debian
if [[ ! -f /etc/debian_version ]]; then
    echo "This system is not running Debian."
    exit 1
fi
