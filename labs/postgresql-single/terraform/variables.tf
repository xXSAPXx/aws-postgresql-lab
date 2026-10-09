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

variable "ssh_private_key_path" {
  type        = string
  default     = null
  description = "Path to the key pair's private key, written into ~/.ssh/aws-postgresql-lab.conf. Leave unset to use ssh-agent / your default keys."
}
