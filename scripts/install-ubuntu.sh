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

# Add PostgreSQL repository
curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo gpg --dearmor -o /usr/share/keyrings/postgresql-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/postgresql-keyring.gpg] http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" | sudo tee /etc/apt/sources.list.d/pgdg.list

# Install PostgreSQL and build dependencies
sudo apt-get update
sudo apt-get install -y \
    "postgresql-$PG_VERSION" \
    "postgresql-server-dev-$PG_VERSION" \
    build-essential \
    git

# Start PostgreSQL service
sudo systemctl start "postgresql@$PG_VERSION-main"

# Wait for PostgreSQL to start
sleep 3

# Create user and set password
sudo -u postgres psql -c "CREATE USER $PGUSER WITH SUPERUSER PASSWORD '$PGPASSWORD';" || true
sudo -u postgres psql -c "ALTER USER $PGUSER WITH PASSWORD '$PGPASSWORD';"

# Create database if it doesn't exist
if [ "$PGDATABASE" != "postgres" ]; then
    sudo -u postgres createdb -O $PGUSER $PGDATABASE || true
fi

# Build and install pgvector
git clone --branch "v$PGVECTOR_VERSION" https://github.com/pgvector/pgvector.git
cd pgvector
make
sudo make install
cd ..
rm -rf pgvector

# Create and configure pgvector extension
PGPASSWORD=$PGPASSWORD psql -h localhost -U $PGUSER -d $PGDATABASE -c 'CREATE EXTENSION IF NOT EXISTS vector;'

# Export environment variables
export_var "PGHOST" "localhost"
export_var "PGUSER" "$PGUSER"
export_var "PGPASSWORD" "$PGPASSWORD"
export_var "PGDATABASE" "$PGDATABASE"

# Verify installation
echo "Checking PostgreSQL installation..."
PGPASSWORD=$PGPASSWORD psql -h localhost -U $PGUSER -d $PGDATABASE -c "SELECT version();"
echo "Checking available extensions..."
PGPASSWORD=$PGPASSWORD psql -h localhost -U $PGUSER -d $PGDATABASE -c "SELECT * FROM pg_available_extensions WHERE name = 'vector';"
echo "Checking installed extensions..."
PGPASSWORD=$PGPASSWORD psql -h localhost -U $PGUSER -d $PGDATABASE -c "SELECT * FROM pg_extension WHERE extname = 'vector';"

# Print success message
echo "PostgreSQL and pgvector have been successfully installed!"
echo "Connection details:"
echo "  Host: localhost"
echo "  User: $PGUSER"
echo "  Database: $PGDATABASE"
echo "  Password: [hidden]"
