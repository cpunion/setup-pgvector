#!/bin/bash
set -ex

# Default versions if not provided
PG_VERSION=${1:-17}
PGVECTOR_VERSION=${2:-0.8.0}
PGUSER=${3:-postgres}
PGPASSWORD=${4:-postgres}
PGDATABASE=${5:-postgres}

# Function to export variables
export_var() {
    local name=$1
    local value=$2
    export "$name=$value"
    # Only export to GITHUB_ENV if running in GitHub Actions
    if [ -n "$GITHUB_ENV" ]; then
        echo "$name=$value" >> $GITHUB_ENV
    fi
}

# Install PostgreSQL
brew install "postgresql@$PG_VERSION"
brew link --force "postgresql@$PG_VERSION"

# Add PostgreSQL binaries to PATH
PG_PATH="/usr/local/opt/postgresql@$PG_VERSION/bin"
# For Apple Silicon Macs
if [ -d "/opt/homebrew/opt/postgresql@$PG_VERSION/bin" ]; then
    PG_PATH="/opt/homebrew/opt/postgresql@$PG_VERSION/bin"
fi
export PATH="$PG_PATH:$PATH"
# Only add to GITHUB_PATH if running in GitHub Actions
if [ -n "$GITHUB_PATH" ]; then
    echo "$PG_PATH" >> $GITHUB_PATH
fi

# Start PostgreSQL
brew services start "postgresql@$PG_VERSION"

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
export_var "PGHOST" "localhost"
export_var "PGUSER" "$PGUSER"
export_var "PGPASSWORD" "$PGPASSWORD"
export_var "PGDATABASE" "$PGDATABASE"

# Verify installation
echo "Checking PostgreSQL installation..."
psql -d $PGDATABASE -c "SELECT version();"
echo "Checking available extensions..."
psql -d $PGDATABASE -c "SELECT * FROM pg_available_extensions WHERE name = 'vector';"
echo "Checking installed extensions..."
psql -d $PGDATABASE -c "SELECT * FROM pg_extension WHERE extname = 'vector';"

# Print success message
echo "PostgreSQL and pgvector have been successfully installed!"
echo "Connection details:"
echo "  Host: localhost"
echo "  User: $PGUSER"
echo "  Database: $PGDATABASE"
echo "  Password: [hidden]"
