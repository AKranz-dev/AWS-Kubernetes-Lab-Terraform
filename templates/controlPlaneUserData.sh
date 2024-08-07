#!/bin/bash -x

# # Install prereqs, aws cfn helper scripts, and the awscli. # #
apt update && apt install -y -qq python3-pip && apt install -y -qq curl
pip install --quiet https://s3.amazonaws.com/cloudformation-examples/aws-cfn-bootstrap-py3-latest.tar.gz
mkdir ~/aws-cfn-bootstrap && cd ~/aws-cfn-bootstrap
curl https://s3.amazonaws.com/cloudformation-examples/aws-cfn-bootstrap-py3-latest.tar.gz -o aws-cfn-bootstrap.tar.gz
tar -xf ./aws-cfn-bootstrap.tar.gz
ln -s ./aws-cfn-bootstrap-2.0/init/ubuntu/cfn-hup /etc/init.d/cfn-hup
apt install -y unzip
mkdir ~/awscli && cd ~/awscli && curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -qq awscliv2.zip
sudo ./aws/install

# # System level configuration prereqs # #
hostnamectl set-hostname k8s-control
ipvar=$(hostname -I)
echo $ipvar k8s-control | tee -a /etc/hosts ~/newHosts
echo "${kubernetesWorker1} k8s-worker1" | tee -a /etc/hosts ~/newHosts
echo "${kubernetesWorker2} k8s-worker2" | tee -a /etc/hosts ~/newHosts
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
apt-get update && apt-get install -y apt-transport-https ca-certificates gpg
mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
apt-get update && apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

# # Initialize the cluster, install pod networking plugin # #
kubeadm init --pod-network-cidr 192.168.0.0/16
export KUBECONFIG=/etc/kubernetes/admin.conf
echo "KUBECONFIG=/etc/kubernetes/admin.conf" >> /etc/environment
while ! kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml; do echo "Trying to apply Calico again in 5 seconds..."; sleep 5; done

# # Pass configurations and cluster join command to worker nodes via AWS SSM # #
joinCommand=$(kubeadm token create --print-join-command)
aws ssm send-command --instance-ids "${kubernetesWorker1ID}" --document-name AWS-RunShellScript --parameters '{"commands":["echo '"$ipvar"' k8s-control >> /etc/hosts","echo '"${kubernetesWorker2}"' k8s-worker2 >> /etc/hosts","'"$joinCommand"'"]}' --output text
aws ssm send-command --instance-ids "${kubernetesWorker2ID}" --document-name AWS-RunShellScript --parameters '{"commands":["echo '"$ipvar"' k8s-control >> /etc/hosts","echo '"${kubernetesWorker1}"' k8s-worker1 >> /etc/hosts","'"$joinCommand"'"]}' --output text