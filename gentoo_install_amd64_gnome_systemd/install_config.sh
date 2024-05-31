#!/bin/bash

DRIVE="/dev/nvme0n1"
EFI_PARTITION="/dev/nvme0n1p1"
SWAP_PARTITION="/dev/nvme0n1p2"
ROOT_PARTITION="/dev/nvme0n1p3"
EFI_SIZE="1G"
SWAP_SIZE="32G"
HOSTNAME="nvidia4090tower"
KERNEL_CONFIG="intel.config"
USERNAME="skywalker"
TIMEZONE="America/New_York"
KEYMAP="us"
LOCALE="en_US.UTF-8 UTF-8"
STAGE3_URL="https://distfiles.gentoo.org/releases/amd64/autobuilds/latest-stage3-amd64-desktop-systemd.txt"
