
output "postgresql_ec2_instance_security_group_id" {
  description = "The ID of the PostgreSQL Instance Security group"
  value       = aws_security_group.postgresql_ec2_instance_sg.id
}

output "pmm_ec2_instance_security_group_id" {
  description = "The ID of the PMM Instance Security group"
  value       = aws_security_group.pmm_ec2_instance_sg.id
}