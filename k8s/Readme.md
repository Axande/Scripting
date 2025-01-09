# Kubernetes Cluster Setup Guide

This guide outlines the steps to set up a Kubernetes cluster with one master node and two worker nodes. Follow the steps below to configure your cluster.

## Prerequisites

- Three Ubuntu-based servers:
  - Master Node: `k8s-control-node`
  - Worker Node 1: `k8s-worker01-node`
  - Worker Node 2: `k8s-worker02-node`
- Ensure all nodes have static IP addresses:
  - Master Node: `192.168.1.56`
  - Worker Node 1: `192.168.1.57`
  - Worker Node 2: `192.168.1.58`

---

## Step 1: Set Hostnames and Update Hosts File

Set the hostname on each node:

```bash
sudo hostnamectl set-hostname "k8s-control-node"   # On Master Node
sudo hostnamectl set-hostname "k8s-worker01-node"  # On Worker Node 1
sudo hostnamectl set-hostname "k8s-worker02-node"  # On Worker Node 2
```

Update the `/etc/hosts` file on all nodes:

```plaintext
192.168.1.56  k8s-control-node
192.168.1.57  k8s-worker01-node
192.168.1.58  k8s-worker02-node
```

---

## Step 2: Disable Swap

Disabling swap is crucial for Kubernetes to function properly:

```bash
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
```

---

## Step 3: Load Kernel Modules and Configure Networking

Load necessary kernel modules:

```bash
sudo modprobe overlay
sudo modprobe br_netfilter
```

Persist module loading:

```bash
sudo tee /etc/modules-load.d/k8s.conf <<EOF
overlay
br_netfilter
EOF
```

Configure sysctl settings for Kubernetes:

```bash
sudo tee /etc/sysctl.d/kubernetes.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
```

Apply the configuration:

```bash
sudo sysctl --system
```

---

## Step 4: Install and Configure Containerd

Install containerd:

```bash
sudo apt update
sudo apt install -y curl gnupg2 software-properties-common apt-transport-https ca-certificates
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/containerd.gpg
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt update && sudo apt install containerd.io -y
```

Configure containerd:

```bash
containerd config default | sudo tee /etc/containerd/config.toml >/dev/null 2>&1
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
```

Restart containerd:

```bash
sudo systemctl restart containerd
sudo systemctl status containerd
```

---

## Step 5: Install Kubernetes Components

Add the Kubernetes package repository:

```bash
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/k8s.gpg
echo 'deb [signed-by=/etc/apt/keyrings/k8s.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | sudo tee /etc/apt/sources.list.d/k8s.list
```

Install Kubernetes components:

```bash
sudo apt update
sudo apt install -y kubelet kubeadm kubectl
sudo systemctl restart kubelet
sudo systemctl status kubelet
```

Disable swap again if necessary.

---

## Step 6: Initialize the Master Node

Initialize the master node:

```bash
sudo kubeadm init --control-plane-endpoint=k8s-control-node
```

Set up kubectl for the current user:

```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

---

## Step 7: Join Worker Nodes

On each worker node, join the cluster using the token provided during the master node initialization:

```bash
kubeadm join k8s-control-node:6443 --token <TOKEN> --discovery-token-ca-cert-hash sha256:<HASH>
```

---

## Step 8: Install a Network Plugin

On the master node, install a network plugin such as Calico or Flannel:

### Install Calico:
```bash
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
```

### Install Flannel:
```bash
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
```

---

## Step 9: Verify the Setup

Check the status of the Kubernetes system pods:

```bash
kubectl -n kube-system get pods
```

---

## Step 10: Permanently Disable Swap

Edit the `/etc/fstab` file and comment out the swap entry:

```plaintext
#/swap.img    none    swap    sw    0   0
```

Remount the filesystem and verify swap is disabled:

```bash
sudo mount -a
cat /proc/swaps
```

Reboot the system:

```bash
sudo reboot
```


