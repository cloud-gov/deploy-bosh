#!/bin/bash

set -e

if [ "$#" -lt 2 ]; then
    echo "USAGE: $0 <bosh name> <bosh ip address>"
    exit 99;
fi

export BOSH_NAME=$1
export BOSH_IP=$2
export BOSH_UAA_IP=$3
ENV=${BOSH_NAME//-bosh/}
export UAA_DOMAIN=${4:-"*.uaa.$ENV-bosh.${ENV}bosh.toolingbosh"}

export TARGET="out"

# generate a cert for the director
certstrap --depot-path ${TARGET} request-cert --cn "${BOSH_NAME}-bosh-director" --ip "${BOSH_IP}" --passphrase ''
certstrap --depot-path ${TARGET} sign "${BOSH_NAME}-bosh-director" --CA master-bosh --passphrase ''

# generate a saml signing cert
certstrap --depot-path ${TARGET} request-cert --cn "${BOSH_NAME}-uaa-saml" --domain "${UAA_DOMAIN}" --passphrase ''
certstrap --depot-path ${TARGET} sign "${BOSH_NAME}-uaa-saml" --CA master-bosh --passphrase ''

# generate a cert for UAA in ssl mode
certstrap --depot-path ${TARGET} request-cert --cn "${BOSH_NAME}-uaa-web" --domain "${UAA_DOMAIN},localhost" --ip "${BOSH_UAA_IP}" --passphrase ''
certstrap --depot-path ${TARGET} sign "${BOSH_NAME}-uaa-web" --CA master-bosh --passphrase ''

# extract the public key for this cert as right now we use it to sign JWTs as well
openssl rsa -in "${TARGET}/${BOSH_NAME}-uaa-web.key" -pubout > "${TARGET}/${BOSH_NAME}-pub.key"

# generate a cert for nats server
certstrap --depot-path ${TARGET} request-cert --cn "${BOSH_NAME}.nats.bosh-internal" --ip "${BOSH_IP}" --passphrase ''
certstrap --depot-path ${TARGET} sign "${BOSH_NAME}.nats.bosh-internal" -CA master-bosh --passphrase ''

# generate a cert for nats director
certstrap --depot-path ${TARGET} request-cert --cn "${BOSH_NAME}.director.bosh-internal" --ip "${BOSH_IP}" --passphrase ''
certstrap --depot-path ${TARGET} sign "${BOSH_NAME}.director.bosh-internal" --CA master-bosh --passphrase ''

# generate a cert for nats health monitor
certstrap --depot-path ${TARGET} request-cert --cn "${BOSH_NAME}.hm.bosh-internal" --ip "${BOSH_IP}" --passphrase ''
certstrap --depot-path ${TARGET} sign "${BOSH_NAME}.hm.bosh-internal" --CA master-bosh --passphrase ''
