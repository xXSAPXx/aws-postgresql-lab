

###################################################################################
# Create a VPC / 1_Public_Subnet and 2 Private Subnets NAT + Internet_Gateway
###################################################################################

# Create the VPC: 
resource "aws_vpc" "postgresql_vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = var.vpc_name
  }
}


# Create a Public_Subnet:
resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.postgresql_vpc.id
  cidr_block              = var.public_subnet_1_cidr
  availability_zone       = var.availability_zone_1 # Replace with your preferred AZ
  map_public_ip_on_launch = true                    # Enable this to auto-assign public IPs
  tags = {
    Name = "Public_Subnet_PMM_IaC"
  }
}



# Create an internet gateway:
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.postgresql_vpc.id
  tags = {
    Name = "Internet_Gateway_IaC"
  }
}



##################################################################
# Create NAT GATEWAY in the public subnet: 
##################################################################

# NAT Gateway in the public subnet: 
resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id


  # Create the NAT In the Public Subnet: 
  subnet_id  = aws_subnet.public_subnet_1.id
  depends_on = [aws_internet_gateway.igw]
}


##################################################################
# Create 2 private_subnets for the VPC:
##################################################################


# Create a Private_Subnet_1:
resource "aws_subnet" "private_subnet_1" {
  vpc_id                  = aws_vpc.postgresql_vpc.id
  cidr_block              = var.private_subnet_1_cidr # Make sure the CIDR block doesn't overlap with the public subnet
  availability_zone       = var.availability_zone_1   # Same AZ as the first public subnet
  map_public_ip_on_launch = false                     # DO NOT Auto-assign public IPs!
  tags = {
    Name = "Private_Subnet_1_PG_IaC"
  }
}

# Create a Private_Subnet_2:
resource "aws_subnet" "private_subnet_2" {
  vpc_id                  = aws_vpc.postgresql_vpc.id
  cidr_block              = var.private_subnet_2_cidr # Make sure the CIDR block doesn't overlap with the public subnet
  availability_zone       = var.availability_zone_2   # Same AZ as the private and public subnet
  map_public_ip_on_launch = false                     # DO NOT Auto-assign public IPs!
  tags = {
    Name = "Private_Subnet_2_PG_IaC"
  }
}


##############################################################################
# Create Route_Tables for both public and private subnets: 
##############################################################################


############### PUBLIC ROUTING TABLE and SUBNETS: ###############
# All traffic from the public subnet is going to the Internet Gateway: 
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.postgresql_vpc.id

  route {
    cidr_block = "0.0.0.0/0" # Any traffic destined for an address outside the VPC will be directed to the VPC internet gateway
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public_rt_postgresql_IaC"
  }
}

##### PUBLIC SUBNETS: ##### 
# Associate the route table with the public_subnet: 
resource "aws_route_table_association" "public_rt_assoc" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_rt.id
}


############### PRIVATE ROUTING TABLE and SUBNETS: ###############
# All traffic from the private subnets are going to the NAT Gateway: 
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.postgresql_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "private_rt_postgresql_IaC"
  }
}

##### PRIVATE SUBNETS: ##### 
# Associate the route table with the 1st PRIVATE subnet:
resource "aws_route_table_association" "private_rt_assoc" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_rt.id
}

# Associate the route table with the 2nd PRIVATE subnet: 
resource "aws_route_table_association" "private_rt_assoc_2" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_rt.id
}


