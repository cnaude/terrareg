#!/usr/bin/env bash

set -e
# set -x

OPENSSL_CERT_SUBJECT=${OPENSSL_CERT_SUBJECT:=/C=US/ST=Arizona/L=Phoenix/O=Snakeoil/CN=terrareg.local}
SSL_CERT_PUBLIC_KEY=${SSL_CERT_PUBLIC_KEY:-/app/terrareg/ssl/terrareg.crt}
SSL_CERT_PRIVATE_KEY=${SSL_CERT_PRIVATE_KEY:-/app/terrareg/ssl/terrareg.key}
SSL_CERT_DAYS=${SSL_CERT_DAYS:-365}

# Check if database upgrades are to be performed
if [ "${MIGRATE_DATABASE}" == "True" ]
then
    poetry run alembic upgrade head
fi

# Check whether to upgrade database and exit
if [ "${MIGRATE_DATABASE_ONLY}" == "True" ]
then
    exit
fi

# If private key has been set, inject into SSH directory
if [ "${SSH_PRIVATE_KEY}" != "" ]
then
    mkdir ~/.ssh
    chmod 700 ~/.ssh
    touch ~/.ssh/id_rsa
    chmod 600 ~/.ssh/id_rsa
    echo -e "${SSH_PRIVATE_KEY}" > ~/.ssh/id_rsa
fi

# generate certificates
mkdir -p $(dirname $SSL_CERT_PRIVATE_KEY)
mkdir -p $(dirname $SSL_CERT_PUBLIC_KEY)
if [[ -n "$SSL_CERT_DAYS" && -n "${OPENSSL_CERT_SUBJECT}" && -n "${SSL_CERT_PRIVATE_KEY}" && -n "${SSL_CERT_PUBLIC_KEY}" ]]; then
    echo "Generating SSL certificate: ${SSL_CERT_PUBLIC_KEY} (${OPENSSL_CERT_SUBJECT})"
    openssl req -new -newkey rsa:4096 -days $SSL_CERT_DAYS -nodes -x509 -subj $OPENSSL_CERT_SUBJECT -keyout $SSL_CERT_PRIVATE_KEY -out $SSL_CERT_PUBLIC_KEY
fi

# Run main executable
poetry run python ./terrareg.py
