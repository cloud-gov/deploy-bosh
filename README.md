## 18F BOSH infrastructure Manifests and Concourse pipeline

This repo contains the source for the BOSH deployment manifest and deployment pipeline for the 18F BOSH deployments.

For your first installation of BOSH, you will want to use bosh-init.

### How to generate a bosh-init manifest:

1. Install `spiff`
1. Copy the secrets example to secrets file:
`cp bosh-init-secrets.example.yml bosh-init-secrets.yml`
1. Change all the variables in CAPS in `bosh-init-secrets.yml` to proper values
1. Run `./bootstrap.sh`

You can now deploy with this BOSH, including other BOSH instances.

### How to generate a standard bosh manifest:
1. Install `spiff`
1. Copy the secrets example to secrets file:
`cp secrets.example.yml secrets.yml`
1. Change all the variables in CAPS in `secrets.yml` to proper values
1. Run `./generate.sh`

Wherever you have your bosh installation run:

1. `bosh deployment manifest.yml`
1. `bosh deploy`

### Generate certificates

You will need to create root-signed certificates because of the SSL validation
of bosh-cli v2.

Use the `generate-master-bosh-certs.sh` script to generate the root certificate
used for signing other certificates and the master director certificate and key.
Because of the SSL validation, we also use the certificate and the key in the
deployment for `bosh-init` in order to avoid bosh creating it's own certificate
and key.

Use the `generate-bosh-certs.sh` script to generate other director certificate
and key pairs.

Update the deployment manifests with the values generated from the two scripts.

In order to run these scripts you must have openssl and [certstrap](https://github.com/square/certstrap) installed.
