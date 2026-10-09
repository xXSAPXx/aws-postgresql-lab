
# Useful values after terraform apply (also written to the SSH config and the Ansible inventory):
########################################################################################################

output "postgresql_ec2_instance_internal_ip" {
  value = module.postgresql_ec2_instance.postgresql_ec2_instance_internal_ip
}

output "pmm_server_public_ip" {
  value = module.pmm_server.pmm_server_public_ip
}

output "pmm_server_private_ip" {
  value = module.pmm_server.pmm_server_private_ip
}

# PMM UI: log in as admin with the password from ../ansible/credentials/pmm_admin_password
output "pmm_url" {
  value = "https://${module.pmm_server.pmm_server_public_ip}"
}
