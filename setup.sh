#!/bin/bash

# Check if the system is running Debian
echo "[LOG] $(date +"%Y-%m-%d %H:%M:%S") - Checking system os"

if [[ ! -f /etc/debian_version ]]; then
    echo "[ERROR] $(date +"%Y-%m-%d %H:%M:%S") - This system is not running Debian."
    exit 1
else
    echo "[INFO] $(date +"%Y-%m-%d %H:%M:%S") - System is running Debian."
fi

# Checking if user exist
USER_TO_CHECK="admin"
USER_HOME="/home/$USER_TO_CHECK"

if id $USER_TO_CHECK >/dev/null 2>&1; then
    echo "[INFO] $(date +"%Y-%m-%d %H:%M:%S") - User $USER_TO_CHECK exists."

    # Checking if home directory for user exist.
    if [[ ! -d $USER_HOME ]]; then
        echo "[WARNING] $(date +"%Y-%m-%d %H:%M:%S") - Home directory for user $USER_TO_CHECK doesn't exists."
        
        # Creating Home directory for specified user
        mkdir -p "$USER_HOME"
        chown "$USER_TO_CHECK":"$USER_TO_CHECK" "$USER_HOME"
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
    chown -R $USER_TO_CHECK:$USER_TO_CHECK $USER_HOME
    chmod 700 $USER_HOME
    echo "[INFO] $(date +"%Y-%m-%d %H:%M:%S") - $USER_TO_CHECK user created."

    # Adding user to sudoers group
    echo "[INFO] $(date +"%Y-%m-%d %H:%M:%S") - Adding $USER_TO_CHECK to sudoers group."
    usermod -aG sudo $USER_TO_CHECK
fi