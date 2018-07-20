#!/bin/bash

set -eux

args=("--vars-file" "terraform-yaml/state.yml")
for ops in ${OPS_PATHS:-}; do
  args=(${args[@]} --ops-file "${ops}")
done

for environment in "development" "staging" "production"; do
  if [ -s terraform-yaml-${environment}/state.yml ]; then
    cloud_config_environment=${environment} bosh interpolate \
      bosh-config/cloud-config/bosh.yml \
      --vars-file terraform-yaml-${environment}/state.yml \
      --vars-env cloud_config \
      > ${environment}-bosh.yml
    args=(${args[@]} "--ops-file" "${environment}-bosh.yml")
  fi
done

bosh -n update-cloud-config bosh-config/cloud-config/base.yml "${args[@]}"
