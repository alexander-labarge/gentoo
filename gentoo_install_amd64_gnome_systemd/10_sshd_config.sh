#!/bin/bash

source /einfo_util.sh
source /install_config.sh

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    einfo "This script must be run as root. Exiting."
    exit 1
fi

einfo "Configuring SSH settings..."

# Define the SSHD configuration file path
SSHD_CONFIG="/etc/ssh/sshd_config"

# Enable SSH root login by updating the sshd_config file
if grep -q "^#PermitRootLogin" "${SSHD_CONFIG}"; then
    # Uncomment the line and change it to allow root login
    sed -i 's/^#PermitRootLogin.*/PermitRootLogin yes/' "${SSHD_CONFIG}"
    einfo "SSH root login has been enabled."
else
    # If the PermitRootLogin line is not commented out, ensure it's set to yes
    if ! grep -q "^PermitRootLogin yes" "${SSHD_CONFIG}"; then
        echo "PermitRootLogin yes" >> "${SSHD_CONFIG}"
        einfo "SSH root login setting has been added."
    else
        einfo "SSH root login was already enabled."
    fi
fi

# Enable the sshd service to start at boot by creating a symlink in the correct systemd directory
SYSTEMD_SSHD_SERVICE="/etc/systemd/system/multi-user.target.wants/sshd.service"
if [ ! -L "${SYSTEMD_SSHD_SERVICE}" ]; then
    ln -sf "/usr/lib/systemd/system/sshd.service" "${SYSTEMD_SSHD_SERVICE}"
    einfo "sshd service has been enabled at boot."
else
    einfo "sshd service was already enabled at boot."
fi

/11_gnome_install.sh