provider "aws" {
    region = var.aws_region
    profile = var.aws_profile
}

# Create a VPC 
resource "aws_vpc" "vpc" {
    cidr_block = var.vpc_cidr_block
    enable_dns_support = true
    enable_dns_hostnames = true
    tags = {
        Name = "jfernandezja-k8s-vpc"
    }
}
 
# Create a Keypair
resource "aws_key_pair" "kubernetes" {
    key_name = "jfernandezja-k8s-keypair"
    public_key = var.ssh_public_key
}
 
# Create an Internet Gateway
resource "aws_internet_gateway" "gw" {
    vpc_id = aws_vpc.vpc.id
}

# Create a subnet with auto-assign public ip addresses
resource "aws_subnet" "kubernetes" {
    vpc_id = aws_vpc.vpc.id
    cidr_block = var.vpc_cidr_block
    map_public_ip_on_launch = true
}

# Create a Route Table on the VPC and add a route to the Internet
resource "aws_route_table" "kubernetes" {
    vpc_id = aws_vpc.vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.gw.id
    }
}

# Associate the route table with the Subnet 
resource "aws_route_table_association" "kubernetes" {
    subnet_id = aws_subnet.kubernetes.id
    route_table_id = aws_route_table.kubernetes.id
}
 
# Create Security Group
resource "aws_security_group" "kubernetes" {
    vpc_id = aws_vpc.vpc.id
    name = "jfernandezja-k8s-secgroup"
}
 
# Allow SSH connections from ALL 
resource "aws_security_group_rule" "allow_ssh_from_all" {
    type    = "ingress"
    protocol  = "tcp"
    from_port  = 22
    to_port   = 22
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = aws_security_group.kubernetes.id
}

# Allow outbound traffic
resource "aws_security_group_rule" "allow_ssh_to_all" {
    type    = "egress"
    protocol  = -1
    from_port  = 0
    to_port   = 0
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = aws_security_group.kubernetes.id
}
 
# Allow API connections from ALL
resource "aws_security_group_rule" "allow_api_from_all" {
    type    = "ingress"
    protocol  = "tcp"
    from_port  = 6443
    to_port   = 6443
    cidr_blocks = ["0.0.0.0/0"]
    security_group_id = aws_security_group.kubernetes.id
}

# Allow the security group members to talk with each other without restrictions
resource "aws_security_group_rule" "allow_cluster_crosstalk" {
    type = "ingress"
    from_port = 0
    to_port = 0
    protocol = "-1"
    source_security_group_id = aws_security_group.kubernetes.id
    security_group_id = aws_security_group.kubernetes.id
}

# Create the Kubernetes etcd
resource "aws_instance" "etcd" {
    ami = local.ami_id

    instance_type = var.aws_instance_type
    
    subnet_id = aws_subnet.kubernetes.id
    user_data_base64 = local.user_data

    vpc_security_group_ids = ["${aws_security_group.kubernetes.id}"]
    key_name = aws_key_pair.kubernetes.id

    tags = {
        Name = "jfernandezja-k8s-etcd"
    }
}

# Create the Kubernetes controlplane
resource "aws_instance" "controlplane" {
    ami = local.ami_id

    instance_type = var.aws_instance_type
    
    subnet_id = aws_subnet.kubernetes.id
    user_data_base64 = local.user_data

    vpc_security_group_ids = ["${aws_security_group.kubernetes.id}"]
    key_name = aws_key_pair.kubernetes.id

    tags = {
        Name = "jfernandezja-k8s-controlplane"
    }
}

# Create the Kubernetes worker
resource "aws_instance" "worker" {
    ami = local.ami_id

    instance_type = var.aws_instance_type
    
    subnet_id = aws_subnet.kubernetes.id
    user_data_base64 = local.user_data

    vpc_security_group_ids = ["${aws_security_group.kubernetes.id}"]
    key_name = aws_key_pair.kubernetes.id

    tags = {
        Name = "jfernandezja-k8s-worker"
    }
}

######
# Output public IPs

output "etcd_public_ip" {
    value = aws_instance.etcd.public_dns
}

output "controlplane_public_ip" {
    value = aws_instance.controlplane.public_dns
}

output "worker_public_ip" {
    value = aws_instance.worker.public_dns
}
