#!/bin/bash

source /einfo_util.sh
source /install_config.sh

# Check for root privileges
if [ "$(id -u)" -ne 0 ]; then
    einfo "This script must be run as root. Exiting."
    exit 1
fi

einfo "Configuring system locale and time zone..."

einfo "Setting locale to $LOCALE..."
echo $LOCALE >> /etc/locale.gen
locale-gen
eselect locale set en_US.utf8
einfo "Locale set to $(eselect locale show)."

# Configure timezone
einfo "Setting timezone to America/New_York..."
ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime
einfo "Timezone set."

# Reload environment variables and set chroot prompt
source /etc/profile
export PS1='(chroot) \[\033[0;31m\]\u\[\033[1;31m\]@\h \[\033[1;34m\]\w \$ \[\033[m\]'

einfo "Emerge required packages. This may take some time..."

# Emerge kernel sources
einfo "Emerging Gentoo Linux kernel sources..."
emerge --verbose --autounmask-continue=y sys-kernel/gentoo-sources

# Emerge Linux firmware
einfo "Emerging Linux firmware..."
emerge --verbose --autounmask-continue=y sys-kernel/linux-firmware

# Select the first available kernel
einfo "Selecting the default kernel..."
eselect kernel set 1

# Emerge Genkernel
einfo "Emerging Genkernel for automatic kernel building..."
emerge --verbose --autounmask-continue=y sys-kernel/genkernel

# Emerge Intel microcode without replacing existing installation
einfo "Emerging Intel microcode..."
emerge --verbose --autounmask-continue=y --noreplace sys-firmware/intel-microcode

# Generate the early Intel microcode CPIO archive
einfo "Generating early Intel microcode CPIO archive..."
iucode_tool -S --write-earlyfw=/boot/early_ucode.cpio /lib/firmware/intel-ucode/*
einfo "Early Intel microcode CPIO archive generated."

# Generate initramfs and kernel with dynamic date in local version string
CURRENT_DATE=$(date +%Y%m%d) # Get the current date in YYYYMMDD format
einfo "Generating initramfs and compiling kernel with Genkernel, including today's date ($CURRENT_DATE) in the kernel version..."
genkernel --kernel-config=/${KERNEL_CONFIG} --kernel-append-localversion=-intel-optimized-$CURRENT_DATE --no-mrproper --no-clean --mountboot --microcode initramfs --install all
einfo "Kernel and initramfs generation complete with date embedded in version."

/7_auto_fstab_gen.sh
