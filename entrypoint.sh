#!/bin/bash
set -e

echo "Waiting for database to become available..."

# Estrai variabili da DATABASE_URL
# Assumiamo che DATABASE_URL sia già presente come variabile d'ambiente su Render
export PGHOST=$(echo $DATABASE_URL | sed -E 's|.*@([^:/?]+).*|\1|')
export PGUSER=$(echo $DATABASE_URL | sed -E 's|postgresql://([^:]+):.*|\1|')
export PGPASSWORD=$(echo $DATABASE_URL | sed -E 's|postgresql://[^:]+:([^@]+)@.*|\1|')
export PGDATABASE=$(echo $DATABASE_URL | sed -E 's|.*/([^?]+).*|\1|')

# Tenta di connettersi al DB via psql (SSL implicito da DATABASE_URL)
until psql "sslmode=require dbname=$PGDATABASE host=$PGHOST user=$PGUSER password=$PGPASSWORD" -c '\q' >/dev/null 2>&1; do
  echo "Database is unavailable - waiting..."
  sleep 2
done

echo "Database is up - running migrations"

# Esegue db:prepare (include create, migrate, seed se serve)
bundle exec rake db:prepare

# Avvia il server Rails
exec bundle exec rails server -b 0.0.0.0
