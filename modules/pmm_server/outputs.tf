# Public IP of the PMM EC2 Instance (PMM UI + SSH bastion):
output "pmm_server_public_ip" {
  value = aws_instance.pmm_server.public_ip
}

# Private IP of the PMM EC2 Instance (used by PMM Clients inside the VPC):
output "pmm_server_private_ip" {
  value = aws_instance.pmm_server.private_ip
}

# Security Group of the PMM Server (lets DB security groups allow traffic from PMM only):
output "pmm_server_security_group_id" {
  value = aws_security_group.pmm_server_sg.id
}
