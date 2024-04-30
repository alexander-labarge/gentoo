#!/bin/bash
set -e
source /einfo_util.sh
source /install_config.sh

# Ensure the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    einfo "This script must be run as root. Please run as root or use sudo."
    exit 1
fi

einfo "Installing GRUB to the EFI System Partition..."

einfo "Adding LUKS Grub command line entry..."

countdown_timer

ROOT_UUID=$(blkid -o value -s UUID ${DRIVE}p3)
# echo "GRUB_ENABLE_CRYPTODISK=y" >> /etc/default/grub
# echo "GRUB_CMDLINE_LINUX=\"cryptdevice=UUID=${ROOT_UUID}:${LUKS_ROOT_NAME} root=/dev/mapper/${LUKS_ROOT_NAME}\"" >> /etc/default/grub

# Install GRUB for x86_64 EFI systems
grub-install --target=x86_64-efi --efi-directory=/efi --removable
if [ $? -eq 0 ]; then
    einfo "GRUB installation successful."
else
    einfo "GRUB installation failed."
    exit 1
fi

einfo "Generating GRUB configuration file..."

# Luks Grub CMD Line Entry

# Generate the GRUB configuration file
grub-mkconfig -o /boot/grub/grub.cfg
if [ $? -eq 0 ]; then
    einfo "GRUB configuration successfully generated."
else
    einfo "Failed to generate GRUB configuration."
    exit 1
fi

einfo "GRUB setup complete."

/10_sshd_config.sh