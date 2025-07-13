#!/bin/bash
set -e

# Remove a potentially pre-existing server.pid for Rails.
rm -f /app/tmp/pids/server.pid

# Install dependencies
bundle install

# Wait for database to be ready
echo "Waiting for database..."
until rails db:version; do
  echo "Database is unavailable - sleeping"
  sleep 1
done

# Run database migrations
echo "Running database migrations..."
rails db:migrate

# Seed the database if it's empty
if [ "$(rails runner "puts Product.count")" -eq "0" ]; then
  echo "Seeding database..."
  rails db:seed
fi

# Then exec the container's main process (what's set as CMD in the Dockerfile).
exec "$@" 