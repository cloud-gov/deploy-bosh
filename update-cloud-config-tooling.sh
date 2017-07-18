#!/bin/bash

set -e -u

files=("bosh-config/cloud-config/cloud-config-base.yml" "terraform-yaml/state.yml")
for file in ${MANIFEST_PATH:-}; do
  files=(${files[@]} "${file}")
done

for environment in "development" "staging" "production"; do
  ENVIRONMENT=${environment} spruce merge --prune terraform_outputs \
    bosh-config/cloud-config/cloud-config-bosh.yml \
    terraform-yaml-${environment}/state.yml \
    > ${environment}-bosh.yml
  files=(${files[@]} ${environment}-bosh.yml)
done

spruce merge --prune terraform_outputs "${files[@]}" > cloud-config-final.yml

bosh-cli -n update-cloud-config cloud-config-final.yml
