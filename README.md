# Setup pgvector Action

This action sets up [pgvector](https://github.com/pgvector/pgvector) in your GitHub Actions workflow. It uses the preinstalled PostgreSQL on GitHub runners and installs pgvector using platform-specific methods.

## Usage

```yaml
steps:
- uses: actions/checkout@v4
- uses: cpunion/setup-pgvector@v1
  with:
    postgres-version: '17' # optional, defaults to 17. Use 14 for ubuntu-22.04 and ubuntu-20.04
    pgvector-version: '0.8.0' # optional, defaults to 0.8.0
```

## Inputs

- `postgres-version`: PostgreSQL version to use (default: '17'). Note: Use '14' for ubuntu-22.04 and ubuntu-20.04.
- `pgvector-version`: pgvector version to install (default: '0.8.0')

## Platform Support

This action supports all major GitHub Actions platforms:
- Ubuntu (using postgresql-xx-pgvector package or building from source)
- macOS (using Homebrew)
- Windows (building from source using Visual Studio Build Tools)

## CI Status

The action is tested on the following platforms:
- Ubuntu: ubuntu-latest, ubuntu-24.04
- Windows: windows-latest, windows-2019
- macOS: macos-latest, macos-13

## Example workflows

### Ubuntu
```yaml
name: Test Ubuntu

on: [push]

jobs:
  test:
    runs-on: ubuntu-latest # or ubuntu-22.04, ubuntu-20.04
    steps:
    - uses: actions/checkout@v4
    - name: Setup pgvector
      uses: cpunion/setup-pgvector@v1
      with:
        postgres-version: '17' # Use '14' for ubuntu-22.04 and ubuntu-20.04
        pgvector-version: '0.8.0'
    - name: Create extension
      run: |
        sudo -u postgres psql -c 'CREATE EXTENSION vector;'
```

### macOS
```yaml
name: Test macOS

on: [push]

jobs:
  test:
    runs-on: macos-latest # or macos-13
    steps:
    - uses: actions/checkout@v4
    - name: Setup pgvector
      uses: cpunion/setup-pgvector@v1
      with:
        pgvector-version: '0.8.0'
    - name: Create extension
      run: |
        psql postgres -c 'CREATE EXTENSION vector;'
```

### Windows
```yaml
name: Test Windows

on: [push]

jobs:
  test:
    strategy:
      matrix:
        os: [windows-latest, windows-2019]
    runs-on: ${{ matrix.os }}
    steps:
    - uses: actions/checkout@v4
    - name: Setup pgvector
      uses: cpunion/setup-pgvector@v1
      with:
        pgvector-version: '0.8.0'
    - name: Create extension
      shell: cmd
      run: |
        psql -U postgres -c "CREATE EXTENSION vector;"
```

## License

MIT
