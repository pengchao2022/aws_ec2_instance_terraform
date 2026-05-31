output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.ubuntu.id
}

output "instance_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = var.use_public_subnet ? aws_instance.ubuntu.public_ip : null
}

output "instance_private_ip" {
  description = "Private IP of the EC2 instance"
  value       = aws_instance.ubuntu.private_ip
}

output "elastic_ip" {
  description = "Elastic IP address (if assigned)"
  value       = var.assign_eip && var.use_public_subnet ? aws_eip.ec2[0].public_ip : null
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = var.use_public_subnet ? "ssh -i ~/.ssh/id_rsa ubuntu@${aws_instance.ubuntu.public_ip}" : "ssh -i ~/.ssh/id_rsa ubuntu@${aws_instance.ubuntu.private_ip} (需要 bastion 主机)"
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.ec2.id
}

output "ami_id" {
  description = "AMI ID used for the instance"
  value       = data.aws_ami.ubuntu.id
}

output "availability_zone" {
  description = "Availability zone of the instance"
  value       = aws_instance.ubuntu.availability_zone
}

output "subnet_id" {
  description = "Subnet ID where the instance is deployed"
  value       = aws_instance.ubuntu.subnet_id
}