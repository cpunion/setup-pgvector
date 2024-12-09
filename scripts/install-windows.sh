#!/bin/bash
set -ex

PG_VERSION=$1
PGVECTOR_VERSION=$2

# Add PostgreSQL binaries to PATH
MSYS2_PATH="/c/msys64/mingw64"
echo "${MSYS2_PATH}/bin" >> $GITHUB_PATH
echo "${MSYS2_PATH}/lib" >> $GITHUB_PATH

# Initialize PostgreSQL database
export PGDATA=/c/msys64/home/$USER/pgdata
export PGHOST=/tmp
mkdir -p $PGDATA
initdb -U postgres --encoding=UTF8 --locale=C

# Configure PostgreSQL
echo "local all postgres trust" > $PGDATA/pg_hba.conf
echo "local all all trust" >> $PGDATA/pg_hba.conf

# Start PostgreSQL
pg_ctl -D $PGDATA -l logfile start

# Get PostgreSQL version
PG_ACTUAL_VERSION=$(psql -U postgres -t -c "SHOW server_version;" | xargs)
echo "PostgreSQL actual version: ${PG_ACTUAL_VERSION}"
PG_MAJOR_VERSION=$(echo ${PG_ACTUAL_VERSION} | cut -d. -f1)
echo "PostgreSQL major version: ${PG_MAJOR_VERSION}"

# Build and install pgvector
git clone --branch v${PGVECTOR_VERSION} https://github.com/pgvector/pgvector.git
cd pgvector
make clean
PATH="${MSYS2_PATH}/bin:$PATH" PG_CONFIG="${MSYS2_PATH}/bin/pg_config" make
PATH="${MSYS2_PATH}/bin:$PATH" PG_CONFIG="${MSYS2_PATH}/bin/pg_config" make install
cd ..
rm -rf pgvector

# Create test database
createdb -U postgres postgres

# Verify installation
echo "Checking PostgreSQL installation..."
psql -U postgres -d postgres -c "SELECT version();"
echo "Checking available extensions..."
psql -U postgres -d postgres -c "SELECT * FROM pg_available_extensions WHERE name = 'vector';"
