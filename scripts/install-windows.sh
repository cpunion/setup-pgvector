#!/bin/bash
set -e

PG_VERSION=$1
PGVECTOR_VERSION=$2

# Install PostgreSQL and build tools via MSYS2
pacman -Syu --noconfirm
pacman -S --noconfirm \
    mingw-w64-x86_64-postgresql${PG_VERSION} \
    mingw-w64-x86_64-gcc \
    mingw-w64-x86_64-make \
    git

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

# Build and install pgvector
git clone --branch v${PGVECTOR_VERSION} https://github.com/pgvector/pgvector.git
cd pgvector
make clean
make
make install
cd ..
rm -rf pgvector

# Create test database
createdb -U postgres postgres

# Verify installation
psql -U postgres -d postgres -c "SELECT version();"
psql -U postgres -d postgres -c "SELECT * FROM pg_available_extensions WHERE name = 'vector';"
