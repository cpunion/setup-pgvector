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

# Verify PostgreSQL installation
sudo -u postgres psql -c "SELECT version();"

echo "Installing pgvector..."
sudo apt-get install -y postgresql-${PG_VERSION}-pgvector
if [ $? -ne 0 ]; then
    echo "Building pgvector from source..."
    sudo apt-get install -y postgresql-server-dev-${PG_VERSION} build-essential git
    git clone --branch v${PGVECTOR_VERSION} https://github.com/pgvector/pgvector.git
    cd pgvector
    make
    sudo make install PG_CONFIG=/usr/lib/postgresql/${PG_VERSION}/bin/pg_config
    cd ..
    rm -rf pgvector
fi

# Configure PostgreSQL authentication for CI
echo "local all postgres trust" | sudo tee /etc/postgresql/${PG_VERSION}/main/pg_hba.conf
echo "local all all trust" | sudo tee -a /etc/postgresql/${PG_VERSION}/main/pg_hba.conf
sudo systemctl restart postgresql
