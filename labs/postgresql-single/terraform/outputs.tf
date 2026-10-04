
# Print all dynamic variables passed to specified modules after terraform deployment:
# Useful for debugging purposes.
# This ensures the modules received the correct env variables.
########################################################################################################

output "postgresql_ec2_instance_internal_ip" {
  value = module.postgresql_ec2_instance.postgresql_ec2_instance_internal_ip
}

# PMM UI (https://<ip>) + SSH bastion:
output "pmm_server_public_ip" {
  value = module.pmm_server.pmm_server_public_ip
}

# Pass this IP to /opt/pmm_installation.sh on the PostgreSQL server:
output "pmm_server_private_ip" {
  value = module.pmm_server.pmm_server_private_ip
}
