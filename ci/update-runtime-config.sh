#!/bin/bash

set -eu

releases=$(ls releases)

pushd releases
  for release in ${releases}; do
    pushd ${release}
      tar xf *.tgz
      release=$(grep "^name" release.MF | awk '{print $2}')
      version=$(grep "^version" release.MF | awk '{print $2}' | sed -e "s/['\"']//g")
      declare -x "release_${release//-/_}"=${version}
    popd
  done
popd

files=("bosh-config/runtime-config/base.yml" "terraform-yaml/state.yml")
if [ -n "${RUNTIME_OVERRIDES:-}" ]; then
  files=(${files[@]} "${RUNTIME_OVERRIDES}")
fi
spruce merge --prune terraform_outputs "${files[@]}" > runtime-config-merged.yml

bosh-cli -n update-runtime-config runtime-config-merged.yml
