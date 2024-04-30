#!/bin/bash
set -e
source /einfo_util.sh
source /install_config.sh

# Ensure script is run as root
if [ "$(id -u)" -ne 0 ]; then
    einfo "This script must be run as root. Exiting."
    exit 1
fi

einfo "Backing up and generating fstab..."

# Backup the current fstab
cp /etc/fstab /etc/fstab.backup

# Start the fstab generation
{
    echo "# /etc/fstab: static file system information."
    echo "#"
    echo "# See fstab(5) for details."
    echo "#"
    echo "# <file system> <mount point>   <type>  <options>       <dump>  <pass>"
} > /etc/fstab

# /efi partition
EFI_UUID=$(blkid -o value -s UUID ${DRIVE}p1)
EFI_FSTAB_ENTRY="UUID=${EFI_UUID} /efi vfat defaults 0 2"
echo "$EFI_FSTAB_ENTRY" >> /etc/fstab
einfo "Adding /efi partition to fstab: $EFI_FSTAB_ENTRY"

# Swap partition
SWAP_UUID=$(blkid -o value -s UUID ${DRIVE}p2)
SWAP_FSTAB_ENTRY="UUID=${SWAP_UUID} none swap sw 0 0"
echo "$SWAP_FSTAB_ENTRY" >> /etc/fstab
einfo "Adding swap partition to fstab: $SWAP_FSTAB_ENTRY"

# Conditional root partition handling
if [[ "$LUKS_ENCRYPTED" == "YES" ]]; then
    ROOT_FSTAB_ENTRY="/dev/mapper/${LUKS_ROOT_NAME} / ext4 defaults 0 1"
    einfo "Adding LUKS encrypted / partition to fstab: $ROOT_FSTAB_ENTRY"
    ROOT_UUID=$(blkid -o value -s UUID ${DRIVE}p3)
    # Update GRUB configuration for LUKS
    #einfo "Updating GRUB configuration for LUKS..."
    #echo "GRUB_CMDLINE_LINUX=\"cryptdevice=UUID=${ROOT_UUID}:${LUKS_ROOT_NAME} root=/dev/mapper/${LUKS_ROOT_NAME}\"" >> /etc/default/grub
    #grub-mkconfig -o /boot/grub/grub.cfg - addressed in 9_bootloader.sh
else
    ROOT_UUID=$(blkid -o value -s UUID ${DRIVE}p3)
    ROOT_FSTAB_ENTRY="UUID=${ROOT_UUID} / ext4 defaults 0 1"
    einfo "Adding / partition to fstab: $ROOT_FSTAB_ENTRY"
fi
echo "$ROOT_FSTAB_ENTRY" >> /etc/fstab

einfo "Fstab generation complete. Contents of /etc/fstab:"
cat /etc/fstab

einfo "Proceeding to system configuration script"
/8_system_config.sh
