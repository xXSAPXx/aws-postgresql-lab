

####################################################################################################################################
######################################## AWS PROVIDER VARIABLES ####################################################################

# AWS provider region: 
provider "aws" {
  region = "us-east-1" # Or use a variable if you prefer
}


# Networking: 
# Crate VPC / Subnets / Nat_Gateway / Routing / Internet_Gateway
######################################################################################

module "vpc" {
  source = "./modules/vpc"

  # --- General VPC Settings ---
  vpc_name              = "PostgreSQL_Playground_VPC_IaC"
  vpc_cidr_block        = "10.0.0.0/24"
  internet_gateway_name = "Internet_Gateway_PostgreSQL_Playground_IaC"

  # --- Availability Zone Settings ---
  availability_zone_1 = "us-east-1a"
  availability_zone_2 = "us-east-1b"


  # --- Subnet CIDR Block Settings ---
  public_subnet_1_cidr  = "10.0.0.0/28"
  private_subnet_1_cidr = "10.0.0.32/28"
  private_subnet_2_cidr = "10.0.0.48/28"

}


# Create ALL Security Groups: 
######################################################################################

module "security_groups" {
  source = "./modules/security_groups"

  # For all SGs:
  vpc_id         = module.vpc.vpc_id
  vpc_cidr_block = module.vpc.vpc_cidr_block # Used for ICMP (Ping) from inside the VPC.

  # --- PostgreSQL_EC2_Instance Sec_Group Settings ---
  postgresql_ec2_instance_cidr_block = module.vpc.vpc_cidr_block # Private DB: reachable only from inside the VPC.
  sec_group_name                     = "PostgreSQL_EC2_Instance_SG"
  sec_group_description              = "Allow SSH / PMM and PostgreSQL Ports"

  # --- PMM_EC2_Instance Sec_Group Settings ---
  pmm_ec2_instance_cidr_block = var.admin_cidr # Only your IP can reach SSH and the PMM UI.
  pmm_sec_group_name          = "PMM_EC2_Instance_SG"
  pmm_sec_group_description   = "Allow SSH / PMM Ports"

}


# Create the EC2: (PostgreSQL Database)
######################################################################################
module "postgresql_ec2_instance" {
  source = "./modules/postgresql_ec2_instance"

  # Wait for the whole VPC (NAT Gateway + routes) so the user_data script has internet access on boot:
  depends_on = [module.vpc]

  # --- Pass Dynamic Variables to PostgreSQL EC2 Script ---
  vpc_cidr_block = module.vpc.vpc_cidr_block

  # --- PostgreSQL_EC2_Instance Settings ---
  ami_id                  = "ami-0583d8c7a9c35822c"
  instance_type           = "t2.small"
  key_name                = var.aws_key_pair
  subnet_id               = module.vpc.private_subnet_1_id
  postgresql_sec_group_id = module.security_groups.postgresql_ec2_instance_security_group_id
  #iam_instance_profile   = module.iam_roles............
  postgresql_tag_name = "postgresql-source"

  # EBS Volume Settings:
  volume_size = 10
  volume_type = "gp2"
}


# # Create the EC2: (PMM Server)
######################################################################################
module "pmm_ec2_instance" {
  source = "./modules/pmm_ec2_instance"

  # Wait for the whole VPC (Internet Gateway + routes) so the user_data script has internet access on boot:
  depends_on = [module.vpc]

  # --- Pass Dynamic Variables to PMM EC2 Script ---
  postgresql_internal_ip = module.postgresql_ec2_instance.postgresql_ec2_instance_internal_ip

  # --- PMM_EC2_Instance Settings ---
  ami_id           = "ami-0583d8c7a9c35822c"
  instance_type    = "t2.small"
  key_name         = var.aws_key_pair
  subnet_id        = module.vpc.public_subnet_1_id
  pmm_sec_group_id = module.security_groups.pmm_ec2_instance_security_group_id
  #iam_instance_profile         = module.iam_roles............
  pmm_tag_name = "pmm-server"

  # EBS Volume Settings:
  volume_size = 10
  volume_type = "gp2"
}



# Print all dynamic variables passed to specified modules after terrafrom deployment: 
# Usefull for debuging purposes.
# This ensures the modules received the correct env variables. 
########################################################################################################

output "postgresql_ec2_instance_internal_ip" {
  value = module.postgresql_ec2_instance.postgresql_ec2_instance_internal_ip
}

output "pmm_ec2_instance_public_ip" {
  value = module.pmm_ec2_instance.pmm_ec2_instance_public_ip
}

# Pass this IP to /opt/pmm_installation.sh on the PostgreSQL server:
output "pmm_ec2_instance_private_ip" {
  value = module.pmm_ec2_instance.pmm_ec2_instance_private_ip
}