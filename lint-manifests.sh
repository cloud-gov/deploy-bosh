#!/bin/sh

set -e

bosh-cli login

for deployment in $(bosh-cli deployments --json | jq -r '.Tables[] | .Rows[] | .name'); do
  echo "Linting manifest for ${deployment}"
  bosh-cli -d "${deployment}" manifest > "${deployment}.yml"
  set +e
  bosh-lint lint-manifest "${deployment}.yml"
  set -e
done
