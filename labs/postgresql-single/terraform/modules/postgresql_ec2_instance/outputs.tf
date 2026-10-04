# Private IP of the PostgreSQL EC2 Instance:
output "postgresql_ec2_instance_internal_ip" {
  value = aws_instance.postgresql_ec2_instance.private_ip
}

# Security Group of the PostgreSQL EC2 Instance:
output "postgresql_ec2_instance_security_group_id" {
  value = aws_security_group.postgresql_ec2_instance_sg.id
}

