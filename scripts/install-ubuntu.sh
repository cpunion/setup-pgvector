#!/bin/bash
set -ex

# Default versions if not provided
PG_VERSION=${1:-17}
PGVECTOR_VERSION=${2:-0.8.0}
PGUSER=${3:-postgres}
PGPASSWORD=${4:-postgres}
PGDATABASE=${5:-postgres}

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

# Create and use temporary directory
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"
git clone --branch v${PGVECTOR_VERSION} https://github.com/pgvector/pgvector.git
cd pgvector
make clean
PG_CONFIG=/usr/lib/postgresql/${PG_MAJOR_VERSION}/bin/pg_config make
sudo PG_CONFIG=/usr/lib/postgresql/${PG_MAJOR_VERSION}/bin/pg_config make install
cd ..
rm -rf "$TEMP_DIR"

# Configure PostgreSQL authentication for CI
echo "local all postgres trust" | sudo tee /etc/postgresql/${PG_VERSION}/main/pg_hba.conf
echo "local all runner trust" | sudo tee -a /etc/postgresql/${PG_VERSION}/main/pg_hba.conf
echo "local all all trust" | sudo tee -a /etc/postgresql/${PG_VERSION}/main/pg_hba.conf
echo "host all all 127.0.0.1/32 trust" | sudo tee -a /etc/postgresql/${PG_VERSION}/main/pg_hba.conf
echo "host all all ::1/128 trust" | sudo tee -a /etc/postgresql/${PG_VERSION}/main/pg_hba.conf

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

# Set password and create database
sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD '$PGPASSWORD';"
if [ "$PGUSER" != "postgres" ]; then
    sudo -u postgres createuser -s $PGUSER
    sudo -u postgres psql -c "ALTER USER $PGUSER WITH PASSWORD '$PGPASSWORD';"
fi
if [ "$PGDATABASE" != "postgres" ]; then
    sudo -u postgres createdb -O $PGUSER $PGDATABASE
fi

# Create and configure pgvector extension
sudo -u postgres psql -d $PGDATABASE -c "CREATE EXTENSION IF NOT EXISTS vector;"

# Export environment variables
export PGHOST=localhost
export PGUSER=$PGUSER
export PGPASSWORD=$PGPASSWORD
export PGDATABASE=$PGDATABASE

# Export to GITHUB_ENV only if running in GitHub Actions
if [ -n "$GITHUB_ENV" ]; then
    echo "PGHOST=$PGHOST" >> $GITHUB_ENV
    echo "PGUSER=$PGUSER" >> $GITHUB_ENV
    echo "PGPASSWORD=$PGPASSWORD" >> $GITHUB_ENV
    echo "PGDATABASE=$PGDATABASE" >> $GITHUB_ENV
fi

# Verify installation
echo "Checking PostgreSQL installation..."
psql -d $PGDATABASE -c "SELECT version();"
echo "Checking available extensions..."
psql -d $PGDATABASE -c "SELECT * FROM pg_available_extensions WHERE name = 'vector';"
echo "Checking installed extensions..."
psql -d $PGDATABASE -c "SELECT * FROM pg_extension WHERE extname = 'vector';"
