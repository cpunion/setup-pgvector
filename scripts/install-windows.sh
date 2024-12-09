#!/bin/bash
set -ex

PG_VERSION=$1
PGVECTOR_VERSION=$2

# Add PostgreSQL binaries to PATH
export PATH="/mingw64/bin:$PATH"
export PKG_CONFIG_PATH="/mingw64/lib/pkgconfig:$PKG_CONFIG_PATH"

# Initialize PostgreSQL database
export PGDATA=/c/data/postgres
export PGHOST=localhost
export PGUSER=postgres
mkdir -p $PGDATA

echo "Initializing PostgreSQL database..."
initdb -U postgres --encoding=UTF8 --locale=C --auth=trust

# Configure PostgreSQL
echo "host    all             all             127.0.0.1/32            trust" >> $PGDATA/pg_hba.conf
echo "host    all             all             ::1/128                 trust" >> $PGDATA/pg_hba.conf

# Configure postgresql.conf
echo "unix_socket_directories = '$PGDATA'" >> $PGDATA/postgresql.conf
echo "listen_addresses = 'localhost'" >> $PGDATA/postgresql.conf

# Start PostgreSQL
echo "Starting PostgreSQL..."
pg_ctl -D $PGDATA -l $PGDATA/logfile start
sleep 3  # Wait for PostgreSQL to start

# Verify PostgreSQL is running
echo "Verifying PostgreSQL connection..."
psql -h localhost -U postgres -c "SELECT version();"

# Get PostgreSQL version
PG_ACTUAL_VERSION=$(psql -h localhost -U postgres -t -c "SHOW server_version;" | xargs)
echo "PostgreSQL actual version: ${PG_ACTUAL_VERSION}"
PG_MAJOR_VERSION=$(echo ${PG_ACTUAL_VERSION} | cut -d. -f1)
echo "PostgreSQL major version: ${PG_MAJOR_VERSION}"

# Build and install pgvector
echo "Building pgvector..."
git clone --branch v${PGVECTOR_VERSION} https://github.com/pgvector/pgvector.git
cd pgvector
make clean
PG_CONFIG=/mingw64/bin/pg_config make
PG_CONFIG=/mingw64/bin/pg_config make install
cd ..
rm -rf pgvector

# Create test database
echo "Creating test database..."
createdb -h localhost -U postgres postgres

# Verify installation
echo "Checking PostgreSQL installation..."
psql -h localhost -U postgres -d postgres -c "SELECT version();"
echo "Checking available extensions..."
psql -h localhost -U postgres -d postgres -c "SELECT * FROM pg_available_extensions WHERE name = 'vector';"
