#!/bin/bash
set -ex

PG_VERSION=$1
PGVECTOR_VERSION=$2

echo "Installing PostgreSQL ${PG_VERSION}..."
sudo /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh -y
sudo apt-get update
sudo apt-get install -y postgresql-${PG_VERSION}

# Configure PostgreSQL
sudo systemctl stop postgresql
sudo pg_dropcluster --stop ${PG_VERSION} main || true
sudo pg_createcluster ${PG_VERSION} main --start || true
sudo systemctl start postgresql

# Create runner user and grant permissions
sudo -u postgres psql -c "CREATE USER runner WITH SUPERUSER;"

# Verify PostgreSQL installation and version
echo "Checking PostgreSQL version..."
PG_ACTUAL_VERSION=$(sudo -u postgres psql -t -c "SHOW server_version;" | xargs)
echo "PostgreSQL actual version: ${PG_ACTUAL_VERSION}"
PG_MAJOR_VERSION=$(echo ${PG_ACTUAL_VERSION} | cut -d. -f1)
echo "PostgreSQL major version: ${PG_MAJOR_VERSION}"

# Remove any existing pgvector installations
sudo apt-get remove -y postgresql-*-pgvector || true
sudo rm -f /usr/lib/postgresql/*/lib/vector.so
sudo rm -f /usr/share/postgresql/*/extension/vector*

echo "Installing pgvector..."
# Always build from source to match PostgreSQL version
echo "Building pgvector from source..."
sudo apt-get install -y postgresql-server-dev-${PG_MAJOR_VERSION} build-essential git
git clone --branch v${PGVECTOR_VERSION} https://github.com/pgvector/pgvector.git
cd pgvector
make clean
PG_CONFIG=/usr/lib/postgresql/${PG_MAJOR_VERSION}/bin/pg_config make
sudo PG_CONFIG=/usr/lib/postgresql/${PG_MAJOR_VERSION}/bin/pg_config make install
cd ..
rm -rf pgvector

# Configure PostgreSQL authentication for CI
echo "local all postgres trust" | sudo tee /etc/postgresql/${PG_VERSION}/main/pg_hba.conf
echo "local all runner trust" | sudo tee -a /etc/postgresql/${PG_VERSION}/main/pg_hba.conf
echo "local all all trust" | sudo tee -a /etc/postgresql/${PG_VERSION}/main/pg_hba.conf

# Restart PostgreSQL to ensure pgvector is loaded
sudo systemctl restart postgresql

# Verify pgvector installation
echo "Verifying pgvector installation..."
echo "Installed extensions:"
sudo -u postgres psql -d postgres -c "SELECT * FROM pg_extension;" || true
echo "Available extensions:"
sudo -u postgres psql -d postgres -c "SELECT * FROM pg_available_extensions WHERE name = 'vector';" || true

# List extension directory contents
echo "Checking extension files..."
echo "PostgreSQL ${PG_MAJOR_VERSION} extension directory:"
ls -la /usr/share/postgresql/${PG_MAJOR_VERSION}/extension/ || true
echo "PostgreSQL ${PG_MAJOR_VERSION} lib directory:"
ls -la /usr/lib/postgresql/${PG_MAJOR_VERSION}/lib/ || true
