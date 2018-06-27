#!/bin/bash

set -eux

bosh interpolate secrets/master-bosh-decrypted.yml --path default_ca.private_key > ./ca.key

# and deploy it!
set +e
bosh create-env \
  bosh-deployment/bosh.yml \
  --state bosh-state/*.json \
  --ops-file bosh-deployment/aws/cpi.yml \
  --ops-file bosh-deployment/aws/iam-instance-profile.yml \
  --ops-file bosh-deployment/misc/powerdns.yml \
  --ops-file bosh-deployment/misc/source-releases/bosh.yml \
  --vars-file bosh-config/variables/master.yml \
  --vars-file terraform-yaml/state.yml \
  --vars-file terraform-secrets/terraform.yml \
  --vars-file common/master-bosh-decrypted.yml
code=$?
set -e

# ensure state gets copied to output
cp bosh-state/*.json updated-bosh-state

exit ${code}
