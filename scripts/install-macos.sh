#!/bin/bash
set -ex

# Default versions if not provided
PG_VERSION=${1:-17}
PGVECTOR_VERSION=${2:-0.8.0}
PGUSER=${3:-postgres}
PGPASSWORD=${4:-postgres}
PGDATABASE=${5:-postgres}

# Install PostgreSQL
brew install "postgresql@$PG_VERSION"
brew services start "postgresql@$PG_VERSION"

# Add PostgreSQL binaries to PATH
export PATH="/opt/homebrew/opt/postgresql@$PG_VERSION/bin:$PATH"

# Wait for PostgreSQL to start
sleep 3

# Set password and create database/user
createuser -s $PGUSER || true
psql -d postgres -c "ALTER USER $PGUSER WITH PASSWORD '$PGPASSWORD';"
if [ "$PGDATABASE" != "postgres" ]; then
    createdb -O $PGUSER $PGDATABASE
fi

# Build and install pgvector
git clone --branch "v$PGVECTOR_VERSION" https://github.com/pgvector/pgvector.git
cd pgvector
make
make install
cd ..
rm -rf pgvector

# Create and configure pgvector extension
psql -d $PGDATABASE -c 'CREATE EXTENSION IF NOT EXISTS vector;'

# Export environment variables
export PGHOST=localhost
export PGUSER=$PGUSER
export PGPASSWORD=$PGPASSWORD
export PGDATABASE=$PGDATABASE

echo "PGHOST=$PGHOST" >> $GITHUB_ENV
echo "PGUSER=$PGUSER" >> $GITHUB_ENV
echo "PGPASSWORD=$PGPASSWORD" >> $GITHUB_ENV
echo "PGDATABASE=$PGDATABASE" >> $GITHUB_ENV

# Verify installation
echo "Checking PostgreSQL installation..."
psql -d $PGDATABASE -c "SELECT version();"
echo "Checking available extensions..."
psql -d $PGDATABASE -c "SELECT * FROM pg_available_extensions WHERE name = 'vector';"
echo "Checking installed extensions..."
psql -d $PGDATABASE -c "SELECT * FROM pg_extension WHERE extname = 'vector';"
