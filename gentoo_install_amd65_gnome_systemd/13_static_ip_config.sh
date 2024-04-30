#!/bin/bash
set -e
source /einfo_util.sh
source /install_config.sh

# Check if the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root." >&2
    exit 1
fi

# Read the current hostname
hostname=$(cat /etc/hostname)

ip=${IP_ADDRESS}

function update_interface_name() {
    # Initially set the interface name to a default value
    local interface_name="eth0"

    # Use ip link show to list all interfaces and grep to find the specific alt names
    # Adjusted the approach to correctly parse the interface name
    local target_interface=$(ip -br link show | grep -E 'eno2|enp0s31f6' | awk '{print $1}')

    # Check if the target interface is found. If so, update the interface_name variable.
    if [[ ! -z "$target_interface" ]]; then
        interface_name="$target_interface"
    else
        echo "No interface found with the specified alternative names."
    fi

    # Output the updated interface name
    echo "Updated interface name: $interface_name"
}

# Path to NetworkManager system-connections directory
nm_dir="/etc/NetworkManager/system-connections/"

# Check if NM directory exists, create if not
if [ ! -d "$nm_dir" ]; then
    mkdir -p "$nm_dir"
    echo "Created NetworkManager system-connections directory."
fi

# Create or update NetworkManager connection profile
function configure_network_manager {
    # Call the function to test it
    update_interface_name
    local con_file="${nm_dir}${interface_name}-static.nmconnection"

    echo "[connection]" > "$con_file"
    echo "id=${interface_name}-static" >> "$con_file"
    echo "type=ethernet" >> "$con_file"
    echo "interface-name=$interface_name" >> "$con_file"
    echo "" >> "$con_file"
    echo "[ipv4]" >> "$con_file"
    echo "method=manual" >> "$con_file"
    echo "addresses=$ip/24" >> "$con_file"
    echo "dns=8.8.8.8;8.8.4.4;" >> "$con_file"
    echo "" >> "$con_file"
    echo "[ipv6]" >> "$con_file"
    echo "method=auto" >> "$con_file"

    chmod 600 "$con_file"
    echo "NetworkManager profile for $interface_name configured with IP $ip."
}

# Configure /etc/hosts with entries for all pi-fighters
function configure_hosts_file {
    # Backup the current /etc/hosts file
    cp /etc/hosts /etc/hosts.backup

    # Define base IP and hostname format
    base_ip="192.168.50."
    hostname_prefix="pi-fighter-"

    # Add localhost entries
    echo "127.0.0.1	localhost" > /etc/hosts
    echo "::1		localhost" >> /etc/hosts
    echo "" >> /etc/hosts

    # Add entries for all pi-fighters
    for i in {1..10}; do
        echo "${base_ip}${i}	${hostname_prefix}${i}" >> /etc/hosts
    done

    echo "${IP_ADDRESS}	${HOSTNAME}" >> /etc/hosts
}

configure_network_manager

configure_hosts_file

echo "Network and hosts configuration completed."

/14_gen_toml_config.sh