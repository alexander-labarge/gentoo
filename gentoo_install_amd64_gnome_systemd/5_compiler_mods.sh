#!/bin/bash

set -e

chmod +x /*.sh

source /einfo_util.sh
source /install_config.sh

# Ensure script is run as root
if [ "$(id -u)" -ne 0 ]; then
    einfo "This script must be run as root. Exiting."
    exit 1
fi

source /etc/profile
export PS1='(chroot) \[\033[0;31m\]\u\[\033[1;31m\]@\h \[\033[1;34m\]\w \$ \[\033[m\]'

einfo "Syncing the Portage tree. This may take a while..."
emerge --sync

einfo "Configuring USE flags for selected packages."

# Define the package and its USE flags
PACKAGE="x11-drivers/nvidia-drivers"
USE_FLAGS="modules strip X persistenced static-libs tools"

# Ensure the package.use directory exists
mkdir -p /etc/portage/package.use

# Apply the USE flag changes for the package
einfo "Applying USE flags for ${PACKAGE}..."
echo "${PACKAGE} ${USE_FLAGS}" >> /etc/portage/package.use/custom

einfo "Installing cpuid2cpuflags to optimize CPU-specific USE flags..."
emerge --verbose --autounmask-continue=y app-portage/cpuid2cpuflags

# Apply CPU-specific USE flags
einfo "Applying CPU-specific USE flags..."
echo "*/* $(cpuid2cpuflags)" > /etc/portage/package.use/00cpu-flags

einfo "Applying additional necessary USE flag changes..."
USE_CHANGES=(
    "sys-kernel/installkernel-gentoo grub"
)

for change in "${USE_CHANGES[@]}"; do
    echo "${change}" >> /etc/portage/package.use/custom
done

einfo "Backing up and updating make.conf with optimized CPU flags..."
cp /etc/portage/make.conf /etc/portage/make.conf.bak2


## Compiler Changes:
OPTIMIZED_FLAGS="$(gcc -v -E -x c /dev/null -o /dev/null -march=native 2>&1 | grep /cc1 | sed -n 's/.*-march=\([a-z]*\)/-march=\1/p' | sed 's/-dumpbase null//')"
sed -i "/^COMMON_FLAGS/c\COMMON_FLAGS=\"-O2 -pipe ${OPTIMIZED_FLAGS}\"" /etc/portage/make.conf
sed -i 's/COMMON_FLAGS="\(.*\)"/COMMON_FLAGS="\1"/;s/  */ /g' /etc/portage/make.conf

# Automatically assign MAKEOPTS based on the number of CPU cores
NUM_CORES=$(nproc)
einfo "Configuring MAKEOPTS for optimal compile times..."
echo "MAKEOPTS=\"-j$((NUM_CORES + 1))\"" >> /etc/portage/make.conf

# Apply general system settings
echo "Applying general system settings..."
echo 'ACCEPT_LICENSE="*"' >> /etc/portage/make.conf
echo 'VIDEO_CARDS="nvidia"' >> /etc/portage/make.conf
echo 'USE="-qt5 -kde X gtk gnome systemd pulseaudio"' >> /etc/portage/make.conf
echo 'ACCEPT_KEYWORDS="~amd64"' >> /etc/portage/make.conf
echo 'GRUB_PLATFORMS="efi-64"' >> /etc/portage/make.conf

# Display the final make.conf to the user
cat /etc/portage/make.conf

einfo "All compiler flag updates and USE changes completed."
einfo "Setting Correct System Profile."
eselect profile set default/linux/amd64/23.0/desktop/gnome/systemd
einfo "Profile Set to Gnome SystemD Desktop AMD64:"
#############################################
#############################################
countdown_timer
#############################################
#############################################
eselect profile list
#############################################
#############################################
countdown_timer
#############################################
#############################################
einfo "Recompiling packages with all changes to get the base system online. This will take some time..."
emerge --verbose --update --deep --newuse @world
emerge --depclean


einfo "Completed. Proceed to kernel configuration next."

/6_kernel_install.sh