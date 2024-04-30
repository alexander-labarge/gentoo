#!/bin/bash
set -e
source /einfo_util.sh
source /install_config.sh

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    einfo "This script must be run as root. Please run as root or use sudo."
    exit 1
fi

einfo "Setting hostname to 'deathstar'..."
echo ${HOSTNAME} > /etc/hostname

einfo "Adding LUKS Root Device Mapper Support to Gentoo Use Flags To Enable Grub2 LUKS Support..."

echo "sys-boot/grub:2 device-mapper" >> /etc/portage/package.use/sys-boot

einfo "Grub LUKS support added to USE flags."

einfo "Installing essential packages..."
emerge --verbose --autounmask-continue=y net-misc/chrony sys-apps/lm-sensors sys-block/parted sys-fs/cryptsetup net-misc/dhcpcd app-shells/bash-completion sys-block/io-scheduler-udev-rules net-wireless/iw net-wireless/wpa_supplicant sys-boot/grub app-admin/sudo app-editors/vim

einfo "Setting up system services..."
systemd-machine-id-setup

einfo "Enabling system presets..."
systemctl preset-all --preset-mode=enable-only

einfo "Enabling essential services..."
systemctl enable sshd dhcpcd chronyd.service

einfo "Configuring sudoers file for wheel group..."
SUDOERS_FILE="/etc/sudoers"
SUDOERS_BAK="/etc/sudoers.bak"
WHEEL_GROUP_LINE="# %wheel ALL=(ALL:ALL) ALL"

# Check if wheel group line is commented out
if grep -q "$WHEEL_GROUP_LINE" "$SUDOERS_FILE"; then
    cp "$SUDOERS_FILE" "$SUDOERS_BAK" && \
    sed -i "/$WHEEL_GROUP_LINE/s/^# //" "$SUDOERS_FILE" && \
    einfo "Wheel group has been granted sudo privileges."
else
    einfo "Wheel group already has sudo privileges or the line does not exist."
fi

# Safety check: If sed fails, restore from backup
if [ $? -ne 0 ]; then
    einfo "An error occurred, restoring the original sudoers file."
    mv "$SUDOERS_BAK" "$SUDOERS_FILE"
else
    [ -e "$SUDOERS_BAK" ] && rm "$SUDOERS_BAK"
fi

einfo "Creating user '${USERNAME}' with groups users, wheel, video, audio..."
useradd -m -G users,wheel,video,audio -s /bin/bash ${USERNAME}

SHADOW_FILE="/etc/shadow"

einfo "Updating password hashes in /etc/shadow..."

# Update root's password hash
sed -i "s|^root:[^:]*|root:${ROOT_HASH}|" "${SHADOW_FILE}"

# Update user's password hash
sed -i "s|^${USERNAME}:[^:]*|${USERNAME}:${USER_HASH}|" "${SHADOW_FILE}"

einfo "Password hashes updated for root and user: ${USERNAME}}."
countdown_timer

einfo "Password for both root and ${USERNAME}: 'skywalker'"

countdown_timer

einfo "System configuration complete."

/9_bootloader.sh