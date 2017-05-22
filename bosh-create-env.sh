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
    --prune terraform_outputs \
    bosh-config/bosh-create-env-deployment.yml \
    common-masterbosh/secrets.yml \
    terraform-yaml/state.yml \
> manifest.yml

# and deploy it!
bosh-cli create-env --state bosh-state/*.json manifest.yml

cp bosh-state/*.json updated-bosh-state
