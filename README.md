# Admin Setup Script for Debian

This script automates the setup of a new `admin` user on a Debian-based system, ensuring secure SSH access and installing essential utilities.

## Purpose

- Create a new `admin` user with home directory.
- Configures SSH access with proper permissions.
- Add `admin` user to the sudoers group.
- Install necessary utilities like `curl`, `wget`, `tree`, `htop`, `net-tools`, `git`, `build-essential`, etc.
- Supports additional package installation via script arguments, such as `python-env`, `nodejs`, `npm`, `apache`, `nginx`, etc.

## Usage

Run the script on a Debian system:

```bash
./setup.sh [additional_packages...]
```
