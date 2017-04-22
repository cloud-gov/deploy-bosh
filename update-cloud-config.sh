#!/bin/bash

set -e -u

if [ -n "${BOSH_USERNAME:-}" ]; then
  # Hack: Add trailing newline to skip OTP prompt
  bosh-cli login <<EOF 1>/dev/null
${BOSH_USERNAME}
${BOSH_PASSWORD}

EOF
fi

files=("bosh-config/cloud-config/cloud-config-base.yml" "terraform-yaml/state.yml")
if [ -n "${MANIFEST_PATH:-}" ]; then
  files=(${files[@]} "${MANIFEST_PATH}")
fi
spruce merge --prune terraform_outputs "${files[@]}" > cloud-config-final.yml

bosh-cli -n update-cloud-config cloud-config-final.yml
