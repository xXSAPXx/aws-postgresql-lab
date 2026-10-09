

####################################################################################################################################
######################################## LAB: postgresql-single ####################################################################
# Single Percona PostgreSQL 17 server (private subnet) monitored by PMM 3 (public subnet, also the SSH jump host).
# Terraform builds the infrastructure, Ansible (../ansible) configures the servers.
# Shared modules live in ../../../modules, lab-specific modules in ./modules.


# Networking:
# Create VPC / Subnets / Nat_Gateway / Routing / Internet_Gateway
######################################################################################

module "vpc" {
  source = "../../../modules/vpc"

  # --- General VPC Settings ---
  name           = "postgresql-single"
  vpc_cidr_block = "10.0.0.0/24"

  # --- Availability Zone Settings ---
  availability_zone_1 = "us-east-1a"
  availability_zone_2 = "us-east-1b"


  # --- Subnet CIDR Block Settings ---
  public_subnet_1_cidr  = "10.0.0.0/28"
  private_subnet_1_cidr = "10.0.0.32/28"
  private_subnet_2_cidr = "10.0.0.48/28"

}


# Create the EC2: (PostgreSQL Database)
######################################################################################
module "postgresql_ec2_instance" {
  source = "./modules/postgresql_ec2_instance"

  # --- PostgreSQL_EC2_Instance Sec_Group Settings ---
  vpc_id                = module.vpc.vpc_id
  vpc_cidr_block        = module.vpc.vpc_cidr_block
  sec_group_name        = "PostgreSQL_EC2_Instance_SG"
  sec_group_description = "Allow SSH / PMM and PostgreSQL Ports"

  # --- PostgreSQL_EC2_Instance Settings ---
  ami_id        = "ami-0583d8c7a9c35822c"
  instance_type = "t2.small"
  key_name      = var.aws_key_pair
  subnet_id     = module.vpc.private_subnet_1_id
  #iam_instance_profile   = module.iam_roles............
  postgresql_tag_name = "postgresql-source"

  # EBS Volume Settings:
  volume_size = 10
  volume_type = "gp2"
}


# Create the EC2: (PMM Server + SSH jump host)
######################################################################################
module "pmm_server" {
  source = "../../../modules/pmm_server"

  # --- PMM_EC2_Instance Sec_Group Settings ---
  vpc_id                = module.vpc.vpc_id
  vpc_cidr_block        = module.vpc.vpc_cidr_block
  admin_cidr            = var.admin_cidr # Only your IP can reach SSH and the PMM UI.
  sec_group_name        = "PMM_Server_SG"
  sec_group_description = "Allow SSH / PMM Ports"

  # --- PMM_EC2_Instance Settings ---
  ami_id        = "ami-0583d8c7a9c35822c"
  instance_type = "t2.small"
  key_name      = var.aws_key_pair
  subnet_id     = module.vpc.public_subnet_1_id
  #iam_instance_profile         = module.iam_roles............
  pmm_tag_name = "pmm-server"

  # EBS Volume Settings:
  volume_size = 10
  volume_type = "gp2"
}
