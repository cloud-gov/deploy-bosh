#!/bin/bash

set -eux

args=("--vars-file" "terraform-yaml/state.yml")
for ops in ${OPS_PATHS:-}; do
  args=(${args[@]} "--ops-file" "${ops}")
done

bosh -n update-cloud-config bosh-config/cloud-config/base.yml "${args[@]}"
