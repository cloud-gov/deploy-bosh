#!/bin/bash

set -eux

bosh interpolate ${COMMON_FILE} --path "/default_ca/private_key" > ./ca.key
AGENT_VER=$(cat nessus-agent-release/version)
sed -i "s/NESSUS_VER/$AGENT_VER/" bosh-config/operations/add-nessus-agent.yml
# todo (mxplusb): there needs to be interpolation at some point before the deployment.
# and deploy it!
set +e
bosh create-env \
  bosh-deployment/bosh.yml \
  --state bosh-state/*.json \
  --ops-file bosh-deployment/aws/cpi.yml \
  --ops-file bosh-deployment/aws/iam-instance-profile.yml \
  --ops-file bosh-deployment/aws/cli-iam-instance-profile.yml \
  --ops-file bosh-deployment/uaa.yml \
  --ops-file bosh-deployment/credhub.yml \
  --ops-file bosh-deployment/jumpbox-user.yml \
  --ops-file bosh-config/operations/cpi.yml \
  --ops-file bosh-config/operations/encryption.yml \
  --ops-file bosh-config/operations/add-cloud-gov-root-certificate.yml \
  --ops-file bosh-config/operations/masterbosh-ntp.yml \
  --ops-file bosh-config/operations/add-nessus-agent.yml \
  --vars-file bosh-config/variables/${BOSH_NAME}.yml \
  --vars-file terraform-yaml/state.yml \
  --vars-file terraform-secrets/terraform.yml \
  --vars-file ${COMMON_FILE} \
  --vars-store ./creds.yml
code=$?
set -e

# ensure state gets copied to output
cp bosh-state/*.json updated-bosh-state

# ensure we copy out creds.yml so we don't miss out on any new bosh-deployment variables
cp creds.yml updated-bosh-creds/master-bosh-creds.yml
