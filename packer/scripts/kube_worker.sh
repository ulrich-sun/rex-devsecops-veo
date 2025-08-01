#!/bin/bash

######### ** FOR WORKER NODE ** #########

# Configure hostname
hostname k8s-wrk-${worker_number}
echo "k8s-wrk-${worker_number}" > /etc/hostname

# Update system and install dependencies
apt-get update
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common

# Install Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  focal stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Configure container prerequisites
tee /etc/modules-load.d/containerd.conf <<EOF
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

# Install Docker and containerd
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io

# Configure Kubernetes repository
mkdir -p /etc/apt/keyrings/
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /" | \
  tee /etc/apt/sources.list.d/kubernetes.list

# System configuration
swapoff -a
sed -i '/swap/d' /etc/fstab
mount -a
systemctl disable --now ufw

# Install Kubernetes components
apt-get update
apt-get install -y \
    kubeadm=1.31.1-1.1 \
    kubelet=1.31.1-1.1 \
    kubectl=1.31.1-1.1
apt-mark hold kubeadm kubelet kubectl

# Configure containerd
rm -f /etc/containerd/config.toml
systemctl restart containerd

# Configure kernel parameters
tee /etc/sysctl.d/kubernetes.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
sysctl --system

# # Wait for master to be ready (improved method)
# attempts=0
# max_attempts=30

# until nc -z k8s-msr-1 6443; do
#     if [ $attempts -eq $max_attempts ]; then
#         echo "Master node not ready after $max_attempts attempts, aborting..."
#         exit 1
#     fi
#     echo "Waiting for master node to be ready... (attempt $((attempts+1))/$max_attempts)"
#     sleep 20
#     ((attempts++))
# done

# # Retrieve join command directly from master via SSH
# join_command=$(ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
#     ubuntu@k8s-msr-1 "cat /home/ubuntu/join_command.sh")

# if [ -z "$join_command" ]; then
#     echo "Failed to retrieve join command from master"
#     exit 1
# fi

# echo "Joining cluster with command: $join_command"
# eval $join_command

# # Verify node joined successfully
# if systemctl is-active --quiet kubelet; then
#     echo "Successfully joined Kubernetes cluster"
# else
#     echo "Error joining Kubernetes cluster"
#     exit 1
# fi
# echo "Kubernetes worker node setup completed successfully"