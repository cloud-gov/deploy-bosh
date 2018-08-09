#!/bin/bash

set -eux

args=("--vars-file" "terraform-yaml/state.yml")
for ops in ${OPS_PATHS:-}; do
  args=(${args[@]} "--ops-file" "${ops}")
done

# Collect isolation segment configs
for segment in terraform-yaml-isolation-segment-*; do
  if [ -d "${segment}" ]; then
    outname="${segment/terraform-yaml-/}.yml"
    cloud_config_segment="${segment/terraform-yaml-isolation-segment-/}" bosh interpolate \
      bosh-config/cloud-config/isolation-segment.yml \
      --vars-file "${segment}/state.yml" \
      --vars-env cloud_config \
      > "${outname}"
    args=(${args[@]} "--ops-file" "${outname}")
  fi
done

bosh -n update-cloud-config bosh-config/cloud-config/base.yml "${args[@]}"
