#!/bin/bash

set -e -u

BOSH_CACERT=${BOSH_CACERT:-}
if [ -n "$BOSH_CACERT" ]; then
  bosh --ca-cert $BOSH_CACERT -n target $BOSH_ENV
else
  bosh -n target $BOSH_ENV
fi

bosh login <<EOF 1>/dev/null
$BOSH_USERNAME
$BOSH_PASSWORD
EOF

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

files=("bosh-config/runtime-config.yml")
if [ -n "${RUNTIME_OVERRIDES:-}" ]; then
  files=(${files[@]} "${RUNTIME_OVERRIDES}")
fi
spruce merge "${files[@]}" > runtime-config-merged.yml

bosh update runtime-config runtime-config-merged.yml
