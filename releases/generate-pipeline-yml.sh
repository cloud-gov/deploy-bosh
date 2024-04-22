#!/bin/bash

set -eux

dir=$(cd $(dirname $0); pwd -P)
releases_yaml="${RELEASES_YAML:-"${dir}/releases.yml"}"

config=$(mktemp)
"${dir}/generate.rb" "${releases_yaml}" > "${config}"
cat "${config}"
rm "${config}"
