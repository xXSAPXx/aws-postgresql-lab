###################################################################################
# PostgreSQL EC2 instance + its security group.
# The server is configured by Ansible (../ansible), not by user_data.
###################################################################################


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
  #iam_instance_profile  = var.iam_instance_profile

  root_block_device {
    volume_size = var.volume_size
    volume_type = var.volume_type
  }

  tags = {
    Name = var.postgresql_tag_name
  }

  # A newer image (e.g. from an "always the latest" AMI lookup) must not replace a running server:
  lifecycle {
    ignore_changes = [ami]
  }
}

