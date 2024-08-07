# # Provider Configuration # #
provider "aws" {
  region                   = var.awsRegion
  shared_config_files      = ["C:/Users/austi/.aws/config"]
  shared_credentials_files = ["C:/Users/austi/.aws/credentials"]
}

# # Dynamic Variable Declaration # #
locals {
  user_data_vars = {
    kubernetesWorker1   = aws_instance.kubernetesWorker1.private_ip
    kubernetesWorker2   = aws_instance.kubernetesWorker2.private_ip
    kubernetesWorker1ID = aws_instance.kubernetesWorker1.id
    kubernetesWorker2ID = aws_instance.kubernetesWorker2.id
  }
}


#Retrieve Ubuntu AMI
resource "aws_ami_copy" "Ubuntu" {
  name              = "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-20231025"
  source_ami_id     = "ami-07b36ea9852e986ad"
  source_ami_region = "us-east-2"
  description       = "Canonical, Ubuntu, 20.04 LTS, amd64 focal image build on 2023-10-25"
}


#KubernetesControlPlane
resource "aws_instance" "KubernetesControlPlane" {
  ami                         = aws_ami_copy.Ubuntu.id
  associate_public_ip_address = false
  key_name                    = aws_key_pair.K8sKeyPair.key_name
  security_groups             = [aws_security_group.kubernetesControlPlaneSecurityGroup.name]
  instance_type               = var.instanceType
  tags                        = { "Name" : "k8s-control-lab" }
  iam_instance_profile        = aws_iam_instance_profile.ec2InstanceProfile.name
  ebs_block_device {
    device_name           = "/dev/sda1"
    delete_on_termination = true
    volume_size           = 30
    volume_type           = "gp2"
    encrypted             = true
  }
  user_data = templatefile("${path.module}/templates/controlPlaneUserData.sh", local.user_data_vars)
}


#kubernetesWorker1
resource "aws_instance" "kubernetesWorker1" {
  ami                         = aws_ami_copy.Ubuntu.id
  associate_public_ip_address = false
  key_name                    = aws_key_pair.K8sKeyPair.key_name
  security_groups             = [aws_security_group.kubernetesWorkersSecurityGroup.name]
  instance_type               = var.instanceType
  tags                        = { "Name" : "k8s-worker1-lab" }
  iam_instance_profile        = aws_iam_instance_profile.ec2InstanceProfile.name
  ebs_block_device {
    device_name           = "/dev/sda1"
    delete_on_termination = true
    volume_size           = 30
    volume_type           = "gp2"
    encrypted             = true
  }
  user_data = templatefile("${path.module}/templates/worker1UserData.sh", {})
}

#kubernetesWorker2
resource "aws_instance" "kubernetesWorker2" {
  ami                         = aws_ami_copy.Ubuntu.id
  associate_public_ip_address = false
  key_name                    = aws_key_pair.K8sKeyPair.key_name
  security_groups             = [aws_security_group.kubernetesWorkersSecurityGroup.name]
  instance_type               = var.instanceType
  tags                        = { "Name" : "k8s-worker2-lab" }
  iam_instance_profile        = aws_iam_instance_profile.ec2InstanceProfile.name
  ebs_block_device {
    device_name           = "/dev/sda1"
    delete_on_termination = true
    volume_size           = 30
    volume_type           = "gp2"
    encrypted             = true
  }
  user_data = templatefile("${path.module}/templates/worker2UserData.sh", {})
}


#ec2InstanceProfileRole
resource "aws_iam_role" "ec2InstanceProfileRole" {
  name                = "K8sEC2InstanceRole"
  assume_role_policy  = jsonencode({ "Version" : "2012-10-17", "Statement" : [{ "Sid" : "", "Effect" : "Allow", "Principal" : { "Service" : "ec2.amazonaws.com" }, "Action" : "sts:AssumeRole" }] })
  managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]
  inline_policy {
    name   = "AdditionalSSMPermissions"
    policy = jsonencode({ "Version" : "2012-10-17", "Statement" : [{ "Sid" : "VisualEditor0", "Effect" : "Allow", "Action" : "ssm:SendCommand", "Resource" : ["arn:aws:ssm:*::document/AWS-RunShellScript", "arn:aws:ec2:*:*:instance/*", "arn:aws:ssm:*:*:managed-instance/*"] }] })
  }
}

#ec2InstanceProfile
resource "aws_iam_instance_profile" "ec2InstanceProfile" {
  name       = "K8sEC2InstanceProfile"
  role       = aws_iam_role.ec2InstanceProfileRole.name
  depends_on = [aws_iam_role.ec2InstanceProfileRole]
}



# # K8s Control Plane SG # #
#kubernetesControlPlaneSecurityGroup
resource "aws_security_group" "kubernetesControlPlaneSecurityGroup" {
  name        = "kubernetesControlPlaneSecurityGroup"
  description = "Security Group for K8s Control Plane"
  vpc_id      = var.vpcID
}

#kubernetesControlPlaneSecurityGroup - Egress Rule
resource "aws_vpc_security_group_egress_rule" "k8sControlPlaneEgress" {
  security_group_id = aws_security_group.kubernetesControlPlaneSecurityGroup.id
  description       = "All traffic outbound IPv4"
  ip_protocol       = -1
  cidr_ipv4         = "0.0.0.0/0"
}

#kubernetesControlPlaneSecurityGroup - Ingress Rule
resource "aws_vpc_security_group_ingress_rule" "k8sControlPlaneIngress" {
  security_group_id            = aws_security_group.kubernetesControlPlaneSecurityGroup.id
  description                  = "All traffic from worker nodes"
  ip_protocol                  = -1
  referenced_security_group_id = aws_security_group.kubernetesWorkersSecurityGroup.id
}




# # K8s Worker Node SG # #
#kubernetesWorkersSecurityGroup
resource "aws_security_group" "kubernetesWorkersSecurityGroup" {
  name        = "kubernetesWorkersSecurityGroup"
  description = "Security Group for K8s worker nodes"
  vpc_id      = var.vpcID
}

#kubernetesWorkersSecurityGroup - Egress Rule
resource "aws_vpc_security_group_egress_rule" "k8sWorkersEgress" {
  security_group_id = aws_security_group.kubernetesWorkersSecurityGroup.id
  description       = "All traffic outbound IPv4"
  ip_protocol       = -1
  cidr_ipv4         = "0.0.0.0/0"
}

#kubernetesWorkersSecurityGroup - Ingress Rule
resource "aws_vpc_security_group_ingress_rule" "k8sWorkersIngress" {
  security_group_id            = aws_security_group.kubernetesWorkersSecurityGroup.id
  description                  = "All traffic from control plane node"
  ip_protocol                  = -1
  referenced_security_group_id = aws_security_group.kubernetesControlPlaneSecurityGroup.id
}



#generateEncryptionKey
resource "tls_private_key" "rsaKey" {
  algorithm = "RSA"
  rsa_bits  = "2048"
}

#ec2KeyPair
resource "aws_key_pair" "K8sKeyPair" {
  key_name = "K8sEc2KeyPair"

  public_key = tls_private_key.rsaKey.public_key_openssh
}


# # Outputs # #
#EC2 Key Pair for SSH
output "private_key_OpenSSH" {
  value     = trimspace(tls_private_key.rsaKey.private_key_openssh)
  sensitive = true
}