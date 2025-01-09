#!/bin/bash

# ----------------------------
# Kubernetes Node Setup Script
#
# Features:
# - Asks the user if the setup is for a Master (m) or Worker (w) node.
# - Configures hostnames and updates /etc/hosts accordingly.
#
# IMPORTANT:
# - This script must be run with root privileges.
# ----------------------------

# Check if run as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root. Use sudo."
    exit 1
fi

echo "Welcome to the Kubernetes Node Setup Script!"
echo "Please select the type of node you want to set up:"
echo "  m - Master Node"
echo "  w - Worker Node"
read -p "Enter your choice (m/w): " NODE_TYPE

if [[ "$NODE_TYPE" == "m" ]]; then
    # Master node setup
    echo "Setting up a Master Node..."

    # Ask for the hostname for the master node
    read -p "Enter the hostname for the master node (e.g., k8s-master-node): " MASTER_HOSTNAME

    if [[ -z "$MASTER_HOSTNAME" ]]; then
        echo "Error: Hostname cannot be empty."
        exit 1
    fi

    # Set hostname
    echo "Setting hostname to $MASTER_HOSTNAME..."
    hostnamectl set-hostname "$MASTER_HOSTNAME"

    # Update /etc/hosts
    echo "Updating /etc/hosts file..."
    echo "192.168.1.56  $MASTER_HOSTNAME" >> /etc/hosts

elif [[ "$NODE_TYPE" == "w" ]]; then
    # Worker node setup
    echo "Setting up a Worker Node..."

    # Ask for master node details
    read -p "Enter the IP address of the master node: " MASTER_IP
    read -p "Enter the hostname of the master node (e.g., k8s-master-node): " MASTER_HOSTNAME

    if [[ -z "$MASTER_IP" || -z "$MASTER_HOSTNAME" ]]; then
        echo "Error: Master IP and hostname cannot be empty."
        exit 1
    fi

    # Get the current hostname
    CURRENT_HOSTNAME=$(hostname)

    # Update /etc/hosts
    echo "Updating /etc/hosts file..."
    echo "$MASTER_IP  $MASTER_HOSTNAME" >> /etc/hosts
    echo "192.168.1.57  $CURRENT_HOSTNAME" >> /etc/hosts

else
    echo "Error: Invalid option. Please enter 'm' for Master or 'w' for Worker."
    exit 1
fi
