#!/bin/sh

set -e -x

SCRIPTPATH=$(cd $(dirname $0); pwd -P)

spruce merge \
  --prune meta --prune templates --prune terraform_outputs \
  "$SCRIPTPATH/bosh-deployment.yml" \
  "$@"
