#!/bin/bash

set -e

# Check for root privileges
if [ "$(id -u)" -ne 0 ]; then
  einfo "This script must be run as root. Please use sudo or switch to root."
  exit 1
fi

source einfo_util.sh
source install_config.sh

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
unchroot_fix_bashrc
cleanup_and_reboot

