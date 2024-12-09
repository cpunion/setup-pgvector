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

# Ensure data directory exists and is empty
rm -rf $PGDATA
mkdir -p $PGDATA

echo "Initializing PostgreSQL database..."
initdb -U postgres --encoding=UTF8 --locale=C --auth=trust

# Configure PostgreSQL
cat > $PGDATA/pg_hba.conf << EOL
# TYPE  DATABASE        USER            ADDRESS                 METHOD
local   all            all                                     trust
host    all            all             127.0.0.1/32           trust
host    all            all             ::1/128                trust
EOL

# Configure postgresql.conf
cat > $PGDATA/postgresql.conf << EOL
listen_addresses = 'localhost'
port = 5432
max_connections = 100
shared_buffers = 128MB
dynamic_shared_memory_type = windows
max_wal_size = 1GB
min_wal_size = 80MB
log_destination = 'stderr'
logging_collector = on
log_directory = 'log'
log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'
log_rotation_age = 1d
log_rotation_size = 10MB
log_min_messages = warning
log_min_error_statement = error
log_min_duration_statement = 1000
client_min_messages = notice
log_connections = on
log_disconnections = on
log_duration = on
log_line_prefix = '%m [%p] '
log_timezone = 'UTC'
datestyle = 'iso, mdy'
timezone = 'UTC'
lc_messages = 'C'
lc_monetary = 'C'
lc_numeric = 'C'
lc_time = 'C'
default_text_search_config = 'pg_catalog.english'
EOL

# Create log directory
mkdir -p $PGDATA/log

# Start PostgreSQL
echo "Starting PostgreSQL..."
pg_ctl -D $PGDATA -w start

# Wait and check the log
sleep 3
echo "PostgreSQL log content:"
cat $PGDATA/log/postgresql-*.log || true

# Verify PostgreSQL is running
echo "Verifying PostgreSQL connection..."
for i in {1..5}; do
    if psql -h localhost -U postgres -c "SELECT version();" 2>/dev/null; then
        break
    fi
    echo "Waiting for PostgreSQL to start (attempt $i)..."
    sleep 2
done

# Get PostgreSQL version
PG_ACTUAL_VERSION=$(psql -h localhost -U postgres -t -c "SHOW server_version;" | xargs)
echo "PostgreSQL actual version: ${PG_ACTUAL_VERSION}"

# Build and install pgvector
echo "Building pgvector..."
git clone --branch v${PGVECTOR_VERSION} https://github.com/pgvector/pgvector.git
cd pgvector
make clean
PG_CONFIG=/mingw64/bin/pg_config make
PG_CONFIG=/mingw64/bin/pg_config make install
cd ..
rm -rf pgvector

# Create and configure pgvector extension
echo "Creating pgvector extension..."
psql -h localhost -U postgres -d postgres -c "CREATE EXTENSION IF NOT EXISTS vector;"

# Export environment variables for PowerShell
echo "PGDATA=$PGDATA" >> $GITHUB_ENV
echo "PGHOST=$PGHOST" >> $GITHUB_ENV
echo "PGUSER=$PGUSER" >> $GITHUB_ENV

# Verify installation
echo "Checking PostgreSQL installation..."
psql -h localhost -U postgres -d postgres -c "SELECT version();"
echo "Checking available extensions..."
psql -h localhost -U postgres -d postgres -c "SELECT * FROM pg_available_extensions WHERE name = 'vector';"
echo "Checking installed extensions..."
psql -h localhost -U postgres -d postgres -c "SELECT * FROM pg_extension WHERE extname = 'vector';"
