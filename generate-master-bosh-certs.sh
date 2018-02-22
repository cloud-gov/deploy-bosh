#!/bin/bash

if [ "$#" -lt 1 ]; then
  echo "USAGE: $0 <master bosh ip address>"
  exit 99;
fi

export MASTER_BOSH_IP=$1
export TARGET="out"

# generate master-bosh.pem / root CA
certstrap --depot-path ${TARGET} init -o 'GSA / TTS / 18F' -ou 'cloud.gov' --cn 'master-bosh' --passphrase ''

# extract the public key
TMPKEY=$(mktemp)
cp ${TARGET}/master-bosh.key ${TMPKEY}
chmod 600 ${TMPKEY}
ssh-keygen -y -f ${TMPKEY} > ${TARGET}/master-bosh.pub
rm ${TMPKEY}

# upload it to AWS.  Use this as the default_key_name is all bosh manifests
key_name="masterbosh-$(date +'%Y%m%d%H%M%S')"
aws ec2 import-key-pair --key-name "${key_name}" --public-key-material "$(cat ${TARGET}/master-bosh.pub)"
echo "${key_name}" > ./key-name

# generate a key and cert for master-bosh nginx
# note: it's important to specify a CN here and an IP, else certstrap with not add a SAN field which the new golang bosh cli requires
certstrap --depot-path ${TARGET} request-cert --cn 'master-bosh-director' --ip ${MASTER_BOSH_IP} --passphrase ''
certstrap --depot-path ${TARGET} sign master-bosh-director --CA master-bosh --passphrase ''

# generate a cert for nats server
certstrap --depot-path ${TARGET} request-cert --cn "master-bosh.nats.bosh-internal" --ip ${MASTER_BOSH_IP} --passphrase ''
certstrap --depot-path ${TARGET} sign master-bosh.nats.bosh-internal -CA master-bosh --passphrase ''

# generate a cert for nats director
certstrap --depot-path ${TARGET} request-cert --cn "master-bosh.director.bosh-internal" --ip ${MASTER_BOSH_IP} --passphrase ''
certstrap --depot-path ${TARGET} sign master-bosh.director.bosh-internal --CA master-bosh --passphrase ''

# generate a cert for nats health monitor
certstrap --depot-path ${TARGET} request-cert --cn "master-bosh.hm.bosh-internal" --ip ${MASTER_BOSH_IP} --passphrase ''
certstrap --depot-path ${TARGET} sign master-bosh.hm.bosh-internal --CA master-bosh --passphrase ''
