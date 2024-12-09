#!/bin/bash
set -ex

# Default versions if not provided
PG_VERSION=${1:-17}
PGVECTOR_VERSION=${2:-0.8.0}
PGUSER=${3:-postgres}
PGPASSWORD=${4:-postgres}
PGDATABASE=${5:-postgres}

# Set environment variables
export PGDATA=/c/data/postgres
export PGHOST=localhost
export PGUSER=$PGUSER
export PGPASSWORD=$PGPASSWORD
export PGDATABASE=$PGDATABASE

# Initialize PostgreSQL if not already initialized
if [ ! -d "$PGDATA" ]; then
    initdb -D "$PGDATA" -U $PGUSER --pwfile=<(echo "$PGPASSWORD")
    
    # Configure PostgreSQL for password authentication
    echo "host    all             all             127.0.0.1/32            md5" >> "$PGDATA/pg_hba.conf"
    echo "host    all             all             ::1/128                 md5" >> "$PGDATA/pg_hba.conf"
fi

# Start PostgreSQL
echo "Starting PostgreSQL..."
pg_ctl -D "$PGDATA" -w start

# Wait for PostgreSQL to start
sleep 3

# Show PostgreSQL logs
echo "PostgreSQL log content:"
cat "$PGDATA/log/postgresql-"*".log"

# Create database if it doesn't exist
if [ "$PGDATABASE" != "postgres" ]; then
    PGPASSWORD=$PGPASSWORD createdb -h localhost -U $PGUSER $PGDATABASE || true
fi

# Build and install pgvector
git clone --branch "v$PGVECTOR_VERSION" https://github.com/pgvector/pgvector.git
cd pgvector
make
make install
cd ..
rm -rf pgvector

# Create and configure pgvector extension
echo "Creating pgvector extension..."
PGPASSWORD=$PGPASSWORD psql -h localhost -U $PGUSER -d $PGDATABASE -c "CREATE EXTENSION IF NOT EXISTS vector;"

# Export environment variables for PowerShell
echo "PGDATA=$PGDATA" >> $GITHUB_ENV
echo "PGHOST=$PGHOST" >> $GITHUB_ENV
echo "PGUSER=$PGUSER" >> $GITHUB_ENV
echo "PGPASSWORD=$PGPASSWORD" >> $GITHUB_ENV
echo "PGDATABASE=$PGDATABASE" >> $GITHUB_ENV

# Verify installation
echo "Checking PostgreSQL installation..."
PGPASSWORD=$PGPASSWORD psql -h localhost -U $PGUSER -d $PGDATABASE -c "SELECT version();"
echo "Checking available extensions..."
PGPASSWORD=$PGPASSWORD psql -h localhost -U $PGUSER -d $PGDATABASE -c "SELECT * FROM pg_available_extensions WHERE name = 'vector';"
echo "Checking installed extensions..."
PGPASSWORD=$PGPASSWORD psql -h localhost -U $PGUSER -d $PGDATABASE -c "SELECT * FROM pg_extension WHERE extname = 'vector';"
