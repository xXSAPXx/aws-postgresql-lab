###################################################################################
# Generate a new base64 encoded userdata script for the PMM EC2.
# With Added Dynamic Variables if needed.
# This script must be passed to the PMM EC2 instance.
###################################################################################

locals {
  pmm_server_userdata = templatefile("${path.module}/pmm_server_user_data.tpl", {
    extra_hosts = var.extra_hosts
  })
}


########################################################################
# Security Group for the PMM Server:
########################################################################

resource "aws_security_group" "pmm_server_sg" {
  name        = var.sec_group_name
  description = var.sec_group_description
  vpc_id      = var.vpc_id

  # SSH (bastion) from your IP:
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr]
  }

  # PMM UI (HTTP) from your IP:
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = distinct([var.admin_cidr, var.vpc_cidr_block]) # PMM UI from outside + PMM Clients inside the VPC.
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = distinct([var.admin_cidr, var.vpc_cidr_block]) # Ping from outside and inside the VPC.
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


########################################################################
# Public EC2 - PMM + Bastion Host + DB Traffic Generator Server:
########################################################################

resource "aws_instance" "pmm_server" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.pmm_server_sg.id]
  key_name               = var.key_name
  user_data              = base64encode(local.pmm_server_userdata)

  root_block_device {
    volume_size = var.volume_size
    volume_type = var.volume_type
  }

  tags = {
    Name = var.pmm_tag_name
  }
}

