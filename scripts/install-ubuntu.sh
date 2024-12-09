#!/bin/bash
set -e

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

# Verify PostgreSQL installation
sudo -u postgres psql -c "SELECT version();"

echo "Installing pgvector..."
# First try installing from package
sudo apt-get install -y postgresql-${PG_VERSION}-pgvector
PGVECTOR_INSTALLED=$?

# If package installation fails, build from source
if [ $PGVECTOR_INSTALLED -ne 0 ]; then
    echo "Building pgvector from source..."
    sudo apt-get install -y postgresql-server-dev-${PG_VERSION} build-essential git
    git clone --branch v${PGVECTOR_VERSION} https://github.com/pgvector/pgvector.git
    cd pgvector
    make clean
    make
    sudo make install
    cd ..
    rm -rf pgvector
fi

# Configure PostgreSQL authentication for CI
echo "local all postgres trust" | sudo tee /etc/postgresql/${PG_VERSION}/main/pg_hba.conf
echo "local all runner trust" | sudo tee -a /etc/postgresql/${PG_VERSION}/main/pg_hba.conf
echo "local all all trust" | sudo tee -a /etc/postgresql/${PG_VERSION}/main/pg_hba.conf

# Restart PostgreSQL to ensure pgvector is loaded
sudo systemctl restart postgresql

# Verify pgvector installation
echo "Verifying pgvector installation..."
sudo -u postgres psql -d postgres -c "SELECT * FROM pg_extension;" || true
sudo -u postgres psql -d postgres -c "SELECT * FROM pg_available_extensions WHERE name = 'vector';" || true

# List extension directory contents
echo "Checking extension files..."
ls -la /usr/share/postgresql/${PG_VERSION}/extension/ || true
ls -la /usr/lib/postgresql/${PG_VERSION}/lib/ || true
