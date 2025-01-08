# Static IP Setup Script for Ubuntu

This script simplifies the process of configuring a static IP address on an Ubuntu machine using Netplan.

---

## Features
- Sets up a static IP address with a predefined network interface and settings.
- Uses Netplan for modern Ubuntu network configuration.
- Backs up the existing Netplan configuration file before applying changes.

---

## How to Use the Script

### 1. Using the Script Locally

If you have downloaded the script locally, follow these steps:

1. **Download the Script**:
   Save the script file (`setup_static_ip.sh`) in your local directory.

2. **Make the Script Executable**:
   Run the following command to make the script executable:
   ```bash
   chmod +x setup_static_ip.sh
   ```

3. **Run the Script**:
   Execute the script with `sudo` to apply changes:
   ```bash
   sudo ./setup_static_ip.sh
   ```

---

### 2. Using the Script with `wget`

To run the script directly from the repository using `wget`:

1. Use the following command to download and run the script:
   ```bash
   wget -qO- https://raw.githubusercontent.com/Axande/Scripting/main/Ubuntu/setup_static_ip.sh | sudo bash
   ```

---

### 3. Using the Script with `curl`

Alternatively, you can run the script using `curl`:

```bash
curl -s https://raw.githubusercontent.com/Axande/Scripting/main/Ubuntu/setup_static_ip.sh | sudo bash
```

---

## Configuration

The script comes with the following pre-configured settings:
- **Interface**: `enp6s18`
- **Static IP**: `192.168.0.213/24`
- **Gateway**: `192.168.0.1`
- **DNS Servers**: `8.8.8.8, 1.1.1.1`

### Modifying the Configuration
If you're setting up a new homelab, modify these variables in the script:
1. `INTERFACE` - The network interface name (e.g., `eth0` or `wlan0`).
2. `STATIC_IP` - The desired static IP address with CIDR notation (e.g., `192.168.1.100/24`).
3. `GATEWAY` - The default gateway for the network.
4. `DNS` - Comma-separated list of DNS servers (e.g., `8.8.8.8,1.1.1.1`).

---

## Notes
1. The script backs up the current Netplan configuration file (`/etc/netplan/01-netcfg.yaml`) before making changes.
2. Reboot your system after running the script to ensure changes are persistent.
3. If you encounter any issues, check the Netplan logs or configuration:
   ```bash
   sudo netplan try
   sudo netplan apply
   ```
