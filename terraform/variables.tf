variable "aws_profile" {
  type 	      = string
  description = "AWS authentication profile"
}

variable "aws_region" {
  type        = string
  description = "AWS region used for all resources"
}

variable "ssh_public_key" {
  type        = string
  description = "SSH Public Key"
}

variable "aws_instance_type" {
  type        = string
  description = "AWS Instance type"
  default     = "t2.micro"
}

variable "vpc_cidr_block" {
  type        = string
  description = "VPC CIDR Block"
  default     = "172.35.0.0/16"
}

locals {
  node_username = "ubuntu"
  ami_id = "ami-0701e7be9b2a77600"
  user_data = "IyEvYmluL2Jhc2gKc3VkbyBhcHQgdXBkYXRlCnN1ZG8gYXB0IGluc3RhbGwgLXkgZG9ja2VyLmlvCnN1ZG8gdXNlcm1vZCAtYUcgZG9ja2VyIHVidW50dQoK"
}
