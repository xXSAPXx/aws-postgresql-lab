# Written by terraform apply (lab: postgresql-single). Rewritten on every apply, do not edit.
# The PMM server is the jump host (ProxyJump): it only relays the connection, your key stays on your machine.

Host pmm-server
    HostName ${pmm_server_public_ip}
    User ${ssh_user}
%{ if ssh_private_key_path != null ~}
    IdentityFile "${ssh_private_key_path}"
%{ endif ~}
    UserKnownHostsFile ~/.ssh/aws-postgresql-lab_known_hosts
    StrictHostKeyChecking accept-new

Host postgresql-source
    HostName ${postgresql_internal_ip}
    User ${ssh_user}
%{ if ssh_private_key_path != null ~}
    IdentityFile "${ssh_private_key_path}"
%{ endif ~}
    UserKnownHostsFile ~/.ssh/aws-postgresql-lab_known_hosts
    StrictHostKeyChecking accept-new
    ProxyJump pmm-server
