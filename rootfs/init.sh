#!/bin/bash
set -e

# Set MongoDB URI
pritunl set-mongodb mongodb://${MONGODB_SERVER:-"mongo"}:27017/pritunl

# Wait for MongoDB to be ready (simple check)
echo "Waiting for MongoDB..."
while ! nc -z ${MONGODB_SERVER:-"mongo"} 27017; do
  sleep 1
done
echo "MongoDB is up"

# Set Server Port
actual_server_port=$(pritunl get app.server_port | cut -d "=" -f2 | awk '{$1=$1};1')
if [[ "$actual_server_port" != "${SERVER_PORT:-443}" ]]; then
    pritunl set app.server_port ${SERVER_PORT:-443}
fi

# Set ACME Domain
actual_acme_domain=$(pritunl get app.acme_domain | cut -d "=" -f2 | awk '{$1=$1};1')
# Исправлено: != вместо -ne, и проверка на пустоту
if [[ -n "${ACME_DOMAIN}" ]] && [[ "$actual_acme_domain" != "${ACME_DOMAIN}" ]] ; then
    echo "Updating ACME settings..."
    pritunl set app.acme_timestamp $(date +%s)
    # Генерация ключа и сохранение
    pritunl set app.acme_key "$(openssl genrsa 4096 2>/dev/null)"
    pritunl set app.acme_domain ${ACME_DOMAIN}
fi

# Start Pritunl
pritunl start

# Keep container alive and stream logs
# Pritunl daemonizes, so we need to tail the log to prevent container exit
exec tail -f /var/lib/pritunl/pritunl.log