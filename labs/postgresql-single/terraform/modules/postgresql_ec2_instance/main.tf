###################################################################################
# Generate a new base64 encoded userdata script for the PostgreSQL EC2.
# With Added Dynamic Variables if needed.
# This script must be passed to the PostgreSQL EC2 instance.
###################################################################################

locals {
  postgresql_ec2_userdata = templatefile("${path.module}/postgresql_ec2_instance_user_data.tpl", {
    vpc_cidr_block = var.vpc_cidr_block
    repo_url       = var.repo_url
    repo_branch    = var.repo_branch
  })
}


########################################################################
# Security Group for the PostgreSQL Source Instance:
# Private DB: SSH / PostgreSQL / Ping only from inside the VPC.
########################################################################

resource "aws_security_group" "postgresql_ec2_instance_sg" {
  name        = var.sec_group_name
  description = var.sec_group_description
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


########################################################################
# Private PostgreSQL DB:
########################################################################

resource "aws_instance" "postgresql_ec2_instance" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.postgresql_ec2_instance_sg.id]
  key_name               = var.key_name
  user_data              = base64encode(local.postgresql_ec2_userdata)
  #iam_instance_profile  = var.iam_instance_profile

  root_block_device {
    volume_size = var.volume_size
    volume_type = var.volume_type
  }

  tags = {
    Name = var.postgresql_tag_name
  }
}

