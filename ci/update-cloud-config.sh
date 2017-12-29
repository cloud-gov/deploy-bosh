#!/bin/bash

set -eu

files=("bosh-config/cloud-config/base.yml" "terraform-yaml/state.yml")
for file in ${MANIFEST_PATH:-}; do
  files=(${files[@]} "${file}")
done
spruce merge --prune terraform_outputs "${files[@]}" > cloud-config-final.yml

bosh-cli -n update-cloud-config cloud-config-final.yml
