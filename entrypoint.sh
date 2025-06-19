#!/bin/bash
set -e

# Check if the database exists and is ready
echo "Waiting for database..."
until pg_isready -h db -U postgres -d myapp_development; do
  sleep 1
done

# Setup database
bundle exec rake db:prepare

# Run Rails server
exec bundle exec rails server -b 0.0.0.0
