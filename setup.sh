#!/bin/bash

# Check if the system is running Debian
echo "[LOG] $(date +"%Y-%m-%d %H:%M:%S") - Checking system os"

if [[ ! -f /etc/debian_version ]]; then
    echo "[ERROR] $(date +"%Y-%m-%d %H:%M:%S") - This system is not running Debian."
    exit 1
else
    echo "[INFO] $(date +"%Y-%m-%d %H:%M:%S") - System is running Debian."

    # This script is only intented to run on debian v12.
    echo "[LOG] $(date +"%Y-%m-%d %H:%M:%S") - Checking debian version..."
    DEBIAN_VERSION=$(cat /etc/debian_version)
    if [[ "$DEBIAN_VERSION" == 12.* ]]; then
        echo "[INFO] $(date +"%Y-%m-%d %H:%M:%S") - Debian version $DEBIAN_VERSION detected executing script."
    else
        echo "[ERROR] $(date +"%Y-%m-%d %H:%M:%S") - This script is only intended for running in Debian 12.x."
        exit 1
    fi
fi


# Update and upgrade Debian
echo "[INFO] $(date +"%Y-%m-%d %H:%M:%S") - Updating and Upgrading Debian."
sudo apt-get update && sudo apt-get upgrade -y

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
    chown -R $USER_TO_CHECK:$USER_TO_CHECK $USER_HOME
    chmod 700 $USER_HOME
    echo "[INFO] $(date +"%Y-%m-%d %H:%M:%S") - $USER_TO_CHECK user created."

    # Adding user to sudoers group
    echo "[INFO] $(date +"%Y-%m-%d %H:%M:%S") - Adding $USER_TO_CHECK to sudoers group."
    usermod -aG sudo $USER_TO_CHECK

    # Specify user password
    echo "[INFO] $(date +"%Y-%m-%d %H:%M:%S") - Specify $USER_TO_CHECK passwd."
    passwd $USER_TO_CHECK
fi

# SSH Configuration
if [[ -f /root/.ssh/authorized_keys ]]; then

    # Checking if .ssh directory exist for specified user
    if [[ -d "$USER_HOME/.ssh" ]]; then

        # Moving authorized_keys 
        mv /root/.ssh/authorized_keys "$USER_HOME/.ssh/authorized_keys"
        chown $USER_TO_CHECK:$USER_TO_CHECK "$USER_HOME/.ssh/authorized_keys"
        chmod 600 "$USER_HOME/.ssh/authorized_keys"
        echo "[INFO] $(date +"%Y-%m-%d %H:%M:%S") - Moved authorized_keys to specified user."

    else
        echo "[WARNING] $(date +"%Y-%m-%d %H:%M:%S") - .ssh directory doesn't exist creating new."

        # If .ssh directory doesn't exist create new
        mkdir "$USER_HOME/.ssh"

        # Moving authorized_keys 
        mv /root/.ssh/authorized_keys "$USER_HOME/.ssh/authorized_keys"
        chown -R $USER_TO_CHECK:$USER_TO_CHECK "$USER_HOME/.ssh"
        chmod 600 "$USER_HOME/.ssh/authorized_keys"
        echo "[INFO] $(date +"%Y-%m-%d %H:%M:%S") - Moved authorized_keys to specified user."
    fi
else
    echo "[ERROR] $(date +"%Y-%m-%d %H:%M:%S") - Root doesn't have authorized_keys."
fi

# Install packages
echo "[INFO] $(date +"%Y-%m-%d %H:%M:%S") - Installing packages."
echo -n "[INPUT] Enter $USER_TO_CHECK password: "
read -rs USER_PASSWORD
echo ""

# Base packages
DEFAULT_PACKAGES="curl wget tree htop net-tools git build-essential"
PACKAGES_TO_INSTALL="$DEFAULT_PACKAGES"

# Append additional packages if --install is used
if [[ "$1" == "--install" ]]; then
    shift
    PACKAGES_TO_INSTALL="$PACKAGES_TO_INSTALL $*"
fi

# Single sudo session for all installations
su - "$USER_TO_CHECK" -c "echo \"$USER_PASSWORD\" | sudo -S apt-get install -y $PACKAGES_TO_INSTALL"

echo "[INFO] $(date +"%Y-%m-%d %H:%M:%S") - Installation complete."