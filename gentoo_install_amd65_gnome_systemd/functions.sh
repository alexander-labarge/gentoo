#!/bin/bash

set -e

function ensure_mount_point_exists() {
    sudo mkdir -p /mnt/gentoo
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