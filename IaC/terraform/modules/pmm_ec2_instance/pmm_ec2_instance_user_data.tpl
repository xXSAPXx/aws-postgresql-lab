#!/bin/bash

##################################################################
# Hostname and /etc/hosts configuration: 
##################################################################

# Note: cloud-init already runs user_data as root.

# Variables from Terraform / # Debug check: 
POSTGRESQL_INTERNAL_IP="${postgresql_internal_ip}"
echo "POSTGRESQL_INTERNAL_IP is: $POSTGRESQL_INTERNAL_IP" > /tmp/debug_env.txt

# Set hostname: 
HOSTNAME="pmm-server"
sudo hostnamectl set-hostname "$HOSTNAME"

# Update /etc/hosts file: 
sudo bash -c "cat <<EOF > /etc/hosts
127.0.0.1   localhost $HOSTNAME
$POSTGRESQL_INTERNAL_IP   postgresql-source
EOF"


# Install / Update package lists:
#sudo dnf update -y
sudo dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
sudo dnf -y install bash-completion
sudo dnf -y install bat
sudo dnf -y install btop
sudo dnf -y install telnet
sudo dnf -y install vim


##################################################################
# User Data Script for PMM Installation: 
##################################################################

# Install Docker and run PMM: 
sudo curl -fsSL https://www.percona.com/get/pmm | /bin/bash

# Enable Docker Service:
sudo systemctl enable docker
sudo systemctl start docker

