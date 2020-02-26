## cloud.gov bosh configuration

This repo contains the Concourse pipeline and BOSH manifests for deploying BOSH via [bosh-deployment](https://github.com/cloudfoundry/bosh-deployment).

## Updating the instance types

Every once in awhile AWS adds new or deprecates old instance types, which means the cloud config will need to be updated. The easiest way to do this is by running the `generate-instance-config.sh` script and copying the output to `.vm_types` section of the [`base.yml`](./cloud-config/base.yml) file.
