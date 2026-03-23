#!/bin/bash
set -e

# Set MongoDB URI
pritunl set-mongodb mongodb://${MONGODB_SERVER:-"mongo"}:27017/pritunl

# Wait for MongoDB to be ready
echo "Waiting for MongoDB..."
while ! nc -z ${MONGODB_SERVER:-"mongo"} 27017; do
  sleep 1
done
echo "MongoDB is up"

# Set server port (исправлено: != для строк вместо -ne)
actual_server_port=$(pritunl get app.server_port | cut -d "=" -f2 | awk '{$1=$1};1')
if [[ "$actual_server_port" != "${SERVER_PORT:-443}" ]]; then
    pritunl set app.server_port ${SERVER_PORT:-443}
fi

# Set ACME domain (исправлено: проверка на пустоту + != для строк)
if [[ -n "${ACME_DOMAIN}" ]]; then
    actual_acme_domain=$(pritunl get app.acme_domain | cut -d "=" -f2 | awk '{$1=$1};1')
    if [[ "$actual_acme_domain" != "${ACME_DOMAIN}" ]]; then
        echo "Updating ACME settings..."
        pritunl set app.acme_timestamp $(date +%s)
        pritunl set app.acme_key "$(openssl genrsa 4096 2>/dev/null)"
        pritunl set app.acme_domain ${ACME_DOMAIN}
    fi
fi

# Start Pritunl (демонизируется)
pritunl start

# Держим контейнер живым — tail логов
exec tail -f /var/lib/pritunl/pritunl.log