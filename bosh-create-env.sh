#!/bin/bash

set -eu

# these values are merged into the manifest via environment variables instead of using spruce's (( file ))
# because (( file )) doesn't support chomping, and the bosh-io-release-resource adds newlines :(
export RELEASES_BOSH_URL=$(cat bosh-release/url  | tr -d '\n')
export RELEASES_BOSH_SHA1=$(cat bosh-release/sha1  | tr -d '\n')

export RELEASES_BOSH_AWS_CPI_URL=$(cat cpi-release/url  | tr -d '\n')
export RELEASES_BOSH_AWS_CPI_SHA1=$(cat cpi-release/sha1  | tr -d '\n')

export STEMCELL_URL=$(cat bosh-stemcell/url  | tr -d '\n')
# pointless, but the manifest requires it, and until we integrate stemcell building into this pipeline
# we have to trust what's in our bucket :/
export STEMCELL_SHA1=$(shasum bosh-stemcell/*.tgz | cut -d" " -f1)

set -x

# generate the manifest
spruce merge \
  --prune meta \
  --prune terraform_outputs \
  --prune secrets \
  bosh-config/bosh-create-env-deployment.yml \
  secrets-common/secrets.yml \
  secrets/secrets.yml \
  terraform-yaml/state.yml \
> manifest.yml

bosh interpolate secrets-common/secrets.yml --path /secrets/ca_key > ./ca-concat.key
csplit -f ca-split ca-concat.key '/-----BEGIN RSA PRIVATE KEY-----/' '{*}'
private_key=$(ls ca-split* | tail -n 1)
cat "${private_key}" > ./ca.key

# and deploy it!
set +e
bosh-cli create-env --state bosh-state/*.json manifest.yml
code=$?

# ensure state gets copied to output
cp bosh-state/*.json updated-bosh-state

exit ${code}
