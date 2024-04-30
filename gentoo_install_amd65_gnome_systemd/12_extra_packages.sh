#!/bin/bash
set -e
source /einfo_util.sh
source /install_config.sh

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    einfo "This script must be run as root"
    exit 1
fi

# Install bluez without replacing existing installations
emerge --verbose --autounmask-continue=y --noreplace net-wireless/bluez

# Install gnome-bluetooth
emerge --verbose --autounmask-continue=y net-wireless/gnome-bluetooth

# Configure Bluetooth main.conf
echo "[General]" > /etc/bluetooth/main.conf
echo "Experimental=true" >> /etc/bluetooth/main.conf

# Manage system services
systemctl disable systemd-networkd.service
systemctl enable bluetooth
systemctl enable cups.service

einfo "Early on, Pulseaudio use flag was set in make.conf - this automatically pulls in the pulseaudio USE flag for bluez and gnome-bluetooth, and the pulseaudio plugin."
einfo "Enabling Pulseaudio service and socket globally for all users."
systemctl --global enable pulseaudio.service pulseaudio.socket

# Add Polkit rule
POLKIT_RULE='/etc/polkit-1/rules.d/50-network-manager-settings.rules'

# Check if the polkit rule file already exists to avoid duplication
if [ ! -f "$POLKIT_RULE" ]; then
    einfo "Adding Polkit rule for NetworkManager settings modification."
    # Use a heredoc to write the JavaScript code into the Polkit rule file
    cat > "$POLKIT_RULE" <<'EOF'
polkit.addRule(function (action, subject) {
    if (action.id == "org.freedesktop.NetworkManager.settings.modify.system" &&
        subject.local) {
        return polkit.Result.YES;
    }
});
EOF
else
    einfo "Polkit rule already exists."
fi

einfo "Bluetooth setup and configuration completed."

countdown_timer

einfo "Cleaning up Install Environment... Please Wait."

countdown_timer

/13_static_ip_config.sh

einfo "Complete - Exiting Chroot Environment".

exit