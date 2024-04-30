#!/bin/bash
set -e
source /install_config.sh
source /einfo_util.sh


# Generate config.toml content:
cat <<EOF > /home/config.toml
[frontend]
idle-timeout = 3

[backend.worker]
name = "${HOSTNAME}"
dest-devs = [
    "/dev/mapper/nvme0n1p1",
    "/dev/mapper/nvme0n1p2",
    "/dev/mapper/nvme0n1p3",
    "/dev/mapper/nvme0n1p4",
]
block-size = 32768
state-file = "state.json"

[backend.server]
port = 44444
host = "192.168.50.66"
retry-delay = 3

[common]
log-level = "DEBUG"
log-file = "error.log"
EOF

echo "config.toml generated."

echo "Cleaning Chroot Install Files."

rm /*.* 2> /dev/null

echo "Install Cleanup Complete"

echo "Exiting Chroot environment."

exit