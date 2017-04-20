#!/bin/bash

set -e -u

bosh-cli login

spruce merge --prune terraform_outputs \
  cloud-config.yml \
  terraform-yaml/state.yml \
  > cloud-config-final.yml

bosh-cli update-cloud-config cloud-config-final.yml
