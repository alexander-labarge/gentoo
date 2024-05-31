#!/bin/bash

source /einfo_util.sh
source /install_config.sh

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    einfo "This script must be run as root. Exiting."
    exit 1
fi

einfo "Updating System Packages to avoid Circular Builds"
sleep 2
emerge --sync
sleep 2
einfo "Updating System Packages for Experimental Features with ACCEPT_KEYWORDS set to ~amd64"
echo 'ACCEPT_KEYWORDS="~amd64"' >> /etc/portage/make.conf
emerge --changed-use --update --deep @world

einfo "Installing graphical environment and NetworkManager..."

# Combine emerge commands into a single operation to streamline the process
emerge --verbose --autounmask-continue=y x11-drivers/nvidia-drivers x11-base/xorg-server gnome-base/gnome gnome-base/gdm net-misc/networkmanager gnome-shell-extensions

einfo "Enabling essential services..."

# Enable GDM and NetworkManager to start at boot
systemctl enable gdm.service
systemctl enable NetworkManager.service

# Configure user environment for GNOME
USER_HOME="/home/${USERNAME}"  # Adjust to your target user's home directory
XINITRC="$USER_HOME/.xinitrc"

# Create or overwrite .xinitrc to start GNOME
echo "exec gnome-session" > "$XINITRC"

# Ensure the XDG_MENU_PREFIX is set for GNOME
if ! grep -q "export XDG_MENU_PREFIX=gnome-" "$XINITRC"; then
    sed -i '1i\export XDG_MENU_PREFIX=gnome-' "$XINITRC"
fi

einfo "Graphical environment setup complete. GDM and NetworkManager have been enabled."

/12_extra_packages.sh