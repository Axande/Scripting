#!/bin/bash

# Check if script is run as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root. Use sudo to execute the script."
    exit 1
fi

echo "Setting up Git on your system..."

# Update the package index
echo "Updating package index..."
apt update -y

# Install Git
echo "Installing Git..."
apt install -y git

# Check if Git was installed successfully
if ! command -v git &>/dev/null; then
    echo "Git installation failed. Please check for issues and try again."
    exit 1
fi

echo "Git installed successfully."

# Configure Git
read -p "Enter your Git user name: " GIT_USER
read -p "Enter your Git email address: " GIT_EMAIL

git config --global user.name "$GIT_USER"
git config --global user.email "$GIT_EMAIL"

echo "Git has been configured with the following details:"
echo "User Name: $(git config --global user.name)"
echo "Email: $(git config --global user.email)"

# Verify Git version
echo "Git version installed:"
git --version

echo "Git setup completed successfully!"
