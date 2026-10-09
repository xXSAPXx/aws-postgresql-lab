# PMM Server module

EC2 instance and security group for the PMM 3 server, in the lab's public subnet. PMM itself is installed by Ansible ([ansible/roles/pmm_server](../../ansible/roles/pmm_server)).

The PMM server is also the SSH jump host for the lab's private servers: it only relays SSH connections (ProxyJump, `ssh -J`), so your private key stays on your machine. Each lab writes an SSH config for you on `terraform apply`; see the lab README, for example [postgresql-single](../../labs/postgresql-single/README.md#connect).


##### PREPARE THE SSH KEY #####

 1) HAVE THE PRIVATE SSH KEY of the EC2 key pair (the `.pem` file from AWS, or a PuTTY `.ppk`).

 2) CONVERT TO OpenSSH FORMAT (only for `.ppk`): in PuTTYgen, *Load* the `.ppk`, then *Conversions → Export OpenSSH key*. On Linux: `puttygen key.ppk -O private-openssh -o key`. A `.pem` is already in OpenSSH format.

 3) PUT THE KEY IN `~/.ssh` WITH STRICT PERMISSIONS. ssh refuses a key that other users can read:

```bash
cp <your-key> ~/.ssh/ && chmod 600 ~/.ssh/<your-key>
# Windows (Ubuntu on WSL): copy it from the Windows drive, e.g.
cp /mnt/c/Users/<you>/Downloads/<your-key> ~/.ssh/ && chmod 600 ~/.ssh/<your-key>
```

 4) SET `ssh_private_key_path = "~/.ssh/<your-key>"` in the lab's `terraform.tfvars`.


##### CONNECT THROUGH THE JUMP HOST (ProxyJump) #####

Use the SSH config written by the lab (`ssh pmm-server`, `ssh postgresql-source`).

Without that config, load the key into ssh-agent first. With `-J`, a `-i` on the command line applies only to the final host, so the jump host needs the key from the agent:

```bash
eval "$(ssh-agent -s)" && ssh-add ~/.ssh/<your-key>

ssh rocky@<pmm_server_public_ip>                                    # PMM server (Rocky Linux user)
ssh -J rocky@<pmm_server_public_ip> rocky@<private_ip>              # private server, through the PMM server
```

Don't use `ssh -A` (agent forwarding): while you're connected, anyone with root on the PMM server could use your agent to log in with your key.
