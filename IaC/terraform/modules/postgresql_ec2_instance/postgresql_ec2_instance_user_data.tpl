#!/bin/bash


##################################################################
# Hostname and /etc/hosts configuration: 
##################################################################

# Note: cloud-init already runs user_data as root.

# Set hostname:
HOSTNAME="postgresql-source"
sudo hostnamectl set-hostname "$HOSTNAME"

# Update /etc/hosts file: 
sudo bash -c "cat <<EOF > /etc/hosts
127.0.0.1   localhost $HOSTNAME
EOF"


##################################################################
# User Data Script for Percona PostgreSQL Installation: 
##################################################################

# Variables:
PG_CONF="/var/lib/pgsql/17/data/postgresql.conf"
PG_HBA="/var/lib/pgsql/17/data/pg_hba.conf"

# Install / Update package lists:
#sudo dnf update -y
sudo dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
sudo dnf -y install curl
sudo dnf -y install bash-completion
sudo dnf -y install bat
sudo dnf -y install bind-utils
sudo dnf -y install btop
sudo dnf -y install iotop
sudo dnf -y install telnet
sudo dnf -y install vim
sudo dnf -y install git


# Install Percona PostgreSQL version 17:
sudo dnf -y module disable postgresql

# Configure Percona PG Repo: 
sudo dnf -y install https://repo.percona.com/yum/percona-release-latest.noarch.rpm

# Enable the Percona PostgreSQL 17 repository: 
sudo percona-release setup ppg17

# Install Percona PostgreSQL server / pgbackrest and other useful extensions: 
sudo dnf -y install percona-postgresql17-server
sudo dnf -y install percona-pgbackrest
sudo dnf -y install percona-pg_repack17

# Initialize PostgreSQL database
/usr/pgsql-17/bin/postgresql-17-setup initdb

# Set PostgreSQL to listen on all interfaces (before the first start, so no restart is needed):
sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" $PG_CONF

# Allow remote connections from inside the VPC with password (scram-sha-256) auth by modifying pg_hba.conf:
echo "host    all             all             ${vpc_cidr_block}             scram-sha-256" | sudo tee -a $PG_HBA

# Enable and start PostgreSQL service
sudo systemctl enable postgresql-17
sudo systemctl start postgresql-17

# Give postgres user sudo privileges: 
echo "postgres ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/postgres



##################################################################
# Download and copy scripts from GitHub repo:
##################################################################

# Create dir for the repo:
sudo mkdir -p /tmp/repo

# Download GitHub repo to /tmp directory 
sudo git clone https://github.com/xXSAPXx/PostgreSQL_Playground.git /tmp/repo

# Copy all scripts to /opt/ directory
sudo cp -r /tmp/repo/Scripts/* /opt/

# Set execute permissions for all scripts in /opt/ directory:
sudo chmod +x /opt/*.sh