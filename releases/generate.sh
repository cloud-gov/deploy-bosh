#!/bin/bash

set -eux

dir=$(cd $(dirname $0); pwd -P)
releases_yaml="${RELEASES_YAML:-"${dir}/releases.yml"}"
ci_url="${CI_URL:-"https://ci.fr.cloud.gov"}"
fly_target=$(fly targets | grep "${ci_url}" | head -n 1 | awk '{print $1}')

if ! fly --target "${fly_target}" workers > /dev/null; then
  echo "Not logged in to concourse"
  exit 1
fi

config=$(mktemp)
${dir}/generate.rb "${releases_yaml}" > "${config}"
if $NO_FLY = "true" ; then
  echo ${config}
else
  fly -t "${fly_target}" set-pipeline -p "${PIPELINE:-bosh-releases}" -c "${config}"
  rm "${config}"
fi


