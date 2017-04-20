#!/bin/bash

set -e -u

bosh-cli login

files=("bosh-config/cloud-config/cloud-config-base.yml" "terraform-yaml/state.yml")
if [ -n "${MANIFEST_PATH:-}" ]; then
  files=(${files[@]} "${MANIFEST_PATH}")
fi
spruce merge --prune terraform_outputs "${files[@]}" > cloud-config-final.yml

bosh-cli update-cloud-config cloud-config-final.yml
