#!/bin/bash

######### ** FOR MASTER NODE ** #########

hostname k8s-msr-1
echo "k8s-msr-1" > /etc/hostname

apt update
apt install apt-transport-https ca-certificates curl software-properties-common -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"

# Installing Docker
tee /etc/modules-load.d/containerd.conf <<EOF
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

apt update
apt-cache policy docker-ce
apt install docker-ce -y

# Adding Kubernetes repositories
mkdir -p /etc/apt/keyrings/
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Turn off swap
swapoff -a
sudo sed -i '/swap/d' /etc/fstab
mount -a
ufw disable

# Installing Kubernetes tools
apt update
apt install -y kubeadm=1.31.1-1.1 kubelet=1.31.1-1.1 kubectl=1.31.1-1.1

# Get IP addresses
export ipaddr=$(ip address|grep eth0|grep inet|awk -F ' ' '{print $2}' |awk -F '/' '{print $1}')
export pubip=$(dig +short myip.opendns.com @resolver1.opendns.com)

# Configure containerd
rm /etc/containerd/config.toml
systemctl restart containerd

# Kernel settings
tee /etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

sysctl --system
kubeadm config images pull --kubernetes-version v1.31.1

# Kubernetes cluster init
# kubeadm init --apiserver-advertise-address=$ipaddr --pod-network-cidr=192.168.0.0/16 --apiserver-cert-extra-sans=$pubip > /tmp/result.out
# cat /tmp/result.out

# # Save join command locally
# tail -2 /tmp/result.out > /home/ubuntu/join_command.sh
# chown ubuntu:ubuntu /home/ubuntu/join_command.sh

# # Configure kubectl
# mkdir -p /root/.kube
# cp -i /etc/kubernetes/admin.conf /root/.kube/config
# cp -i /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
# chown -R ubuntu:ubuntu /home/ubuntu/.kube

# # Install Helm
# curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
# chmod 700 get_helm.sh
# ./get_helm.sh

# # Setup flannel
# kubectl create ns kube-flannel
# kubectl label --overwrite ns kube-flannel pod-security.kubernetes.io/enforce=privileged
# helm repo add flannel https://flannel-io.github.io/flannel/
# helm install flannel --set podCidr="192.168.0.0/16" --namespace kube-flannel flannel/flannel

# # Configure bash completion
# echo "source <(kubectl completion bash)" >> /home/ubuntu/.bashrc
# echo "source <(kubectl completion bash)" >> /root/.bashrc
# echo "alias k=kubectl" >> /home/ubuntu/.bashrc
# echo "alias k=kubectl" >> /root/.bashrc
# echo "complete -o default -F __start_kubectl k" >> /home/ubuntu/.bashrc
# echo "complete -o default -F __start_kubectl k" >> /root/.bashrc