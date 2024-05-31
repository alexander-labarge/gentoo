#!/bin/bash

# Ensure required utilities are sourced
source einfo_util.sh
source install_config.sh
source functions.sh

# Functions for tasks (ensure these functions are defined in the sourced files or here)
format_drives
display_drive_changes
format_efi
setup_swap
format_root
ensure_mount_point_exists
mount_partition
copy_files_to_target
change_directory
download_and_extract_tarball
prepare_chroot_env
chroot_gentoo_with_script
cleanup_and_reboot
