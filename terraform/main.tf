provider "aws" {
  region = var.aws_region
}

# ============================================
# 获取现有资源
# ============================================

# 获取现有的 VPC
data "aws_vpc" "existing" {
  id = var.vpc_id
}

# 获取现有的公有子网
data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
  tags = {
    Type = "public"
  }
}

# 获取公有子网详细信息
data "aws_subnet" "public" {
  for_each = toset(data.aws_subnets.public.ids)
  id       = each.value
}

# 获取现有的私有子网
data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
  tags = {
    Type = "private"
  }
}

# 获取私有子网详细信息
data "aws_subnet" "private" {
  for_each = toset(data.aws_subnets.private.ids)
  id       = each.value
}

# 获取最新的 Ubuntu 24.04 LTS AMI
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

# ============================================
# 安全组（允许所有 IP 访问 SSH）
# ============================================

resource "aws_security_group" "ec2" {
  name        = "${var.instance_name}-sg"
  description = "Security group for EC2 instance - allows SSH from anywhere"
  vpc_id      = var.vpc_id

  # SSH 访问（允许所有 IP）
  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 允许所有出站流量
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

# ============================================
# SSH 密钥对
# ============================================

resource "aws_key_pair" "my_key" {
  key_name   = var.key_name
  public_key = var.public_key
  
  tags = {
    Name        = var.key_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# ============================================
# EC2 实例
# ============================================

locals {
  # 使用第一个公有子网（EC2 需要公网 IP）
  public_subnet_list  = [for id, subnet in data.aws_subnet.public : subnet.id]
  private_subnet_list = [for id, subnet in data.aws_subnet.private : subnet.id]
  
  # 修正：使用 try 函数避免跨行三元运算符错误
  selected_subnet_id = var.use_public_subnet ? try(local.public_subnet_list[0], null) : try(local.private_subnet_list[0], null)
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

# ============================================
# 弹性 IP（可选，用于固定公网 IP）
# ============================================

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