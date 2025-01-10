#!/bin/bash

# ----------------------------
# Kubernetes Node Setup Script with Swap Disable and Kernel Configuration
#
# Features:
# - Asks the user if the setup is for a Master (m) or Worker (w) node.
# - Configures hostnames and updates /etc/hosts.
# - Disables swap permanently.
# - Configures kernel modules and networking for Kubernetes.
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

    # Get the current hostname
    CURRENT_HOSTNAME=$(hostname)

    echo "Setting hostname to $CURRENT_HOSTNAME..."
    hostnamectl set-hostname "$CURRENT_HOSTNAME"

    # Get the current host's IP address
    CURRENT_IP=$(hostname -I | awk '{print $1}') # Fetch the first IP address

    if [[ -z "$CURRENT_IP" ]]; then
        echo "Error: Unable to fetch the current host's IP address."
        exit 1
    fi

    # Update /etc/hosts
    echo "Updating /etc/hosts file..."
    sed -i "s/^.*$CURRENT_HOSTNAME\$/$CURRENT_IP  $CURRENT_HOSTNAME/" /etc/hosts

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

    # Get the current host IP address
    CURRENT_IP=$(hostname -I | awk '{print $1}') # Fetch the first IP address

    if [[ -z "$CURRENT_IP" ]]; then
        echo "Error: Unable to fetch the current host's IP address."
        exit 1
    fi

    # Update /etc/hosts
    echo "Updating /etc/hosts file..."
    sed -i "s/^.*$CURRENT_HOSTNAME\$/$CURRENT_IP  $CURRENT_HOSTNAME/" /etc/hosts
    echo -e "\n$MASTER_IP  $MASTER_HOSTNAME" >> /etc/hosts

    echo "Worker node setup completed."

else
    echo "Error: Invalid option. Please enter 'm' for Master or 'w' for Worker."
    exit 1
fi

read -p "Press Enter to continue..."

# Step 2: Disable Swap
echo "Disabling swap temporarily..."
swapoff -a
if [[ $? -eq 0 ]]; then
    echo "Swap disabled temporarily."
else
    echo "Failed to disable swap temporarily. Please check for issues."
    exit 1
fi

echo "Permanently disabling swap..."
sed -i '/ swap / s/^/#/' /etc/fstab

if ! grep -q "swap" /proc/swaps; then
    echo "Swap has been permanently disabled."
else
    echo "Failed to disable swap permanently. Please check /etc/fstab."
    exit 1
fi

echo "Swap disable process completed successfully."

read -p "Press Enter to continue..."

# Step 3: Configure Kernel Modules and Networking
echo "Configure Kernel Modules and Networking"
modprobe overlay
modprobe br_netfilter

cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

cat <<EOF | tee /etc/sysctl.d/kubernetes.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

sysctl --system

echo "Kernel modules and networking configuration completed successfully."

read -p "Press Enter to continue..."

# Step 4: Install containerd and dependencies
echo "Installing containerd and necessary dependencies..."
apt update
apt install -y curl gnupg2 software-properties-common apt-transport-https ca-certificates
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/containerd.gpg
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt update
apt install -y containerd.io

# Configure containerd
containerd config default | tee /etc/containerd/config.toml >/dev/null 2>&1
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml

# Restart containerd and verify its status
systemctl restart containerd
systemctl status containerd --no-pager

# Confirm success
echo "Containerd installation and configuration completed successfully."

read -p "Press Enter to continue..."

#Step 5: Setup Kubernetes
echo "Setup Kubernetes..."
mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/k8s.gpg
echo 'deb [signed-by=/etc/apt/keyrings/k8s.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | tee /etc/apt/sources.list.d/k8s.list

apt update
apt install -y kubelet kubeadm kubectl

systemctl restart kubelet
systemctl status kubelet --no-pager

echo "Kubernetes components installation completed successfully (if the kubelet service is not running, ensure swap is disabled and try again)."

read -p "Press Enter to continue..."

#Step 6: Setup the interconnectivity

if [[ "$NODE_TYPE" == "m" ]]; then
    echo "Initializing the Master Node..."
    sudo kubeadm init --control-plane-endpoint=$MASTER_HOSTNAME

    echo "Setting up kubectl for the current user..."
    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config

    # Install Calico network plugin
    echo "Installing Calico network plugin..."
    kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
    if [[ $? -ne 0 ]]; then
        echo "Error: Failed to install Calico network plugin."
        exit 1
    fi

    # Install Flannel network plugin
    echo "Installing Flannel network plugin..."
    kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
    if [[ $? -ne 0 ]]; then
        echo "Error: Failed to install Flannel network plugin."
        exit 1
    fi
fi

# Worker Node Setup
if [[ "$NODE_TYPE" == "w" ]]; then
    echo "Setting up the Worker Node..."
    echo "Please run the following kubeadm join command on the Worker Node: \"kubeadm token create --print-join-command\""
    read -p "Enter the kubeadm join command provided by the Master Node: " KUBEADM_JOIN_COMMAND
    

    if [[ -z "$KUBEADM_JOIN_COMMAND" ]]; then
        echo "Error: kubeadm join command cannot be empty."
        exit 1
    fi

    echo "Joining the Worker Node to the cluster..."
    eval "$KUBEADM_JOIN_COMMAND"
fi

echo "Kubernetes Setup Testing Script"

echo
echo "kubectl get pods -n kube-system"
echo "kubectl get nodes"

echo
echo "kubectl create ns demo-app"
echo "kubectl create deployment nginx-app --image nginx --replicas 2 --namespace demo-app"
echo "kubectl get deployment -n demo-app"
echo "kubectl get pods -n demo-app"
echo "kubectl expose deployment nginx-app -n demo-app --type NodePort --port 80"
echo "kubectl get svc -n demo-app"
echo "kubectl get svc -n demo-app"
echo
echo "Then, use the Node IP and the NodePort in a web browser or a curl command."
echo "http://192.168.1.100:30001"

echo
echo "Recreating the join command"
echo "kubeadm token create --print-join-command"

