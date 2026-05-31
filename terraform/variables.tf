variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_id" {
  description = "ID of the existing VPC"
  type        = string
}

variable "instance_name" {
  description = "Name of the EC2 instance"
  type        = string
  default     = "my-ubuntu-server"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "root_volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 20
}

variable "key_name" {
  description = "Name of the SSH key pair in AWS"
  type        = string
  default     = "my-key"
}

variable "public_key" {
  description = "Your SSH public key content"
  type        = string
  sensitive   = true
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "use_public_subnet" {
  description = "Use public subnet (true) or private subnet (false)"
  type        = bool
  default     = true
}

variable "assign_eip" {
  description = "Assign Elastic IP to the instance"
  type        = bool
  default     = false
}

variable "user_data" {
  description = "User data script for EC2 instance"
  type        = string
  default     = <<-EOF
    #!/bin/bash
    apt update
    apt install -y nginx
    systemctl enable nginx
    systemctl start nginx
    echo "Hello from Terraform EC2" > /var/www/html/index.html
  EOF
}