#!/bin/bash

# ----------------------------
# Script for Setting Static IP on Ubuntu
#
# IMPORTANT:
# 1. Update the following variables if moving to a new homelab setup:
#    - INTERFACE: The network interface (e.g., enp6s18, eth0).
#    - STATIC_IP: The desired static IP address for the machine (use CIDR /24 for subnet).
#    - GATEWAY: The default gateway for the network.
#    - DNS: The DNS servers for name resolution.
#
# 2. This script is designed for Ubuntu systems using Netplan.
# ----------------------------

# Hardcoded Variables
INTERFACE="enp6s18"                  # Network interface
STATIC_IP="192.168.0.213/24"         # Static IP address with /24 subnet
GATEWAY="192.168.0.1"                # Default gateway
DNS="8.8.8.8,1.1.1.1"               # DNS servers, comma-separated

# Check if run as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root. Use sudo."
    exit 1
fi

# Confirm with the user
echo "This script will configure the following settings:"
echo "Interface: $INTERFACE"
echo "Static IP: $STATIC_IP"
echo "Gateway: $GATEWAY"
echo "DNS: $DNS"
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
        addresses: [${DNS//,/ }]
EOL

# Apply configuration
echo "Applying Netplan configuration..."
netplan apply

if [[ $? -eq 0 ]]; then
    echo "Static IP configuration applied successfully!"
    echo "Interface: $INTERFACE"
    echo "Static IP: $STATIC_IP"
    echo "Gateway: $GATEWAY"
    echo "DNS: $DNS"
    echo "Reboot the machine to ensure changes are persistent."
else
    echo "Failed to apply Netplan configuration. Please check the logs."
    exit 1
fi
