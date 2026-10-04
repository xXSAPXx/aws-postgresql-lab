

variable "name" {
  description = "Prefix for the Name tag of every VPC resource (use the lab name, e.g. postgresql-single)."
  type        = string
}

variable "vpc_cidr_block" {
  description = "The CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/24"
}

variable "public_subnet_1_cidr" {
  description = "CIDR block for the public subnet (PMM / bastion + NAT Gateway)."
  type        = string
  default     = "10.0.0.0/28"
}

variable "private_subnet_1_cidr" {
  description = "CIDR block for private subnet 1 (availability_zone_1)."
  type        = string
  default     = "10.0.0.32/28"
}


variable "private_subnet_2_cidr" {
  description = "CIDR block for private subnet 2 (availability_zone_2)."
  type        = string
  default     = "10.0.0.48/28"
}

variable "availability_zone_1" {
  description = "Availability zone for the public subnet and private subnet 1."
  type        = string
  default     = "us-east-1a"
}

variable "availability_zone_2" {
  description = "Availability zone for private subnet 2."
  type        = string
  default     = "us-east-1b"
}
