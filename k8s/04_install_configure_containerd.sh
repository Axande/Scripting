#!/bin/bash

# ----------------------------
# Script to Install and Configure Containerd
#
# Features:
# - Installs containerd and its dependencies.
# - Configures containerd for Kubernetes compatibility.
# - Ensures containerd is running correctly.
#
# IMPORTANT:
# - This script must be run with root privileges.
# ----------------------------

# Check if run as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root. Use sudo."
    exit 1
fi

# Install containerd and dependencies
echo "Installing containerd and necessary dependencies..."
apt update
apt install -y curl gnupg2 software-properties-common apt-transport-https ca-certificates
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/containerd.gpg
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt update
apt install -y containerd.io

# Configure containerd
echo "Configuring containerd for Kubernetes compatibility..."
containerd config default | tee /etc/containerd/config.toml >/dev/null 2>&1
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml

# Restart containerd and verify its status
echo "Restarting and verifying containerd service..."
systemctl restart containerd
systemctl status containerd --no-pager

# Confirm success
echo "Containerd installation and configuration completed successfully."
