#!/bin/bash

bosh interpolate \
  bosh-config/variables/terraform.yml \
  -l terraform-yaml/state.yml \
  > terraform-secrets/terraform.yml
