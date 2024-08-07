#!/bin/bash -x

# # System level configuration prereqs # #
hostnamectl set-hostname k8s-worker1
ipvar=$(hostname -I)
echo $ipvar k8s-worker1 >> /etc/hosts
touch /etc/modules-load.d/k8s.conf
echo overlay >> /etc/modules-load.d/k8s.conf
echo br_netfilter >> /etc/modules-load.d/k8s.conf
modprobe overlay
modprobe br_netfilter
touch /etc/sysctl.d/k8s.conf
echo net.bridge.bridge-nf-call-iptables  = 1 >> /etc/sysctl.d/k8s.conf
echo net.bridge.bridge-nf-call-ip6tables = 1 >> /etc/sysctl.d/k8s.conf
echo net.ipv4.ip_forward                 = 1 >> /etc/sysctl.d/k8s.conf
sysctl --system

# # Install containerd, setup K8s package repo, install kubelet, kubeam, and kubectl # #
apt-get update && apt-get install -y containerd
mkdir /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
systemctl restart containerd
swapoff -a
apt-get update && apt-get install -y apt-transport-https ca-certificates curl gpg
mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
apt-get update && apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl




