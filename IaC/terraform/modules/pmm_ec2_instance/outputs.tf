# Public IP of the PMM EC2 Instance: 
output "pmm_ec2_instance_public_ip" {
  value = aws_instance.pmm_ec2_instance.public_ip
}

# Private IP of the PMM EC2 Instance (used by PMM Clients inside the VPC):
output "pmm_ec2_instance_private_ip" {
  value = aws_instance.pmm_ec2_instance.private_ip
}
