#!/bin/bash

# ----------------------------
# Script to Install Kubernetes Components
#
# Features:
# - Adds the Kubernetes package repository.
# - Installs kubelet, kubeadm, and kubectl.
# - Ensures the kubelet service is running.
#
# IMPORTANT:
# - This script must be run with root privileges.
# ----------------------------

# Check if run as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root. Use sudo."
    exit 1
fi

# Add the Kubernetes package repository
echo "Adding the Kubernetes package repository..."
mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/k8s.gpg
echo 'deb [signed-by=/etc/apt/keyrings/k8s.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | tee /etc/apt/sources.list.d/k8s.list

# Install Kubernetes components
echo "Installing kubelet, kubeadm, and kubectl..."
apt update
apt install -y kubelet kubeadm kubectl

# Restart and verify kubelet service
echo "Restarting and verifying kubelet service..."
systemctl restart kubelet
systemctl status kubelet --no-pager

# Confirm success
echo "Kubernetes components installation completed successfully."
echo "If the kubelet service is not running, ensure swap is disabled and try again."
