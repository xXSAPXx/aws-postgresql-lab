# Lab: postgresql-single

A single Percona PostgreSQL 17 server in a private subnet, monitored by PMM 3. Use it to practise configuration, query analysis with pg_stat_monitor and PMM, and the basics before the HA labs. pgBackRest and pg_repack are installed.

## What it deploys

- **VPC** `10.0.0.0/24`: one public subnet, two private subnets in two availability zones, and a NAT gateway.
- **postgresql-source**: Percona PostgreSQL 17 with pg_stat_monitor, in private subnet 1. Reachable only from inside the VPC.
- **pmm-server**: PMM 3 (Docker) in the public subnet, also the SSH jump host. SSH and the PMM UI accept connections only from your `admin_cidr`.

Both servers run Rocky Linux 10 (the newest official image at deploy time), on t3.small instances by default. Change them with `postgresql_instance_type` and `pmm_instance_type` in `terraform.tfvars`; Rocky Linux 10 needs a current type such as t3 or m7i, not t2. For load tests, use a non-burstable type such as `m7i.large`: t3 instances are throttled once their CPU credits run out, which looks like a slow database in PMM.

**Cost:** about $0.10 per hour in us-east-1 while the lab runs (NAT gateway $0.045, two t3.small $0.042, two public IPs $0.010, disks $0.003). Always run `terraform destroy` when you're done.

Terraform (`terraform/`) builds the infrastructure. Ansible (`ansible/`) installs and configures everything on the servers; [how the Ansible part works](../../ansible/README.md).

## Before your first deploy

Run all commands from a Linux or macOS shell. On Windows, use Ubuntu on WSL (see the [root README](../../README.md#before-your-first-lab)).

1. Copy `terraform/terraform.tfvars.example` to `terraform/terraform.tfvars` and set `aws_key_pair`, `admin_cidr` and `ssh_private_key_path`.
2. Add this line at the top of `~/.ssh/config`:
   ```
   Include aws-postgresql-lab.conf
   ```

## Deploy

```bash
cd labs/postgresql-single/terraform
terraform init
terraform apply              # about 3 minutes

cd ../ansible
ansible-playbook site.yml    # about 10 minutes on the first run
```

`terraform apply` also writes the SSH config (`~/.ssh/aws-postgresql-lab.conf`) and the Ansible inventory (`ansible/inventory.ini`) with the new IPs. The playbook installs PostgreSQL and PMM, generates the lab passwords into `ansible/credentials/` and registers PostgreSQL in PMM.

## Connect

```bash
ssh pmm-server               # PMM server / jump host
ssh postgresql-source        # PostgreSQL, through the jump host
```

The PMM server only relays the connection (ProxyJump), so your private key never leaves your machine.

PMM UI: the `pmm_url` from `terraform output`. Log in as `admin` with the password from `ansible/credentials/pmm_admin_password`.

## Break, fix, reset

Break whatever you like on the servers. Running `ansible-playbook site.yml` again puts everything Ansible manages back into the known-good state: packages, configuration files, the `pmm` user, services and the PMM registration. It changes only what differs. It does not restore data you deleted.

## Tear down

```bash
cd labs/postgresql-single/terraform
terraform destroy
```

This also removes the SSH config and the inventory. The passwords stay in `ansible/credentials/` and are reused on the next deploy.
