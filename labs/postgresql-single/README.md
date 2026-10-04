# Lab: postgresql-single

A single Percona PostgreSQL 17 server in a private subnet, monitored by PMM 3. Use it to practise configuration, query analysis with pg_stat_monitor and PMM, and the basics before the HA labs. pgBackRest and pg_repack are installed.

## What it deploys

- **VPC** `10.0.0.0/24`: one public subnet, two private subnets in two availability zones, and a NAT gateway.
- **postgresql-source**: Percona PostgreSQL 17 in private subnet 1. Reachable only from inside the VPC.
- **pmm-server**: PMM 3 in the public subnet, also the SSH bastion. SSH and the PMM UI accept connections only from your `admin_cidr`.

## Deploy

```bash
cd labs/postgresql-single/terraform
cp terraform.tfvars.example terraform.tfvars   # set aws_key_pair and admin_cidr
terraform init
terraform apply
```

The servers finish installing about 5 minutes after `apply` completes. The install log on each server is `/var/log/cloud-init-output.log`.

## Connect

The PMM server is the SSH jump host (ProxyJump, `ssh -J`). It only relays the connection, so your private key never leaves your machine. Terraform generates the SSH config for you.

**One-time setup**

1. Set `ssh_private_key_path` in `terraform.tfvars`, or load the key into ssh-agent instead. Key setup on Windows: [modules/pmm_server/README.md](../../modules/pmm_server/README.md).
2. Add this line at the top of `~/.ssh/config`:
   ```
   Include aws-postgresql-lab.conf
   ```

**After every deploy** (new IPs and host keys), write the config and reset the lab's known_hosts file. From `labs/postgresql-single/terraform`:

Git Bash, Linux, macOS:
```bash
terraform output -raw ssh_config > ~/.ssh/aws-postgresql-lab.conf
rm -f ~/.ssh/aws-postgresql-lab_known_hosts
```

PowerShell (plain `>` writes a BOM or UTF-16, which ssh can't parse):
```powershell
terraform output -raw ssh_config | Set-Content -Encoding ascii $HOME\.ssh\aws-postgresql-lab.conf
Remove-Item $HOME\.ssh\aws-postgresql-lab_known_hosts -ErrorAction SilentlyContinue
```

Then connect:
```bash
ssh pmm-server          # PMM server / jump host
ssh postgresql-source   # PostgreSQL, through the jump host
```

The same host names work with `scp` and VS Code Remote-SSH.

PMM UI: `https://<pmm_server_public_ip>`. The default login is `admin` / `admin`; change it on first login.

## Register PostgreSQL in PMM

On `postgresql-source`:

```bash
PMM_DB_PASSWORD='<choose-a-password>' /opt/pmm_installation.sh <pmm_server_private_ip>
```

This installs pg_stat_monitor and the PMM client, creates the `pmm` monitoring user and registers the server with PMM. It is safe to re-run. If you changed the PMM admin password, also pass `PMM_ADMIN_PASSWORD='<password>'`.

## Tear down

```bash
terraform destroy
```

## Testing script changes from a branch

On boot, the PostgreSQL server clones this repo and copies `labs/postgresql-single/scripts/` to `/opt`. To test changes before merging, push your branch and set `repo_branch = "<branch>"` in `terraform.tfvars`.
