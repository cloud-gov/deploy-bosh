#!/bin/bash

set -e -u

files=("bosh-config/cloud-config/cloud-config-base.yml" "terraform-yaml/state.yml")
for file in ${MANIFEST_PATH:-}; do
  files=(${files[@]} "${file}")
done
spruce merge --prune terraform_outputs "${files[@]}" > cloud-config-final.yml

# TODO delete after https://github.com/cloudfoundry/bosh-cli/issues/7 is resolved
diff --old-group-format=$'\e[0;31m%<\e[0m' --new-group-format=$'\e[0;32m%>\e[0m' <(bosh-cli cloud-config) cloud-config-final.yml || true

bosh-cli -n update-cloud-config cloud-config-final.yml
