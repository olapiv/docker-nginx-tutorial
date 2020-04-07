#!/bin/sh

python manage.py migrate
python manage.py collectstatic --no-input --clear

gunicorn hello_django.wsgi:application --bind 0.0.0.0:8000

exec "$@"