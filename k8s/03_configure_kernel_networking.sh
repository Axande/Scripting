#!/bin/bash

# ----------------------------
# Script to Configure Kernel Modules and Networking for Kubernetes
#
# Features:
# - Loads necessary kernel modules for Kubernetes.
# - Configures sysctl settings for proper networking.
# - Ensures changes persist across reboots.
#
# IMPORTANT:
# - This script must be run with root privileges.
# ----------------------------

# Check if run as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root. Use sudo."
    exit 1
fi

# Load necessary kernel modules
echo "Loading kernel modules..."
modprobe overlay
modprobe br_netfilter

# Persist module loading
echo "Persisting kernel modules..."
cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

# Configure sysctl settings
echo "Configuring sysctl settings for Kubernetes networking..."
cat <<EOF | tee /etc/sysctl.d/kubernetes.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

# Apply the configuration
echo "Applying sysctl settings..."
sysctl --system

# Confirm success
echo "Kernel modules and networking configuration completed successfully."
