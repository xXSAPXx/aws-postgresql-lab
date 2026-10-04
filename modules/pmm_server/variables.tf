
##########################################
# TERRAFORM VARIABLES
##########################################

variable "extra_hosts" {
  type        = map(string)
  default     = {}
  description = "Extra /etc/hosts entries for the PMM Server as { hostname = private_ip }, e.g. the DB servers it monitors"
}


##########################################
# PMM SECURITY GROUP VARIABLES
##########################################

variable "vpc_id" {
  type        = string
  description = "The ID of the VPC where the security group will be created"
}

variable "vpc_cidr_block" {
  type        = string
  description = "VPC CIDR: PMM Clients inside the VPC connect to the PMM Server on 443"
}

variable "admin_cidr" {
  type        = string
  description = "Your public IP in CIDR form. Only this range can reach SSH and the PMM UI"
}

variable "sec_group_name" {
  description = "Name for the PMM Server Security Group"
  type        = string
  default     = "PMM_Server_SG"
}

variable "sec_group_description" {
  description = "Description for the PMM Server Security Group"
  type        = string
  default     = "Allow SSH / PMM Ports"
}


##########################################
# PMM EC2 INSTANCE VARIABLES
##########################################

variable "ami_id" {
  description = "AMI ID to launch the EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type (PMM needs at least 2 GB RAM)"
  type        = string
  default     = "t2.small"
}

variable "subnet_id" {
  description = "Public Subnet ID to launch the EC2 instance in"
  type        = string
}

variable "key_name" {
  description = "Key pair name for SSH access"
  type        = string
}

#variable "iam_instance_profile" {
#  description = "IAM Role for the Prometheus Automatic Service Discovery"
#  type        = string
#}

variable "volume_size" {
  description = "EBS Volume GBs Size"
  type        = number
  default     = 10
}

variable "volume_type" {
  description = "EBS Volume Type"
  type        = string
  default     = "gp2"
}

variable "pmm_tag_name" {
  description = "Tags to apply to the EC2 instance"
  type        = string
  default     = "pmm-server"
}
