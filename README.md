# Admin Setup Script for Debian & Ubuntu

This script automates the setup of a new `admin` user on Debian and Ubuntu systems, ensuring secure SSH access and installing essential utilities.

## Supported Versions

- Debian: 9, 10, 11, 12, 13
- Ubuntu LTS: 16.04, 18.04, 20.04, 22.04, 24.04, 26.04

## Purpose

- Create a new `admin` user (customizable) with home directory.
- Configures SSH access with proper permissions.
- Add the user to the sudoers group.
- Install necessary utilities like `sudo`, `curl`, `wget`, `tree`, `htop`, `net-tools`, `git`, `build-essential`, etc.
- Supports additional package installation via script arguments, such as `python3`, `nodejs`, `npm`, `apache2`, `nginx`, etc.

## Usage

Run the script as root (or with sudo) on a Debian or Ubuntu system:

```bash
bash setup.sh
bash setup.sh -u USERNAME
bash setup.sh -i PACKAGE-1 PACKAGE-2
bash setup.sh -u USERNAME -i PACKAGE-1 PACKAGE-2
```

- `-u` sets the target username (defaults to `admin`).
- `-i` installs additional packages (space-separated) on top of the defaults.

## Swap Setup

`allocate_swap_memory.sh` creates a swap file, enables it immediately, and makes it persistent across reboots. It prompts for the swap size in MB.

```bash
bash allocate_swap_memory.sh
```

> **Note:** Both scripts must be run as root and only run on the supported versions listed above.
