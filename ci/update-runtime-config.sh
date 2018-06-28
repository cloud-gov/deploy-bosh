#!/bin/bash

set -eu

releases=$(ls releases)

pushd releases
  for release in ${releases}; do
    pushd ${release}
      tar xf *.tgz
      release=$(grep "^name" release.MF | awk '{print $2}')
      version=$(grep "^version" release.MF | awk '{print $2}' | sed -e "s/['\"']//g")
      declare -x "runtime_release_${release//-/_}"=${version}
    popd
  done
popd

bosh -n update-runtime-config \
  bosh-config/runtime-config/runtime.yml \
  --vars-env runtime \
  --vars-file terraform-yaml/state.yml \
  --vars-file common/*.yml
