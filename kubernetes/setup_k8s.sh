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

setup_node(){
    read -p "Please select the type of node you want to set up: Master Node(m) or Worker Node(w): " NODE_TYPE

    if [[ "$NODE_TYPE" == "m" ]]; then
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
        # Ask for master node details
        read -p "Enter the IP address of the master node: " MASTER_IP
        read -p "Enter the hostname of the master node (e.g., k8s-master-node): " MASTER_HOSTNAME

        if [[ -z "$MASTER_IP" || -z "$MASTER_HOSTNAME" ]]; then
            echo "Error: Master IP and hostname cannot be empty."
            exit 1
        fi

        # Get the current hostname
        echo "Setting hostname to $CURRENT_HOSTNAME..."
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

        # Add master details directly after the worker entry
        if grep -q "$CURRENT_HOSTNAME" /etc/hosts; then
            sed -i "/$CURRENT_HOSTNAME/a\\$MASTER_IP  $MASTER_HOSTNAME" /etc/hosts
        else
            echo "$MASTER_IP  $MASTER_HOSTNAME" >> /etc/hosts
        fi
    else
        echo "Error: Invalid option. Please enter 'm' for Master or 'w' for Worker."
        exit 1
    fi
}

disable_swap(){
    echo "Disabling swap..."
    swapoff -a
    sed -i '/\s\+swap\s\+/ s/^/#/' /etc/fstab
}

setup_kernel_modules(){
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
}

setup_containerd(){
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
}

setup_kubernetes(){
    echo "Setup Kubernetes..."
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/k8s.gpg
    echo 'deb [signed-by=/etc/apt/keyrings/k8s.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | tee /etc/apt/sources.list.d/k8s.list

    apt update
    apt install -y kubelet kubeadm kubectl

    systemctl restart kubelet
    systemctl status kubelet --no-pager

    echo "Kubernetes components installation completed successfully (if the kubelet service is not running, ensure swap is disabled and try again)."
}

reset_kubernetes() {
    echo "Cleaning up previous Kubernetes installation..."
    sudo kubeadm reset --force
}

setup_master_node_k8s(){
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
}

setup_worker_node_k8s(){
    echo "Setting up the Worker Node..."
    echo "Please run the following kubeadm join command on the Worker Node: \"kubeadm token create --print-join-command\""
    read -p "Enter the kubeadm join command provided by the Master Node: " KUBEADM_JOIN_COMMAND
    

    if [[ -z "$KUBEADM_JOIN_COMMAND" ]]; then
        echo "Error: kubeadm join command cannot be empty."
        exit 1
    fi

    echo "Joining the Worker Node to the cluster..."
    eval "$KUBEADM_JOIN_COMMAND"
}

setup_metallb(){
    echo "Setup MetalLB..."

    kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/main/config/manifests/metallb-native.yaml
    if [[ $? -ne 0 ]]; then
        echo "Failed to apply MetalLB manifests. Exiting."
        exit 1
    fi

    # Wait for MetalLB pods to start
    echo "Waiting for MetalLB pods to be ready..."
    kubectl -n metallb-system wait --for=condition=Ready pods --all --timeout=120s
    if [[ $? -ne 0 ]]; then
        echo "MetalLB pods failed to start. Exiting."
        exit 1
    fi

    # Step 2: Ask user for IP range
    echo "Please provide the IP range for MetalLB to use:"
    read -p "Enter the lower bound of the IP range (e.g., 192.168.0.220): " IP_LOWER
    read -p "Enter the upper bound of the IP range (e.g., 192.168.0.230): " IP_UPPER

    # Validate input
    if [[ -z "$IP_LOWER" || -z "$IP_UPPER" ]]; then
        echo "Error: Both lower and upper bounds are required. Exiting."
        exit 1
    fi

    echo "Using IP range: $IP_LOWER - $IP_UPPER"
    
    cat <<EOF | kubectl apply -f -
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  namespace: metallb-system
  name: my-ip-pool
spec:
  addresses:
  - $IP_LOWER-$IP_UPPER
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  namespace: metallb-system
  name: my-l2-adv
spec: {}
EOF

    if [[ $? -ne 0 ]]; then
        echo "Failed to configure IP Address Pool. Exiting."
        exit 1
    fi

    # Step 3: Verify Configuration
    kubectl -n metallb-system get pods
    if [[ $? -ne 0 ]]; then
        echo "Failed to verify MetalLB pods. Exiting."
        exit 1
    fi
}

post_setup_info(){
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
    echo "Assign new node as worker node:"
    echo "kubectl taint nodes <node-name> node-role.kubernetes.io/master:NoSchedule-"
}

# Main Script Execution
# ----------------------------
# Check if run as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root. Use sudo."
    exit 1
fi

echo "Welcome to the Kubernetes Node Setup Script!"


setup_node # Step 1: Setup the node based on its type
disable_swap # Step 2: Disable Swap
setup_kernel_modules # Step 3: Configure Kernel Modules and Networking
setup_containerd # Step 4: Install containerd and dependencies
setup_kubernetes #Step 5: Setup Kubernetes

# Step 5b. Clean kubernetes installation
echo "Do you want to clean any previous Kubernetes installation? (y/n)"
read -r user_input

if [ "$user_input" = "y" ] || [ "$user_input" = "Y" ]; then
    reset_kubernetes
fi

# Step 6a: Master Node Setup
if [[ "$NODE_TYPE" == "m" ]]; then
    setup_master_node_k8s
    setup_metallb
fi

# Step 6b: Worker Node Setup
if [[ "$NODE_TYPE" == "w" ]]; then
    setup_worker_node_k8s
fi

post_setup_info
