# List of scripts

<details>
  <summary>Static IP</summary>

# Setup Static IP

This script configures a static IP address on an Ubuntu machine using Netplan.

---

### 1. Download the Script
```bash
wget -O static_ip_setup.sh https://raw.githubusercontent.com/Axande/Scripting/refs/heads/main/Ubuntu/static_ip_setup.sh
```

### 2. Run the Script
```bash
chmod +x static_ip_setup.sh
sudo ./static_ip_setup.sh
```

### 3. Reboot
```bash
sudo reboot
```
</details>

<!-- Set Hostname -->

<details> 
  <summary>Set Hostname</summary>

# Update hostname

This script updates the hostname of an Ubuntu machine.

---

### 1. Download the Script
```bash
wget -O update_hostname.sh https://raw.githubusercontent.com/Axande/Scripting/refs/heads/main/Ubuntu/update_hostname.sh
```

### 2. Run the Script
```bash
chmod +x update_hostname.sh
sudo ./update_hostname.sh
```

</details>


</details>

<!-- K8S -->

<details> 
  <summary>K8S</summary>

# Update hostname

This script sets up kubernetes.

---

### 2. Disable swap permanently
```bash
wget -qO- https://raw.githubusercontent.com/Axande/Scripting/main/k8s/02_disable_swap.sh | sudo bash
```

</details>