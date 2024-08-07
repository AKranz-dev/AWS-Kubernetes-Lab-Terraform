# Welcome to AWS-Kubernetes-Lab-Terraform!

Hi! AWS-Kubernetes-Lab-Terraform is an Terraform configuration template that bootstraps a 3-node Kubernetes cluster on EC2. AWS-Kubernetes-Lab-Terraform makes it easy to begin working with an EC2-hosted kubernetes cluster in minutes. AWS-Kubernetes-Lab-Terraform fully automates cluster provisioning and configuration, so you can immediately begin running kubectl commands when you SSH to the control plane. No manual configuration is required!


# How to use
- Simply configure the AWS provider for authentication in main.tf. More information in the AWS Provider documentation: https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication-and-configuration
  - Additionally, ensure the IAM user/role you are using to authenticate Terraform has proper access to provision the resources mentioned below.
- AWS-Kubernetes-Lab-Terraform is written to allow deployments in any region, and does not require any parameters be given to run.
- Connect to the newly created k8s-control EC2 using Systems Manager. You are able to connect immediately as the agent is already installed.
  - Alternatively, you can you an SSH client of your choice. The SSH private key is included in the Terraform Outputs.
- You can begin running kubectl commands immediately, with no further configuration required. Enjoy!



# How it works
- AWS-Kubernetes-Lab-Terraform provisions 3 EC2 instances to host the kubernetes cluster (a control plane, and 2 worker nodes), and supporting resources.
- All system and Kubernetes configurations are scripted in the UserData section of each EC2 instance. 
- The UserData script on the control plane EC2 calls Systems Manager at the end of it's configuration to pass the cluster join command to the worker nodes.
- The Terraform configuration is lightweight, only provisioning resources as absolutely necessary.



# Specifications
- **AWS-Kubernetes-Lab-Terraform.yaml**
  - 3 EC2 instances
  - EC2 instance profile and IAM role
  - Security groups for the control node and worker nodes, and their ingress/egress rules.
  - An EC2 key pair
- **EC2 instances**:
   - OS: Ubuntu 20.04 Focal Fossa
   - Size: t2.medium
   - Packages:
        - curl
        - python3-pip
        - aws-cfn-bootstrap
        - awscliv2
        - unzip
        - kubeadm
        - kubectl
        - kubelet
- **Kubernetes**:
  - Version: latest
  - Container Runtime: containerd
  - Pod Networking Plugin: Calico



# Background
 For a weekend project, I wanted to write some IaC that would bootstrap all infrastructure and server configuration required to run a Kubernetes cluster on EC2. It sounded like a fun automation challenge, not to mention I now have a super easy way to spin up K8s clusters within minutes. 
 
 This is a great tool to have for my home lab, as it allows me to perform sandboxing in Kubernetes. I can experiment with different plugins and applications, easily standing up and tearing down clusters.

 Finally, in terms of cost, its a no-brainer. As long as you turn off your EC2 instances when you're not using them, you're looking at dollars and cents for a monthly cost. Well-worth the value that comes with hands-on experience with Kubernetes and it's related technologies.

