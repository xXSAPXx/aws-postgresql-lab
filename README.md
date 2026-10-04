# aws-postgresql-lab

Hands-on database labs on AWS that simulate a production environment. Each lab is deployed with Terraform, put under load, broken and fixed like a real incident, then torn down so you only pay for the hours you use.

## How a lab works

1. **Deploy:** `terraform apply` builds the network, the database servers and monitoring (PMM).
2. **Load:** generate test traffic so the database is under stress.
3. **Break / fix:** kill nodes, fill disks, restore from backup, and watch it all in PMM.
4. **Tear down:** `terraform destroy` removes everything.

## Labs

| Lab | What it deploys | Status |
|---|---|---|
| [postgresql-single](labs/postgresql-single/) | Percona PostgreSQL 17 + PMM 3 | Available |
| postgresql-patroni | Patroni HA cluster with etcd, pgBackRest backups to S3 | Planned |
| pxc | Percona XtraDB Cluster | Planned |
| mongodb-replicaset | MongoDB replica set | Planned |

## Repository layout

```
modules/              Shared Terraform modules, used by every lab
  vpc/                VPC, public + private subnets, NAT gateway, routing
  pmm_server/         PMM 3 server, also the SSH bastion host
  iam_roles/          (placeholder)
  s3_for_backups/     (placeholder)
labs/<lab>/
  terraform/          The lab's Terraform root, with its own state file
  scripts/            Scripts copied to /opt on the lab's servers
```

## Before your first lab

- An AWS account and the AWS CLI configured with credentials.
- Terraform 1.10 or newer.
- An EC2 key pair in `us-east-1`.
- An S3 bucket for Terraform state (one-time setup):
  ```bash
  aws s3api create-bucket --bucket <your-bucket> --region us-east-1
  aws s3api put-bucket-versioning --bucket <your-bucket> --versioning-configuration Status=Enabled
  ```
  Then initialize each lab with `terraform init -backend-config="bucket=<your-bucket>"`.

## Cost

Labs are meant to run for a few hours and then be destroyed. Always run `terraform destroy` when you finish: the NAT gateway alone costs about $1 a day if left running. Every resource is tagged with `Lab = <lab name>`, so you can find leftovers and track spend per lab.

## Proposed Architecture
<img width="550" alt="PG_infra" src="https://github.com/user-attachments/assets/f33a2212-26e5-40c1-a6e1-b06265be7d83" />
