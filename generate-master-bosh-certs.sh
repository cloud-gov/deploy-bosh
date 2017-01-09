#!/bin/bash

if [ "$#" -lt 1 ]; then
    echo "USAGE: $0 <master bosh ip address>"
    exit 99;
fi

export MASTER_BOSH_IP=$1
export TARGET="out"

# generate master-bosh.pem / root CA
certstrap --depot-path ${TARGET} init -o 'GSA / TTS / 18F' -ou 'cloud.gov' --cn 'master-bosh' --passphrase ''

# generate a key and csr for master-bosh nginx
# note: it's important to specify a CN here and an IP, else certstrap with not add a SAN field which the new golang bosh cli requires
certstrap --depot-path ${TARGET} request-cert --cn 'master-bosh-director' --ip ${MASTER_BOSH_IP} --passphrase ''
certstrap --depot-path ${TARGET} sign master-bosh-director --CA master-bosh

# extract the public key
TMPKEY=$(mktemp)
cp ${TARGET}/master-bosh.key ${TMPKEY}
chmod 600 ${TMPKEY}
ssh-keygen -y -f ${TMPKEY} > ${TARGET}/master-bosh.pub
rm ${TMPKEY}

echo "Master BOSH public key (upload as a keypair AWS):"
cat ${TARGET}/master-bosh.pub

