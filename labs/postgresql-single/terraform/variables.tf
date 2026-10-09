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

# Instance types: t2/t3 are burstable. Under sustained load they run out of CPU credits and are throttled
# (t2.small: 20% of a vCPU), which shows up in PMM as a slow database. For load tests use a non-burstable
# type, e.g. m7i.large (2 vCPU, 8 GB).
variable "postgresql_instance_type" {
  type        = string
  default     = "t2.small"
  description = "EC2 instance type of the PostgreSQL server"
}

variable "pmm_instance_type" {
  type        = string
  default     = "t2.small"
  description = "EC2 instance type of the PMM server (PMM needs at least 2 GB RAM)"
}

variable "ssh_private_key_path" {
  type        = string
  default     = null
  description = "Path to the key pair's private key, written into ~/.ssh/aws-postgresql-lab.conf. Leave unset to use ssh-agent / your default keys."
}
