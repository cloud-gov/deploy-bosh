#!/bin/sh

set -e -x

SCRIPTPATH=$( cd $(dirname $0) ; pwd -P )

spruce merge \
  $SCRIPTPATH/bosh-deployment.yml \
  $@
