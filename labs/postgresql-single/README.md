# Lab: postgresql-single

A single Percona PostgreSQL 17 server in a private subnet, monitored by PMM 3. Use it to practise configuration, query analysis with pg_stat_monitor and PMM, and the basics before the HA labs. pgBackRest and pg_repack are installed.

## What it deploys

- **VPC** `10.0.0.0/24`: one public subnet, two private subnets in two availability zones, and a NAT gateway.
- **postgresql-source**: Percona PostgreSQL 17 with pg_stat_monitor, in private subnet 1. Reachable only from inside the VPC.
- **pmm-server**: PMM 3 (Docker) in the public subnet, also the SSH jump host and the load generator (psql, pgbench). SSH and the PMM UI accept connections only from your `admin_cidr`.

Both servers run Rocky Linux 10 (the newest official image at deploy time): PostgreSQL on a t3.small, the PMM server on a t3.medium because it also generates the load. Change them with `postgresql_instance_type` and `pmm_instance_type` in `terraform.tfvars`; Rocky Linux 10 needs a current type such as t3 or m7i, not t2. For load tests, use a non-burstable type for PostgreSQL such as `m7i.large`: t3 instances are throttled once their CPU credits run out, which looks like a slow database in PMM.

**Cost:** about $0.12 per hour in us-east-1 while the lab runs (NAT gateway $0.045, t3.medium $0.042, t3.small $0.021, two public IPs $0.010, disks $0.003). Always run `terraform destroy` when you're done.

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

## Generate load

The PMM server acts as the application: it sends load to PostgreSQL over the network, like an application server would. `psql` and `pgbench` are installed there, and the `bench` user's password is in `~/.pgpass` (for `rocky` and `root`) for every PostgreSQL server of the lab, so you only name the server:

```bash
ssh pmm-server
pgbench -h postgresql-source -U bench -i -s 20 bench               # create ~300 MB of test data (once)
pgbench -h postgresql-source -U bench -c 8 -j 2 -T 300 -P 10 bench # 8 clients for 5 minutes, progress every 10 s
psql -h postgresql-source -U bench bench                           # SQL shell as the bench user
```

Watch the effect in PMM: **Dashboards → PostgreSQL → PostgreSQL Instance Summary**, and **Query Analytics**.

For a live view on the database server itself, two tools are installed. Run them as the `postgres` OS user:

```bash
ssh postgresql-source
sudo -iu postgres pg_activity    # overview
sudo -iu postgres pg_top         # drill down into one PID
```

- **[pg_activity](https://github.com/dalibo/pg_activity)**: all sessions with their queries, waits and per-process CPU / memory / IO. `F1` / `F2` / `F3` show running / waiting / blocking queries; select a process with the arrow keys and press `C` to cancel or `K` to terminate it. `h` lists all keys.
- **[pg_top](https://pg_top.gitlab.io/)**: press a key, then enter a PID. `Q` shows its full query, `E` its EXPLAIN plan, `L` the locks it holds. `A` runs EXPLAIN ANALYZE, which **executes the statement again**, so never use it on an UPDATE or DELETE.

## Break, fix, reset

Break whatever you like on the servers. Running `ansible-playbook site.yml` again puts everything Ansible manages back into the known-good state: packages, configuration files, the `pmm` user, services and the PMM registration. It changes only what differs. It does not restore data you deleted.

## Tear down

```bash
cd labs/postgresql-single/terraform
terraform destroy
```

This also removes the SSH config and the inventory. The passwords stay in `ansible/credentials/` and are reused on the next deploy.
