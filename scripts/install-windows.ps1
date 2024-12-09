param(
    [string]$PostgresVersion,
    [string]$PgVectorVersion
)

# Install PostgreSQL
choco install postgresql$PostgresVersion --params '/Password:postgres'
$pgPath = "C:\Program Files\PostgreSQL\$PostgresVersion"
echo "$pgPath\bin" | Out-File -FilePath $env:GITHUB_PATH -Encoding utf8 -Append
echo "$pgPath\lib" | Out-File -FilePath $env:GITHUB_PATH -Encoding utf8 -Append
refreshenv

# Start PostgreSQL service
Start-Service postgresql-x64-$PostgresVersion
Start-Sleep -s 3  # Wait for PostgreSQL to start
$env:PGPASSWORD = 'postgres'
psql -U postgres -c "SELECT version();"
