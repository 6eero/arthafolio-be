#!/bin/bash
set -e

rm -f /app/tmp/pids/server.pid

# 1. Log dell'ambiente in uso
echo "🌿 Environment detected: ${RAILS_ENV}"

# 2. Verifica che DATABASE_URL sia presente
if [ -z "$DATABASE_URL" ]; then
  echo "❌ Error: DATABASE_URL is not set. Please provide it in your env file."
  exit 1
fi

echo "🌍 Using remote database from DATABASE_URL"

# 3. Estrai i parametri di connessione per il check
export PGHOST=$(echo $DATABASE_URL | sed -E 's|.*@([^:/?]+).*|\1|')
export PGUSER=$(echo $DATABASE_URL | sed -E 's|postgresql://([^:]+):.*|\1|')
export PGPASSWORD=$(echo $DATABASE_URL | sed -E 's|postgresql://[^:]+:([^@]+)@.*|\1|')
export PGDATABASE=$(echo $DATABASE_URL | sed -E 's|.*/([^?]+).*|\1|')
export PGSSLMODE=require

# 4. Attendi che il DB remoto risponda
echo "🔧 Waiting for remote database to become available..."
until psql "sslmode=$PGSSLMODE dbname=$PGDATABASE host=$PGHOST user=$PGUSER password=$PGPASSWORD" -c '\q' >/dev/null 2>&1; do
  echo "⏳ Database is unavailable - waiting..."
  sleep 2
done

echo "✅ Database is up - running migrations"
bundle exec rake db:prepare

echo "🚀 Starting Rails server..."
exec bundle exec rails server -b 0.0.0.0 -p 3000