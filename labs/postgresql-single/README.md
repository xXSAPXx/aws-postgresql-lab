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

Add your key to the SSH agent (`ssh-add <path-to-key>`), then use the PMM server as a jump host:

```bash
ssh ec2-user@<pmm_server_public_ip>                                            # PMM / bastion
ssh -J ec2-user@<pmm_server_public_ip> ec2-user@<postgresql_ec2_instance_internal_ip>  # PostgreSQL
```

PMM UI: `https://<pmm_server_public_ip>`. The default login is `admin` / `admin`; change it on first login.

Windows key setup notes: [modules/pmm_server/README.md](../../modules/pmm_server/README.md).

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
