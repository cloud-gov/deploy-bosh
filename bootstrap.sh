#!/bin/sh

# Generate manifest and initial deploy
set -e -x

SCRIPTPATH=$( cd $(dirname $0) ; pwd -P )

SECRETS=$SCRIPTPATH/bosh-init-secrets.yml
MANIFEST=$SCRIPTPATH/bosh-init-manifest.yml
if [ ! -z "$1" ]; then
  SECRETS=$1
fi
if [ ! -z "$2" ]; then
  MANIFEST=$2
fi

spruce merge \
  $SCRIPTPATH/bosh-init-deployment.yml \
  $SECRETS \
  > $MANIFEST

bosh-init deploy $MANIFEST

# Upload releases and stemcell required for deploying another bosh
bosh upload release https://bosh.io/d/github.com/cloudfoundry/bosh
bosh upload release https://bosh.io/d/github.com/cloudfoundry/uaa-release
bosh upload release https://bosh.io/d/github.com/cloudfoundry-incubator/bosh-aws-cpi-release
bosh upload stemcell https://bosh.io/d/stemcells/bosh-aws-xen-hvm-ubuntu-trusty-go_agent
