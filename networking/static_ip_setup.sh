#!/bin/bash

# ----------------------------
# Ubuntu Static IP Configuration Script using Netplan
# ----------------------------
# This script configures a static IP address for a specified network interface.
# Users must provide:
#   - Network interface name (e.g., enp6s18, eth0)
#   - Static IP address
#
# Features:
# ✅ Prompts user for interface name dynamically
# ✅ Ensures correct permissions for Netplan files
# ✅ Backs up existing Netplan configurations
# ✅ Asks for user confirmation before applying changes
# ----------------------------

# Netplan configuration directory
NETPLAN_DIR="/etc/netplan"

# Check if run as root
if [[ $EUID -ne 0 ]]; then
    echo "❌ Error: This script must be run as root. Use sudo."
    exit 1
fi

# Welcome message
echo "🔹 Welcome to the Ubuntu Static IP Setup Script!"
echo "💡 This script will configure your network interface with a static IP."
echo ""

# List available network interfaces
echo "🔍 Available network interfaces:"
ip -o link show | awk -F': ' '{print "  - " $2}'

# Prompt for network interface name
read -p "Enter your network interface name (e.g., eth0, enp6s18): " INTERFACE

# Validate the interface
if ! ip link show "$INTERFACE" > /dev/null 2>&1; then
    echo "❌ Error: Network interface '$INTERFACE' not found. Please check and try again."
    exit 1
fi

# Prompt for static IP
read -p "Enter the static IP address (e.g., 192.168.0.220): " USER_IP
if [[ -z "$USER_IP" ]]; then
    echo "❌ Error: No IP address entered. Please run the script again."
    exit 1
fi

# Set other network details
SUBNET="/24"                             # Subnet in CIDR notation
GATEWAY="192.168.0.1"                    # Default gateway
DNS=("8.8.8.8" "1.1.1.1")                # DNS servers
STATIC_IP="${USER_IP}${SUBNET}"           # Full static IP
NETPLAN_FILE="${NETPLAN_DIR}/01-netcfg.yaml"

# Confirm settings with the user
echo ""
echo "⚙️  The script will apply the following settings:"
echo "🔹 Interface:  $INTERFACE"
echo "🔹 Static IP:  $STATIC_IP"
echo "🔹 Gateway:    $GATEWAY"
echo "🔹 DNS:        ${DNS[@]}"
read -p "Do you want to proceed? (y/n): " CONFIRM

if [[ "$CONFIRM" != "y" ]]; then
    echo "❌ Aborted by user."
    exit 0
fi

# Backup existing Netplan configuration
echo "📂 Backing up existing Netplan configurations..."
mkdir -p "${NETPLAN_DIR}/backup"
TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
for file in ${NETPLAN_DIR}/*.yaml; do
    [ -f "$file" ] && cp "$file" "${NETPLAN_DIR}/backup/$(basename $file).bak-$TIMESTAMP"
done
echo "✅ Backup completed."

# Clean up existing Netplan files
echo "🧹 Removing existing Netplan configuration files..."
rm -f ${NETPLAN_DIR}/*.yaml
echo "✅ Old Netplan configurations removed."

# Create new Netplan configuration
echo "📝 Creating new Netplan configuration file: $NETPLAN_FILE..."
cat <<EOL > $NETPLAN_FILE
network:
  version: 2
  ethernets:
    $INTERFACE:
      dhcp4: false
      addresses:
        - $STATIC_IP
      routes:
        - to: default
          via: $GATEWAY
      nameservers:
        addresses:
EOL

# Append DNS servers line by line
for dns in "${DNS[@]}"; do
    echo "          - $dns" >> $NETPLAN_FILE
done

# Apply correct permissions
echo "🔒 Applying correct permissions to Netplan file..."
chmod 600 "$NETPLAN_FILE"
echo "✅ Permissions set to 600 (root-only access)."

# Apply Netplan configuration
echo "🚀 Applying Netplan changes..."
netplan apply

# Check if Netplan applied successfully
if [[ $? -eq 0 ]]; then
    echo "✅ Static IP configuration applied successfully!"
    echo "🌐 Interface:  $INTERFACE"
    echo "🌐 Static IP:  $STATIC_IP"
    echo "🌐 Gateway:    $GATEWAY"
    echo "🌐 DNS:        ${DNS[@]}"
    echo "🔄 Please reboot the machine to ensure changes persist."
else
    echo "❌ Error: Failed to apply Netplan configuration. Please check logs with: journalctl -xe"
    exit 1
fi

# Prompt to reboot
read -p "Would you like to reboot now? (y/n): " REBOOT
if [[ "$REBOOT" == "y" ]]; then
    echo "🔄 Rebooting..."
    reboot
else
    echo "✅ Setup complete. Please reboot manually to apply changes."
fi
