#!/bin/bash
set -ex

PG_VERSION=$1

brew install postgresql@${PG_VERSION}
brew link postgresql@${PG_VERSION}
echo "/usr/local/opt/postgresql@${PG_VERSION}/bin" >> $GITHUB_PATH

brew services start postgresql@${PG_VERSION}
sleep 3 # wait for PostgreSQL to start

# Get PostgreSQL version
PG_ACTUAL_VERSION=$(psql postgres -t -c "SHOW server_version;" | xargs)
echo "PostgreSQL actual version: ${PG_ACTUAL_VERSION}"
PG_MAJOR_VERSION=$(echo ${PG_ACTUAL_VERSION} | cut -d. -f1)
echo "PostgreSQL major version: ${PG_MAJOR_VERSION}"

createdb $USER || true

# Build and install pgvector from source
brew install gcc make
git clone --branch v${PGVECTOR_VERSION} https://github.com/pgvector/pgvector.git
cd pgvector
make clean
PG_CONFIG=/usr/local/opt/postgresql@${PG_VERSION}/bin/pg_config make
sudo PG_CONFIG=/usr/local/opt/postgresql@${PG_VERSION}/bin/pg_config make install
cd ..
rm -rf pgvector

# Verify installation
echo "Checking PostgreSQL installation..."
psql postgres -c "SELECT version();"
echo "Checking available extensions..."
psql postgres -c "SELECT * FROM pg_available_extensions WHERE name = 'vector';"
