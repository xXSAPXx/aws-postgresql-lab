
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

# SSH config with the PMM server as jump host (README: Connect):
#   terraform output -raw ssh_config > ~/.ssh/aws-postgresql-lab.conf
output "ssh_config" {
  value = templatefile("${path.module}/ssh_config.tpl", {
    pmm_server_public_ip   = module.pmm_server.pmm_server_public_ip
    postgresql_internal_ip = module.postgresql_ec2_instance.postgresql_ec2_instance_internal_ip
    ssh_private_key_path   = var.ssh_private_key_path
  })
}
