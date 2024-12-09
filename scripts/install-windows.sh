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

# Set environment variables
export_var "PGDATA" "/c/data/postgres"
export_var "PGHOST" "localhost"
export_var "PGUSER" "$PGUSER"
export_var "PGPASSWORD" "$PGPASSWORD"
export_var "PGDATABASE" "$PGDATABASE"

# Initialize PostgreSQL if not already initialized
if [ ! -d "$PGDATA" ]; then
    # Create a temporary password file
    PWFILE=$(mktemp)
    echo "$PGPASSWORD" > "$PWFILE"
    
    initdb -D "$PGDATA" -U $PGUSER --pwfile="$PWFILE"
    rm -f "$PWFILE"
    
    # Configure PostgreSQL for password authentication
    echo "host    all             all             127.0.0.1/32            md5" >> "$PGDATA/pg_hba.conf"
    echo "host    all             all             ::1/128                 md5" >> "$PGDATA/pg_hba.conf"

    # Configure logging
    cat >> "$PGDATA/postgresql.conf" << EOL
logging_collector = on
log_directory = 'log'
log_filename = 'postgresql-%Y-%m-%d.log'
log_rotation_age = 1d
EOL

    # Create log directory
    mkdir -p "$PGDATA/log"
fi

# Start PostgreSQL
echo "Starting PostgreSQL..."
pg_ctl -D "$PGDATA" -w start

# Wait for PostgreSQL to start
sleep 3

# Show PostgreSQL logs
echo "PostgreSQL log content:"
if [ -f "$PGDATA/log/postgresql-$(date +%Y-%m-%d).log" ]; then
    cat "$PGDATA/log/postgresql-$(date +%Y-%m-%d).log"
else
    echo "Log file not found. PostgreSQL is still running, continuing..."
fi

# Create database if it doesn't exist
if [ "$PGDATABASE" != "postgres" ]; then
    PGPASSWORD=$PGPASSWORD createdb -h localhost -U $PGUSER $PGDATABASE || true
fi

# Install build tools and dependencies if running in MSYS2
if command -v pacman &> /dev/null; then
    pacman -S --noconfirm \
        mingw-w64-x86_64-gcc \
        mingw-w64-x86_64-postgresql \
        make
fi

# Add PostgreSQL binaries to PATH
export PATH="/mingw64/bin:$PATH"
export PKG_CONFIG_PATH="/mingw64/lib/pkgconfig:$PKG_CONFIG_PATH"

# Install pgvector
echo "Building pgvector from source..."
pacman -S --noconfirm git make gcc

# Create and use temporary directory
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"
git clone --branch v${PGVECTOR_VERSION} https://github.com/pgvector/pgvector.git
cd pgvector
make clean
PATH=$PATH:/mingw64/bin make USE_PGXS=1
PATH=$PATH:/mingw64/bin make USE_PGXS=1 install
cd ..
rm -rf "$TEMP_DIR"

# Create extension
PGPASSWORD=$PGPASSWORD psql -h localhost -U $PGUSER -d $PGDATABASE -c "CREATE EXTENSION IF NOT EXISTS vector;"

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
echo "  Data directory: $PGDATA"
