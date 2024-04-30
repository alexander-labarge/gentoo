#!/bin/bash

set -e

# Function to partition and format a drive
function format_drives() {
    clear
    einfo "This will install a custom Gentoo Linux AMD64 Operating System to $DRIVE and will create the following partition layout:"
    einfo "1. EFI System Partition: ${EFI_SIZE}B"
    einfo "2. Linux Swap Partition: ${SWAP_SIZE}B"
    einfo "3. Linux Root Partition: Remaining space"
    einfo
    einfo "WARNING: This operation will destroy all data on $DRIVE."

    if [ ! -b "$DRIVE" ]; then
      einfo "$DRIVE does not exist or is not a block DRIVE. Operation aborted."
      exit 1
    fi

    # Create new partition table and partitions
    einfo "Creating new partition table and partitions on $DRIVE..."

    # Execute fdisk commands
    if echo -e "g\nn\n1\n2048\n+${EFI_SIZE}\nt\n1\nn\n2\n\n+${SWAP_SIZE}\nt\n2\n19\nn\n3\n\n\n\nt\n3\n23\nw" | fdisk $DRIVE; then
      einfo "Partition table and partitions on $DRIVE have been successfully created."
    else
      einfo "There was an error creating the partitions. Please check the output for details."
      exit 1
    fi

    # Display the final partition table
    einfo "Final partition table for $DRIVE:"
    fdisk -l $DRIVE

    einfo "Partitioning complete. Proceeding to format the partitions..."

    countdown_timer
}

function ensure_mount_point_exists() {
    sudo mkdir -p /mnt/gentoo
}

function cleanup_and_reboot() {
    read -p "Do you want to unmount filesystems and cleanup? (y/n) " unmount_answer
    if [[ ${unmount_answer,,} =~ ^(yes|y)$ ]]; then
        unchroot_fix_bashrc
        einfo "Unmounting filesystems..."
        cd ~
        if swapoff $SWAP_PARTITION && umount /mnt/gentoo/efi && umount -l /mnt/gentoo/dev{/shm,/pts,} && umount -R /mnt/gentoo; then
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
            chroot_gentoo
        * )
            einfo "Exiting without reboot. You can reboot manually later."
        ;;
    esac
    einfo "System cleanup complete."
}

function mount_partition() {
    if [[ "$LUKS_ENCRYPTED" == "YES" ]]; then
        einfo "LUKS encryption detected. Mounting LUKS Block Device $ROOT_PARTITION..."
        countdown_timer
        sudo mount /dev/mapper/${LUKS_ROOT_NAME} /mnt/gentoo
    else
        einfo "No LUKS encryption detected. Mounting $ROOT_PARTITION..."
        countdown_timer
        sudo mount $ROOT_PARTITION /mnt/gentoo
        einfo "Root partition has been successfully mounted."
        countdown_timer
    fi
}

function copy_files_to_target() {
    cp ./*.* /mnt/gentoo
}

function change_directory() {
    cd /mnt/gentoo
}

function chroot_gentoo() {
    chroot /mnt/gentoo /bin/bash -c "
        source /etc/profile
        echo \"export PS1='(chroot) \[\033[0;31m\]\u\[\033[1;31m\]@\h \[\033[1;34m\]\w \$ \[\033[m\]'\" >> ~/.bashrc
        exec bash -i
    "
}

function unchroot_fix_bashrc() {
    chroot /mnt/gentoo /bin/bash -c "
        sed -i '/export PS1/d' ~/.bashrc
        exec bash -i
    "
}

function chroot_gentoo_with_script() {
    chroot /mnt/gentoo /bin/bash -c 'source /5_compiler_mods.sh' || {
        einfo "An error occurred during the chroot execution."
        exit 1
    }
}

function prepare_chroot_env(){
    mkdir -p /mnt/gentoo/efi

    # Mount the EFI partition
    einfo "Mounting the EFI partition..."
    if ! mountpoint -q /mnt/gentoo/efi; then
        mount $EFI_PARTITION /mnt/gentoo/efi && einfo "$EFI_PARTITION mounted on /mnt/gentoo/efi." || einfo "Failed to mount $EFI_PARTITION."
    else
        einfo "$EFI_PARTITION is already mounted."
    fi

    # Mount the root partition, with LUKS handling if applicable
    if [[ "$LUKS_ENCRYPTED" == "YES" ]]; then
        einfo "LUKS encryption detected. Assuming /dev/mapper/${LUKS_ROOT_NAME} is already unlocked and mounted."

    else
        einfo "Mounting the root partition..."
        mount $ROOT_PARTITION /mnt/gentoo && einfo "$ROOT_PARTITION mounted on /mnt/gentoo." || einfo "Failed to mount $ROOT_PARTITION."
    fi

    # Copy DNS settings
    einfo "Copying DNS settings to the new environment..."
    cp /etc/resolv.conf /mnt/gentoo/etc && einfo "DNS settings copied." || einfo "Failed to copy DNS settings."

    # Mount necessary filesystems for the chroot environment
    einfo "Turning Swap Space On..."
    swapon "$SWAP_PARTITION" && einfo "Swap space turned on." || einfo "Failed to turn on swap space."
    einfo "Mounting necessary filesystems for the chroot environment..."
    mount --types proc /proc /mnt/gentoo/proc && einfo "/proc mounted."
    mount --rbind /sys /mnt/gentoo/sys && mount --make-rslave /mnt/gentoo/sys && einfo "/sys mounted and set as slave."
    mount --rbind /dev /mnt/gentoo/dev && mount --make-rslave /mnt/gentoo/dev && einfo "/dev mounted and set as slave."
    mount --rbind /run /mnt/gentoo/run && mount --make-rslave /mnt/gentoo/run && einfo "/run mounted and set as slave."
}

function display_drive_changes() {
    einfo "Formatting Filesytems..."
    einfo "This script will perform the following actions:"
    einfo "1. Format $EFI_PARTITION as FAT32 for the EFI System Partition."
    einfo "2. Set up and enable a swap partition on $SWAP_PARTITION."
    einfo "3. Format $ROOT_PARTITION as ext4 for the root filesystem."
}


function download_and_extract_tarball() {
    STAGE3_URL="https://distfiles.gentoo.org/releases/amd64/autobuilds/latest-stage3-amd64-desktop-systemd.txt"
    STAGE3_FILE=$(curl -s $STAGE3_URL | grep -m1 -oP '\d+T\d+Z/stage3-.*\.tar.xz')
    if [ -z "$STAGE3_FILE" ]; then
        einfo "Failed to find the stage3 file URL. Please check the $STAGE3_URL content."
        exit 1
    fi

    FULL_URL="https://distfiles.gentoo.org/releases/amd64/autobuilds/$STAGE3_FILE"

    einfo "Downloading $FULL_URL..."
    countdown_timer
    wget $FULL_URL
    einfo "Extracting the stage3 tarball..."
    countdown_timer
    sudo tar xpvf stage3-*.tar.xz --xattrs-include='*.*' --numeric-owner

    einfo "Stage3 tarball has been successfully extracted."
    countdown_timer
}

# Function to format EFI partition as FAT32
format_efi() {
    einfo "Formatting $EFI_PARTITION as FAT32..."
    if mkfs.vfat -F 32 "$EFI_PARTITION"; then
        einfo "$EFI_PARTITION formatted successfully."
        #############################################
        #############################################
        countdown_timer
        #############################################
        #############################################
    else
        einfo "Failed to format $EFI_PARTITION. Please check that the partition exists and try again."
        exit 1
    fi
}

# Function to setup and enable the swap partition
setup_swap() {
    einfo "Setting up swap on $SWAP_PARTITION..."
    if mkswap "$SWAP_PARTITION"; then
        einfo "Swap on $SWAP_PARTITION set up."
        #############################################
        #############################################
        countdown_timer
        #############################################
        #############################################
    else
        einfo "Failed to set up swap on $SWAP_PARTITION. Please check that the partition exists and try again."
        exit 1
    fi
}

# Function to format the root partition as ext4 or set up LUKS encryption based on configuration
format_root() {
    if [[ "$LUKS_ENCRYPTED" == "YES" ]]; then
        einfo "Setting up LUKS encryption on $ROOT_PARTITION..."
        printf "$LUKS_PASSPHRASE" | cryptsetup luksFormat --type luks2 $ROOT_PARTITION -
        printf "$LUKS_PASSPHRASE" | cryptsetup open $ROOT_PARTITION ${LUKS_ROOT_NAME} -
        mkfs.ext4 -F /dev/mapper/${LUKS_ROOT_NAME}
        einfo "LUKS encryption setup complete."
        #############################################
        #############################################
        countdown_timer
        #############################################
        #############################################
    else
        einfo "Formatting $ROOT_PARTITION as ext4..."
        if mkfs.ext4 -F "$ROOT_PARTITION"; then
            einfo "$ROOT_PARTITION formatted successfully."
            #############################################
            #############################################
            countdown_timer
            #############################################
            #############################################
        else
            einfo "Failed to format $ROOT_PARTITION. Please check that the partition exists and try again."
            exit 1
        fi
    fi
}

function burn_iso_to_usb() {
    # Get a list of drives
    drives=$(lsblk -dp | grep -o '^/dev[^ ]*')
    echo "Available drives:"
    echo "$drives"
    
    # Ask the user which drive they want to burn the iso to
    while true; do
        read -p "Which drive would you like to burn the iso to? " drive
        if [[ $drives = *"$drive"* ]]; then
            break
        else
            echo "Invalid drive. Please enter a valid drive."
        fi
    done

    # Unmount anything attached to the selected drive
    sudo umount /dev/${drive}*

    # Delete existing partitions and create a new GPT partition on the drive
    echo -e "g\nn\n\n\n\nw" | sudo fdisk /dev/$drive

    # Inform the OS of partition table changes
    sudo partprobe /dev/$drive

    # Burn the iso to the drive
    sudo dd if=livegui-amd64-20240407T165048Z.iso of=/dev/${drive} bs=1M status=progress
}