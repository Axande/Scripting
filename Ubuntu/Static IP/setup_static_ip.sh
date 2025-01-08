#!/bin/bash

# ----------------------------
# Script for Setting Static IP on Ubuntu
#
# IMPORTANT:
# 1. The user provides only the static IP address.
# 2. Update the following hardcoded settings if moving to a new homelab:
#    - INTERFACE: The network interface (e.g., enp6s18, eth0).
#    - GATEWAY: The default gateway for the network.
#    - DNS: The DNS servers for name resolution.
# 3. This script is designed for Ubuntu systems using Netplan.
# ----------------------------

# Hardcoded Variables
INTERFACE="enp6s18"                  # Network interface
GATEWAY="192.168.0.1"                # Default gateway
DNS=("8.8.8.8" "1.1.1.1")            # DNS servers, array format
SUBNET="/24"                         # Subnet in CIDR notation

# Check if run as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root. Use sudo."
    exit 1
fi

# Welcome message
echo "Welcome to the Static IP Setup Script for Ubuntu!"
echo "This script will configure the network interface with hardcoded settings."
echo "Please enter the static IP address for your machine (e.g., 192.168.0.213):"

# Prompt the user for the static IP
read -p "Static IP Address: " USER_IP

# Validate user input
if [[ -z "$USER_IP" ]]; then
    echo "Error: No IP address entered. Please run the script again."
    exit 1
fi

# Combine user input with subnet
STATIC_IP="${USER_IP}${SUBNET}"

# Confirm with the user
echo "The script will apply the following settings:"
echo "Interface: $INTERFACE"
echo "Static IP: $STATIC_IP"
echo "Gateway: $GATEWAY"
echo "DNS: ${DNS[@]}"
read -p "Do you want to proceed? (y/n): " CONFIRM

if [[ "$CONFIRM" != "y" ]]; then
    echo "Aborted by user."
    exit 0
fi

# Backup existing Netplan configuration
NETPLAN_FILE="/etc/netplan/01-netcfg.yaml"
if [[ -f $NETPLAN_FILE ]]; then
    cp $NETPLAN_FILE ${NETPLAN_FILE}.bak
    echo "Backup of $NETPLAN_FILE created."
fi

# Write new Netplan configuration
cat <<EOL > $NETPLAN_FILE
network:
  version: 2
  ethernets:
    $INTERFACE:
      addresses:
        - $STATIC_IP
      routes:
        - to: default
          via: $GATEWAY
      nameservers:
        addresses:
EOL

# Add DNS servers line by line
for dns in "${DNS[@]}"; do
    echo "          - $dns" >> $NETPLAN_FILE
done

# Apply configuration
echo "Applying Netplan configuration..."
netplan apply

if [[ $? -eq 0 ]]; then
    echo "Static IP configuration applied successfully!"
    echo "Interface: $INTERFACE"
    echo "Static IP: $STATIC_IP"
    echo "Gateway: $GATEWAY"
    echo "DNS: ${DNS[@]}"
    echo "Reboot the machine to ensure changes are persistent."
else
    echo "Failed to apply Netplan configuration. Please check the logs."
    exit 1
fi
