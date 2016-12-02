#!/bin/sh

set -e -x

SCRIPTPATH=$( cd $(dirname $0) ; pwd -P )

spruce merge \
  --prune meta --prune templates \
  $SCRIPTPATH/bosh-deployment.yml \
  $@
