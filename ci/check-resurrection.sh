#!/bin/bash

set -eux

echo "Checking if resurrection is enabled..."
resurrection_status=$(bosh curl /resurrection)

if [[ "${resurrection_status}" == '{"resurrection":true}' ]]; then
  echo "Resurrection is on"
  exit 0
else
  echo "Resurrection is off, run 'bosh update-resurrection on' to enable"
  exit 1
fi
