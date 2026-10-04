#!/bin/bash

# Exit on error, undefined variable, or error in a pipeline
set -euo pipefail

# Usage (safe to re-run):
#   PMM_DB_PASSWORD='<password>' /opt/pmm_installation.sh <PMM_SERVER_PRIVATE_IP>
#
#   PMM_DB_PASSWORD    - Password for the PostgreSQL 'pmm' monitoring user (required).
#   PMM_ADMIN_PASSWORD - PMM UI admin password (optional, defaults to 'admin'). URL-encode special characters.
#   PMM_SERVER_PRIVATE_IP - From the Terraform output: pmm_ec2_instance_private_ip

# Variables:
PG_CONF="/var/lib/pgsql/17/data/postgresql.conf"
PG_HBA="/var/lib/pgsql/17/data/pg_hba.conf"
PMM_SERVER_IP="${1:-}"
PMM_DB_PASSWORD="${PMM_DB_PASSWORD:-}"
PMM_ADMIN_PASSWORD="${PMM_ADMIN_PASSWORD:-admin}"

# Check if PMM Server IP was passed
if [ -z "$PMM_SERVER_IP" ]; then
    echo "❌ ERROR: PMM server private IP not provided."
    echo "Usage: PMM_DB_PASSWORD='<password>' $0 <PMM_SERVER_PRIVATE_IP>"
    exit 1
fi

# Check if the password for the PostgreSQL 'pmm' user was passed
if [ -z "$PMM_DB_PASSWORD" ]; then
    echo "❌ ERROR: PMM_DB_PASSWORD not set (password for the PostgreSQL 'pmm' monitoring user)."
    echo "Usage: PMM_DB_PASSWORD='<password>' $0 <PMM_SERVER_PRIVATE_IP>"
    exit 1
fi

echo "➡ Registering PMM Client with PMM Server at $PMM_SERVER_IP..."

###############################################################################
# Script for | percona-pg-stat-monitor | Installation:
###############################################################################

# Install PG_stat_monitor package:
sudo dnf -y install percona-pg-stat-monitor17

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Update PostgreSQL configuration file to load the pg_stat_monitor extension:

# 1. Update the shared_preload_libraries line (Replaces entire line if it already exists)
sudo sed -i "s|^#*shared_preload_libraries *=.*|shared_preload_libraries = 'pg_stat_monitor'|" "$PG_CONF"

# 2. Ensure the pg_stat_monitor parameters are added right below shared_preload_libraries (Only add if not already present)
sudo grep -q "pg_stat_monitor.pgsm_query_max_len" "$PG_CONF" || \
  sudo sed -i "/shared_preload_libraries/a pg_stat_monitor.pgsm_query_max_len = 2048" "$PG_CONF"

sudo grep -q "pg_stat_monitor.pgsm_normalized_query" "$PG_CONF" || \
  sudo sed -i "/shared_preload_libraries/a pg_stat_monitor.pgsm_normalized_query = 1" "$PG_CONF"

# Query plans in QAN: set to 'on' to enable (adds overhead under load).
sudo grep -q "pg_stat_monitor.pgsm_enable_query_plan" "$PG_CONF" || \
  sudo sed -i "/shared_preload_libraries/a pg_stat_monitor.pgsm_enable_query_plan = off" "$PG_CONF"
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Restart PostgreSQL service to apply changes:
sudo systemctl restart postgresql-17
sleep 5

# Create the pg_stat_monitor extension in the 'postgres' database:
sudo -u postgres psql -d postgres -c "CREATE EXTENSION IF NOT EXISTS pg_stat_monitor;"

# Verify the installation by checking the pg_stat_monitor view:
sudo -u postgres psql -d postgres -c "SELECT pg_stat_monitor_version();"



##################################################################
# Script for Client PMM Installation:
##################################################################

# Enable Percona PMM Repository:
sudo percona-release disable all
sudo percona-release enable pmm3-client

# Install PMM Client:
sudo dnf -y install pmm-client


# Create the PMM User in PostgreSQL (or reset its password if it already exists):
sudo -u postgres psql -v ON_ERROR_STOP=1 -v pmm_password="$PMM_DB_PASSWORD" <<'SQL'
SELECT 'CREATE ROLE pmm WITH LOGIN SUPERUSER' WHERE NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'pmm')\gexec
ALTER ROLE pmm WITH PASSWORD :'pmm_password';
SQL

# Allow password auth for the pmm user over the socket and localhost TCP (pmm-agent connects to 127.0.0.1:5432).
# These lines must come before the default 'peer' / 'ident' rules, so they are inserted under the section comments:
sudo grep -qE '^local\s+all\s+pmm\s' "$PG_HBA" || \
  sudo sed -i '/^# "local" is for Unix domain socket connections only/a local   all             pmm                                     scram-sha-256' "$PG_HBA"

sudo grep -qE '^host\s+all\s+pmm\s+127\.0\.0\.1/32' "$PG_HBA" || \
  sudo sed -i '/^# IPv4 local connections:/a host    all             pmm             127.0.0.1/32            scram-sha-256' "$PG_HBA"

sudo -u postgres psql -c "SELECT pg_reload_conf();"


##################################################################
# PMM Client Registration:
##################################################################

# Register PMM Client to PMM Server (--force re-registers this node cleanly when the script is re-run):
sudo pmm-admin config --server-insecure-tls --force \
  --server-url="https://admin:${PMM_ADMIN_PASSWORD}@${PMM_SERVER_IP}:443"

# Add PostgreSQL service to PMM
sudo pmm-admin add postgresql \
  --username=pmm \
  --password="$PMM_DB_PASSWORD" \
  --server-url="https://admin:${PMM_ADMIN_PASSWORD}@${PMM_SERVER_IP}:443" \
  --server-insecure-tls \
  --service-name="postgresql-source" \
  --auto-discovery-limit=10

echo "✅ PMM registration completed."

