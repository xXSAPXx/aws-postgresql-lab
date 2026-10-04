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

# Repo with this lab's scripts, cloned by the PostgreSQL server on boot:
variable "repo_url" {
  type        = string
  default     = "https://github.com/xXSAPXx/PostgreSQL_Playground.git"
  description = "Git repo the PostgreSQL server clones on boot to copy the lab scripts to /opt"
}

variable "repo_branch" {
  type        = string
  default     = "main"
  description = "Branch to clone. Set it to your pushed feature branch to test script changes before merging."
}