provider "aws" {
  region = var.aws_region
}

# get the public subnets ID list 
data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
  tags = {
    Type = "public"
  }
}

# Iterate through the list of IDs to obtain detailed information for each subnet
data "aws_subnet" "public" {
  for_each = toset(data.aws_subnets.public.ids)
  id       = each.value
}

# get the current private subnets ID list
data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
  tags = {
    Type = "private"
  }
}

# lterate through the list of IDs to obtain detailed information for each subnet
data "aws_subnet" "private" {
  for_each = toset(data.aws_subnets.private.ids)
  id       = each.value
}

# get the latest ubuntu version
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


# setup the security group
resource "aws_security_group" "ec2" {
  name        = "${var.instance_name}-sg"
  description = "Security group for EC2 instance - allows SSH from anywhere"
  vpc_id      = var.vpc_id

  # ssh allow all IPs
  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.instance_name}-sg"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
# ssh keys
resource "aws_key_pair" "my_key" {
  key_name   = var.key_name
  public_key = var.public_key
  
  tags = {
    Name        = var.key_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# ec2 instance
locals {
  # get the subnets list
  public_subnet_ids  = [for id, subnet in data.aws_subnet.public : subnet.id]
  private_subnet_ids = [for id, subnet in data.aws_subnet.private : subnet.id]
  
  # use the first public subnet and first private subnet 
  selected_subnet_id = var.use_public_subnet ? public_subnet_ids[0] : private_subnet_ids[0]
}

resource "aws_instance" "ubuntu" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = local.selected_subnet_id
  vpc_security_group_ids      = [aws_security_group.ec2.id]
  key_name                    = aws_key_pair.my_key.key_name
  associate_public_ip_address = var.use_public_subnet

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = "gp3"
    encrypted   = true
    tags = {
      Name = "${var.instance_name}-root-volume"
    }
  }

  tags = {
    Name        = var.instance_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }

  user_data = var.user_data
}
# use the EIP like bind a public IP 
resource "aws_eip" "ec2" {
  count    = var.assign_eip && var.use_public_subnet ? 1 : 0
  instance = aws_instance.ubuntu.id
  domain   = "vpc"

  tags = {
    Name        = "${var.instance_name}-eip"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}