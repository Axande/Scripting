#!/bin/bash

# ----------------------------
# Script for Updating Hostname on Ubuntu
#
# IMPORTANT:
# - The user provides a hostname, which will be used to update the Ubuntu VM.
# - This script will update the hostname immediately and ensure it persists across reboots.
# ----------------------------

# Check if run as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root. Use sudo."
    exit 1
fi

# Welcome message
echo "Welcome to the Hostname Update Script for Ubuntu!"
echo "This script will update the hostname of your machine."
echo "Please enter the new hostname:"

# Prompt the user for the hostname
read -p "Hostname: " NEW_HOSTNAME

# Validate user input
if [[ -z "$NEW_HOSTNAME" ]]; then
    echo "Error: No hostname entered. Please run the script again."
    exit 1
fi

# Confirm with the user
echo "The script will update the hostname to: $NEW_HOSTNAME"
read -p "Do you want to proceed? (y/n): " CONFIRM

if [[ "$CONFIRM" != "y" ]]; then
    echo "Aborted by user."
    exit 0
fi

# Update hostname immediately
echo "Updating hostname..."
CURRENT_HOSTNAME=$(hostname)
hostnamectl set-hostname "$NEW_HOSTNAME"

if [[ $? -eq 0 ]]; then
    echo "Hostname updated successfully from '$CURRENT_HOSTNAME' to '$NEW_HOSTNAME'."
else
    echo "Failed to update hostname. Please check for issues."
    exit 1
fi

# Update /etc/hosts
echo "Updating /etc/hosts file..."
if grep -q "$CURRENT_HOSTNAME" /etc/hosts; then
    sed -i "s/$CURRENT_HOSTNAME/$NEW_HOSTNAME/g" /etc/hosts
else
    echo "127.0.1.1 $NEW_HOSTNAME" >> /etc/hosts
fi

# Confirm success
echo "Hostname update completed."
echo "Current hostname is now: $(hostname)"
echo "Reboot the machine to ensure changes are persistent."

# Prompt to reboot
read -p "Would you like to reboot now? (y/n): " REBOOT
if [[ "$REBOOT" == "y" ]]; then
    echo "Rebooting..."
    reboot
else
    echo "Please reboot the machine manually to ensure changes are fully applied."
fi
