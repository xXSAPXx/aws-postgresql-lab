###################################################################################
# PMM Server EC2 instance + its security group.
# PMM itself is installed by Ansible (ansible/roles/pmm_server), not by user_data.
###################################################################################


########################################################################
# Security Group for the PMM Server:
########################################################################

resource "aws_security_group" "pmm_server_sg" {
  name        = var.sec_group_name
  description = var.sec_group_description
  vpc_id      = var.vpc_id

  # SSH (jump host) from your IP:
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
# Public EC2 - PMM + SSH jump host + DB Traffic Generator Server:
########################################################################

resource "aws_instance" "pmm_server" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.pmm_server_sg.id]
  key_name               = var.key_name

  root_block_device {
    volume_size = var.volume_size
    volume_type = var.volume_type
  }

  tags = {
    Name = var.pmm_tag_name
  }
}

