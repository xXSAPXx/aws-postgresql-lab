
##########################################
# POSTGRESQL SECURITY GROUP VARIABLES
##########################################

variable "vpc_id" {
  type        = string
  description = "The ID of the VPC where the security group will be created"
}

variable "vpc_cidr_block" {
  type        = string
  description = "VPC CIDR allowed to reach the instance (SSH / PostgreSQL / ping)"
}

variable "sec_group_name" {
  description = "Name for the PostgreSQL Instance Security Group"
  type        = string
  default     = "PostgreSQL_EC2_Instance_SG"
}

variable "sec_group_description" {
  description = "Description for the PostgreSQL Instance Security Group"
  type        = string
  default     = "Allow SSH / PMM and PostgreSQL Ports"
}


##########################################
# POSTGRESQL EC2 INSTANCE VARIABLES
##########################################

variable "ami_id" {
  description = "AMI ID to launch the EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.small"
}

variable "subnet_id" {
  description = "Subnet ID to launch the EC2 instance in"
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

variable "postgresql_tag_name" {
  description = "Tags to apply to the EC2 instance"
  type        = string
  default     = "postgresql-source"
}
