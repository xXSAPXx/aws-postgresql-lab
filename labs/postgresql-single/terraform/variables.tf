# AWS Variables:
variable "aws_key_pair" {
  type        = string
  sensitive   = true
  description = "SSH KeyPair for the EC2 instances"
}

variable "admin_cidr" {
  type        = string
  description = "Your public IP in CIDR form (e.g. 203.0.113.10/32). Only this range can reach SSH and the PMM UI."

  validation {
    condition     = can(cidrhost(var.admin_cidr, 0))
    error_message = "admin_cidr must be a valid CIDR block, e.g. 203.0.113.10/32."
  }
}

# Instance types: Rocky Linux 10 needs x86-64-v3 CPUs, so use a current (Nitro) type such as t3 or m7i, not t2.
# t3 is burstable: under sustained load it runs out of CPU credits and is throttled to 20% of each vCPU,
# which shows up in PMM as a slow database. For load tests use a non-burstable type, e.g. m7i.large (2 vCPU, 8 GB).
variable "postgresql_instance_type" {
  type        = string
  default     = "t3.small"
  description = "EC2 instance type of the PostgreSQL server"

  validation {
    condition     = !startswith(var.postgresql_instance_type, "t2.")
    error_message = "Rocky Linux 10 needs a current instance type (t3, m7i, ...), not t2."
  }
}

variable "pmm_instance_type" {
  type        = string
  default     = "t3.medium"
  description = "EC2 instance type of the PMM server, which is also the load generator (PMM alone needs at least 2 GB RAM)"

  validation {
    condition     = !startswith(var.pmm_instance_type, "t2.")
    error_message = "Rocky Linux 10 needs a current instance type (t3, m7i, ...), not t2."
  }
}

variable "ssh_private_key_path" {
  type        = string
  default     = null
  description = "Path to the key pair's private key, written into ~/.ssh/aws-postgresql-lab.conf. Leave unset to use ssh-agent / your default keys."
}
