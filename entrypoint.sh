#!/usr/bin/env bash
set -e

echo "Waiting for postgres to connect ..."
cd /app/src

# Wait for the database to be up and ready, if not ready, then sleep for 5 seconds
while ! nc -z ${DB_HOST} ${DB_PORT}; do
  sleep 5
done

echo "PostgreSQL is active"

python manage.py collectstatic --noinput

python manage.py migrate
echo "Postgresql migrations finished"

# Create a superuser using the specified credentials. If the user already exists, an error code would be returned.
# Thet's why there is '|| true', it make the command not return an error code, because otherwise the container would
# fail to start when a superuser already exists.
if [ -n "$DJANGO_SUPERUSER_USERNAME" ] && [ -n "$DJANGO_SUPERUSER_EMAIL" ] && [ -n "$DJANGO_SUPERUSER_PASSWORD" ]; then
    echo "Creating superuser ${DJANGO_SUPERUSER_USERNAME}..."
    python manage.py createsuperuser --username "$DJANGO_SUPERUSER_USERNAME" --email "$DJANGO_SUPERUSER_EMAIL" --no-input || true
fi

gunicorn tsa_app.wsgi:application --bind 0.0.0.0:8000
