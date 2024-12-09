# Setup pgvector

GitHub Action and scripts to set up PostgreSQL with pgvector extension for vector similarity search.

## Features

- 🚀 Quick setup of PostgreSQL with pgvector extension
- 🔄 Supports both GitHub Actions and local installation
- 🛠️ Customizable PostgreSQL and pgvector versions
- 🔐 Secure password authentication
- 🌐 Cross-platform support: Ubuntu, Windows (MSYS2), and macOS
- 🏗️ Builds pgvector from source for maximum compatibility

## Quick Start

### GitHub Actions

```yaml
steps:
- uses: cpunion/setup-pgvector@main
  with:
    postgres-version: '17'
    postgres-user: 'myuser'
    postgres-password: 'mypassword'
    postgres-db: 'mydb'

- name: Test pgvector
  env:
    PGPASSWORD: mypassword
  run: |
    psql -h localhost -U myuser -d mydb -c 'CREATE EXTENSION vector;'
```

### Local Installation

#### Method 1: Direct Installation

```bash
# Ubuntu
curl -fsSL https://raw.githubusercontent.com/cpunion/setup-pgvector/main/scripts/install-ubuntu.sh | bash

# macOS
curl -fsSL https://raw.githubusercontent.com/cpunion/setup-pgvector/main/scripts/install-macos.sh | bash

# Windows (MSYS2)
curl -fsSL https://raw.githubusercontent.com/cpunion/setup-pgvector/main/scripts/install-windows.sh | bash
```

With custom parameters:
```bash
# Format: curl ... | bash -s [PG_VERSION] [PGVECTOR_VERSION] [PGUSER] [PGPASSWORD] [PGDATABASE]
curl -fsSL https://raw.githubusercontent.com/cpunion/setup-pgvector/main/scripts/install-ubuntu.sh | bash -s 17 0.8.0 myuser mypassword mydb
```

#### Method 2: Clone and Run

```bash
# Ubuntu
./scripts/install-ubuntu.sh

# macOS
./scripts/install-macos.sh

# Windows (MSYS2)
./scripts/install-windows.sh
```

## Requirements

- Ubuntu: No additional requirements
- Windows: MSYS2 environment
- macOS: Homebrew
- Git (for building pgvector)

## Detailed Usage

### GitHub Actions

```yaml
steps:
- uses: cpunion/setup-pgvector@main
  with:
    # PostgreSQL version to install (default: 17)
    postgres-version: '17'
    # pgvector version to install (default: 0.8.0)
    pgvector-version: '0.8.0'
    # PostgreSQL user to create (default: postgres)
    postgres-user: 'myuser'
    # Password for the PostgreSQL user (default: postgres)
    postgres-password: 'mypassword'
    # Database to create (default: postgres)
    postgres-db: 'mydb'

- name: Test pgvector
  env:
    PGPASSWORD: mypassword
  run: |
    psql -h localhost -U myuser -d mydb -c 'CREATE EXTENSION vector;'
    psql -h localhost -U myuser -d mydb -c 'CREATE TABLE items (id bigserial PRIMARY KEY, embedding vector(3));'
    psql -h localhost -U myuser -d mydb -c "INSERT INTO items (embedding) VALUES ('[1,2,3]');"
    psql -h localhost -U myuser -d mydb -c 'SELECT * FROM items;'
```

### Script Parameters

All installation scripts accept the following parameters:

1. `PG_VERSION` (default: 17) - PostgreSQL version to install
2. `PGVECTOR_VERSION` (default: 0.8.0) - pgvector version to install
3. `PGUSER` (default: postgres) - PostgreSQL user to create
4. `PGPASSWORD` (default: postgres) - Password for the PostgreSQL user
5. `PGDATABASE` (default: postgres) - Database to create

### Connection Details

After installation, you can connect to PostgreSQL using:

```bash
# Using password from environment variable
export PGPASSWORD=mypassword
psql -h localhost -U myuser -d mydb

# Or using password prompt
psql -h localhost -U myuser -d mydb
```

## Supported Platforms

- Ubuntu (latest, 24.04)
- Windows (latest, 2019)
- macOS (latest, 13)

## Notes

- The scripts will install PostgreSQL if not already installed
- The scripts will create the specified user and database if they don't exist
- The scripts will build and install pgvector from source
- All connections are configured to use password authentication

## License

MIT
