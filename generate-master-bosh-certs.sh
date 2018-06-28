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
