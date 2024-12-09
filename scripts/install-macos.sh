#!/bin/bash
set -ex

PG_VERSION=$1

brew install postgresql@${PG_VERSION}
brew link postgresql@${PG_VERSION}
echo "/usr/local/opt/postgresql@${PG_VERSION}/bin" >> $GITHUB_PATH

brew services start postgresql@${PG_VERSION}
sleep 3 # wait for PostgreSQL to start

createdb $USER || true
brew install pgvector
