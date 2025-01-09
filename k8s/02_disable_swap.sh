#!/bin/bash

# ----------------------------
# Script to Disable Swap Permanently
#
# Features:
# - Disables swap temporarily and permanently.
#
# IMPORTANT:
# - This script must be run as root.
# ----------------------------

# Check if run as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root. Use sudo."
    exit 1
fi

# Welcome message
echo "Welcome to the Swap Disable Script!"
echo "This script will disable swap temporarily and ensure it is permanently disabled."
echo

# Disable swap temporarily
echo "Disabling swap temporarily..."
swapoff -a
if [[ $? -eq 0 ]]; then
    echo "Swap disabled temporarily."
else
    echo "Failed to disable swap temporarily. Please check for issues."
    exit 1
fi

# Permanently disable swap by updating /etc/fstab
echo "Permanently disabling swap..."
sed -i '/ swap / s/^/#/' /etc/fstab
mount -a

# Verify if swap is disabled
if ! grep -q "swap" /proc/swaps; then
    echo "Swap has been permanently disabled."
else
    echo "Failed to disable swap permanently. Please check /etc/fstab for issues."
    exit 1
fi

# Confirm success
echo "Swap disable process completed successfully."

