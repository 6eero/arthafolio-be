#!/bin/bash
set -e

echo "🔧 Waiting for database to become available..."

# Se DATABASE_URL è presente (es. in produzione), la scompone
if [ -n "$DATABASE_URL" ]; then
  echo "🌍 Using DATABASE_URL"

  export PGHOST=$(echo $DATABASE_URL | sed -E 's|.*@([^:/?]+).*|\1|')
  export PGUSER=$(echo $DATABASE_URL | sed -E 's|postgresql://([^:]+):.*|\1|')
  export PGPASSWORD=$(echo $DATABASE_URL | sed -E 's|postgresql://[^:]+:([^@]+)@.*|\1|')
  export PGDATABASE=$(echo $DATABASE_URL | sed -E 's|.*/([^?]+).*|\1|')
  
  export PGSSLMODE=require
else
  echo "💻 Using local DB environment variables"
  # Imposta un default per SSL solo se non è già stato definito
  export PGSSLMODE=${PGSSLMODE:-disable}
fi

# Verifica che tutte le variabili siano presenti
: "${PGHOST:?Missing PGHOST}"
: "${PGUSER:?Missing PGUSER}"
: "${PGPASSWORD:?Missing PGPASSWORD}"
: "${PGDATABASE:?Missing PGDATABASE}"

# Attendi che il DB risponda
until psql "sslmode=$PGSSLMODE dbname=$PGDATABASE host=$PGHOST user=$PGUSER password=$PGPASSWORD" -c '\q' >/dev/null 2>&1; do
  echo "⏳ Database is unavailable - waiting..."
  sleep 2
done

echo "✅ Database is up - running migrations"
bundle exec rake db:prepare

echo "🚀 Starting Rails server..."
exec bundle exec rails server -b 0.0.0.0 -p 3000
