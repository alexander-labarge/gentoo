#!/bin/bash
set -e
# Change to the root directory to ensure that no mounted directories are in use
cd /

function cleanup_and_reboot() {
    read -p "Do you want to unmount filesystems and cleanup? (y/n) " unmount_answer
    if [[ ${unmount_answer,,} =~ ^(yes|y)$ ]]; then
        einfo "Unmounting filesystems..."
        if umount /mnt/gentoo/efi && umount -l /mnt/gentoo/dev{/shm,/pts,} && umount -R /mnt/gentoo; then
            einfo "Filesystems unmounted successfully."
        else
            echo "Failed to unmount some filesystems."
            return 1
        fi
    else
        einfo "Skipping unmounting."
    fi

    read -p "Do you want to reboot now, re-enter chroot, or exit? (reboot/chroot/exit) " action
    case ${action,,} in
        reboot )
            einfo "Rebooting..."
            reboot
        ;;
        chroot )
            einfo "Re-entering chroot environment..."
            chroot /mnt/gentoo /bin/bash
        ;;
        * )
            einfo "Exiting without reboot. You can reboot manually later."
        ;;
    esac
    einfo "System cleanup complete."
}

cleanup_and_reboot