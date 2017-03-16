#!/bin/bash

set -e

if [ "$#" -lt 2 ]; then
    echo "USAGE: $0 <bosh name> <bosh ip address>"
    exit 99;
fi

export BOSH_NAME=$1
export BOSH_IP=$2

export TARGET="out"

# generate a cert for the director
certstrap --depot-path ${TARGET} request-cert --cn "${BOSH_NAME}-bosh-director" --ip ${BOSH_IP} --passphrase ''
certstrap --depot-path ${TARGET} sign ${BOSH_NAME}-bosh-director --CA master-bosh --passphrase ''

# generate a saml signing cert
certstrap --depot-path ${TARGET} request-cert --cn "${BOSH_NAME}-uaa-saml" --ip ${BOSH_IP} --passphrase ''
certstrap --depot-path ${TARGET} sign ${BOSH_NAME}-uaa-saml --CA master-bosh --passphrase ''

# generate a cert for UAA in ssl mode
certstrap --depot-path ${TARGET} request-cert --cn "${BOSH_NAME}-uaa-web" --ip ${BOSH_IP} --passphrase ''
certstrap --depot-path ${TARGET} sign ${BOSH_NAME}-uaa-web --CA master-bosh --passphrase ''

# extract the public key for this cert as right now we use it to sign JWTs as well
openssl rsa -in ${TARGET}/${BOSH_NAME}-uaa-web.key -pubout > ${TARGET}/${BOSH_NAME}-pub.key
