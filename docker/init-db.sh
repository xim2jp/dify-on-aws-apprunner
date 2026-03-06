#!/bin/bash
# Create dify_plugin database if it doesn't exist
# This runs at container startup before supervisord
set -e

if [ -n "$DB_HOST" ] && [ -n "$DB_USERNAME" ] && [ -n "$DB_PASSWORD" ]; then
  export PGPASSWORD="$DB_PASSWORD"
  for i in $(seq 1 30); do
    if pg_isready -h "$DB_HOST" -p "${DB_PORT:-5432}" -U "$DB_USERNAME" 2>/dev/null; then
      echo "DB is ready, checking dify_plugin database..."
      # Check if dify_plugin exists, create if not
      DB_EXISTS=$(psql -h "$DB_HOST" -p "${DB_PORT:-5432}" -U "$DB_USERNAME" -d "$DB_DATABASE" -tAc "SELECT 1 FROM pg_database WHERE datname='dify_plugin'" 2>/dev/null || echo "")
      if [ "$DB_EXISTS" != "1" ]; then
        psql -h "$DB_HOST" -p "${DB_PORT:-5432}" -U "$DB_USERNAME" -d "$DB_DATABASE" -c "CREATE DATABASE dify_plugin;" 2>/dev/null && echo "Created dify_plugin database" || echo "dify_plugin database may already exist"
      else
        echo "dify_plugin database already exists"
      fi
      break
    fi
    echo "Waiting for DB... ($i/30)"
    sleep 2
  done
  unset PGPASSWORD
fi
