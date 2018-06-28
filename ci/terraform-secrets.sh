#!/bin/bash

bosh interpolate \
  "bosh-config/variables/${VARS_FILE:-terraform.yml}" \
  -l terraform-yaml/state.yml \
  > terraform-secrets/terraform.yml
