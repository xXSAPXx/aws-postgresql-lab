###################################################################################
# Generate a new base64 encoded userdata script for the PostgreSQL EC2.
# With Added Dynamic Variables if needed.
# This script must be passed to the PostgreSQL EC2 instance.
###################################################################################

locals {
  postgresql_ec2_userdata = templatefile("${path.module}/postgresql_ec2_instance_user_data.tpl", {
    vpc_cidr_block = var.vpc_cidr_block
  })
}


########################################################################
# Private PostgreSQL DB:
########################################################################

resource "aws_instance" "postgresql_ec2_instance" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [var.postgresql_sec_group_id]
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

